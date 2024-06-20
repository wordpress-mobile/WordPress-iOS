@testable import WordPressAuthenticator
import XCTest

class ResultConvenienceInitTests: XCTestCase {

    func testResultWithOptionalInputs() throws {
        // Syntax sugar to keep line length shorter. SUT = System Under Test
        typealias SUT = Result<Int, NSError>

        let testError = NSError(domain: "test", code: 1, userInfo: .none)

        // When value is some and error is nil, returns the value
        XCTAssertEqual(
            try XCTUnwrap(SUT(value: 1, error: .none, inconsistentStateError: testError).get()),
            1
        )

        // When value is some and error is some, returns the error
        let someError = NSError(domain: "test", code: 2)
        XCTAssertThrowsError(
            try SUT(value: 1, error: someError, inconsistentStateError: testError).get()
        ) { error in
            XCTAssertEqual(error as NSError, someError)
        }

        // When value is none and error is some, returns the error
        XCTAssertThrowsError(
            try SUT(value: .none, error: someError, inconsistentStateError: testError).get()
        ) { error in
            XCTAssertEqual(error as NSError, someError)
        }

        // When both value and error are none, returns the given error for this inconsistent state
        XCTAssertThrowsError(
            try SUT(value: .none, error: .none, inconsistentStateError: testError).get()
        ) { error in
            XCTAssertEqual(error as NSError, testError)
        }
    }
}
