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

    /// Returns the row model for a specific index path.
    ///
    /// - Precondition: `indexPath` should represent a valid section and row, otherwise this method
    ///                 will raise an exception.
    ///
    public func rowAtIndexPath(_ indexPath: IndexPath) -> ImmuTableRow {
        return sections[indexPath.section].rows[indexPath.row]
    }

    /// Registers the row custom class or nib with the table view so it can later be
    /// dequeued with `dequeueReusableCellWithIdentifier(_:forIndexPath:)`
    ///
    public static func registerRows(_ rows: [ImmuTableRow.Type], tableView: UITableView) {
        registerRows(rows, registrator: tableView)
    }

    /// This function exists for testing purposes
    /// - seealso: registerRows(_:tableView:)
    internal static func registerRows(_ rows: [ImmuTableRow.Type], registrator: CellRegistrar) {
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


/// ImmuTableSection represents the view model for a table view section.
///
/// A section has an optional header and footer text, and zero or more rows.
/// - seealso: ImmuTableRow
///
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


/// ImmuTableRow represents the minimum common elements of a row model.
///
/// You should implement your own types that conform to ImmuTableRow to define your custom rows.
///
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
    ///
    /// - Precondition: You can assume that the passed cell is of the type defined
    ///   by cell.cellClass and force downcast accordingly.
    ///
    func configureCell(_ cell: UITableViewCell)

    /// An ImmuTableCell value defining the associated cell type.
    ///
    /// - Seealso: See ImmuTableCell for possible options.
    ///
    static var cell: ImmuTableCell { get }

    /// The desired row height (Optional)
    ///
    /// If not defined or nil, the default height will be used.
    ///
    static var customHeight: Float? { get }
}

extension ImmuTableRow {
    public var reusableIdentifier: String {
        return type(of: self).cell.reusableIdentifier
    }

    public var cellClass: UITableViewCell.Type {
        return type(of: self).cell.cellClass
    }

    public static var customHeight: Float? {
        return nil
    }
}


// MARK: - ImmuTableCell


/// ImmuTableCell describes cell types so they can be registered with a table view.
///
/// It supports two options:
///    - Nib for Interface Builder defined cells.
///    - Class for cells defined in code.
/// Both cases presume a custom UITableViewCell subclass. If you aren't subclassing,
/// you can also use UITableViewCell as the type.
///
/// - Note: If you need to use any cell style other than .Default we recommend you
///  subclass UITableViewCell and override init(style:reuseIdentifier:).
///
public enum ImmuTableCell {

    /// A cell using a UINib. Values are the UINib object and the custom cell class.
    case nib(UINib, UITableViewCell.Type)

    /// A cell using a custom class. The associated value is the custom cell class.
    case `class`(UITableViewCell.Type)

    /// A String that uniquely identifies the cell type
    public var reusableIdentifier: String {
        switch self {
        case .class(let cellClass):
            return NSStringFromClass(cellClass)
        case .nib(_, let cellClass):
            return NSStringFromClass(cellClass)
        }
    }

    /// The class of the custom cell
    public var cellClass: UITableViewCell.Type {
        switch self {
        case .class(let cellClass):
            return cellClass
        case .nib(_, let cellClass):
            return cellClass
        }
    }
}


// MARK: -


/// ImmuTableViewHandler is a helper to facilitate integration of ImmuTable in your
/// table view controllers.
///
/// It acts as the table view data source and delegate, and signals the table view to
/// reload its data when the underlying model changes.
///
/// - Note: As it keeps a weak reference to its target, you should keep a strong
///         reference to the handler from your view controller.
///
open class ImmuTableViewHandler: NSObject, UITableViewDataSource, UITableViewDelegate {
    typealias UIViewControllerWithTableView = TableViewContainer & UITableViewDataSource & UITableViewDelegate & UIViewController

    @objc unowned let target: UIViewControllerWithTableView
    private weak var passthroughScrollViewDelegate: UIScrollViewDelegate?

    /// Initializes the handler with a target table view controller.
    /// - postcondition: After initialization, it becomse the data source and
    ///   delegate for the the target's table view.
    @objc init(takeOver target: UIViewControllerWithTableView, with passthroughScrollViewDelegate: UIScrollViewDelegate? = nil) {
        self.target = target
        self.passthroughScrollViewDelegate = passthroughScrollViewDelegate

        super.init()

        self.target.tableView.dataSource = self
        self.target.tableView.delegate = self
    }

    /// An ImmuTable object representing the table structure.
    open var viewModel = ImmuTable.Empty {
        didSet {
            if target.isViewLoaded {
                target.tableView.reloadData()
            }
        }
    }

    /// Configure the handler to automatically deselect any cell after tapping it.
    @objc var automaticallyDeselectCells = false

    // MARK: UITableViewDataSource

