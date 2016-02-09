import Foundation
import WordPressShared


/// This class will display the Blog's Language setting, and will allow the user to pick a new value.
/// Upon selection, WordPress.com backend will get hit, and the new value will be persisted.
///
public class LanguageViewController : UITableViewController
{
    /// Designated Initializer
    ///
    /// - Parameters
    ///     - Blog: The blog for which we wanna display the languages picker
    ///
    public convenience init(blog: Blog) {
        self.init(style: .Grouped)
        self.blog = blog
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Language", comment: "Title for the Language Picker Screen")
        
        // Setup tableView
        WPStyleGuide.configureColorsForView(view, andTableView: tableView)
        WPStyleGuide.resetReadableMarginsForTableView(tableView)
    }
    
    
    
    // MARK: - UITableViewDataSoutce Methods
    public override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    public override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    public override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier)
        if cell == nil {
            cell = WPTableViewCell(style: .Value1, reuseIdentifier: reuseIdentifier)
            cell?.accessoryType = .DisclosureIndicator
            WPStyleGuide.configureTableViewCell(cell)
        }
        
        configureTableViewCell(cell!)
        
        return cell!
    }
    
    public override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return WPTableViewSectionHeaderFooterView.heightForFooter(footerText, width: view.bounds.width)
    }
    
    public override func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let headerView = WPTableViewSectionHeaderFooterView(reuseIdentifier: nil, style: .Footer)
        headerView.title = footerText
        return headerView
    }

    
    
    // MARK: - Private Methods
    private func configureTableViewCell(cell: UITableViewCell) {
        let languageId = blog.settings.languageID.integerValue
        cell.textLabel?.text = NSLocalizedString("Language", comment: "Language of the current blog")
        cell.detailTextLabel?.text = Languages.sharedInstance.nameForLanguageWithId(languageId)
    }
    
    

    // MARK: - Private Constants
    private let reuseIdentifier = "reuseIdentifier"
    private let footerText = NSLocalizedString("The language in which this site is primarily written. " +
                                                "You can modify the interface language in your Account Settings.",
                                                comment: "Footer Text displayed in Blog Language Settings View")
    
    // MARK: - Private Properties
    private var blog : Blog!
}
