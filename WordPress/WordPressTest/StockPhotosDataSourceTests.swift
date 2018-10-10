import XCTest
@testable import WordPress

final class MockMediaGroup: NSObject, WPMediaGroup {
    struct Constants {
        static let name = "🦄"
    }

    func name() -> String {
        return Constants.name
    }

    func image(with size: CGSize, completionHandler: @escaping WPMediaImageBlock) -> WPMediaRequestID {
        return 0
    }

    func cancelImageRequest(_ requestID: WPMediaRequestID) {
        //
    }

    func baseGroup() -> Any {
        return ""
    }

    func identifier() -> String {
        return "group id"
    }

    func numberOfAssets(of mediaType: WPMediaType, completionHandler: WPMediaCountBlock? = nil) -> Int {
        return 10
    }
}


final class StockPhotosDataSourceTests: XCTestCase {
    private var dataSource: StockPhotosDataSource?
    private var mockService: StockPhotosService?

    private struct Constants {
        static let searchTerm = "unicorns"
        static let groupCount = 1
        static let groupName = String.freePhotosLibrary

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

//    func testDataSourceReceivesRequestedCount() {
//        dataSource?.search(for: Constants.searchTerm)
//
//        //Searches are debounced for half a second
//        wait(for: 1)
//
//        XCTAssertEqual(dataSource?.numberOfAssets(), Constants.itemCount())
//    }

    func testDataSourceManagesExpectedNumberOfGroups() {
        let groupCount = dataSource?.numberOfGroups()

        XCTAssertEqual(groupCount, Constants.groupCount)
    }

    func testSearchCancelledClearsData() {
        dataSource?.searchCancelled()

        XCTAssertEqual(dataSource?.numberOfAssets(), 0)
    }

    func testClearRemovesData() {
        dataSource?.clearSearch(notifyObservers: false)

        XCTAssertEqual(dataSource?.numberOfAssets(), 0)
    }

    func testGroupIsNamePhotosLibrary() {
        let groupAtIndexZero = dataSource?.group(at: 0)
        let groupName = groupAtIndexZero?.name()

        XCTAssertEqual(groupName, Constants.groupName)
    }

    func testDataSourceOnlyManagesImages() {
        let mediaType = dataSource?.mediaTypeFilter()

        XCTAssertEqual(mediaType, WPMediaType.image)
    }

    func testDataSourceIsSortedAscending() {
        XCTAssertTrue(dataSource!.ascendingOrdering())
    }

    func testSetSelectedGroupIsIgnored() {
        let groupToBeIgnored = MockMediaGroup()
        dataSource?.setSelectedGroup(groupToBeIgnored)

        let selectedGroup = dataSource?.selectedGroup()

        XCTAssertEqual(selectedGroup?.name(), Constants.groupName)
    }

    func testOrderingCanNotBeChanged() {
        dataSource?.setAscendingOrdering(false)

        XCTAssertTrue(dataSource!.ascendingOrdering())
    }
}
