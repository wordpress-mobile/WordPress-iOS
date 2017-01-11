import Foundation
import UIKit
import WordPressShared
import WordPressComKit


/// This class presents a list of Sites, and allows the user to select one from the list. Works
/// absolutely detached from the Core Data Model, since it was designed for Extension usage.
///
class SitePickerViewController: UITableViewController {
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
        onChange?(site.ID, (site.name?.characters.count)! > 0 ? site.name : site.URL.host)
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

        RequestRouter.bearerToken = oauth2Token as String

        let service = SiteService()

        showLoadingView()

        service.fetchSites { [weak self] sites, error in
            DispatchQueue.main.async {
                self?.sites = sites ?? [Site]()
                self?.tableView.reloadData()
                self?.showEmptySitesIfNeeded()
            }
        }
    }

    fileprivate func configureCell(_ cell: UITableViewCell, site: Site) {
        // Site's Details
        cell.textLabel?.text = site.name
        cell.detailTextLabel?.text = site.URL.host

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
    fileprivate var sites           = [Site]()
    fileprivate var noResultsView   = WPNoResultsView()

    // MARK: - Private Constants
    fileprivate let reuseIdentifier = "reuseIdentifier"
    fileprivate let rowHeight       = CGFloat(74)
}
