import Foundation
import UIKit
import WordPressShared
import WordPressComKit


class BlogPickerViewController : UITableViewController
{
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        setupTableView()
        loadSites()
    }
    
    
    // MARK: - UITableView Methods
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sites?.count ?? 0
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return rowHeight
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier)
        if cell == nil {
            cell = WPTableViewCell(style: .Subtitle, reuseIdentifier: reuseIdentifier)
            WPStyleGuide.configureTableViewCell(cell)
        }
        
        let site = sites?[indexPath.row]
        cell?.textLabel?.text = site?.name
        cell?.detailTextLabel?.text = NSURLComponents(URL: site!.URL, resolvingAgainstBaseURL: true)!.host
        cell?.backgroundColor = UIColor.clearColor()
        
        return cell!
    }
    
    
    // MARK: Private Methods
    private func setupView() {
        title = NSLocalizedString("Site Picker", comment: "Title for the Site Picker")
        preferredContentSize = UIScreen.mainScreen().bounds.size
    }
    
    private func setupTableView() {
        let blurEffect = UIBlurEffect(style: .Light)
        tableView.backgroundColor = UIColor.clearColor()
        tableView.backgroundView = UIVisualEffectView(effect: blurEffect)
        tableView.separatorEffect = UIVibrancyEffect(forBlurEffect: blurEffect)
    }
    
    
    // MARK: Remote Helpers
    private func loadSites() {
        let token = ""
        let service = SiteService(bearerToken: token, urlSession: NSURLSession.sharedSession())
        
        service.fetchSites { sites, error in
            dispatch_async(dispatch_get_main_queue()) {
                self.sites = sites
                self.tableView.reloadData()
            }
        }
    }
    
    
    // MARK: - Private Properties
    private var sites : [Site]?
    
    // MARK: - Private Constants
    private let reuseIdentifier = "reuseIdentifier"
    private let rowHeight       = CGFloat(74)
}
