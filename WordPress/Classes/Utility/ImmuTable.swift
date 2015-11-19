public typealias ImmuTableActionType = () -> Void

public protocol Reusable {
    static var reusableIdentifier: String { get }
}

extension Reusable {
    var reusableIdentifier: String {
        get {
            return self.dynamicType.reusableIdentifier
        }
    }
}

public protocol ImmuTableRow: Reusable {
    var action: ImmuTableActionType? { get }
    static var cellClass: AnyClass { get }
    func configureCell(cell: UITableViewCell)
}

public struct ImmuTableSection {
    let headerText: String?
    let rows: [ImmuTableRow]
    let footerText: String?

    init(rows: [ImmuTableRow]) {
        self.headerText = nil
        self.rows = rows
        self.footerText = nil
    }

    init(headerText: String?, rows: [ImmuTableRow], footerText: String?) {
        self.headerText = headerText
        self.rows = rows
        self.footerText = footerText
    }
}

public struct ImmuTable {
    public let sections: [ImmuTableSection]

    public func rowAtIndexPath(indexPath: NSIndexPath) -> ImmuTableRow {
        return sections[indexPath.section].rows[indexPath.row]
    }

    public static func registerRows(rows: [ImmuTableRow.Type], tableView: UITableView) {
        let classes = rows.reduce([:]) {
            (var classes, row) -> [String: AnyClass] in

            classes[row.reusableIdentifier] = row.cellClass
            return classes
        }
        for (identifier, cellClass) in classes {
            tableView.registerClass(cellClass, forCellReuseIdentifier: identifier)
        }
    }
}

extension UITableView {
    func registerImmuTableRows(rows: [ImmuTableRow.Type]) {
        ImmuTable.registerRows(rows, tableView: self)
    }
}

extension WPTableViewCell: Reusable {
    public static var reusableIdentifier: String {
        get {
            return NSStringFromClass(self)
        }
    }
}

protocol TypedImmuTableRow: ImmuTableRow {
    typealias CellType: AnyObject, Reusable
}

extension TypedImmuTableRow {
    static var reusableIdentifier: String {
        get {
            return CellType.reusableIdentifier
        }
    }

    static var cellClass: AnyClass {
        get {
            return CellType.self
        }
    }
}

struct NavigationItemRow : TypedImmuTableRow {
    typealias CellType = WPTableViewCellDefault

    let title: String
    let action: ImmuTableActionType?

    func configureCell(cell: UITableViewCell) {
        let cell = cell as! CellType

        cell.textLabel?.text = title
        cell.accessoryType = .DisclosureIndicator
    }
}

struct EditableTextRow : TypedImmuTableRow {
    typealias CellType = WPTableViewCellValue1

    let title: String
    let value: String
    let action: ImmuTableActionType?

    func configureCell(cell: UITableViewCell) {
        cell.textLabel?.text = title
        cell.detailTextLabel?.text = value
        cell.accessoryType = .DisclosureIndicator
    }
}
