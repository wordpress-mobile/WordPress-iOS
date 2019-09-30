import Foundation
import WordPressShared



/// The purpose of this class is to render an interface that allows the user to Insert / Edit / Delete
/// a set of strings.
///
open class SettingsListEditorViewController: UITableViewController {
    // MARK: - Public Properties
    @objc open var footerText: String?
    @objc open var emptyText: String?
    @objc open var insertTitle: String?
    @objc open var editTitle: String?
    @objc open var onChange: ((Set<String>) -> Void)?


    // MARK: - Initialiers
    @objc public convenience init(collection: Set<String>?) {
        self.init(style: .grouped)

        emptyText = NSLocalizedString("No Items", comment: "List Editor Empty State Message")

        if let unwrappedCollection = collection?.sorted() as [String]? {
            rows.addObjects(from: unwrappedCollection)
        }
    }



    // MARK: - View Lifecycle
    open override func viewDidLoad() {
        super.viewDidLoad()
        setupNavBar()
        setupTableView()
    }



    // MARK: - Helpers
    fileprivate func notifyDidChange() {
        let orderedRows = Set<String>(rows.array as! [String])
        onChange?(orderedRows)
    }



    // MARK: - Setup Helpers
    fileprivate func setupNavBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add,
            target: self,
            action: #selector(SettingsListEditorViewController.addItemPressed(_:)))
    }

    fileprivate func setupTableView() {
        tableView.register(WPTableViewCell.self, forCellReuseIdentifier: reuseIdentifier)
        WPStyleGuide.configureColors(view: view, tableView: tableView)
    }



    // MARK: - Button Handlers
    @IBAction func addItemPressed(_ sender: AnyObject?) {
        let settingsViewController = SettingsTextViewController(text: nil, placeholder: nil, hint: nil)
        settingsViewController.title = insertTitle
        settingsViewController.onValueChanged = { (updatedValue: String!) in
            self.insertString(updatedValue)
            self.notifyDidChange()
            self.tableView.reloadData()
        }

        navigationController?.pushViewController(settingsViewController, animated: true)
    }



    // MARK: - UITableViewDataSoutce Methods
    open override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    open override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Note:
        // We'll always render, at least, one row, with the Empty State text
        return max(rows.count, 1)
    }

    open override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier)!

        WPStyleGuide.configureTableViewCell(cell)

        cell.accessoryType = isEmpty() ? .none : .disclosureIndicator
        cell.textLabel?.text = isEmpty() ? emptyText : stringAtIndexPath(indexPath)
        cell.textLabel?.textColor = isEmpty() ? .neutral(.shade10) : .neutral(.shade70)

        return cell
    }

    open override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return footerText
    }

    open override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        WPStyleGuide.configureTableViewSectionFooter(view)
    }

    open override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectSelectedRowWithAnimation(true)

        // Empty State
        if isEmpty() {
            addItemPressed(nil)
            return
        }

        // Edit!
        let oldText = stringAtIndexPath(indexPath)

        let settingsViewController = SettingsTextViewController(text: oldText, placeholder: nil, hint: nil)
        settingsViewController.title = editTitle
        settingsViewController.onValueChanged = { (newText: String!) in
            self.replaceString(oldText, newText: newText)
            self.notifyDidChange()
            self.tableView.reloadData()
        }

        navigationController?.pushViewController(settingsViewController, animated: true)
    }

    open override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return isEmpty() == false
    }

    open override func tableView(_ tableView: UITableView,
                                 editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }

    open override func tableView(_ tableView: UITableView,
                                 commit editingStyle: UITableViewCell.EditingStyle,
                                 forRowAt indexPath: IndexPath) {
        // Nuke it from the collection
        removeAtIndexPath(indexPath)
        notifyDidChange()

        // Empty State: We'll always render a single row, indicating that there are no items
        if isEmpty() {
            tableView.reloadRows(at: [indexPath], with: .fade)
        } else {
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }



    // MARK: - Helpers
    fileprivate func stringAtIndexPath(_ indexPath: IndexPath) -> String {
        return rows.object(at: indexPath.row) as! String
    }

    fileprivate func removeAtIndexPath(_ indexPath: IndexPath) {
        rows.removeObject(at: indexPath.row)
    }

    fileprivate func insertString(_ newText: String) {
        if newText.isEmpty {
            return
        }

        rows.add(newText)
        sortStrings()
    }

    fileprivate func replaceString(_ oldText: String, newText: String) {
        if oldText == newText {
            return
        }

        insertString(newText)
        rows.remove(oldText)
    }

    fileprivate func sortStrings() {
        self.rows.sort (comparator: { ($0 as! String).compare($1 as! String) })
    }

    fileprivate func isEmpty() -> Bool {
        return rows.count == 0
    }



    // MARK: - Constants
    fileprivate let reuseIdentifier = "WPTableViewCell"

    // MARK: - Properties
    fileprivate var rows = NSMutableOrderedSet()
}
