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

import class Dispatch.DispatchQueue
import struct Dispatch.DispatchTime

public struct Futures {
	
	// MARK: - Wait
	
	public static func wait_<T,T1, E,E1>(
		_ future0: Future<T, E>, _ future1: Future<T1, E1>
	) -> Future<(T,T1), Error> {
		return future0.flatMap { f0 in
			future1.map { (f0, $0) }
		}
	}
	
	public static func wait<T,T1,T2, E,E1,E2>(
		_ future0: Future<T, E>, _ future1: Future<T1, E1>, _ future2: Future<T2, E2>
	) -> Future<(T,T1,T2), Error> {
		return future0.flatMap { f0 in
			future1.flatMap { f1 in
				future2.map { (f0, f1, $0) }
			}
		}
	}
	
	public static func wait<T,T1,T2,T3, E,E1,E2,E3>(
		_ future0: Future<T, E>, _ future1: Future<T1, E1>,
		_ future2: Future<T2, E2>, _ future3: Future<T3, E3>
	) -> Future<(T,T1,T2,T3), Error> {
		return future0.flatMap { f0 in
			future1.flatMap { f1 in
				future2.flatMap { f2 in
					future3.map { (f0, f1, f2, $0) }
				}
			}
		}
	}
	
	public static func wait<T,T1,T2,T3,T4, E,E1,E2,E3,E4>(
		_ future0: Future<T, E>, _ future1: Future<T1, E1>,
		_ future2: Future<T2, E2>, _ future3: Future<T3, E3>,
		_ future4: Future<T4, E4>
	) -> Future<(T,T1,T2,T3,T4), Error> {
		return future0.flatMap { f0 in
			future1.flatMap { f1 in
				future2.flatMap { f2 in
					future3.flatMap { f3 in
						future4.map { (f0, f1, f2, f3, $0) }
					}
				}
			}
		}
	}
	
	public static func wait<T,T1,T2,T3,T4,T5, E,E1,E2,E3,E4,E5>(
		_ future0: Future<T, E>, _ future1: Future<T1, E1>,
		_ future2: Future<T2, E2>, _ future3: Future<T3, E3>,
		_ future4: Future<T4, E4>, _ future5: Future<T5, E5>
	) -> Future<(T,T1,T2,T3,T4,T5), Error> {
		return future0.flatMap { f0 in
			future1.flatMap { f1 in
				future2.flatMap { f2 in
					future3.flatMap { f3 in
						future4.flatMap { f4 in
							future5.map { (f0, f1, f2, f3, f4, $0) }
						}
					}
				}
			}
		}
	}
	
	// MARK: - Combine
	
	public static func combine<ValueType, ErrorType: Error>(
		_ blocks: Future<ValueType, ErrorType>...,
		blockQueue queue: DispatchQueue? = nil,
		timeout: DispatchTime? = nil
	) -> Future<[ValueType], ErrorType>{
		return combine(blocks, blockQueue: queue, timeout: timeout)
	}
	
	public static func combine<ValueType, ErrorType: Error>(
		_ blocks: [Future<ValueType, ErrorType>],
		blockQueue queue: DispatchQueue? = nil,
		timeout: DispatchTime? = nil
	) -> Future<[ValueType], ErrorType>{
		return Future<[ValueType], ErrorType>(
			Await<ValueType, ErrorType>(blockQueue: queue ?? .global()).run((blocks.map { block in { block.syncResult } }))
		)
	}
	
	public static func combineOmittingErrors<ValueType, ErrorType: Error>(
		_ blocks: Future<ValueType, ErrorType>...,
		blockQueue queue: DispatchQueue? = nil,
		timeout: DispatchTime? = nil
	) -> Future<[Int: ValueType], ErrorType>{
		return combineOmittingErrors(blocks, blockQueue: queue, timeout: timeout)
	}
	
	public static func combineOmittingErrors<ValueType, ErrorType: Error>(
		_ blocks: [Future<ValueType, ErrorType>],
		blockQueue queue: DispatchQueue? = nil,
		timeout: DispatchTime? = nil
	) -> Future<[Int: ValueType], ErrorType>{
		return Future<[Int: ValueType], ErrorType>(
			Await<ValueType, ErrorType>(blockQueue: queue ?? .global()).runOmittingErrors((blocks.map { block in { block.syncResult } }))
		)
	}
	
	// MARK: - Combine for different types
	
	public static func combine<T,T1, E,E1: Error>(
		_ future0: Future<T,E>, _ future1: Future<T1,E1>,
		blockQueue queue: DispatchQueue? = nil,
		timeout: DispatchTime? = nil
	) -> Future<(T,T1), AsyncAwait.Failure> {
		return Future<(T,T1), AsyncAwait.Failure>(
			MultiAwait(blockQueue: queue ?? .global()).run(future0.syncResult, future1.syncResult)
		)
	}
	
	public static func combineOmittingErrors<T,T1, E,E1: Error>(
		_ future0: Future<T,E>, _ future1: Future<T1,E1>,
		blockQueue queue: DispatchQueue? = nil,
		timeout: DispatchTime? = nil
	) -> Future<(T?,T1?), Error> {
		return Future<(T?,T1?), Error>(
			MultiAwait(blockQueue: queue ?? .global()).runOmittingErrors(future0.syncResult, future1.syncResult)
		)
	}
}
