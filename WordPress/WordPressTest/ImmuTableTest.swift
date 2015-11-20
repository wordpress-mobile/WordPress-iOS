import XCTest
@testable import WordPress

class ImmuTableTest: XCTestCase {

    func testRegisterRows() {
        let mockTable = MockTableView()
        let rowsToRegister: [ImmuTableRow.Type] = [
            BasicImmuTableRow.self,
            ImageImmuTableRow.self,
            TestImmuTableRow.self
        ]

        ImmuTable.registerRows(rowsToRegister, tableView: mockTable)
        XCTAssertEqual(2, mockTable.registeredClasses.count, "Each cell class shouldn't be registered more than once")
    }

}

class TestTableViewCell: UITableViewCell {}

struct BasicImmuTableRow: CustomImmuTableRow {
    typealias CellType = UITableViewCell
    let title: String
    var action: ImmuTableActionType? = nil
    func configureCell(cell: UITableViewCell) {
    }
}

struct ImageImmuTableRow: CustomImmuTableRow {
    typealias CellType = UITableViewCell
    let title: String
    let image: UIImage
    var action: ImmuTableActionType? = nil
    func configureCell(cell: UITableViewCell) {
    }
}

struct TestImmuTableRow: CustomImmuTableRow {
    typealias CellType = TestTableViewCell
    let title: String
    var action: ImmuTableActionType? = nil
    func configureCell(cell: UITableViewCell) {
    }
}

class MockTableView: CellRegistrable {
    var registeredClasses = [(String, AnyClass)]()
    func registerClass(cellClass: AnyClass?, forCellReuseIdentifier identifier: String) {
        registeredClasses.append((identifier, cellClass!))
    }
}
