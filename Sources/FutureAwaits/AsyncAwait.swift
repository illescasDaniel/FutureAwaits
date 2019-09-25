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
