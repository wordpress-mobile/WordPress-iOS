import Foundation
import UIKit

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

protocol CustomImmuTableRow: ImmuTableRow {
    typealias CellType: AnyObject
}

extension CustomImmuTableRow {
    static var reusableIdentifier: String {
        get {
            return NSStringFromClass(cellClass)
        }
    }

    static var cellClass: AnyClass {
        get {
            return CellType.self
        }
    }
}
