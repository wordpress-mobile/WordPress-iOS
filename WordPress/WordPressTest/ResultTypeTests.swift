import XCTest
@testable import WordPress

final class ResultTypeTests: XCTestCase {
    private struct Constants {
        static let value = "🦄"
        static let error = NSError(domain: "c", code: 0, userInfo: nil)
    }

    func testSuccessContainsValue() {
        let result: Result = .success(Constants.value)

        switch result {
        case .success(let data):
            XCTAssertEqual(data, Constants.value)
        case .error:
            XCTFail()
        }
    }

    func testErrorContainsExpectedError() {
        let result: Result<String> = .error(Constants.error)

        switch result {
        case .success:
            XCTFail()
        case .error(let value):
            XCTAssertEqual(value.localizedDescription, Constants.error.localizedDescription)
        }
    }
}
