import XCTest
@testable import WordPress

final class StockPhotosDataSourceTests: XCTestCase {
    private var dataSource: StockPhotosDataSource?
    private var mockService: StockPhotosService?

    private struct Constants {
        static let searchTerm = "unicorns"

        static func itemCount() -> Int {
            return searchTerm.count
        }
    }

    override func setUp() {
        super.setUp()
        mockService = MockStockPhotosService(mediaCount: Constants.itemCount())
        dataSource = StockPhotosDataSource(service: mockService!)
    }

    override func tearDown() {
        dataSource = nil
        mockService = nil
        super.tearDown()
    }

    func testDataSourceReceivesRequestedCount() {
        dataSource?.search(for: Constants.searchTerm)

        //Searches are debounced for half a second
        wait(for: 1)

        XCTAssertEqual(dataSource?.numberOfAssets(), Constants.itemCount())
    }
}
