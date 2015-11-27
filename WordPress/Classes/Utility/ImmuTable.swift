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

public protocol CellRegistrable {
    func registerClass(cellClass: AnyClass?, forCellReuseIdentifier identifier: String)
}

extension UITableView: CellRegistrable { }

public struct ImmuTable {
    public let sections: [ImmuTableSection]

    public func rowAtIndexPath(indexPath: NSIndexPath) -> ImmuTableRow {
        return sections[indexPath.section].rows[indexPath.row]
    }

    public static func registerRows(rows: [ImmuTableRow.Type], tableView: CellRegistrable) {
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

public class ImmuTableDataSource: NSObject, UITableViewDataSource {
    var viewModel: ImmuTable
    var configureCell: ((UITableViewCell) -> Void)?

    init(viewModel: ImmuTable) {
        self.viewModel = viewModel
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

        configureCell?(cell)

        return cell
    }
}

public class ImmuTableDelegate: NSObject, UITableViewDelegate {
    var viewModel: ImmuTable

    init(viewModel: ImmuTable) {
        self.viewModel = viewModel
    }

    public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let row = viewModel.rowAtIndexPath(indexPath)
        if let action = row.action {
            action(row)
        }
    }
}

public class ImmuTableViewController: UITableViewController {
    var viewModel = ImmuTable(sections: []) {
        didSet {
            dataSource.viewModel = viewModel
            delegate.viewModel = viewModel
            if isViewLoaded() {
                tableView.reloadData()
            }
        }
    }

    lazy var dataSource: ImmuTableDataSource = {
        return ImmuTableDataSource(viewModel: self.viewModel)
    }()
    
    lazy var delegate: ImmuTableDelegate = {
        return ImmuTableDelegate(viewModel: self.viewModel)
    }()

    override public func viewDidLoad() {
        super.viewDidLoad()

        tableView.dataSource = dataSource
        tableView.delegate = delegate
    }

    public func registerRows(rows: [ImmuTableRow.Type]) {
        ImmuTable.registerRows(rows, tableView: tableView)
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
