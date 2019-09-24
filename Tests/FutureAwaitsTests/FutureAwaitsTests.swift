import XCTest
@testable import FutureAwaits

final class FutureAwaitsTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(FutureAwaits().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
