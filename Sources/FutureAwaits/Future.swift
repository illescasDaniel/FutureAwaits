//
//  File.swift
//  
//
//  Created by Daniel Illescas Romero on 24/09/2019.
//

import enum Swift.Result
import class Dispatch.DispatchQueue
import struct Dispatch.DispatchTime

public class Future<ValueType, ErrorType: Error> {
	
	typealias FutureResult = Result<ValueType, AsyncAwait.Error<ErrorType>>
	
	private let resultBuilder: () -> FutureResult
	private var cachedResult: FutureResult?
	
	init(_ resultBuilder: @escaping @autoclosure () -> FutureResult) {
		self.resultBuilder = resultBuilder
	}
	
	init(_ resultClosureBuilder: @escaping AsyncAwait.ClosureCallback<Result<ValueType, ErrorType>>, blockQueue: DispatchQueue? = nil, timeout: DispatchTime? = nil) {
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
	
	/// The customQueue parameter MUST NOT be the main queue
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
}
