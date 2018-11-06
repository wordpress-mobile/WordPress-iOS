import XCTest
@testable import WordPress

final class SiteCreationDataCoordinatorTests: XCTestCase {
    private struct MockModel {
        let id: String
    }

    private class Cell: UITableViewCell, ModelSettableCell {
        var model: MockModel? {
            didSet {

            }
        }

    }

    private lazy var mockData: [MockModel]? = {
        return [MockModel(id: "1"),
                MockModel(id: "2"),
                MockModel(id: "3")]
    }()

    private var coordinator: (UITableViewDataSource & UITableViewDelegate)?

    override func setUp() {
        super.setUp()
        if let mock = mockData {
            coordinator = SiteCreationDataCoordinator(data: mock, cellType: Cell.self, selection: didSelect)
        }
    }

    override func tearDown() {
        mockData = nil
        coordinator = nil
        super.tearDown()
    }

    func testNumberOfRowsMatchesExpectation() {
        let count = coordinator?.tableView(UITableView(), numberOfRowsInSection: 0)

        XCTAssertEqual(count, mockData?.count)
    }

    private func didSelect(_ mock: MockModel) {

    }
}
