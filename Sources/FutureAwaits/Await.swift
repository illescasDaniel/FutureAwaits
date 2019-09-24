//
//  File.swift
//  
//
//  Created by Daniel Illescas Romero on 24/09/2019.
//

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
	fileprivate func _run(_ block: @escaping AsyncAwait.ClosureCallback<Result<ValueType, AsyncAwait.Error<ErrorType>>>) -> Result<ValueType, AsyncAwait.Error<ErrorType>> {
		
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
