import UIKit
import WordPressShared
import WordPressKit

class ShareModularViewController: ShareExtensionAbstractViewController {

    // MARK: - Private Properties

    /// TableView for site list
    ///
    @IBOutlet fileprivate var tableView: UITableView!

    /// Back Bar Button
    ///
    fileprivate lazy var backButton: UIBarButtonItem = {
        let publishTitle = NSLocalizedString("Back", comment: "Back action on share extension site picker screen. Takes the user to the share extension editor screen.")
        let button = UIBarButtonItem(title: publishTitle, style: .plain, target: self, action: #selector(backWasPressed))
        button.accessibilityIdentifier = "Publish Button"
        return button
    }()

    /// Publish Bar Button
    ///
    fileprivate lazy var publishButton: UIBarButtonItem = {
        let publishTitle = NSLocalizedString("Publish", comment: "Publish post action on share extension site picker screen.")
        let button = UIBarButtonItem(title: publishTitle, style: .plain, target: self, action: #selector(publishWasPressed))
        button.accessibilityIdentifier = "Publish Button"
        return button
    }()

    /// Activity spinner used when loading sites
    ///
    fileprivate lazy var activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .gray)
    fileprivate lazy var noResultsView: WPNoResultsView = {
        $0.accessoryView = activityIndicatorView
        return $0
    }(WPNoResultsView())

    fileprivate var firstTimeLoad: Bool = true

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupSiteData()

        // Initialize Interface
        setupNavigationBar()
        setupTableView()
        setupNoResultsView()

        // Load Data
        reloadSitesIfNeeded()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    // MARK: - Setup Helpers

    fileprivate func setupSiteData() {
        // If this is our first time loading this screen AND the selected site ID is empty, prefill
        // the selected site info with what we historically used in the past.
        if firstTimeLoad {
            firstTimeLoad = false
            if shareData.selectedSiteID == nil {
                shareData.selectedSiteID = historicalSelectedSiteID
                shareData.selectedSiteName = historicalSelectedSiteName
            }
        }
    }

    fileprivate func setupNavigationBar() {
        self.navigationItem.hidesBackButton = true
        navigationItem.leftBarButtonItem = backButton
        navigationItem.rightBarButtonItem = publishButton
    }

    fileprivate func setupTableView() {
        // Register the cells
        tableView.register(ShareSitesTableViewCell.self, forCellReuseIdentifier: Constants.sitesReuseIdentifier)

        // Hide the separators, whenever the table is empty
        tableView.tableFooterView = UIView()

        // Style!
        WPStyleGuide.configureColors(for: view, andTableView: tableView)
        WPStyleGuide.configureAutomaticHeightRows(for: tableView)
    }

    fileprivate func setupNoResultsView() {
        tableView.addSubview(noResultsView)
    }
}

// MARK: - Actions

extension ShareModularViewController {
    @objc func backWasPressed() {
        if let editor = navigationController?.previousViewController() as? ShareExtensionEditorViewController {
            editor.sites = sites
            editor.shareData = shareData
        }
        _ = navigationController?.popViewController(animated: true)
    }

    @objc func publishWasPressed() {
        // FIXME: Add Publish task
    }
}

// MARK: - UITableView DataSource Conformance

extension ShareModularViewController: UITableViewDataSource {
    @objc func numberOfSections(in tableView: UITableView) -> Int {
        return Section.count
    }

    @objc func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .sites:
            return rowCountForSitesSection
        default:
            // FIXME: This will change
            return Constants.emptyCount
        }
    }

    @objc func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier  = reusableIdentifierForIndexPath(indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier)!
        configureCell(cell, indexPath: indexPath)

        return cell
    }

    @objc func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let isSitesSection = indexPath.section == Section.sites.rawValue
        return isSitesSection ? Constants.blogRowHeight : Constants.defaultRowHeight
    }

    @objc func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        // Hide when the section is empty!
        if isSectionEmpty(section) {
            return nil
        }

        let theSection = Section(rawValue: section)!
        return theSection.headerText()
    }

    @objc func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        WPStyleGuide.configureTableViewSectionHeader(view)
    }

    @objc func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        // Hide when the section is empty!
        if isSectionEmpty(section) {
            return nil
        }

        let theSection = Section(rawValue: section)!
        return theSection.footerText()
    }

    @objc func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        WPStyleGuide.configureTableViewSectionFooter(view)
    }
}

// MARK: - UITableView Delegate Conformance

extension ShareModularViewController: UITableViewDelegate {
    @objc func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath),
            let site = siteForRowAtIndexPath(indexPath) else {
            return
        }
        cell.accessoryType = .checkmark

        shareData.selectedSiteID = site.blogID.intValue
        shareData.selectedSiteName = (site.name?.count)! > 0 ? site.name : URL(string: site.url)?.host
    }

    @objc func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) else {
            return
        }
        cell.accessoryType = .none
    }
}

// MARK: - UITableView Helpers

