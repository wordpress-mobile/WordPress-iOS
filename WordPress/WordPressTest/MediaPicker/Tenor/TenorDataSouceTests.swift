
import XCTest

@testable import WordPress

final class TenorDataSourceTests: XCTestCase {
    private var dataSource: TenorDataSource?
    private var mockService: TenorService?

    private struct Constants {
        static let searchTerm = "cat"
        static let groupCount = 1
        static let groupName = String.tenor

        static func itemCount() -> Int {
            return searchTerm.count
        }
    }

    override func setUp() {
        super.setUp()
        mockService = MockTenorService(resultsCount: Constants.itemCount())
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

        XCTAssertEqual(dataSource?.numberOfAssets(), Constants.itemCount())
    }

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
