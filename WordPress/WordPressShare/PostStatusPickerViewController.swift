import Foundation
import UIKit
import WordPressShared

class PostStatsPickerViewController : UITableViewController
{
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupTableView()
        setupNoResultsView()
        loadStatuses()
    }
    
    
    // MARK: - UITableView Methods
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return statuses.count
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return rowHeight
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier)
        if cell == nil {
            cell = WPTableViewCell(style: .Subtitle, reuseIdentifier: reuseIdentifier)
            WPStyleGuide.Share.configureBlogTableViewCell(cell!)
        }
        
        let status = sortedStatuses[indexPath.row].0
        configureCell(cell!, status: status)
        
        return cell!
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let status = sortedStatuses[indexPath.row].0
        let description = statuses[status]!
        onChange?(postStatus: status, description: description)
        navigationController?.popViewControllerAnimated(true)
    }
    
    
    // MARK: - Setup Helpers
    private func setupView() {
        title = NSLocalizedString("Post Status", comment: "Title for the Post Status Picker")
        preferredContentSize = UIScreen.mainScreen().bounds.size
    }
    
    private func setupTableView() {
        // Blur!
        let blurEffect = UIBlurEffect(style: .Light)
        tableView.backgroundColor = UIColor.clearColor()
        tableView.backgroundView = UIVisualEffectView(effect: blurEffect)
        tableView.separatorEffect = UIVibrancyEffect(forBlurEffect: blurEffect)
        
        // Fix: Hide the cellSeparators, when the table is empty
        tableView.tableFooterView = UIView()
    }
    
    private func setupNoResultsView() {
        noResultsView = WPNoResultsView()
        tableView.addSubview(noResultsView)
    }
    
    
    // MARK: - Private Helpers
    private func configureCell(cell: UITableViewCell, status: String) {
        // Status' Details
        let statusDescription = statuses[status]
        cell.textLabel?.text = statusDescription
    }
    
    private func loadStatuses() {
        let statuses = [
            "draft" : NSLocalizedString("Draft", comment: "Draft post status"),
            "publish" : NSLocalizedString("Publish", comment: "Publish post status")]
        sortedStatuses = statuses.sort({ $0.1 < $1.1 })
    }
    
    // MARK: Typealiases
    typealias PickerHandler = (postStatus: String, description: String) -> Void
    
    // MARK: - Public Properties
    var onChange                : PickerHandler?
    
    // MARK: - Private Properties
    private var statuses: [String: String]!
    private var sortedStatuses: [(String, String)]!
    private var noResultsView   : WPNoResultsView!
    
    // MARK: - Private Constants
    private let reuseIdentifier = "reuseIdentifier"
    private let rowHeight       = CGFloat(74)
}
