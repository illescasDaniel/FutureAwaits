import XCTest
@testable import FutureAwaits

final class FutureAwaitsTests: XCTestCase {
	
	enum Test: Error {
		case test
	}
	
	// Result with Await
	
	func somethingAsync() -> Result<Int, AsyncAwait.Error<Test>> {
		return await { completion in
			DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
				let retrievedValue = 23
				if Bool.random() {
					completion(.failure(Test.test))	 // ??
				} else {
					completion(.success(retrievedValue))
				}
			}
		}
	}
    
	// Futures

	func somethingFuture() -> Future<Int, Test> {
		return Future({ completion in
			DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
				let retrievedValue = 23
				if Bool.random() {
					completion(.failure(Test.test))
				} else {
					completion(.success(retrievedValue))
				}
			}
		})
	}

	func somethingFuture2() -> Future<Int, Test> {
		return Future(await { completion in
			DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
				let retrievedValue = 30
				if Bool.random() {
					completion(.failure(Test.test))
				} else {
					completion(.success(retrievedValue))
				}
			}
		})
	}

	func somethingFuture3() -> Future<Int, Test> {
		return Future(somethingFuture2())
	}

	func somethingFuture4() -> Future<(Int, Int), Error> {
		return Future(MultiAwait.default.run(
			self.somethingAsync(),
			self.somethingAsync()
		))
	}

	func somethingFuture5() -> Future<[Int], Test> {
		return Future(Await.default.run(
			{ self.somethingAsync() },
			{ self.somethingAsync() }
		))
	}

	func somethingFuture6() -> Future<[Int: Int], Test> {
		return Future(Await.default.runOmittingErrors(
			{ self.somethingAsync() },
			{ self.somethingAsync() }
		))
	}

	// -- REAL TESTS --
	
	func testAwaits() {
		
		let expectation = XCTestExpectation(description: "testAwaitsExpectation")
		expectation.expectedFulfillmentCount = 507
		expectation.assertForOverFulfill = true
		
		let locker = NSLock()
		
		func realFulfill() {
			locker.lock()
			expectation.fulfill()
			locker.unlock()
		}
		
		async {
			for _ in 0..<101 {
				Await.default.run(
					{ self.somethingAsync() },
					{ self.somethingAsync() }
				).onSuccess { results in
					print(results)
					realFulfill()
				}.onFailure { error in
					print(error)
					realFulfill()
				}
			}
		}
		
		async {
			for _ in 0..<101 {
				Await.default.runOmittingErrors(
					{ self.somethingAsync() },
					{ self.somethingAsync() }
				).onSuccess { results in
					print(results)
					realFulfill()
				}.onFailure { error in
					print(error)
					realFulfill()
				}
			}
		}
		async {
			for _ in 0..<102 {
				Await.default.run(
					{ self.somethingAsync() },
					{ self.somethingAsync() },
					{ self.somethingAsync() },
					{ self.somethingAsync() }
				).onSuccess { results in
					print(results)
					realFulfill()
				}.onFailure {
					print($0)
					realFulfill()
				}
			}
		}

		async {
			for _ in 0..<101 {
				MultiAwait.default.run(
					self.somethingAsync(),
					self.somethingAsync()
				).onSuccess { results in
					print(results)
					realFulfill()
				}.onFailure {
					print($0)
					realFulfill()
				}
			}
		}
		async {
			for _ in 0..<102 {
				MultiAwait.default.runOmittingErrors(
					self.somethingAsync(),
					self.somethingAsync()
				).onSuccess { results in
					print(results)
					realFulfill()
				}.onFailure {
					print($0)
					realFulfill()
				}
			}
		}
		
		wait(for: [expectation], timeout: 70)
	}
	
	func testFutures() {
		
		let expectation = XCTestExpectation(description: "testFuturesExpectation")
		expectation.expectedFulfillmentCount = 8
		expectation.assertForOverFulfill = true
		
		let locker = NSLock()
		
		func realFulfill() {
			locker.lock()
			expectation.fulfill()
			locker.unlock()
		}
		
		self.somethingFuture().then {
			print($0)
			realFulfill()
		}
		self.somethingFuture2().then {
			print($0)
			realFulfill()
		}
		self.somethingFuture3().then {
			print($0)
			realFulfill()
		}

		async {
			let result1 = self.somethingFuture().syncResult
			let result2 = self.somethingFuture2().syncResult
			print(result1, result2)
			realFulfill()
		}

		self.somethingFuture3().then {
			print($0)
			realFulfill()
		}
		
		self.somethingFuture4().then {
			print($0)
			realFulfill()
		}

		self.somethingFuture5().then {
			print($0)
			realFulfill()
		}

		self.somethingFuture6().then {
			print("THIS:", $0)
			realFulfill()
		}

		wait(for: [expectation], timeout: 70)
	}
	
	func testFuturesFeatures() {
		
		let expectation = XCTestExpectation(description: "testFuturesExpectation")
		expectation.expectedFulfillmentCount = 171
		expectation.assertForOverFulfill = true
		
		let locker = NSLock()
		
		func realFulfill() {
			locker.lock()
			expectation.fulfill()
			locker.unlock()
		}
		
		self.somethingFuture().onSuccess { value in
			print(value)
			realFulfill()
		}.onFailure { error in
			print(error)
			realFulfill()
		}
		
		self.somethingFuture()
			.map { $0 * 2}
			.then { result in
				print(result)
				realFulfill()
			}
		
		for _ in 0..<107 {
			Future.combine([
				self.somethingFuture(), self.somethingFuture2()
			]).onSuccess { results in
				print(results)
				realFulfill()
			}.onFailure { error in
				print(error)
				realFulfill()
			}
		}
		
		for _ in 0..<62 {
			Future.combineOmittingErrors([
				self.somethingFuture(), self.somethingFuture2(), self.somethingFuture3()
			]).onSuccess { results in
				print(results)
				realFulfill()
			}.onFailure { error in
				print(error)
				realFulfill()
			}
		}
		
		wait(for: [expectation], timeout: 70)
	}

	static var allTests = [
		("testAwaits", testAwaits),
		("testFutures", testFutures),
		("testFuturesFeatures", testFuturesFeatures)
    ]
}
