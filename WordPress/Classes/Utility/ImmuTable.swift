/**
 ImmuTable represents the view model for a static UITableView.

 ImmuTable consists of zero or more sections, each one containing zero or more rows,
 and an optional header and footer text.

 Each row contains the model necessary to configure a specific type of UITableViewCell.

 To use ImmuTable, first you need to create some custom rows. An example row for a cell
 that acts as a button which performs a destructive action could look like this:

     struct DestructiveButtonRow: ImmuTableRow {
         static let cell = ImmuTableCell.Class(UITableViewCell.self)
         let title: String
         let action: ImmuTableAction?

         func configureCell(cell: UITableViewCell) {
             cell.textLabel?.text = title
             cell.textLabel?.textAlignment = .Center
             cell.textLabel?.textColor = UIColor.redColor()
         }
     }

 The easiest way to use ImmuTable is through ImmuTableViewHandler, which takes a
 UITableViewController as an argument, and acts as the table view delegate and data
 source. You would then assign an ImmuTable object to the handler's `viewModel`
 property.

 - attention: before using any ImmuTableRow type, you need to call `registerRows(_:tableView:)`
 passing the row type. This is needed so ImmuTable can register the class or nib with the table view.
 If you fail to do this, UIKit will raise an exception when it tries to load the row.
 */
public struct ImmuTable {
    /// An array of the sections to be represented in the table view
    public let sections: [ImmuTableSection]

    /// Initializes an ImmuTable object with the given sections
    public init(sections: [ImmuTableSection]) {
        self.sections = sections
    }

    /**
     Returns the row model for a specific index path.
     
     - precondition: `indexPath` should represent a valid section and row,
     otherwise this method will raise an exception.
     */
    public func rowAtIndexPath(indexPath: NSIndexPath) -> ImmuTableRow {
        return sections[indexPath.section].rows[indexPath.row]
    }

    /**
     Registers the row custom class or nib with the table view so it can later be
     dequeued with `dequeueReusableCellWithIdentifier(_:forIndexPath:)`
     */
    public static func registerRows(rows: [ImmuTableRow.Type], tableView: UITableView) {
        registerRows(rows, registrator: tableView)
    }

    /// This function exists for testing purposes
    /// - seealso: registerRows(_:tableView:)
    internal static func registerRows(rows: [ImmuTableRow.Type], registrator: CellRegistrator) {
        let registrables = rows.reduce([:]) {
            (classes, row) -> [String: ImmuTableCell] in

            var classes = classes
            classes[row.cell.reusableIdentifier] = row.cell
            return classes
        }
        for (identifier, registrable) in registrables {
            registrator.register(registrable, cellReuseIdentifier: identifier)
        }
    }
}

extension ImmuTable {
    /// Alias for an ImmuTable with no sections
    static var Empty: ImmuTable {
        return ImmuTable(sections: [])
    }
}


// MARK: -


/**
ImmuTableSection represents the view model for a table view section.

A section has an optional header and footer text, and zero or more rows.

- seealso: ImmuTableRow
*/
public struct ImmuTableSection {
    let headerText: String?
    let rows: [ImmuTableRow]
    let footerText: String?

    /// Initializes a ImmuTableSection with the given rows and optionally header and footer text
    public init(headerText: String? = nil, rows: [ImmuTableRow], footerText: String? = nil) {
        self.headerText = headerText
        self.rows = rows
        self.footerText = footerText
    }
}


// MARK: - ImmuTableRow


/**
ImmuTableRow represents the minimum common elements of a row model.

You should implement your own types that conform to ImmuTableRow to define your custom rows.
*/
public protocol ImmuTableRow {

    /**
     The closure to call when the row is tapped. The row is passed as an argument to the closure.

     To improve readability, we recommend that you implement the action logic in one of
     your view controller methods, instead of including the closure inline.
     
     Also, be mindful of retain cycles. If your closure needs to reference `self` in
     any way, make sure to use `[unowned self]` in the parameter list.
     
     An example row with its action could look like this:

         class ViewController: UITableViewController {

             func buildViewModel() {
                 let item1Row = NavigationItemRow(title: "Item 1", action: navigationAction())
                 ...
             }

             func navigationAction() -> ImmuTableRow -> Void {
                 return { [unowned self] row in
                     let controller = self.controllerForRow(row)
                     self.navigationController?.pushViewController(controller, animated: true)
                 }
             }

             ...
             
         }

     */
    var action: ImmuTableAction? { get }

    /// This method is called when an associated cell needs to be configured.
    /// - precondition: You can assume that the passed cell is of the type defined
    ///   by cell.cellClass and force downcast accordingly.
    func configureCell(cell: UITableViewCell)

    /// An ImmuTableCell value defining the associated cell type.
    /// - seealso: See ImmuTableCell for possible options.
    static var cell: ImmuTableCell { get }

    /// The desired row height (Optional)
    ///
    /// If not defined or nil, the default height will be used.
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


// MARK: - ImmuTableCell


/**
ImmuTableCell describes cell types so they can be registered with a table view.

It supports two options:
    - Nib for Interface Builder defined cells.
    - Class for cells defined in code.
Both cases presume a custom UITableViewCell subclass. If you aren't subclassing,
you can also use UITableViewCell as the type.

- note: If you need to use any cell style other than .Default we recommend you
  subclass UITableViewCell and override init(style:reuseIdentifier:).
*/
public enum ImmuTableCell {

    /// A cell using a UINib. Values are the UINib object and the custom cell class.
    case Nib(UINib, UITableViewCell.Type)

    /// A cell using a custom class. The associated value is the custom cell class.
    case Class(UITableViewCell.Type)

    /// A String that uniquely identifies the cell type
    public var reusableIdentifier: String {
        switch self {
        case .Class(let cellClass):
            return NSStringFromClass(cellClass)
        case .Nib(_, let cellClass):
            return NSStringFromClass(cellClass)
        }
    }

    /// The class of the custom cell
    public var cellClass: UITableViewCell.Type {
        switch self {
        case .Class(let cellClass):
            return cellClass
        case .Nib(_, let cellClass):
            return cellClass
        }
    }
}


// MARK: -


/**
ImmuTableViewHandler is a helper to facilitate integration of ImmuTable in your
table view controllers.

It acts as the table view data source and delegate, and signals the table view to
reload its data when the underlying model changes.

- note: as it keeps a weak reference to its target, you should keep a strong 
  reference to the handler from your view controller.
*/
public class ImmuTableViewHandler: NSObject, UITableViewDataSource, UITableViewDelegate {
    unowned let target: UITableViewController

    /// Initializes the handler with a target table view controller.
    /// - postcondition: After initialization, it becomse the data source and
    ///   delegate for the the target's table view.
    public init(takeOver target: UITableViewController) {
        self.target = target
        super.init()

        self.target.tableView.dataSource = self
        self.target.tableView.delegate = self
    }

    /// An ImmuTable object representing the table structure.
    public var viewModel = ImmuTable.Empty {
        didSet {
            if target.isViewLoaded() {
                target.tableView.reloadData()
            }
        }
    }

    // MARK: Table View Data Source

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

    public func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return viewModel.sections[section].headerText
    }

    public func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return viewModel.sections[section].footerText
    }

    // MARK: Table View Delegate

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


// MARK: - Type aliases


public typealias ImmuTableAction = (ImmuTableRow) -> Void


// MARK: - Internal testing helpers


protocol CellRegistrator {
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

