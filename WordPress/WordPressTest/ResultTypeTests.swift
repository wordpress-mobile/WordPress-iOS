import XCTest
@testable import WordPress

final class ResultTypeTests: XCTestCase {
    private struct Constants {
        static let value = "🦄"
        static let error = NSError(domain: "c", code: 0, userInfo: nil)
    }

    func testSuccessContainsValue() {
        let result = success()

        switch result {
        case .success(let data):
            XCTAssertEqual(data, Constants.value)
        case .failure:
            XCTFail()
        }
    }

    func testErrorContainsExpectedError() {
        let result = failure()

        switch result {
        case .success:
            XCTFail()
        case .failure(let value):
            XCTAssertEqual(value.localizedDescription, Constants.error.localizedDescription)
        }
    }

    private func success() -> Result<String, Error> {
        return .success(Constants.value)
    }

    private func failure() -> Result<String, Error> {
        return .failure(Constants.error)
    }
}
