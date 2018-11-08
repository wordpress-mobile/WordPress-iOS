import XCTest
@testable import WordPress

final class SiteSegmentsDataSourceTests: XCTestCase {
    private var dataSource: UITableViewDataSource?
    private var mock: MockSiteSegmentsService?

    override func setUp() {
        super.setUp()
        mock = MockSiteSegmentsService()
        dataSource = SiteSegmentsDataSource(data: mock!.mockSiteTypes)
    }

    override func tearDown() {
        dataSource = nil
        mock = nil
        super.tearDown()
    }

    func testDataSourceCountMatchesMockCount() {
        let table = UITableView()
        let count = dataSource?.tableView(table, numberOfRowsInSection: 0)

        XCTAssertEqual(count, mock?.mockCount)
    }
}
