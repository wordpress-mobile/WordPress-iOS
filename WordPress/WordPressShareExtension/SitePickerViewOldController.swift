import Foundation
import UIKit
import WordPressShared
import WordPressKit

/// This class presents a list of Sites, and allows the user to select one from the list. Works
/// absolutely detached from the Core Data Model, since it was designed for Extension usage.
///
class SitePickerViewOldController: UITableViewController {
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupTableView()
        setupNoResultsView()
        loadSites()
    }


    // MARK: - UITableView Methods
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sites.count
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return rowHeight
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
        let site = sites[indexPath.row]

        configureCell(cell, site: site)

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let site = sites[indexPath.row]
        onChange?(site.blogID.intValue, (site.name?.count)! > 0 ? site.name : URL(string: site.url)?.host)
        _ = navigationController?.popViewController(animated: true)
    }


    // MARK: - Setup Helpers
    fileprivate func setupView() {
        title = NSLocalizedString("Site Picker", comment: "Title for the Site Picker")
        preferredContentSize = UIScreen.main.bounds.size
    }

    fileprivate func setupTableView() {
        // Blur!
        let blurEffect = UIBlurEffect(style: .light)
        tableView.backgroundColor = UIColor.clear
        tableView.backgroundView = UIVisualEffectView(effect: blurEffect)
        tableView.separatorEffect = UIVibrancyEffect(blurEffect: blurEffect)

        // Fix: Hide the cellSeparators, when the table is empty
        tableView.tableFooterView = UIView()

        // Cells
        tableView.register(WPTableViewCellSubtitle.self, forCellReuseIdentifier: reuseIdentifier)
    }

    fileprivate func setupNoResultsView() {
        tableView.addSubview(noResultsView)
    }


    // MARK: - Private Helpers
    fileprivate func loadSites() {
        guard let oauth2Token = ShareExtensionService.retrieveShareExtensionToken() else {
            showEmptySitesIfNeeded()
            return
        }

        let api = WordPressComRestApi(oAuthToken: oauth2Token, userAgent: nil)
        let remote = AccountServiceRemoteREST.init(wordPressComRestApi: api)
        remote?.getVisibleBlogs(success: { [weak self] blogs in
            DispatchQueue.main.async {
                self?.sites = (blogs as? [RemoteBlog]) ?? [RemoteBlog]()
                self?.tableView.reloadData()
                self?.showEmptySitesIfNeeded()
            }
        }, failure: { [weak self] error in
            NSLog("Error retrieving blogs: \(String(describing: error))")
            DispatchQueue.main.async {
                self?.sites = [RemoteBlog]()
                self?.tableView.reloadData()
                self?.showEmptySitesIfNeeded()
            }
        })

        showLoadingView()
    }

    fileprivate func configureCell(_ cell: UITableViewCell, site: RemoteBlog) {
        // Site's Details
        cell.textLabel?.text = site.name
        cell.detailTextLabel?.text = URL(string: site.url)?.host

        // Site's Blavatar
        cell.imageView?.image = WPStyleGuide.Share.blavatarPlaceholderImage

        if let siteIconPath = site.icon,
            let siteIconUrl = URL(string: siteIconPath) {
            cell.imageView?.downloadBlavatar(siteIconUrl)
        }

        // Style
        WPStyleGuide.Share.configureBlogTableViewCell(cell)
    }


    // MARK: - No Results Helpers
    fileprivate func showLoadingView() {
        noResultsView.titleText = NSLocalizedString("Loading Sites...", comment: "Legend displayed when loading Sites")
        noResultsView.isHidden = false
    }

    fileprivate func showEmptySitesIfNeeded() {
        let hasSites = (sites.isEmpty == false)
        noResultsView.titleText = NSLocalizedString("No Sites", comment: "Legend displayed when the user has no sites")
        noResultsView.isHidden = hasSites
    }

    // MARK: Typealiases
    typealias PickerHandler = (_ siteId: Int, _ description: String?) -> Void

    // MARK: - Public Properties
    var onChange: PickerHandler?

    // MARK: - Private Properties
    fileprivate var sites           = [RemoteBlog]()
    fileprivate var noResultsView   = WPNoResultsView()

    // MARK: - Private Constants
    fileprivate let reuseIdentifier = "reuseIdentifier"
    fileprivate let rowHeight       = CGFloat(74)
}
