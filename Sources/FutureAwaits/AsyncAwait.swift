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

import protocol Swift.Error
import protocol Foundation.LocalizedError
import class Dispatch.DispatchQueue

import Foundation

public enum AsyncAwait {
	
	public typealias Completion = () -> Void
	public typealias Callback<T> = (T) -> Void
	public typealias ClosureCallback<T> = Callback<Callback<T>>
	
	public enum Error<E: Swift.Error>: LocalizedError {
		case noResult
		case timedOut
		case error(E)
		public var errorDescription: String? {
			switch self {
			case .noResult:
				return "AsyncAwait.Error.noResult"
			case .timedOut:
				return "AsyncAwait.Error.timedOut"
			case .error(let error):
				return "AsyncAwait.Error - \(error.localizedDescription)"
			}
		}
	}
	
	public static func runOnGlobalQueue(_ block: @escaping Completion) {
		DispatchQueue.global().async {
			block()
		}
	}
	
	public static func runOnUIQueue(_ block: @escaping Completion) {
		DispatchQueue.main.async {
			block()
		}
	}
}