fileprivate extension ShareModularViewController {
    func reusableIdentifierForIndexPath(_ indexPath: IndexPath) -> String {
        switch Section(rawValue: indexPath.section)! {
        case .sites:
            return Constants.sitesReuseIdentifier
        default:
            return Constants.defaultReuseIdentifier
        }
    }

    func configureCell(_ cell: UITableViewCell, indexPath: IndexPath) {
        guard let site = siteForRowAtIndexPath(indexPath) else {
            return
        }

        // Site's Details
        let displayURL = URL(string: site.url)?.host ?? ""
        if let name = site.name.nonEmptyString() {
            cell.textLabel?.text = name
            cell.detailTextLabel?.isEnabled = true
            cell.detailTextLabel?.text = displayURL
        } else {
            cell.textLabel?.text = displayURL
            cell.detailTextLabel?.isEnabled = false
            cell.detailTextLabel?.text = nil
        }

        // Site's Blavatar
        cell.imageView?.image = WPStyleGuide.Share.blavatarPlaceholderImage
        if let siteIconPath = site.icon,
            let siteIconUrl = URL(string: siteIconPath) {
            cell.imageView?.downloadBlavatar(siteIconUrl)
        } else {
            cell.imageView?.image = WPStyleGuide.Share.blavatarPlaceholderImage
        }

        if site.blogID.intValue == shareData.selectedSiteID {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }

        WPStyleGuide.Share.configureTableViewSiteCell(cell)
    }

    fileprivate var rowCountForSitesSection: Int {
        return sites?.count ?? 0
    }

    func siteForRowAtIndexPath(_ indexPath: IndexPath) -> RemoteBlog? {
        guard let sites = sites else {
            return nil
        }
        return sites[indexPath.row]
    }

    func isSectionEmpty(_ sectionIndex: Int) -> Bool {
        switch Section(rawValue: sectionIndex)! {
        case .sites:
            return hasSites
        default:
            return false
        }
    }
}

// MARK: - No Results Helpers

fileprivate extension ShareModularViewController {
    fileprivate func showLoadingView() {
        noResultsView.titleText = NSLocalizedString("Loading Sites...", comment: "Legend displayed when loading Sites")
        activityIndicatorView.startAnimating()
        noResultsView.isHidden = false
    }

    fileprivate func showEmptySitesIfNeeded() {
        guard hasSites else {
            return
        }

        noResultsView.titleText = NSLocalizedString("No Sites", comment: "Legend displayed when the user has no sites")
        noResultsView.isHidden = hasSites
    }
}

// MARK: - Backend Interaction

fileprivate extension ShareModularViewController {
    func reloadSitesIfNeeded() {
        guard !hasSites, let oauth2Token = oauth2Token else {
            showEmptySitesIfNeeded()
            return
        }

        let api = WordPressComRestApi(oAuthToken: oauth2Token, userAgent: nil)
        let remote = AccountServiceRemoteREST.init(wordPressComRestApi: api)
        remote?.getVisibleBlogs(success: { [weak self] blogs in
            DispatchQueue.main.async {
                self?.sites = (blogs as? [RemoteBlog]) ?? [RemoteBlog]()
                self?.activityIndicatorView.stopAnimating()
                self?.tableView.reloadData()
                self?.showEmptySitesIfNeeded()
            }
            }, failure: { [weak self] error in
                NSLog("Error retrieving blogs: \(String(describing: error))")
                DispatchQueue.main.async {
                    self?.sites = [RemoteBlog]()
                    self?.activityIndicatorView.stopAnimating()
                    self?.tableView.reloadData()
                    self?.showEmptySitesIfNeeded()
                }
        })

        showLoadingView()
    }

    func savePostToRemoteSite() {
        guard let _ = oauth2Token, let siteID = shareData.selectedSiteID else {
            fatalError("Need to have an oauth token and site ID selected.")
        }

        // Save the selected site for later use
        if let selectedSiteName = shareData.selectedSiteName {
            ShareExtensionService.configureShareExtensionLastUsedSiteID(siteID, lastUsedSiteName: selectedSiteName)
        }

        // Proceed uploading the actual post
        if shareData.sharedImageDict.values.count > 0 {
            uploadPostWithMedia(subject: shareData.title,
                                body: shareData.contentBody,
                                status: shareData.postStatus,
                                siteID: siteID,
                                requestEnqueued: {
                                    self.tracks.trackExtensionPosted(self.shareData.postStatus)
                                    self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
            })
        } else {
            let remotePost: RemotePost = {
                let post = RemotePost()
                post.siteID = NSNumber(value: siteID)
                post.status = shareData.postStatus
                post.title = shareData.title
                post.content = shareData.contentBody
                return post
            }()
            let uploadPostOpID = coreDataStack.savePostOperation(remotePost, groupIdentifier: groupIdentifier, with: .inProgress)
            uploadPost(forUploadOpWithObjectID: uploadPostOpID, requestEnqueued: {
                self.tracks.trackExtensionPosted(self.shareData.postStatus)
                self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
            })
        }
    }
}

// MARK: - Table Sections

fileprivate extension ShareModularViewController {
    fileprivate enum Section: Int {
        case modules       = 0
        case sites         = 1

        func headerText() -> String {
            switch self {
            case .modules:
                return String()
            case .sites:
                return String()
            }
        }

        func footerText() -> String {
            switch self {
            case .modules:
                // FIXME: Placeholder for summary module
                return String("Save XXX as a draft/published post on:")
            case .sites:
                return String()
            }
        }

        static let count: Int = {
            var max: Int = 0
            while let _ = Section(rawValue: max) { max += 1 }
            return max
        }()
    }
}

// MARK: - Constants

fileprivate extension ShareModularViewController {
    struct Constants {
        static let sitesReuseIdentifier    = String(describing: WPTableViewCell.self)
        static let defaultReuseIdentifier  = String(describing: ShareModularViewController.self)
        static let blogRowHeight           = CGFloat(74.0)
        static let defaultRowHeight        = CGFloat(44.0)
        static let emptyCount              = 0
    }
}

// MARK: - UITableView Cells

class ShareSitesTableViewCell: WPTableViewCell {

    // MARK: - Initializers
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    public required override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    }

    public convenience init() {
        self.init(style: .subtitle, reuseIdentifier: nil)
    }
}
