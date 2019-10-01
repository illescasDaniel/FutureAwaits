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
import class Dispatch.DispatchQueue
import struct Dispatch.DispatchTime

public struct MultiAwait {
	
	public static var `default`: MultiAwait {
		return MultiAwait()
	}
	
	public let queue: DispatchQueue?
	public let timeout: DispatchTime?
	
	public init(blockQueue queue: DispatchQueue? = nil, timeout: DispatchTime? = nil) {
		self.queue = queue
		self.timeout = timeout
	}
	
	public func run<T,U, E,EE>(
		_ block0: @escaping @autoclosure () -> Result<T, AsyncAwait.Error<E>>,
		_ block1: @escaping @autoclosure () -> Result<U, AsyncAwait.Error<EE>>,
		timeout: DispatchTime? = nil
		) -> Result<(T,U), AsyncAwait.Error<Error>> {
	
		var results: (T?, U?) = (nil, nil)
		var output: Result<(T,U), AsyncAwait.Error<Error>>?
		let (locker, locker2) = (NSLock(), NSLock())
		
		DispatchQueue.concurrentPerform(iterations: 2) { index in
			guard output == nil else { return }
			do {
				switch index {
				case 0:
					let value = try block0().get()
					locker.lock()
					results.0 = value
					locker.unlock()
				case 1:
					let value = try block1().get()
					locker.lock()
					results.1 = value
					locker.unlock()
				default: break
				}
			} catch {
				locker2.lock()
				output = .failure(.error(error))
				locker2.unlock()
			}
		}
		
		if output == nil, let result0 = results.0, let result1 = results.1 {
			output = .success( (result0, result1) )
		}
		
		return output ?? Result.failure(.noResult)
	}
	
	public func runOmittingErrors<T,U, E,EE>(
		_ block0: @escaping @autoclosure () -> Result<T, AsyncAwait.Error<E>>,
		_ block1: @escaping @autoclosure () -> Result<U, AsyncAwait.Error<EE>>,
		timeout: DispatchTime? = nil
		) -> Result<(T?,U?), AsyncAwait.Error<Error>> {
	
		var results: (T?, U?) = (nil, nil)
		var output: Result<(T?,U?), AsyncAwait.Error<Error>>?
		let (locker, locker2) = (NSLock(), NSLock())
		
		DispatchQueue.concurrentPerform(iterations: 2) { index in
			do {
				switch index {
				case 0:
					let value = try block0().get()
					locker.lock()
					results.0 = value
					locker.unlock()
				case 1:
					let value = try block1().get()
					locker.lock()
					results.1 = value
					locker.unlock()
				default: break
				}
			} catch {
				locker2.lock()
				output = .failure(.error(error))
				locker2.unlock()
			}
		}
		
		if results.0 != nil || results.1 != nil || output == nil {
			output = Result.success(results)
		}

		return output ?? Result.failure(.noResult)
	}
	
	// ...
	
	// TODO: add versions for 3 or more parameters
}

