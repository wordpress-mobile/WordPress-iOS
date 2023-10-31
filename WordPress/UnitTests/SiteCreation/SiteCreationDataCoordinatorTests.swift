import XCTest
@testable import WordPress

final class SiteCreationDataCoordinatorTests: XCTestCase {
    private struct MockModel {
        let id: String
    }

    private class Cell: UITableViewCell, ModelSettableCell {
        var outlet1: String?

        var model: MockModel? {
            didSet {
                outlet1 = model?.id
            }
        }
    }

    private let tableView = UITableView()

    private lazy var mockData: [MockModel]? = {
        return [MockModel(id: "1"),
                MockModel(id: "2"),
                MockModel(id: "3")]
    }()

    private var selectedModel: MockModel?

    private var coordinator: (UITableViewDataSource & UITableViewDelegate)?

    override func setUp() {
        super.setUp()

        tableView.register(Cell.self, forCellReuseIdentifier: Cell.cellReuseIdentifier())

        if let mock = mockData {
            coordinator = TableDataCoordinator(data: mock, cellType: Cell.self, selection: didSelect)
        }

        selectedModel = nil
    }

    override func tearDown() {
        mockData = nil
        coordinator = nil
        selectedModel = nil
        super.tearDown()
    }

    func testNumberOfRowsMatchesExpectation() {
        let count = coordinator?.tableView(tableView, numberOfRowsInSection: 0)

        XCTAssertEqual(count, mockData?.count)
    }

    func testDataSourcePopulatesCell() {
        let cell = coordinator?.tableView(tableView, cellForRowAt: IndexPath(item: 0, section: 0)) as? Cell

        XCTAssertEqual(cell?.outlet1, mockData?.first?.id)
    }

    func testSelection() {
        coordinator?.tableView!(tableView, didSelectRowAt: IndexPath(item: 0, section: 0))

        XCTAssertEqual(selectedModel?.id, mockData?.first?.id)
    }

    private func didSelect(_ mock: MockModel) {
        selectedModel = mock
    }
}
