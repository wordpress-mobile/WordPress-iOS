import XCTest
@testable import WordPress

class ImmuTableTest: XCTestCase {

    func testRegisterRowsWorksWithNibs() {
        let mockTable = MockTableView()
        let rowsToRegister: [ImmuTableRow.Type] = [
            TestWithNibImmuTableRow.self
        ]

        ImmuTable.registerRows(rowsToRegister, tableView: mockTable)
        XCTAssertEqual(mockTable.registeredNibs.count, 1, "The table should have registered a nib for TestWithNibImmuTableRow")
        XCTAssertEqual(mockTable.registeredClasses.count, 0, "The table shouldn't have registered any classes for TestWithNibImmuTableRow")
    }

    func testRegisterRowsDoesntRegisterSameCellTwice() {
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
class ImmuTableTestViewCellWithNib: UITableViewCell {}

struct BasicImmuTableRow: CustomCellImmuTableRow {
    typealias CellType = UITableViewCell
    let title: String
    var action: ImmuTableActionType? = nil
    func configureCell(cell: UITableViewCell) {
    }
}

struct ImageImmuTableRow: CustomCellImmuTableRow {
    typealias CellType = UITableViewCell
    let title: String
    let image: UIImage
    var action: ImmuTableActionType? = nil
    func configureCell(cell: UITableViewCell) {
    }
}

struct TestImmuTableRow: CustomCellImmuTableRow {
    typealias CellType = TestTableViewCell
    let title: String
    var action: ImmuTableActionType? = nil
    func configureCell(cell: UITableViewCell) {
    }
}

struct TestWithNibImmuTableRow: CustomNibImmuTableRow {
    typealias CellType = ImmuTableTestViewCellWithNib
    static let nib = UINib(nibName: "ImmuTableTestViewCellWithNib", bundle: NSBundle(forClass: ImmuTableTestViewCellWithNib.self))
    static let customHeight: Float? = nil
    var action: ImmuTableActionType? = nil
    func configureCell(cell: UITableViewCell) {
    }
}

class MockTableView: CellRegistrator {
    var registeredClasses = [(String, AnyClass)]()
    var registeredNibs = [(String, UINib)]()
    func register(registrable: CellRegistrable, cellReuseIdentifier identifier: String) {
        switch registrable {
        case .Class(let cellClass):
            registeredClasses.append((identifier, cellClass))
        case .Nib(let nib):
            registeredNibs.append((identifier, nib))
        }
    }
    func registerClass(cellClass: AnyClass?, forCellReuseIdentifier identifier: String) {
        registeredClasses.append((identifier, cellClass!))
    }
}
