import Foundation
import UIKit
import WordPressShared
import WordPressKit

protocol SitePickerDelegate: class {
    func didSelectSite(siteId: Int, description: String?)
}

/// This class presents a list of Sites, and allows the user to select one from the list. Works
/// absolutely detached from the Core Data Model, since it was designed for Extension usage.
///
class SitePickerViewController: UITableViewController {

    weak var sitePickerDelegate: SitePickerDelegate?

    // MARK: - Private Constants

    fileprivate let reuseIdentifier = "reuseIdentifier"

    // MARK: - Private Properties

    fileprivate var sites           = [RemoteBlog]()
    fileprivate var noResultsView   = WPNoResultsView()

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupNoResultsView()
        loadSites()
    }

    // MARK: - Setup & Configuration

    fileprivate func setupTableView() {
        // Fix: Hide the cellSeparators, when the table is empty
        tableView.tableFooterView = UIView()
        tableView.allowsSelection = true
        tableView.delegate = self

        // Style!
        tableView.backgroundColor = UIColor.clear
        tableView.separatorColor = WPStyleGuide.greyLighten20()
        WPStyleGuide.configureAutomaticHeightRows(for: tableView)

        // Cells
        tableView.register(WPTableViewCellSubtitle.self, forCellReuseIdentifier: reuseIdentifier)
    }

    fileprivate func setupNoResultsView() {
        tableView.addSubview(noResultsView)
    }

    // MARK: - UITableView Methods
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sites.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
        let site = sites[indexPath.row]

        configureCell(cell, site: site)

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let site = sites[indexPath.row]
        let siteName = (site.name?.count)! > 0 ? site.name : URL(string: site.url)?.host
        sitePickerDelegate?.didSelectSite(siteId: site.blogID.intValue, description: siteName)
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
        cell.selectionStyle = .blue

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
}
