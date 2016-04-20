import XCTest
@testable import WordPress

class ImmuTableTest: XCTestCase {

    func testRegisterRowsWorksWithNibs() {
        let mockTable = MockTableView()
        let rowsToRegister: [ImmuTableRow.Type] = [
            TestWithNibImmuTableRow.self
        ]

        ImmuTable.registerRows(rowsToRegister, registrator: mockTable)
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

        ImmuTable.registerRows(rowsToRegister, registrator: mockTable)
        XCTAssertEqual(2, mockTable.registeredClasses.count, "Each cell class shouldn't be registered more than once")
    }

}

class TestTableViewCell: UITableViewCell {}
class ImmuTableTestViewCellWithNib: UITableViewCell {}

struct BasicImmuTableRow: ImmuTableRow {
    static let cell = ImmuTableCell.Class(UITableViewCell)
    let title: String
    var action: ImmuTableAction? = nil
    func configureCell(cell: UITableViewCell) {
    }
}

struct ImageImmuTableRow: ImmuTableRow {
    static let cell = ImmuTableCell.Class(UITableViewCell)
    let title: String
    let image: UIImage
    var action: ImmuTableAction? = nil
    func configureCell(cell: UITableViewCell) {
    }
}

struct TestImmuTableRow: ImmuTableRow {
    static let cell = ImmuTableCell.Class(TestTableViewCell)
    let title: String
    var action: ImmuTableAction? = nil
    func configureCell(cell: UITableViewCell) {
    }
}

struct TestWithNibImmuTableRow: ImmuTableRow {
    typealias CellType = ImmuTableTestViewCellWithNib
    static let cell: ImmuTableCell = {
        let nib = UINib(nibName: "ImmuTableTestViewCellWithNib", bundle: NSBundle(forClass: ImmuTableTestViewCellWithNib.self))
        return ImmuTableCell.Nib(nib, CellType.self)
    }()
    var action: ImmuTableAction? = nil
    func configureCell(cell: UITableViewCell) {
    }
}

class MockTableView: CellRegistrator {
    var registeredClasses = [(String, AnyClass)]()
    var registeredNibs = [(String, UINib)]()
    func register(cell: ImmuTableCell, cellReuseIdentifier identifier: String) {
        switch cell {
        case .Class(let cellClass):
            registeredClasses.append((identifier, cellClass))
        case .Nib(let nib, _):
            registeredNibs.append((identifier, nib))
        }
    }
    func registerClass(cellClass: AnyClass?, forCellReuseIdentifier identifier: String) {
        registeredClasses.append((identifier, cellClass!))
    }
}
