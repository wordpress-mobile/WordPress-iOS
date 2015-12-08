import Foundation
import UIKit

public typealias ImmuTableActionType = (ImmuTableRow) -> Void

public protocol ImmuTableRow {
    var action: ImmuTableActionType? { get }
    func configureCell(cell: UITableViewCell)
    static var cell: ImmuTableCell { get }
    static var customHeight: Float? { get }
}

extension ImmuTableRow {
    public var reusableIdentifier: String {
        return self.dynamicType.cell.reusableIdentifier
    }

    public var cellClass: UITableViewCell.Type {
        return self.dynamicType.cell.cellClass
    }

    public static var customHeight: Float? {
        return nil;
    }
}

public struct ImmuTableSection {
    let headerText: String?
    let rows: [ImmuTableRow]
    let footerText: String?

    public init(rows: [ImmuTableRow]) {
        self.headerText = nil
        self.rows = rows
        self.footerText = nil
    }

    public init(headerText: String?, rows: [ImmuTableRow], footerText: String?) {
        self.headerText = headerText
        self.rows = rows
        self.footerText = footerText
    }
}

public enum ImmuTableCell {
    case Nib(UINib, UITableViewCell.Type)
    case Class(UITableViewCell.Type)

    public var reusableIdentifier: String {
        switch self {
        case .Class(let cellClass):
            return NSStringFromClass(cellClass)
        case .Nib(_, let cellClass):
            return NSStringFromClass(cellClass)
        }
    }

    public var cellClass: UITableViewCell.Type {
        switch self {
        case .Class(let cellClass):
            return cellClass
        case .Nib(_, let cellClass):
            return cellClass
        }
    }
}

public protocol CellRegistrator {
    func register(cell: ImmuTableCell, cellReuseIdentifier: String)
}


extension UITableView: CellRegistrator {
    public func register(cell: ImmuTableCell, cellReuseIdentifier: String) {
        switch cell {
        case .Nib(let nib, _):
            registerNib(nib, forCellReuseIdentifier: cell.reusableIdentifier)
        case .Class(let cellClass):
            registerClass(cellClass, forCellReuseIdentifier: cell.reusableIdentifier)
        }
    }
}

/**
 ImmuTable represents the view model for a static UITableView.

 ImmuTable consists of zero or more sections, each one containing zero or more rows,
 and an optional header and footer text.

 Each row contains the model necessary to configure a specific type of UITableViewCell.

 - attention: before using any ImmuTableRow type, you need to call `registerRows(_:tableView:)`
 passing the row type. This is needed so ImmuTable can register the class or nib with the table view.
 If you fail to do this, UIKit will raise an exception when it tries to load the row.
 */
public struct ImmuTable {
    public let sections: [ImmuTableSection]

    public init(sections: [ImmuTableSection]) {
        self.sections = sections
    }

    public func rowAtIndexPath(indexPath: NSIndexPath) -> ImmuTableRow {
        return sections[indexPath.section].rows[indexPath.row]
    }

    public static func registerRows(rows: [ImmuTableRow.Type], tableView: CellRegistrator) {
        let registrables = rows.reduce([:]) {
            (var classes, row) -> [String: ImmuTableCell] in

            classes[row.cell.reusableIdentifier] = row.cell
            return classes
        }
        for (identifier, registrable) in registrables {
            tableView.register(registrable, cellReuseIdentifier: identifier)
        }
    }
}

public class ImmuTableViewHandler: NSObject, UITableViewDataSource, UITableViewDelegate {
    unowned let target: UITableViewController

    public init(takeOver target: UITableViewController) {
        self.target = target
        super.init()

        self.target.tableView.dataSource = self
        self.target.tableView.delegate = self
    }

    public var viewModel = ImmuTable(sections: []) {
        didSet {
            if target.isViewLoaded() {
                target.tableView.reloadData()
            }
        }
    }

    public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return viewModel.sections.count
    }

    public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.sections[section].rows.count
    }

    public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let row = viewModel.rowAtIndexPath(indexPath)
        let cell = tableView.dequeueReusableCellWithIdentifier(row.reusableIdentifier, forIndexPath: indexPath)

        row.configureCell(cell)

        return cell
    }

    public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let row = viewModel.rowAtIndexPath(indexPath)
        row.action?(row)
    }

    public func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let row = viewModel.rowAtIndexPath(indexPath)
        if let customHeight = row.dynamicType.customHeight {
            return CGFloat(customHeight)
        }
        return tableView.rowHeight
    }
}

