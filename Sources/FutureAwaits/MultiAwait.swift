//
//  File.swift
//  
//
//  Created by Daniel Illescas Romero on 24/09/2019.
//

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

