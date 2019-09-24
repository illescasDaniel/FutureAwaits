//
//  File.swift
//  
//
//  Created by Daniel Illescas Romero on 24/09/2019.
//

import enum Swift.Result

public extension Result {
	@discardableResult
	func onSuccess(_ completionHandler: @escaping AsyncAwait.Callback<Success>) -> Result<Success, Failure> {
		if case .success(let value) = self {
			completionHandler(value)
		}
		return self
	}
	@discardableResult
	func onError(_ completionHandler: @escaping AsyncAwait.Callback<Failure>) -> Result<Success, Failure> {
		if case .failure(let error) = self {
			completionHandler(error)
		}
		return self
	}
}
