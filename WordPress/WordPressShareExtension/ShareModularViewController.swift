import UIKit
import WordPressShared
import WordPressKit

class ShareModularViewController: ShareExtensionAbstractViewController {

    // MARK: - Private Properties

    fileprivate var isPublishingPost: Bool = false

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

    /// Refresh Control
    ///
    fileprivate lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(pullToRefresh(sender:)), for: .valueChanged)
        return refreshControl
    }()

    /// Activity spinner used when loading sites
    ///
    fileprivate lazy var activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .gray)

    /// No results (and loading) view
    ///
    fileprivate lazy var noResultsView: WPNoResultsView = {
        $0.accessoryView = activityIndicatorView
        return $0
    }(WPNoResultsView())

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Initialize Interface
        setupNavigationBar()
        setupTableView()
        setupNoResultsView()

        // Load Data
        setupCachedDataIfNeeded()
        reloadSitesIfNeeded()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    // MARK: - Setup Helpers

    fileprivate func setupCachedDataIfNeeded() {
        // If the selected site ID is empty, prefill the selected site with what was already used
        guard shareData.selectedSiteID == nil else {
            return
        }

        shareData.selectedSiteID = historicalSelectedSiteID
        shareData.selectedSiteName = historicalSelectedSiteName
    }

    fileprivate func setupNavigationBar() {
        self.navigationItem.hidesBackButton = true
        navigationItem.leftBarButtonItem = backButton
        navigationItem.rightBarButtonItem = publishButton
    }

    fileprivate func setupTableView() {
        // Register the cells
        tableView.register(ShareSitesTableViewCell.self, forCellReuseIdentifier: Constants.sitesReuseIdentifier)
        tableView.register(WPTableViewCell.self, forCellReuseIdentifier: Constants.defaultReuseIdentifier)

        // Hide the separators, whenever the table is empty
        tableView.tableFooterView = UIView()

        // Refresh Control
        tableView.refreshControl = refreshControl

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
        savePostToRemoteSite()
    }

    @objc func pullToRefresh(sender: UIRefreshControl) {
        clearSiteDataAndReloadTable()
        reloadSitesIfNeeded()
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
        case .summary:
            return 1
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
        return isSitesSection ? Constants.siteRowHeight : Constants.defaultRowHeight
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
        clearAllSelectedSites()
        cell.accessoryType = .checkmark
        tableView.flashRowAtIndexPath(indexPath, scrollPosition: .none, flashLength: Constants.flashAnimationLength, completion: nil)
        shareData.selectedSiteID = site.blogID.intValue
        shareData.selectedSiteName = (site.name?.count)! > 0 ? site.name : URL(string: site.url)?.host
        updatePublishButtonStatus()
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
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
        case .summary:
            return Constants.defaultReuseIdentifier
        }
    }

    func configureCell(_ cell: UITableViewCell, indexPath: IndexPath) {
        if isSummaryRow(indexPath) {
            cell.textLabel?.text            = summaryRowText()
            cell.textLabel?.textAlignment   = .natural
            cell.accessoryType              = .none
            WPStyleGuide.Share.configureTableViewSummaryCell(cell)
        } else {
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

    func clearAllSelectedSites() {
        for row in 0 ..< rowCountForSitesSection {
            let cell = tableView.cellForRow(at: IndexPath(row: row, section: Section.sites.rawValue))
            cell?.accessoryType = .none
        }
    }

    func clearSiteDataAndReloadTable() {
        sites = nil
        tableView.reloadData()
    }

    func isSummaryRow(_ path: IndexPath) -> Bool {
        return path.section == Section.summary.rawValue
    }

    func summaryRowText() -> String {
        return NSLocalizedString("Publish post on:", comment: "Text displayed in the share extension's summary view. It describes the publish post action.")
    }
}

// MARK: - No Results Helpers

fileprivate extension ShareModularViewController {
    func showLoadingView() {
        updatePublishButtonStatus()
        if isPublishingPost {
            noResultsView.titleText = NSLocalizedString("Publishing Post...", comment: "Placeholder text displayed in the share extention when publishing a post to the server.")
        } else {
            noResultsView.titleText = NSLocalizedString("Loading Sites...", comment: "Placeholder text displayed in the share extention when loading sites from the server.")
        }

        if refreshControl.isRefreshing {
            activityIndicatorView.alpha = Constants.zeroAlpha
        } else {
            activityIndicatorView.alpha = Constants.fullAlpha
            activityIndicatorView.startAnimating()
        }

        noResultsView.isHidden = false
    }

    func showEmptySitesIfNeeded() {
        updatePublishButtonStatus()
        refreshControl.endRefreshing()
        activityIndicatorView.stopAnimating()

        guard !hasSites else {
            noResultsView.isHidden = true
            return
        }

        noResultsView.titleText = NSLocalizedString("No Available Sites", comment: "Placeholder text displayed in the share extention when no sites could be loaded for the user.")
        activityIndicatorView.alpha = Constants.zeroAlpha
        noResultsView.isHidden = false
    }

    func updatePublishButtonStatus() {
        guard hasSites, shareData.selectedSiteID != nil, isPublishingPost == false else {
            publishButton.isEnabled = false
            return
        }

        publishButton.isEnabled = true
    }
}

// MARK: - Backend Interaction

fileprivate extension ShareModularViewController {
    func reloadSitesIfNeeded() {
        guard !hasSites, let oauth2Token = oauth2Token else {
            tableView.reloadData()
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

    func savePostToRemoteSite() {
        guard let _ = oauth2Token, let siteID = shareData.selectedSiteID else {
            fatalError("Need to have an oauth token and site ID selected.")
        }

        isPublishingPost = true
        tableView.refreshControl = nil
        clearSiteDataAndReloadTable()
        showLoadingView()

        // Next, save the selected site for later use
        if let selectedSiteName = shareData.selectedSiteName {
            ShareExtensionService.configureShareExtensionLastUsedSiteID(siteID, lastUsedSiteName: selectedSiteName)
        }

        // Then proceed uploading the actual post
        if shareData.sharedImageDict.values.count > 0 {
            uploadPostWithMedia(subject: shareData.title,
                                body: shareData.contentBody,
                                status: shareData.postStatus,
                                siteID: siteID,
                                requestEnqueued: {
                                    self.tracks.trackExtensionPosted(self.shareData.postStatus)
                                    self.dismiss(animated: true, completion: self.dismissalCompletionBlock)
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
                self.dismiss(animated: true, completion: self.dismissalCompletionBlock)
            })
        }
    }
}

// MARK: - Table Sections

fileprivate extension ShareModularViewController {
        enum Section: Int {
        case summary       = 0
        case sites         = 1

        func headerText() -> String {
            switch self {
            case .summary:
                return String()
            case .sites:
                return String()
            }
        }

        func footerText() -> String {
            switch self {
            case .summary:
                return String()
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
        static let sitesReuseIdentifier    = String(describing: ShareSitesTableViewCell.self)
        static let defaultReuseIdentifier  = String(describing: ShareModularViewController.self)
        static let siteRowHeight           = CGFloat(74.0)
        static let defaultRowHeight        = CGFloat(44.0)
        static let emptyCount              = 0
        static let flashAnimationLength    = 0.2
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
