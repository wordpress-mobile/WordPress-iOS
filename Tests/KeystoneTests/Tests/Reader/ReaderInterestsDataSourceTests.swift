import XCTest
import WordPressKit
@testable import WordPress

private struct Constants {
    static let testTitle = "Test Title"
    static let testSlug = "test-title"
}

// MARK: - MockInterestsService
class MockInterestsService: ReaderInterestsService {
    var success = true
    var fetchSuccessExpectation: XCTestExpectation?
    var fetchFailureExpectation: XCTestExpectation?

    private let failureError = NSError(domain: "org.wordpress.reader-tests", code: 1, userInfo: nil)

    public class func mock(title: String, slug: String) -> RemoteReaderInterest {
        let payload = Data("""
        {
            "title": "\(title)",
            "slug": "\(slug)"
        }
        """.utf8)

        return try! JSONDecoder().decode(RemoteReaderInterest.self, from: payload)
    }

    func fetchInterests(success: @escaping ([RemoteReaderInterest]) -> Void, failure: @escaping (Error) -> Void) {
        guard self.success else {
            fetchFailureExpectation?.fulfill()

            failure(failureError)
            return
        }

        let interests = [
            Self.mock(title: Constants.testTitle, slug: Constants.testSlug)
        ]

        success(interests)
        fetchSuccessExpectation?.fulfill()
    }
}

// MARK: - MockInterestsDelegate
private class MockInterestsDelegate: ReaderInterestsDataDelegate {
    var fetchExpectation: XCTestExpectation

    init(_ expectation: XCTestExpectation) {
        fetchExpectation = expectation
    }

    func readerInterestsDidUpdate(_ dataSource: ReaderInterestsDataSource) {
        fetchExpectation.fulfill()
    }
}

// MARK: - ReaderInterestsDataSourceTests
class ReaderInterestsDataSourceTests: XCTestCase {
    func testFetchInterestsSucceeds() {
        let service = MockInterestsService()

        let dataSource = ReaderInterestsDataSource(topics: [], service: service)

        let successExpectation = expectation(description: "Fetching of interests succeeds")

        service.success = true
        service.fetchSuccessExpectation = successExpectation

        dataSource.reload()

        wait(for: [successExpectation], timeout: 4)

        XCTAssertEqual(dataSource.count, 1)
    }

    func testFetchInterestsFails() {
        let service = MockInterestsService()
        let dataSource = ReaderInterestsDataSource(topics: [], service: service)

        let failureExpectation = expectation(description: "Fetching of interests fails")

        service.success = false
        service.fetchFailureExpectation = failureExpectation

        dataSource.reload()

        wait(for: [failureExpectation], timeout: 4)

        XCTAssertEqual(dataSource.count, 0)
    }

    func testInterestsDataSourceDelegateIsCalled() {
        let delegateExpectation = expectation(description: "DataSource delegate is called sucessfully")
        let delegate = MockInterestsDelegate(delegateExpectation)

        let service = MockInterestsService()
        let dataSource = ReaderInterestsDataSource(topics: [], service: service)
        dataSource.delegate = delegate

        dataSource.reload()

        wait(for: [delegateExpectation], timeout: 4)

        XCTAssertEqual(dataSource.count, 1)
    }

    func testDataSourceInterestInterestFor() throws {
        let service = MockInterestsService()
        let dataSource = ReaderInterestsDataSource(topics: [], service: service)
        let successExpectation = expectation(description: "Fetching of interests succeeds")

        service.success = true
        service.fetchSuccessExpectation = successExpectation

        dataSource.reload()

        wait(for: [successExpectation], timeout: 4)

        let interest = try XCTUnwrap(dataSource.interest(for: 0), "Expected interest at index 0 to exist")
        XCTAssertEqual(interest.title, Constants.testTitle)
        XCTAssertEqual(interest.slug, Constants.testSlug)
        XCTAssertEqual(interest.isSelected, false)
    }

    func testDataSourceInterestInvalidIndexPath() {
        let service = MockInterestsService()
        let dataSource = ReaderInterestsDataSource(topics: [], service: service)
        let successExpectation = expectation(description: "Fetching of interests succeeds")

        service.success = true
        service.fetchSuccessExpectation = successExpectation

        dataSource.reload()

        wait(for: [successExpectation], timeout: 4)

        // Queries for invalid index should return nil instead of crashing.
        XCTAssertNil(dataSource.interest(for: 1))
    }

    func testDataSourceInterestToggleSelected() throws {
        let service = MockInterestsService()
        let dataSource = ReaderInterestsDataSource(topics: [], service: service)
        let successExpectation = expectation(description: "Fetching of interests succeeds")

        service.success = true
        service.fetchSuccessExpectation = successExpectation

        dataSource.reload()

        wait(for: [successExpectation], timeout: 4)

        // Toggle on
        let interest = try XCTUnwrap(dataSource.interest(for: 0), "Expected interest at index 0 to exist")
        interest.toggleSelected()
        XCTAssertEqual(interest.isSelected, true)

        // Toggle off
        interest.toggleSelected()

        // Re-fetch interest.
        // The view model stored in the data source's `interests` array should also be updated.
        let updatedInterest = try XCTUnwrap(dataSource.interest(for: 0), "Expected interest at index 0 to exist")
        XCTAssertEqual(updatedInterest.isSelected, false)
    }

    func testDataSourceInterestSelectedInterests() throws {
        let service = MockInterestsService()
        let dataSource = ReaderInterestsDataSource(topics: [], service: service)
        let successExpectation = expectation(description: "Fetching of interests succeeds")

        service.success = true
        service.fetchSuccessExpectation = successExpectation

        dataSource.reload()

        wait(for: [successExpectation], timeout: 4)

        // Toggle on
        let interest = try XCTUnwrap(dataSource.interest(for: 0), "Expected interest at index 0 to exist")
        interest.toggleSelected()

        XCTAssertEqual(dataSource.count, dataSource.selectedInterests.count)
    }
}
