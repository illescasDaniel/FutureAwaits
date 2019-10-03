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

	public typealias AwaitResult = Result<ValueType, ErrorType>
	
	public static var `default`: Await<ValueType, ErrorType> {
		return Await()
	}
	
	public let queue: DispatchQueue?
	public let timeout: DispatchTime?
	
	public init(blockQueue queue: DispatchQueue? = nil, timeout: DispatchTime? = nil) {
		self.queue = queue
		self.timeout = timeout
	}

	public func run(_ block: @escaping AsyncAwait.ClosureCallback<AwaitResult>) -> AwaitResult {

		let dispatchGroup = DispatchGroup()
		dispatchGroup.enter()

		var result: AwaitResult?
		let resultF: AsyncAwait.Callback<AwaitResult> = { r in
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

		dispatchGroup.wait()

		if let validResult = result {
			return validResult
		}

		fatalError()
	}

	public func run(_ blocks: () -> Result<ValueType, ErrorType>...) -> Result<[ValueType], ErrorType> {
		return run(blocks)
	}
	
	public func run(_ blocks: [() -> Result<ValueType, ErrorType>]) -> Result<[ValueType], ErrorType> {
		var results: [Int: ValueType] = [:]
		var output: Result<[ValueType], ErrorType>?
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
				output = .failure(error)
				locker2.unlock()
			}
		}
		if output == nil {
			output = Result.success(results.sorted(by: { lhs, rhs in lhs.key < rhs.key}).map { $1 })
		}
		return output ?? .success([])
	}
	
	public func runOmittingErrors(_ blocks: () -> Result<ValueType, ErrorType>...) -> Result<[Int: ValueType], ErrorType> {
		return runOmittingErrors(blocks)
	}
	
	public func runOmittingErrors(_ blocks: [() -> Result<ValueType, ErrorType>]) -> Result<[Int: ValueType], ErrorType> {
		var results: [Int: ValueType] = [:]
		var output: Result<[Int: ValueType], ErrorType>?
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
				output = .failure(error)
				locker2.unlock()
			}
		}
		if !results.isEmpty {
			output = Result.success(results)
		}
		return output ?? .success([:])
	}
}
