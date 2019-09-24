import protocol Swift.Error
import class Dispatch.DispatchQueue

public enum AsyncAwait {
	
	public typealias Completion = () -> Void
	public typealias Callback<T> = (T) -> Void
	public typealias ClosureCallback<T> = Callback<Callback<T>>
	
	public enum Error<E: Swift.Error>: Swift.Error {
		case noResult
		case timedOut
		case error(E)
	}
	
	static func runOnGlobalQueue(_ block: @escaping Completion) {
		DispatchQueue.global().async {
			block()
		}
	}
	
	static func runOnUIQueue(_ block: @escaping Completion) {
		DispatchQueue.main.async {
			block()
		}
	}
}
