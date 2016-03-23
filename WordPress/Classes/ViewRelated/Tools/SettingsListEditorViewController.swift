import Foundation
import WordPressShared



/// The purpose of this class is to render an interface that allows the user to Insert / Edit / Delete a set of strings.

public class SettingsListEditorViewController : UITableViewController
{
    // MARK: - Public Properties
    public var footerText   : String?
    public var emptyText    : String?
    public var insertTitle  : String?
    public var editTitle    : String?
    public var onChange     : ((Set<String>) -> Void)?
    
    
    // MARK: - Initialiers
    public convenience init(collection: Set<String>?) {
        self.init(style: .Grouped)
        
        emptyText = NSLocalizedString("No Items", comment: "List Editor Empty State Message")
        
        if let unwrappedCollection = collection?.sort() as [String]? {
            rows.addObjectsFromArray(unwrappedCollection)
        }
    }
    
    
    
    // MARK: - View Lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupNavBar()
        setupTableView()
    }
    
    
    
    // MARK: - Helpers
    private func notifyDidChange() {
        let orderedRows = Set<String>(rows.array as! [String])
        onChange?(orderedRows)
    }
    
    
    
    // MARK: - Setup Helpers
    private func setupNavBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Add,
            target: self,
            action: #selector(SettingsListEditorViewController.addItemPressed(_:)))
    }
    
    private func setupTableView() {
        tableView.registerClass(WPTableViewCell.self, forCellReuseIdentifier: reuseIdentifier)
        tableView.cellLayoutMarginsFollowReadableWidth = false
        WPStyleGuide.configureColorsForView(view, andTableView: tableView)
    }
    
    
    
    // MARK: - Button Handlers
    @IBAction func addItemPressed(sender: AnyObject?) {
        let settingsViewController = SettingsTextViewController(text: nil, placeholder: nil, hint: nil, isPassword: false)
        settingsViewController.title = insertTitle
        settingsViewController.onValueChanged = { (updatedValue : String!) in
            self.insertString(updatedValue)
            self.notifyDidChange()
            self.tableView.reloadData()
        }
        
        navigationController?.pushViewController(settingsViewController, animated: true)
    }
    
    
    
    // MARK: - UITableViewDataSoutce Methods
    public override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    public override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Note: 
        // We'll always render, at least, one row, with the Empty State text
        return max(rows.count, 1)
    }
    
    public override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier)!

        WPStyleGuide.configureTableViewCell(cell)

        cell.accessoryType = isEmpty() ? .None : .DisclosureIndicator
        cell.textLabel?.text = isEmpty() ? emptyText : stringAtIndexPath(indexPath)
        cell.textLabel?.textColor = isEmpty() ? WPStyleGuide.greyLighten20() : WPStyleGuide.darkGrey()
        
        return cell
    }
    
    public override func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let unwrappedFooterText = footerText else {
            return nil
        }

        
        let footerView = WPTableViewSectionHeaderFooterView(reuseIdentifier: nil, style: .Footer)
        footerView.title = unwrappedFooterText
        
        return footerView
    }
    
    public override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard let unwrappedFooterText = footerText else {
            return CGFloat.min
        }
        
        let height = WPTableViewSectionHeaderFooterView.heightForFooter(unwrappedFooterText, width: view.frame.width)
        return height
    }
    
    public override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectSelectedRowWithAnimation(true)
        
        // Empty State
        if isEmpty() {
            return
        }
        
        // Edit!
        let oldText = stringAtIndexPath(indexPath)
        
        let settingsViewController = SettingsTextViewController(text: oldText, placeholder: nil, hint: nil, isPassword: false)
        settingsViewController.title = editTitle
        settingsViewController.onValueChanged = { (newText : String!) in
            self.replaceString(oldText, newText: newText)
            self.notifyDidChange()
            self.tableView.reloadData()
        }
     
        navigationController?.pushViewController(settingsViewController, animated: true)
    }
    
    public override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return isEmpty() == false
    }
    
    public override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return .Delete
    }
    
    public override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        // Nuke it from the collection
        removeAtIndexPath(indexPath)
        notifyDidChange()
        
        // Empty State: We'll always render a single row, indicating that there are no items
        if isEmpty() {
            tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else {
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        }
    }
    
    
    
    // MARK: - Helpers
    private func stringAtIndexPath(indexPath : NSIndexPath) -> String {
        return rows.objectAtIndex(indexPath.row) as! String
    }
    
    private func removeAtIndexPath(indexPath : NSIndexPath) {
        rows.removeObjectAtIndex(indexPath.row)
    }
    
    private func insertString(newText: String) {
        if newText.isEmpty {
            return
        }
        
        rows.addObject(newText)
        sortStrings()
    }
    
    private func replaceString(oldText: String, newText: String) {
        if oldText == newText {
            return
        }
        
        insertString(newText)
        rows.removeObject(oldText)
    }
    
    private func sortStrings() {
        self.rows.sortUsingComparator { ($0 as! String).compare($1 as! String) }
    }
    
    private func isEmpty() -> Bool {
        return rows.count == 0
    }
    
    
    
    // MARK: - Constants
    private let reuseIdentifier = "WPTableViewCell"

    // MARK: - Properties
    private var rows = NSMutableOrderedSet()
}
