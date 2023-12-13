import XCTest

@testable import WordPress

final class TenorDataSourceTests: XCTestCase {
    private var dataSource: TenorDataSource?
    private var mockService: TenorService?

    private struct Constants {
        static let searchTerm = "cat"
        static let itemCount = 3
    }

    override func setUp() {
        super.setUp()
        mockService = MockTenorService(resultsCount: Constants.itemCount)
        dataSource = TenorDataSource(service: mockService!)
    }

    override func tearDown() {
        dataSource = nil
        mockService = nil
        super.tearDown()
    }

    func testDataSourceReceivesRequestedCount() {
        dataSource?.search(for: Constants.searchTerm)

        // Searches are debounced for half a second
        wait(for: 1)

        XCTAssertEqual(dataSource?.assets.count, Constants.itemCount)
    }
}
