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
    static let cell = ImmuTableCell.class(UITableViewCell.self)
    let title: String
    var action: ImmuTableAction? = nil
    func configureCell(_ cell: UITableViewCell) {
    }
}

struct ImageImmuTableRow: ImmuTableRow {
    static let cell = ImmuTableCell.class(UITableViewCell.self)
    let title: String
    let image: UIImage
    var action: ImmuTableAction? = nil
    func configureCell(_ cell: UITableViewCell) {
    }
}

struct TestImmuTableRow: ImmuTableRow {
    static let cell = ImmuTableCell.class(TestTableViewCell.self)
    let title: String
    var action: ImmuTableAction? = nil
    func configureCell(_ cell: UITableViewCell) {
    }
}

struct TestWithNibImmuTableRow: ImmuTableRow {
    typealias CellType = ImmuTableTestViewCellWithNib
    static let cell: ImmuTableCell = {
        let nib = UINib(nibName: "ImmuTableTestViewCellWithNib", bundle: Bundle(for: ImmuTableTestViewCellWithNib.self))
        return ImmuTableCell.nib(nib, CellType.self)
    }()
    var action: ImmuTableAction? = nil
    func configureCell(_ cell: UITableViewCell) {
    }
}

class MockTableView: CellRegistrar {
    var registeredClasses = [(String, AnyClass)]()
    var registeredNibs = [(String, UINib)]()
    func register(_ cell: ImmuTableCell, cellReuseIdentifier identifier: String) {
        switch cell {
        case .class(let cellClass):
            registeredClasses.append((identifier, cellClass))
        case .nib(let nib, _):
            registeredNibs.append((identifier, nib))
        }

    }
    func registerClass(_ cellClass: AnyClass?, forCellReuseIdentifier identifier: String) {
        registeredClasses.append((identifier, cellClass!))
    }
}
