import Foundation
import UIKit

public typealias ImmuTableActionType = (ImmuTableRow) -> Void

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
    static var registrable: CellRegistrable { get }
    static var customHeight: Float? { get }
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

public enum CellRegistrable {
    case Nib(UINib)
    case Class(AnyClass)
}

public protocol CellRegistrator {
    func register(registrable: CellRegistrable, cellReuseIdentifier: String)
}


extension UITableView: CellRegistrator {
    public func register(registrable: CellRegistrable, cellReuseIdentifier: String) {
        switch registrable {
        case .Nib(let nib):
            registerNib(nib, forCellReuseIdentifier: cellReuseIdentifier)
        case .Class(let cellClass):
            registerClass(cellClass, forCellReuseIdentifier: cellReuseIdentifier)
        }
    }
}

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
            (var classes, row) -> [String: CellRegistrable] in

            classes[row.reusableIdentifier] = row.registrable
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

public protocol CustomImmuTableRow: ImmuTableRow {
    typealias CellType: AnyObject
}

extension CustomImmuTableRow {
    public static var reusableIdentifier: String {
        get {
            return NSStringFromClass(cellClass)
        }
    }

    public static var cellClass: AnyClass {
        get {
            return CellType.self
        }
    }
}

public protocol CustomCellImmuTableRow: CustomImmuTableRow { }
extension CustomCellImmuTableRow {
    public static var customHeight: Float? {
        get {
            return nil
        }
    }
    public static var registrable: CellRegistrable {
        get {
            return .Class(cellClass)
        }
    }
}

protocol CustomNibImmuTableRow: CustomImmuTableRow {
    static var nib: UINib { get }
}
extension CustomNibImmuTableRow {
    static var registrable: CellRegistrable {
        get {
            return .Nib(nib)
        }
    }
}

