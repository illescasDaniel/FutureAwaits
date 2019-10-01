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
import class Foundation.NSLock
import class Dispatch.DispatchGroup
import class Dispatch.DispatchQueue
import struct Dispatch.DispatchTime

public struct Await<ValueType, ErrorType: Error> {
	
	public static var `default`: Await<ValueType, ErrorType> {
		return Await()
	}
	
	public let queue: DispatchQueue?
	public let timeout: DispatchTime?
	
	public init(blockQueue queue: DispatchQueue? = nil, timeout: DispatchTime? = nil) {
		self.queue = queue
		self.timeout = timeout
	}
	
	public func run(_ block: @escaping AsyncAwait.ClosureCallback<Result<ValueType, ErrorType>>) -> Result<ValueType, AsyncAwait.Error<ErrorType>> {
		
		let dispatchGroup = DispatchGroup()
		dispatchGroup.enter()
		
		var result: Result<ValueType, ErrorType>?
		let resultF: AsyncAwait.Callback<Result<ValueType, ErrorType>> = { r in
			result = r
			dispatchGroup.leave()
		}
		
		if let queue = self.queue {
			queue.async {
				block(resultF)
			}
		} else {
			block(resultF)
		}
		
		if let timeout = self.timeout {
			if dispatchGroup.wait(timeout: timeout)	== .timedOut {
				return .failure(.timedOut)
			}
		} else {
			dispatchGroup.wait()
		}
		
		if let validResult = result {
			switch validResult {
			case .success(let resultValue):
				return .success(resultValue)
			case .failure(let resultError):
				return .failure(.error(resultError))
			}
		}
		
		return .failure(.noResult)
	}
	
	// TODO: refactor to use `run` method of viceversa
	internal func _run(_ block: @escaping AsyncAwait.ClosureCallback<Result<ValueType, AsyncAwait.Error<ErrorType>>>) -> Result<ValueType, AsyncAwait.Error<ErrorType>> {
		
		let dispatchGroup = DispatchGroup()
		dispatchGroup.enter()
		
		var result: Result<ValueType, AsyncAwait.Error<ErrorType>>?
		let resultF: AsyncAwait.Callback<Result<ValueType, AsyncAwait.Error<ErrorType>>> = { r in
			result = r
			dispatchGroup.leave()
		}
		
		if let queue = queue {
			queue.async {
				block(resultF)
			}
		} else {
			block(resultF)
		}
		
		if let timeout = timeout {
			if dispatchGroup.wait(timeout: timeout)	== .timedOut {
				return .failure(.timedOut)
			}
		} else {
			dispatchGroup.wait()
		}
		
		return result ?? .failure(.noResult)
	}
	
	public func run(_ blocks: () -> Result<ValueType, AsyncAwait.Error<ErrorType>>...) -> Result<[ValueType], AsyncAwait.Error<ErrorType>> {
		return run(blocks)
	}
	
	public func run(_ blocks: [() -> Result<ValueType, AsyncAwait.Error<ErrorType>>]) -> Result<[ValueType], AsyncAwait.Error<ErrorType>> {
		var results: [Int: ValueType] = [:]
		var output: Result<[ValueType], AsyncAwait.Error<ErrorType>>?
		let (locker, locker2) = (NSLock(), NSLock())
		DispatchQueue.concurrentPerform(iterations: blocks.count) { index in
			guard output == nil else { return }
			let result = blocks[index]()
			switch result {
			case .success(let output):
				locker.lock()
				results[index] = output
				locker.unlock()
			case .failure(let error):
				locker2.lock()
				output = Result.failure(error)
				locker2.unlock()
			}
		}
		if output == nil {
			output = Result.success(results.sorted(by: { lhs, rhs in lhs.key < rhs.key}).map { $1 })
		}
		return output ?? .failure(.noResult)
	}
	
	public func runOmittingErrors(_ blocks: () -> Result<ValueType, AsyncAwait.Error<ErrorType>>...) -> Result<[Int: ValueType], AsyncAwait.Error<ErrorType>> {
		return runOmittingErrors(blocks)
	}
	
	public func runOmittingErrors(_ blocks: [() -> Result<ValueType, AsyncAwait.Error<ErrorType>>]) -> Result<[Int: ValueType], AsyncAwait.Error<ErrorType>> {
		var results: [Int: ValueType] = [:]
		var output: Result<[Int: ValueType], AsyncAwait.Error<ErrorType>>?
		let (locker, locker2) = (NSLock(), NSLock())
		DispatchQueue.concurrentPerform(iterations: blocks.count) { index in
			guard output == nil else { return }
			let result = blocks[index]()
			switch result {
			case .success(let output):
				locker.lock()
				results[index] = output
				locker.unlock()
			case .failure(let error):
				locker2.lock()
				output = Result.failure(error)
				locker2.unlock()
			}
		}
		if !results.isEmpty {
			output = Result.success(results)
		}
		return output ?? .failure(.noResult)
	}
}
