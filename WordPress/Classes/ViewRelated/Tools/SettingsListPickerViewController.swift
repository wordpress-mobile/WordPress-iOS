import Foundation
import WordPressShared



/// SettingsListPicker will render a list of options, and will allow the user to select one from the list.
///
class SettingsListPickerViewController<T:Equatable> : UITableViewController
{
    /// Current selected value, if any
    ///
    var selectedValue : T?
    
    /// Callback to be executed whenever the selectedValue changes
    ///
    var onChange : (T -> Void)?
    
    
    
    // MARK: - Initializers
    init(headers: [String]? = nil, footers: [String]? = nil, titles: [[String]], subtitles: [[String]]? = nil, values: [[T]])
    {
        self.headers = headers
        self.footers = footers
        self.titles = titles
        self.subtitles = subtitles
        self.values = values
        
        super.init(style: .Grouped)
        
        assert(titles.count == values.count)
        assert(titles.count == subtitles?.count || subtitles == nil)
        assert(headers?.count == titles.count || headers == nil)
        assert(footers?.count == titles.count || footers == nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.headers = nil
        self.footers = nil
        self.titles = nil
        self.subtitles = nil
        self.values = nil
        self.selectedValue = nil
        self.onChange = nil
        
        super.init(coder: aDecoder)
        
        return nil
    }
    
    
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
    }

    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        
        // Note: This fixes an extra padding glitch upon rotation
        view.setNeedsLayout()
    }
    
    
    
    // MARK: - Setup Helpers
    private func setupTableView() {
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
        var cell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier)
        if cell == nil {
            cell = WPTableViewCell(style: .Subtitle, reuseIdentifier: reuseIdentifier)
            WPStyleGuide.configureTableViewSmallSubtitleCell(cell)
        }

        
        let title = titles?[indexPath.section][indexPath.row] ?? String()
        let subtitle = subtitles?[indexPath.section][indexPath.row] ?? String()
        let selected = values?[indexPath.section][indexPath.row] == selectedValue
        
        cell?.textLabel?.text = title
        cell?.detailTextLabel?.text = subtitle
        cell?.accessoryType = selected ? .Checkmark : .None
        
        return cell!
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
    
    
    
    
    // MARK: - Private Properties
    
    /// Header Strings to be applied over the diferent sections
    ///
    private let headers : [String]?
    
    /// Footer Strings to be applied over the diferent sections
    ///
    private let footers : [String]?
    
    /// Titles to be rendered
    ///
    private let titles : [[String]]?
    
    /// Row Subtitles. Should contain the exact same number as titles
    ///
    private let subtitles : [[String]]?
    
    /// Row Values. Should contain the exact same number as titles
    ///
    private let values : [[T]]?
}
