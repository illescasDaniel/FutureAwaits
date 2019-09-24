//
//  File.swift
//  
//
//  Created by Daniel Illescas Romero on 24/09/2019.
//

import enum Swift.Result
import class Dispatch.DispatchQueue
import struct Dispatch.DispatchTime

public typealias NaiveFuture<T> = Future<T, Never>
public typealias VoidFuture<E: Error> = Future<Void, E>

public class Future<ValueType, ErrorType: Error> {
	
	typealias FutureResult = Result<ValueType, AsyncAwait.Error<ErrorType>>
	
	private let resultBuilder: () -> FutureResult
	private var cachedResult: FutureResult?
	
	init(_ resultBuilder: @escaping @autoclosure () -> FutureResult) {
		self.resultBuilder = resultBuilder
	}
	
	init(
		_ resultClosureBuilder: @escaping AsyncAwait.ClosureCallback<Result<ValueType, ErrorType>>,
		blockQueue: DispatchQueue? = nil,
		timeout: DispatchTime? = nil
	) {
		self.resultBuilder = {
			return Await<ValueType, ErrorType>(blockQueue: blockQueue, timeout: timeout).run(resultClosureBuilder)
		}
	}
	
	init(_ otherFuture: Future) {
		self.resultBuilder = otherFuture.resultBuilder
		self.cachedResult = otherFuture.cachedResult
	}
	
	/// Must be call outside of the main thread
	var syncResult: FutureResult {
		if let savedResult = cachedResult {
			return savedResult
		}
		let result = resultBuilder()
		cachedResult = result
		return result
	}
	
	/// The customQueue parameter MUST NOT be the `main` queue
	@discardableResult
	func then(customQueue: DispatchQueue? = nil, _ callback: @escaping AsyncAwait.Callback<FutureResult>) -> Future {
		if let queue = customQueue {
			queue.async {
				callback(self.syncResult)
			}
		} else {
			AsyncAwait.runOnGlobalQueue {
				callback(self.syncResult)
			}
		}
		return self
	}
	
	/// Must be call outside of the main thread
	func get() throws -> ValueType {
		return try syncResult.get()
	}
	
	func map<NewSuccess>(_ transform: @escaping (ValueType) -> NewSuccess) -> Future<NewSuccess, ErrorType> {
		return Future<NewSuccess, ErrorType>(self.syncResult.map(transform))
	}
	
	func mapError<NewFailure>(_ transform: @escaping (ErrorType) -> NewFailure) -> Future<ValueType, NewFailure> {
		return Future<ValueType, NewFailure>(self.syncResult.mapError { asyncAwaitError in
			switch asyncAwaitError {
			case .noResult:
				return AsyncAwait.Error.noResult
			case .timedOut:
				return AsyncAwait.Error.timedOut
			case .error(let error):
				return AsyncAwait.Error.error(transform(error))
			}
		})
	}
	
	@discardableResult
	func onSuccess(customQueue: DispatchQueue? = nil, _ completionHandler: @escaping (ValueType) -> Void) -> Future {
		self.then(customQueue: customQueue) { result in
			if case .success(let successValue) = result {
				completionHandler(successValue)
			}
		}
		return self
	}
	
	/// Called on ANY error (time outs of the await function or custom errors)
	@discardableResult
	func onFailure(
		customQueue: DispatchQueue? = nil, _
		completionHandler: @escaping (AsyncAwait.Error<ErrorType>) -> Void
	) -> Future {
		self.then(customQueue: customQueue) { result in
			if case .failure(let errorValue) = result {
				completionHandler(errorValue)
			}
		}
		return self
	}
	
	@discardableResult
	func onError(
		customQueue: DispatchQueue? = nil, _
		completionHandler: @escaping (ErrorType) -> Void
	) -> Future {
		self.then(customQueue: customQueue) { result in
			if case .failure(let errorValue) = result, case .error(let error) = errorValue {
				completionHandler(error)
			}
		}
		return self
	}
}
