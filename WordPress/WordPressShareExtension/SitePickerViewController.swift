import Foundation
import UIKit
import WordPressShared
import WordPressComKit


/// This class presents a list of Sites, and allows the user to select one from the list. Works
/// absolutely detached from the Core Data Model, since it was designed for Extension usage.
///
class SitePickerViewController : UITableViewController
{
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupTableView()
        setupNoResultsView()
        loadSites()
    }


    // MARK: - UITableView Methods
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sites.count
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return rowHeight
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier, forIndexPath: indexPath)
        let site = sites[indexPath.row]

        configureCell(cell, site: site)

        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let site = sites[indexPath.row]
        onChange?(siteId: site.ID, description: site.name?.characters.count > 0 ? site.name : site.URL.host)
        navigationController?.popViewControllerAnimated(true)
    }


    // MARK: - Setup Helpers
    private func setupView() {
        title = NSLocalizedString("Site Picker", comment: "Title for the Site Picker")
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

        // Cells
        tableView.registerClass(WPTableViewCellSubtitle.self, forCellReuseIdentifier: reuseIdentifier)
    }

    private func setupNoResultsView() {
        tableView.addSubview(noResultsView)
    }


    // MARK: - Private Helpers
    private func loadSites() {
        guard let oauth2Token = ShareExtensionService.retrieveShareExtensionToken() else {
            showEmptySitesIfNeeded()
            return
        }

        RequestRouter.bearerToken = oauth2Token as String

        let service = SiteService()

        showLoadingView()

        service.fetchSites { [weak self] sites, error in
            dispatch_async(dispatch_get_main_queue()) {
                self?.sites = sites ?? [Site]()
                self?.tableView.reloadData()
                self?.showEmptySitesIfNeeded()
            }
        }
    }

    private func configureCell(cell: UITableViewCell, site: Site) {
        // Site's Details
        cell.textLabel?.text = site.name
        cell.detailTextLabel?.text = site.URL.host

        // Site's Blavatar
        cell.imageView?.image = WPStyleGuide.Share.blavatarPlaceholderImage

        if let siteIconPath = site.icon,
            siteIconUrl = NSURL(string: siteIconPath)
        {
            cell.imageView?.downloadBlavatar(siteIconUrl)
        }

        // Style
        WPStyleGuide.Share.configureBlogTableViewCell(cell)
    }


    // MARK: - No Results Helpers
    private func showLoadingView() {
        noResultsView.titleText = NSLocalizedString("Loading Sites...", comment: "Legend displayed when loading Sites")
        noResultsView.hidden = false
    }

    private func showEmptySitesIfNeeded() {
        let hasSites = (sites.isEmpty == false)
        noResultsView.titleText = NSLocalizedString("No Sites", comment: "Legend displayed when the user has no sites")
        noResultsView.hidden = hasSites
    }


    // MARK: Typealiases
    typealias PickerHandler = (siteId: Int, description: String?) -> Void

    // MARK: - Public Properties
    var onChange                : PickerHandler?

    // MARK: - Private Properties
    private var sites           = [Site]()
    private var noResultsView   = WPNoResultsView()

    // MARK: - Private Constants
    private let reuseIdentifier = "reuseIdentifier"
    private let rowHeight       = CGFloat(74)
}
