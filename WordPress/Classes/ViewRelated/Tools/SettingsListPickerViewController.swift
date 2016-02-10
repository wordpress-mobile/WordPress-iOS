import Foundation
import WordPressShared



/// SettingsListPicker will render a list of options, and will allow the user to select one from the list.
///
class SettingsListPickerViewController : UITableViewController
{
    /// Header Strings to be applied over the diferent sections
    ///
    var headers : [String]?

    /// Footer Strings to be applied over the diferent sections
    ///
    var footers : [String]?
    
    /// Titles to be rendered
    ///
    var titles : [[String]]?
    
    /// Row Values. Should contain the exact same number as titles
    ///
    var values : [[NSObject]]?
    
    /// Current selected value, if any
    ///
    var selectedValue : NSObject?
    
    /// Callback to be executed whenever the selectedValue changes
    ///
    var onChange : (AnyObject -> Void)?
    
    
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        assert(titles!.count == values!.count)
    }
    
    
    
    // MARK: - Setup Helpers
    private func setupTableView() {
        tableView.registerClass(WPTableViewCell.self, forCellReuseIdentifier: reuseIdentifier)
        tableView.cellLayoutMarginsFollowReadableWidth = false
        WPStyleGuide.configureColorsForView(view, andTableView: tableView)
    }
    
    
    
    // MARK: - UITableViewDataSource Methods
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return titles?.count ?? 0
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return titles?[section].count ?? 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier)!
        
        WPStyleGuide.configureTableViewCell(cell)
        
        let title = titles?[indexPath.section][indexPath.row] ?? String()
        let selected = values?[indexPath.section][indexPath.row] == selectedValue
        
        cell.textLabel?.text = title
        cell.accessoryType = selected ? .Checkmark : .None
        
        return cell
    }

    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let text = headers?[section] else {
            return nil
        }
        
        let footerView = WPTableViewSectionHeaderFooterView(reuseIdentifier: nil, style: .Header)
        footerView.title = text
        
        return footerView
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let text = headers?[section] else {
            return 0
        }
        
        return WPTableViewSectionHeaderFooterView.heightForHeader(text, width: view.frame.width)
    }
    
    override func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let text = footers?[section] else {
            return nil
        }
        
        let footerView = WPTableViewSectionHeaderFooterView(reuseIdentifier: nil, style: .Footer)
        footerView.title = text
        
        return footerView
    }
    
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard let text = footers?[section] else {
            return 0
        }
        
        return WPTableViewSectionHeaderFooterView.heightForFooter(text, width: view.frame.width)
    }
    
    
    
    // MARK: - UITableViewDelegate Methods
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        guard let newValue = values?[indexPath.section][indexPath.row] else {
            return
        }
        
        selectedValue = newValue
        tableView.reloadDataPreservingSelection()
        
        // Note: due to a weird UITableView interaction between reloadData and deselectSelectedRow,
        // we'll introduce a slight delay before deselecting, to avoid getting the highlighted row flickering.
        dispatch_async(dispatch_get_main_queue()) {
            tableView.deselectSelectedRowWithAnimation(true)
        }
        
        // Callback!
        onChange?(newValue)
    }
    
    
    
    // MARK: - Constants
    private let reuseIdentifier = "WPTableViewCell"
}
