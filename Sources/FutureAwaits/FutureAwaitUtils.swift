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

typealias AwaitError = AsyncAwait.Error

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