    open func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.sections.count
    }

    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.sections[section].rows.count
    }

    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = viewModel.rowAtIndexPath(indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: row.reusableIdentifier, for: indexPath)

        row.configureCell(cell)

        return cell
    }

    open func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return viewModel.sections[section].headerText
    }

    open func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return viewModel.sections[section].footerText
    }

    // MARK: UITableViewDelegate

    open func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if target.responds(to: #selector(UITableViewDelegate.tableView(_:willSelectRowAt:))) {
            return target.tableView?(tableView, willSelectRowAt: indexPath)
        } else {
            return indexPath
        }
    }
    open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if target.responds(to: #selector(UITableViewDelegate.tableView(_:didSelectRowAt:))) {
            target.tableView?(tableView, didSelectRowAt: indexPath)
        } else {
            let row = viewModel.rowAtIndexPath(indexPath)
            row.action?(row)
        }
        if automaticallyDeselectCells {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }

    open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let row = viewModel.rowAtIndexPath(indexPath)
        if let customHeight = type(of: row).customHeight {
            return CGFloat(customHeight)
        }
        return tableView.rowHeight
    }

    open func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if target.responds(to: #selector(UITableViewDelegate.tableView(_:heightForFooterInSection:))) {
            return target.tableView?(tableView, heightForFooterInSection: section) ?? UITableView.automaticDimension
        }

        return UITableView.automaticDimension
    }

    open func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if target.responds(to: #selector(UITableViewDelegate.tableView(_:heightForHeaderInSection:))) {
            return target.tableView?(tableView, heightForHeaderInSection: section) ?? UITableView.automaticDimension
        }

        return UITableView.automaticDimension
    }

    open func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if target.responds(to: #selector(UITableViewDelegate.tableView(_:viewForFooterInSection:))) {
            return target.tableView?(tableView, viewForFooterInSection: section)
        }

        return nil
    }

    open func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if target.responds(to: #selector(UITableViewDelegate.tableView(_:viewForHeaderInSection:))) {
            return target.tableView?(tableView, viewForHeaderInSection: section)
        }

        return nil
    }

    open func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if target.responds(to: #selector(UITableViewDataSource.tableView(_:canEditRowAt:))) {
            return target.tableView?(tableView, canEditRowAt: indexPath) ?? false
        }

        return false
    }

    open func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        if target.responds(to: #selector(UITableViewDelegate.tableView(_:editActionsForRowAt:))) {
            return target.tableView?(tableView, editActionsForRowAt: indexPath)
        }

        return nil
    }

    // MARK: UIScrollViewDelegate

    open func scrollViewDidScroll(_ scrollView: UIScrollView) {
        passthroughScrollViewDelegate?.scrollViewDidScroll?(scrollView)
    }

    open func scrollViewDidZoom(_ scrollView: UIScrollView) {
        passthroughScrollViewDelegate?.scrollViewDidZoom?(scrollView)
    }

    open func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        passthroughScrollViewDelegate?.scrollViewWillBeginDragging?(scrollView)
    }

    open func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        passthroughScrollViewDelegate?.scrollViewWillEndDragging?(scrollView, withVelocity: velocity, targetContentOffset: targetContentOffset)
    }

    open func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        passthroughScrollViewDelegate?.scrollViewDidEndDragging?(scrollView, willDecelerate: decelerate)
    }

    open func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        passthroughScrollViewDelegate?.scrollViewWillBeginDecelerating?(scrollView)
    }

    open func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        passthroughScrollViewDelegate?.scrollViewDidEndDecelerating?(scrollView)
    }

    open func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        passthroughScrollViewDelegate?.scrollViewDidEndScrollingAnimation?(scrollView)
    }

    open func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return passthroughScrollViewDelegate?.viewForZooming?(in: scrollView)
    }

    open func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        passthroughScrollViewDelegate?.scrollViewWillBeginZooming?(scrollView, with: view)
    }

    open func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        passthroughScrollViewDelegate?.scrollViewDidEndZooming?(scrollView, with: view, atScale: scale)
    }

    open func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        return passthroughScrollViewDelegate?.scrollViewShouldScrollToTop?(scrollView) ?? true
    }

    open func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        passthroughScrollViewDelegate?.scrollViewDidScrollToTop?(scrollView)
    }

    open func scrollViewDidChangeAdjustedContentInset(_ scrollView: UIScrollView) {
        passthroughScrollViewDelegate?.scrollViewDidChangeAdjustedContentInset?(scrollView)
    }
}


// MARK: - Type aliases

public typealias ImmuTableAction = (ImmuTableRow) -> Void


// MARK: - Internal testing helpers

protocol CellRegistrar {
    func register(_ cell: ImmuTableCell, cellReuseIdentifier: String)
}


extension UITableView: CellRegistrar {
    public func register(_ cell: ImmuTableCell, cellReuseIdentifier: String) {
        switch cell {
        case .nib(let nib, _):
            self.register(nib, forCellReuseIdentifier: cell.reusableIdentifier)
        case .class(let cellClass):
            self.register(cellClass, forCellReuseIdentifier: cell.reusableIdentifier)
        }
    }
}

// MARK: - UITableViewController conformance

@objc public protocol TableViewContainer: class {
    var tableView: UITableView! { get set }
}

extension UITableViewController: TableViewContainer {}
