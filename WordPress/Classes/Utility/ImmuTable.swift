public typealias ImmuTableActionType = () -> Void

public protocol ReusableCell {
    static var reusableIdentifier: String { get }
}

public protocol ImmuTableRow {
    static var reusableIdentifier: String { get }
    var action: ImmuTableActionType? { get }
    func configureCell(cell: UITableViewCell)
    static func registerInTableView(tableView: UITableView)
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
}

extension WPTableViewCell: ReusableCell {
    public static var reusableIdentifier: String {
        get {
            return NSStringFromClass(self)
        }
    }
}

struct NavigationItemRow : ImmuTableRow {
    typealias CellType = WPTableViewCellDefault

    static var reusableIdentifier: String {
        get {
            return CellType.reusableIdentifier
        }
    }

    static func registerInTableView(tableView: UITableView) {
        tableView.registerClass(CellType.self, forCellReuseIdentifier: reusableIdentifier)
    }

    let title: String
    let action: ImmuTableActionType?

    func configureCell(cell: UITableViewCell) {
        let cell = cell as! CellType

        cell.textLabel?.text = title
        cell.accessoryType = .DisclosureIndicator
    }
}

struct EditableTextRow : ImmuTableRow {
    typealias CellType = WPTableViewCellValue1

    static var reusableIdentifier: String {
        get {
            return CellType.reusableIdentifier
        }
    }

    static func registerInTableView(tableView: UITableView) {
        tableView.registerClass(CellType.self, forCellReuseIdentifier: reusableIdentifier)
    }

    let title: String
    let value: String
    let action: ImmuTableActionType?

    func configureCell(cell: UITableViewCell) {
        cell.textLabel?.text = title
        cell.detailTextLabel?.text = value
        cell.accessoryType = .DisclosureIndicator
    }
}
