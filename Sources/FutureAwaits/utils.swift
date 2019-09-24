//
//  File.swift
//  
//
//  Created by Daniel Illescas Romero on 24/09/2019.
//

import enum Swift.Result
import class Dispatch.DispatchQueue
import struct Dispatch.DispatchTime

public func async(_ block: @escaping AsyncAwait.Completion) {
	return AsyncAwait.runOnGlobalQueue(block)
}
public func asyncUI(_ block: @escaping AsyncAwait.Completion) {
	return AsyncAwait.runOnUIQueue(block)
}

public func await<Value, E>(
	queue: DispatchQueue? = nil,
	timeout: DispatchTime? = nil,
	_ block: @escaping AsyncAwait.ClosureCallback<Result<Value, E>>
) -> Result<Value, AsyncAwait.Error<E>> {
	return Await<Value,E>(blockQueue: queue, timeout: timeout).run(block)
}

public func concurrentlyPerform(_ blocks: () -> Void ...) {
	DispatchQueue.concurrentPerform(iterations: blocks.count) { index in
		blocks[index]()
	}
}
