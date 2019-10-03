/*
The MIT License (MIT)

Copyright (c) 2019 Daniel Illescas Romero <https://github.com/illescasDaniel/FutureAwaits>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

import enum Swift.Result
import class Dispatch.DispatchQueue
import struct Dispatch.DispatchTime

public typealias NaiveFuture<T> = Future<T, Never>
public typealias VoidFuture<E: Error> = Future<Void, E>

public class Future<ValueType, ErrorType: Error> {

	private let _futureQueue = DispatchQueue(label: "_futureQueue_", qos: .utility)
	
	public typealias FutureResult = Result<ValueType, ErrorType>
	
	private let resultBuilder: () -> FutureResult
	private var cachedResult: FutureResult?
	
	public init(_ resultBuilder: @escaping @autoclosure () -> FutureResult) {
		self.resultBuilder = resultBuilder
	}
	
	public init(
		_ resultClosureBuilder: @escaping AsyncAwait.ClosureCallback<Result<ValueType, ErrorType>>,
		blockQueue: DispatchQueue? = nil,
		timeout: DispatchTime? = nil
	) {
		self.resultBuilder = {
			return Await<ValueType, ErrorType>(blockQueue: blockQueue, timeout: timeout).run(resultClosureBuilder)
		}
	}
	
	public init(_ otherFuture: Future) {
		self.resultBuilder = otherFuture.resultBuilder
		self.cachedResult = otherFuture.cachedResult
	}
	
	/// Must be call outside of the main thread
	public var syncResult: FutureResult {
		if let savedResult = cachedResult {
			return savedResult
		}
		let result = resultBuilder()
		cachedResult = result
		return result
	}

	@discardableResult
	public func then(_ callback: @escaping AsyncAwait.Callback<FutureResult>) -> Future {
		_futureQueue.async {
			callback(self.syncResult)
		}
		return self
	}
	
	/// Must be call outside of the main thread
	public func get() throws -> ValueType {
		return try syncResult.get()
	}
	
	public func map<NewSuccess>(_ transform: @escaping (ValueType) -> NewSuccess) -> Future<NewSuccess, ErrorType> {
		return Future<NewSuccess, ErrorType>(self.syncResult.map(transform))
	}
	
	public func flatMap<NewSuccess>(_ transform: @escaping (ValueType) -> Future<NewSuccess, ErrorType>) -> Future<NewSuccess, ErrorType> {
		return Future<NewSuccess, ErrorType>(self.syncResult.flatMap { transform($0).syncResult})
	}
	
	public func flatMap<NewSuccess, NewFailure>(_ transform: @escaping (ValueType) -> Future<NewSuccess, NewFailure>) -> Future<NewSuccess, Error> {
		return Future<NewSuccess, Error>({ completion in
			switch self.syncResult {
			case .success(let value):
				let result = transform(value).syncResult
				switch result {
				case .success(let value2):
					completion(.success(value2))
				case .failure(let error1):
					completion(.failure(error1))
				}
			case .failure(let error1):
				completion(.failure(error1))
			}
		})
	}
	
	public func mapError<NewFailure>(_ transform: @escaping (ErrorType) -> NewFailure) -> Future<ValueType, NewFailure> {
		return Future<ValueType, NewFailure>(self.syncResult.mapError(transform))
	}
	
	@discardableResult
	public func onSuccess(_ completionHandler: @escaping (ValueType) -> Void) -> Future {
		return self.then { result in
			if case .success(let successValue) = result {
				completionHandler(successValue)
			}
		}
	}
	
	/// Called on ANY error (time outs of the await function or custom errors)
	@discardableResult
	public func onFailure(_
		completionHandler: @escaping (ErrorType) -> Void
	) -> Future {
		return self.then { result in
			if case .failure(let errorValue) = result {
				completionHandler(errorValue)
			}
		}
	}
}
