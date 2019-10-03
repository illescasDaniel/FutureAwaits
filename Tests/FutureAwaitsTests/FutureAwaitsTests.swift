import XCTest
@testable import FutureAwaits

final class FutureAwaitsTests: XCTestCase {
	
	enum Test: Error, LocalizedError {
		case test
		var errorDescription: String? {
			return NSLocalizedString("error here!", comment: "")
		}
	}
	enum Other: Error, LocalizedError {
		case test
		var errorDescription: String? {
			return NSLocalizedString("error here other!", comment: "")
		}
	}
	
	// Result with Await

	func somethingAsync() -> Result<Int, Test> {
		return await { completion in
			DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds( Int.random(in: 50...1432) )) {
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
			DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds( Int.random(in: 71...843) )) {
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
			DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds( Int.random(in: 2...1031) )) {
				let retrievedValue = 30
				if Bool.random() {
					completion(.failure(Test.test))
				} else {
					completion(.success(retrievedValue))
				}
			}
		})
	}
	
	func somethingFuture10(value: Int) -> Future<Double, Other> {
		return Future(await { completion in
			DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds( Int.random(in: 30...2034) )) {
				let retrievedValue: Double = Double(value) + 19
				if Bool.random() {
					completion(.failure(Other.test))
				} else {
					completion(.success(retrievedValue))
				}
			}
		})
	}

	func somethingFuture3() -> Future<Int, Test> {
		return Future(somethingFuture2())
	}

	func somethingFuture4() -> Future<(Int, Int), AsyncAwait.Failure> {
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
		
		let expectedCount = 507
		var realCount = 0
		let expectation = XCTestExpectation(description: "testAwaitsExpectation")
		expectation.expectedFulfillmentCount = expectedCount
		expectation.assertForOverFulfill = true
		
		let locker = NSLock()
		
		func realFulfill() {
			locker.lock()
			expectation.fulfill()
			locker.unlock()
			realCount += 1
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
		
		wait(for: [expectation], timeout: 1000)
		
		XCTAssertEqual(realCount, expectedCount, "Some awaits didn't fulfill")
	}
	
	func testFutures() {
		
		let expectedCount = 25
		var realCount = 0
		let expectation = XCTestExpectation(description: "testFuturesExpectation")
		expectation.expectedFulfillmentCount = expectedCount
		expectation.assertForOverFulfill = true
		
		let locker = NSLock()
		
		func realFulfill() {
			locker.lock()
			expectation.fulfill()
			locker.unlock()
			realCount += 1
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
			let value3 = try? self.somethingFuture3().get()
			print(result1, result2, value3 ?? "_")
			realFulfill()
		}
		
		async {
			do {
				let value1 = try self.somethingFuture().get()
				let value2 = try self.somethingFuture2().get()
				let value3 = try self.somethingFuture3().get()
				print(value1, value2, value3)
			} catch {
				print(error)
			}
			realFulfill()
		}
		
		for _ in 0..<16 {
			Futures.wait(
				self.somethingFuture(), self.somethingFuture2(), self.somethingFuture3()
			).onSuccess { (value1, value2, value3) in
				print(value1, value2, value3)
				realFulfill()
			}.onFailure { error in
				print(error.localizedDescription)
				realFulfill()
			}
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

		wait(for: [expectation], timeout: 1000)
		
		XCTAssertEqual(realCount, expectedCount, "Some futures didn't fulfill")
	}

	func testFuturesFeatures() {
		
		let expectedCount = 392
		var realCount = 0
		let expectation = XCTestExpectation(description: "testFuturesExpectation")
		expectation.expectedFulfillmentCount = expectedCount
		expectation.assertForOverFulfill = true
		
		let locker = NSLock()
		
		func realFulfill() {
			locker.lock()
			expectation.fulfill()
			locker.unlock()
			realCount += 1
		}
		
		self.somethingFuture().onSuccess { value in
			print(value)
			realFulfill()
		}.onFailure { error in
			print(error)
			realFulfill()
		}
		
		self.somethingFuture()
			.map { $0 * 2 }
			.then { result in
				print(result)
				realFulfill()
			}
		
		for i in 0..<52 {
			self.somethingFuture()
				.flatMap { self.somethingFuture10(value: $0) }
				.map { $0 * Double(i) }
				.flatMap { self.somethingFuture10(value: Int($0)) }
				.then { result in
					print(result)
					realFulfill()
				}
		}
		
		for _ in 0..<107 {
			
			Futures.combine([
				self.somethingFuture(), self.somethingFuture2()
			]).onSuccess { results in
				print(results)
				realFulfill()
			}.onFailure { error in
				print(error)
				realFulfill()
			}
			
			Futures.combine(
				self.somethingFuture(), self.somethingFuture10(value: 1)
			).onSuccess { (result1, result2) in
				print(result1, result2)
				realFulfill()
			}.onFailure { error in
				print(error)
				realFulfill()
			}
		}
		
		for _ in 0..<62 {
			Futures.combineOmittingErrors([
				self.somethingFuture(), self.somethingFuture2(), self.somethingFuture3()
			]).onSuccess { results in
				print(results)
				realFulfill()
			}.onFailure { error in
				print(error)
				realFulfill()
			}
			
			Futures.combineOmittingErrors(
				self.somethingFuture(), self.somethingFuture10(value: 1)
			).onSuccess { (result1, result2) in
				print(result1 ?? "nil", result2 ?? "nil")
				realFulfill()
			}.onFailure { error in
				print(error)
				realFulfill()
			}
		}
		
		wait(for: [expectation], timeout: 1000)
		
		XCTAssertEqual(realCount, expectedCount, "Some futures (2) didn't fulfill")
	}

	func _getValue(completionHandler: @escaping (Int) -> Void) {
		URLSession.shared.dataTask(with: URL(string: "https://www.wikipedia.com")!) { (data, response, error) in
			completionHandler(data?.count ?? 0)
		}.resume()
	}
	func _futureTest() -> Future<Int, Never> {
		return Future({ completion in
			self._getValue { value in
				completion(.success(value))
			}
		})
	}
	func _futureTest2() -> Future<Int, Never> {
		return Future({ completion in
			DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(Int.random(in: 600...2001))) {
				completion(.success(90))
			}
		})
	}
	func _futureTest3() -> Future<Int, Never> {
		return Future({ completion in
			DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(Int.random(in: 303...1081))) {
				completion(.success(10))
			}
		})
	}
	func _futureTest4() -> Future<Int, Never> {
		return Future({ completion in
			DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(Int.random(in: 303...1081))) {
				completion(.success(11))
			}
		})
	}
	func _awaitTest() -> Result<Int, Never> {
		return await { completion in
			self._getValue { value in
				completion(.success(value))
			}
		}
	}

	func testMultiple() {

		let expectedCount = 102 * 4 * 2
		var realCount = 0
		let expectation = XCTestExpectation(description: "testFuturesExpectation")
		expectation.expectedFulfillmentCount = expectedCount
		expectation.assertForOverFulfill = true

		let locker = NSLock()

		func realFulfill() {
			locker.lock()
			expectation.fulfill()
			locker.unlock()
			realCount += 1
		}


		for _ in 0..<102 {
			self._futureTest().then {
				print($0)
				realFulfill()
			}
			self._futureTest2().then {
				print($0)
				realFulfill()
			}
			self._futureTest3().then {
				print($0)
				realFulfill()
			}
			self._futureTest4().then {
				print($0)
				realFulfill()
			}
		}

		let f1 = self._futureTest()
		let f2 = self._futureTest2()
		let f3 = self._futureTest3()
		let f4 = self._futureTest4()

		for _ in 0..<102 {
			f1.then {
				print($0)
				realFulfill()
			}
			f2.then {
				print($0)
				realFulfill()
			}
			f3.then {
				print($0)
				realFulfill()
			}
			f4.then {
				print($0)
				realFulfill()
			}
		}

		wait(for: [expectation], timeout: 1000)

		XCTAssertEqual(realCount, expectedCount, "Some futures (2) didn't fulfill")
	}

	static var allTests = [
		("testAwaits", testAwaits),
		("testFutures", testFutures),
		("testFuturesFeatures", testFuturesFeatures),
		("testMultiple", testMultiple)
    ]
}
