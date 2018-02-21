import UIKit
import WordPressKit
import WordPressShared

class ShareModularViewController: ShareExtensionAbstractViewController {

    // MARK: - Private Properties

    fileprivate var isPublishingPost: Bool = false

    /// StackView container for the tables
    ///
    @IBOutlet fileprivate var verticalStackView: UIStackView!

    /// Height constraint for modules tableView
    ///
    @IBOutlet weak var modulesHeightConstraint: NSLayoutConstraint!

    /// TableView for modules
    ///
    @IBOutlet fileprivate var modulesTableView: UITableView!

    /// TableView for site list
    ///
    @IBOutlet fileprivate var sitesTableView: UITableView!

    /// Back Bar Button
    ///
    fileprivate lazy var backButton: UIBarButtonItem = {
        let backTitle = NSLocalizedString("Back", comment: "Back action on share extension site picker screen. Takes the user to the share extension editor screen.")
        let button = UIBarButtonItem(title: backTitle, style: .plain, target: self, action: #selector(backWasPressed))
        button.accessibilityIdentifier = "Back Button"
        return button
    }()

    /// Cancel Bar Button
    ///
    fileprivate lazy var cancelButton: UIBarButtonItem = {
        let cancelTitle = NSLocalizedString("Cancel", comment: "Cancel action on the app extension modules screen.")
        let button = UIBarButtonItem(title: cancelTitle, style: .plain, target: self, action: #selector(cancelWasPressed))
        button.accessibilityIdentifier = "Cancel Button"
        return button
    }()

    /// Publish Bar Button
    ///
    fileprivate lazy var publishButton: UIBarButtonItem = {
        let publishTitle: String
        if self.originatingExtension == .share {
            publishTitle = NSLocalizedString("Publish", comment: "Publish post action on share extension site picker screen.")
        } else {
            publishTitle = NSLocalizedString("Save", comment: "Save draft post action on share extension site picker screen.")
        }

        let button = UIBarButtonItem(title: publishTitle, style: .plain, target: self, action: #selector(publishWasPressed))
        if self.originatingExtension == .share {
            button.accessibilityIdentifier = "Publish Button"
        } else {
            button.accessibilityIdentifier = "Draft Button"
        }

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
    fileprivate lazy var loadingActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .gray)

    /// No results view
    ///
    @objc lazy var noResultsView: WPNoResultsView = {
        let title = NSLocalizedString("No available sites", comment: "A short message that informs the user no sites could be loaded in the share extension.")
        return WPNoResultsView(title: title, message: nil, accessoryView: nil, buttonTitle: nil)
    }()

    /// Loading view
    ///
    @objc lazy var loadingView: WPNoResultsView = {
        let title = NSLocalizedString("Fetching sites...", comment: "A short message to inform the user data for their sites are being fetched.")
        return WPNoResultsView(title: title, message: nil, accessoryView: loadingActivityIndicatorView, buttonTitle: nil)
    }()

    /// Publishing view
    ///
    @objc lazy var publishingView: WPNoResultsView = {
        let title: String
        if self.originatingExtension == .share {
            title = NSLocalizedString("Publishing post...", comment: "A short message that informs the user a post is being published to the server from the share extension.")
        } else {
            title = NSLocalizedString("Saving post...", comment: "A short message that informs the user a draft post is being saved to the server from the share extension.")
        }
        let activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        activityIndicatorView.startAnimating()
        return WPNoResultsView(title: title, message: nil, accessoryView: activityIndicatorView, buttonTitle: nil)
    }()

    /// Cancelling view
    ///
    @objc lazy var cancellingView: WPNoResultsView = {
        let title = NSLocalizedString("Cancelling...", comment: "A short message that informs the user the share extension is being cancelled.")
        let activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        activityIndicatorView.startAnimating()
        return WPNoResultsView(title: title, message: nil, accessoryView: activityIndicatorView, buttonTitle: nil)
    }()

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Initialize Interface
        setupNavigationBar()
        setupSitesTableView()
        setupModulesTableView()
        clearAllNoResultsViews()

        // Load Data
        loadContentIfNeeded()
        setupPrimarySiteIfNeeded()
        reloadSitesIfNeeded()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        verifyAuthCredentials(onSuccess: nil)
    }

    // MARK: - Setup Helpers

    fileprivate func loadContentIfNeeded() {
        // Only attempt loading data from the context when launched from the draft extension
        guard originatingExtension != .share, let extensionContext = context else {
            return
        }

        ShareExtractor(extensionContext: extensionContext)
            .loadShare { share in
                self.shareData.title = share.title
                self.shareData.contentBody = share.combinedContentHTML

                share.images.forEach({ image in
                    if let fileURL = self.saveImageToSharedContainer(image) {
                        self.shareData.sharedImageDict.updateValue(UUID().uuidString, forKey: fileURL)

                         // Use the filename as the uploadID here.
                        self.shareData.contentBody = self.shareData.contentBody.stringByAppendingMediaURL(mediaURL: fileURL.absoluteString, uploadID: fileURL.lastPathComponent)
                    }
                })

                // Clear out the extension context after loading it once. We don't need it anymore.
                self.context = nil
                self.refreshModulesTable()
        }
    }

    fileprivate func setupPrimarySiteIfNeeded() {
        // If the selected site ID is empty, prefill the selected site with what was already used
        guard shareData.selectedSiteID == nil else {
            return
        }

        shareData.selectedSiteID = primarySiteID
        shareData.selectedSiteName = primarySiteName
    }

    fileprivate func setupNavigationBar() {
        self.navigationItem.hidesBackButton = true
        if originatingExtension == .share {
            navigationItem.leftBarButtonItem = backButton
        } else {
            navigationItem.leftBarButtonItem = cancelButton
        }
        navigationItem.rightBarButtonItem = publishButton
    }

    fileprivate func setupModulesTableView() {
        // Register the cells
        modulesTableView.register(WPTableViewCellValue1.self, forCellReuseIdentifier: Constants.modulesReuseIdentifier)

        // Hide the separators, whenever the table is empty
        modulesTableView.tableFooterView = UIView()

        // Style!
        WPStyleGuide.configureColors(for: view, andTableView: modulesTableView)
        WPStyleGuide.configureAutomaticHeightRows(for: modulesTableView)

        // Update the height constraint to match the number of modules * default row height
        modulesHeightConstraint.constant = (CGFloat(ModulesSection.count) * Constants.defaultRowHeight)
        view.layoutIfNeeded()
    }

    fileprivate func setupSitesTableView() {
        // Register the cells
        sitesTableView.register(ShareSitesTableViewCell.self, forCellReuseIdentifier: Constants.sitesReuseIdentifier)

        // Hide the separators, whenever the table is empty
        sitesTableView.tableFooterView = UIView()

        // Refresh Control
        sitesTableView.refreshControl = refreshControl

        // Style!
        WPStyleGuide.configureColors(for: view, andTableView: sitesTableView)
        WPStyleGuide.configureAutomaticHeightRows(for: sitesTableView)
    }
}

// MARK: - Actions

extension ShareModularViewController {
    @objc func cancelWasPressed() {
        tracks.trackExtensionCancelled()
        cleanUpSharedContainer()
        dismiss(animated: true, completion: self.dismissalCompletionBlock)
    }

    @objc func backWasPressed() {
        if let editor = navigationController?.previousViewController() as? ShareExtensionEditorViewController {
            editor.sites = sites
            editor.shareData = shareData
            editor.originatingExtension = originatingExtension
        }
        _ = navigationController?.popViewController(animated: true)
    }

    @objc func publishWasPressed() {
        savePostToRemoteSite()
    }

    @objc func pullToRefresh(sender: UIRefreshControl) {
        clearCategoriesAndRefreshModulesTable()
        clearSiteDataAndRefreshSitesTable()
        reloadSitesIfNeeded()
    }

    func showTagsPicker() {
        guard let siteID = shareData.selectedSiteID, isPublishingPost == false else {
            return
        }

        let tagsPicker = ShareTagsPickerViewController(siteID: siteID, tags: shareData.tags)
        tagsPicker.onValueChanged = { [weak self] tagString in
            if self?.shareData.tags != tagString {
                self?.tracks.trackExtensionTagsSelected(tagString)
                self?.shareData.tags = tagString
                self?.refreshModulesTable()
            }
        }

        tracks.trackExtensionTagsOpened()
        navigationController?.pushViewController(tagsPicker, animated: true)
    }

    func showCategoriesPicker() {
        guard let siteID = shareData.selectedSiteID, isPublishingPost == false else {
            return
        }

        // FIXME: Load the categories from shareData, handle onChanged, and setup analytics
        let categoriesPicker = ShareCategoriesPickerViewController(siteID: siteID, categories: nil)
        navigationController?.pushViewController(categoriesPicker, animated: true)
    }
}

// MARK: - UITableView DataSource Conformance

extension ShareModularViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        if tableView == modulesTableView {
            return ModulesSection.count
        } else {
            // Only 1 section in the sites table
            return 1
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == modulesTableView {
            switch ModulesSection(rawValue: section)! {
            case .categories:
                return 1
            case .tags:
                return 1
            case .summary:
                return 1
            }
        } else {
            return rowCountForSites
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == modulesTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: Constants.modulesReuseIdentifier)!
            configureModulesCell(cell, indexPath: indexPath)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: Constants.sitesReuseIdentifier)!
            configureSiteCell(cell, indexPath: indexPath)
            return cell
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView == modulesTableView {
            return Constants.defaultRowHeight
        } else {
            return Constants.siteRowHeight
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if tableView == modulesTableView {
            if isModulesSectionEmpty(section) {
                // Hide when the section is empty!
                return nil
            }
            let theSection = ModulesSection(rawValue: section)!
            return theSection.headerText()
        } else {
            // No header for sites table
            return nil
        }
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        WPStyleGuide.configureTableViewSectionHeader(view)
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if tableView == modulesTableView {
            if isModulesSectionEmpty(section) {
                // Hide when the section is empty!
                return nil
            }
            let theSection = ModulesSection(rawValue: section)!
            return theSection.footerText()
        } else {
            // No footer for sites table
            return nil
        }
    }

    func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        WPStyleGuide.configureTableViewSectionFooter(view)
    }
}

// MARK: - UITableView Delegate Conformance

extension ShareModularViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == sitesTableView {
            selectedSitesTableRowAt(indexPath)
        } else {
            selectedModulesTableRowAt(indexPath)
        }
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        guard tableView == sitesTableView else {
            return
        }
        guard let cell = tableView.cellForRow(at: indexPath) else {
            return
        }
        cell.accessoryType = .none
    }
}

// MARK: - Modules UITableView Helpers

fileprivate extension ShareModularViewController {
    func configureModulesCell(_ cell: UITableViewCell, indexPath: IndexPath) {
        switch indexPath.section {
        case ModulesSection.categories.rawValue:
            WPStyleGuide.Share.configureModuleCell(cell)
            cell.textLabel?.text = NSLocalizedString("Category", comment: "Category menu item in share extension.")
            cell.accessibilityLabel = "Category"
            if shareData.totalCategoryCount > 1 {
                cell.accessoryType = .disclosureIndicator
                cell.isUserInteractionEnabled = true
            } else {
                cell.accessoryType = .none
                cell.isUserInteractionEnabled = false
            }

            if !shareData.selectedCategoriesString.isEmpty {
                cell.detailTextLabel?.text = shareData.selectedCategoriesString
                cell.detailTextLabel?.textColor = WPStyleGuide.darkGrey()
            } else {
                cell.detailTextLabel?.text =  ""
                cell.detailTextLabel?.textColor = WPStyleGuide.grey()
            }
        case ModulesSection.tags.rawValue:
            WPStyleGuide.Share.configureModuleCell(cell)
            cell.textLabel?.text = NSLocalizedString("Tags", comment: "Tags menu item in share extension.")
            cell.accessoryType = .disclosureIndicator
            cell.accessibilityLabel = "Tags"
            if let tags = shareData.tags, !tags.isEmpty {
                cell.detailTextLabel?.text = tags
                cell.detailTextLabel?.textColor = WPStyleGuide.darkGrey()
            } else {
                cell.detailTextLabel?.text =  NSLocalizedString("Add tags", comment: "Placeholder text for tags module in share extension.")
                cell.detailTextLabel?.textColor = WPStyleGuide.grey()
            }
        default:
            // Summary section
            cell.textLabel?.text            = summaryRowText()
            cell.textLabel?.textAlignment   = .natural
            cell.accessoryType              = .none
            cell.isUserInteractionEnabled   = false
            WPStyleGuide.Share.configureTableViewSummaryCell(cell)
        }
    }

    func isModulesSectionEmpty(_ sectionIndex: Int) -> Bool {
        switch ModulesSection(rawValue: sectionIndex)! {
        case .categories:
            return false
        case .tags:
            return false
        case .summary:
            return false
        }
    }

    func selectedModulesTableRowAt(_ indexPath: IndexPath) {
        switch ModulesSection(rawValue: indexPath.section)! {
        case .categories:
            if shareData.totalCategoryCount > 1 {
                modulesTableView.flashRowAtIndexPath(indexPath, scrollPosition: .none, flashLength: Constants.flashAnimationLength, completion: nil)
                showCategoriesPicker()
            }
            return
        case .tags:
            modulesTableView.flashRowAtIndexPath(indexPath, scrollPosition: .none, flashLength: Constants.flashAnimationLength, completion: nil)
            showTagsPicker()
            return
        case .summary:
            return
        }
    }

    func summaryRowText() -> String {
        if originatingExtension == .share {
            return SummaryText.summaryPublishing
        } else if originatingExtension == .saveToDraft && shareData.sharedImageDict.isEmpty {
            return SummaryText.summaryDraftDefault
        } else if originatingExtension == .saveToDraft && !shareData.sharedImageDict.isEmpty {
            return ShareNoticeText.pluralize(shareData.sharedImageDict.count,
                                             singular: SummaryText.summaryDraftSingular,
                                             plural: SummaryText.summaryDraftPlural)
        } else {
            return String()
        }
    }

    func refreshModulesTable() {
        modulesTableView.reloadData()
    }

    func clearCategoriesAndRefreshModulesTable() {
        shareData.clearCategoryInfo()
        refreshModulesTable()
    }
}

// MARK: - Sites UITableView Helpers

fileprivate extension ShareModularViewController {
    func configureSiteCell(_ cell: UITableViewCell, indexPath: IndexPath) {
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

    var rowCountForSites: Int {
        return sites?.count ?? 0
    }

    func selectedSitesTableRowAt(_ indexPath: IndexPath) {
        guard let cell = sitesTableView.cellForRow(at: indexPath), let site = siteForRowAtIndexPath(indexPath) else {
            return
        }

        clearAllSelectedSiteRows()
        cell.accessoryType = .checkmark
        sitesTableView.flashRowAtIndexPath(indexPath, scrollPosition: .none, flashLength: Constants.flashAnimationLength, completion: nil)
        shareData.selectedSiteID = site.blogID.intValue
        shareData.selectedSiteName = (site.name?.count)! > 0 ? site.name : URL(string: site.url)?.host
        fetchDefaultCategoryForSelectedSite()
        updatePublishButtonStatus()
        self.refreshModulesTable()
    }

    func siteForRowAtIndexPath(_ indexPath: IndexPath) -> RemoteBlog? {
        guard let sites = sites else {
            return nil
        }
        return sites[indexPath.row]
    }

    func clearAllSelectedSiteRows() {
        for row in 0 ..< rowCountForSites {
            let cell = sitesTableView.cellForRow(at: IndexPath(row: row, section: 0))
            cell?.accessoryType = .none
        }
    }

    func clearSiteDataAndRefreshSitesTable() {
        sites = nil
        sitesTableView.reloadData()
    }
}

// MARK: - No Results Helpers

fileprivate extension ShareModularViewController {

    func showLoadingView() {
        updatePublishButtonStatus()
        clearAllNoResultsViews()
        if refreshControl.isRefreshing {
            loadingActivityIndicatorView.alpha = Constants.zeroAlpha
        } else {
            loadingActivityIndicatorView.alpha = Constants.fullAlpha
            loadingActivityIndicatorView.startAnimating()
        }
        view.addSubview(loadingView)
        loadingView.centerInSuperview()
    }

    func showPublishingView() {
        updatePublishButtonStatus()
        clearAllNoResultsViews()
        view.addSubview(publishingView)
        publishingView.centerInSuperview()
    }

    func showCancellingView() {
        updatePublishButtonStatus()
        clearAllNoResultsViews()
        view.addSubview(cancellingView)
        cancellingView.centerInSuperview()
    }

    func showEmptySitesIfNeeded() {
        updatePublishButtonStatus()
        clearAllNoResultsViews()
        refreshControl.endRefreshing()
        loadingActivityIndicatorView.stopAnimating()

        guard !hasSites else {
            return
        }

        view.addSubview(noResultsView)
        noResultsView.centerInSuperview()
    }

    func clearAllNoResultsViews() {
        noResultsView.removeFromSuperview()
        loadingView.removeFromSuperview()
        publishingView.removeFromSuperview()
        cancellingView.removeFromSuperview()
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
    func fetchDefaultCategoryForSelectedSite() {
        guard let _ = oauth2Token, let siteID = shareData.selectedSiteID else {
            return
        }

        clearCategoriesAndRefreshModulesTable()
        let networkService = AppExtensionsService()
        networkService.fetchSettingsForSite(siteID, onSuccess: { settings in
            guard let settings = settings,
                let defaultCategoryID = settings.defaultCategoryID else {
                return
            }

            networkService.fetchCategoriesForSite(siteID, onSuccess: { categories in
                let defaultCategoryArray = categories.filter { $0.categoryID == defaultCategoryID }
                guard !defaultCategoryArray.isEmpty, let defaultCategoryName = defaultCategoryArray.first?.name else {
                    return
                }

                self.shareData.totalCategoryCount = categories.count
                self.shareData.setDefaultCategory(categoryID: defaultCategoryID, categoryName: defaultCategoryName)
                DispatchQueue.main.async {
                    self.refreshModulesTable()
                }
            }, onFailure: { error in
                let error = self.createErrorWithDescription("Could not successfully fetch the default category for site: \(siteID)")
                self.tracks.trackExtensionError(error)
            })
        }) { _ in
            let error = self.createErrorWithDescription("Could not successfully fetch the settings for site: \(siteID)")
            self.tracks.trackExtensionError(error)
        }
    }

    func reloadSitesIfNeeded() {
        guard !hasSites else {
            sitesTableView.reloadData()
            showEmptySitesIfNeeded()
            return
        }
        let networkService = AppExtensionsService()
        networkService.fetchSites(onSuccess: { blogs in
            DispatchQueue.main.async {
                self.sites = (blogs) ?? [RemoteBlog]()
                self.sitesTableView.reloadData()
                self.showEmptySitesIfNeeded()
                self.fetchDefaultCategoryForSelectedSite()
            }
        }) {
            DispatchQueue.main.async {
                self.sites = [RemoteBlog]()
                self.sitesTableView.reloadData()
                self.showEmptySitesIfNeeded()
            }
        }

        showLoadingView()
    }

    func savePostToRemoteSite() {
        guard let _ = oauth2Token, let siteID = shareData.selectedSiteID else {
            let error = createErrorWithDescription("Could not save post to remote site: oauth token or site ID is nil.")
            self.tracks.trackExtensionError(error)
            return
        }

        isPublishingPost = true
        sitesTableView.refreshControl = nil
        clearSiteDataAndRefreshSitesTable()
        showPublishingView()

        // Next, save the selected site for later use
        if let selectedSiteName = shareData.selectedSiteName {
            ShareExtensionService.configureShareExtensionLastUsedSiteID(siteID, lastUsedSiteName: selectedSiteName)
        }

        // Then proceed uploading the actual post
        let networkService = AppExtensionsService()
        let localImageURLs = [URL](shareData.sharedImageDict.keys)
        if !localImageURLs.isEmpty {
            // We have media, so let's upload it with the post
            networkService.uploadPostWithMedia(title: shareData.title,
                                               body: shareData.contentBody,
                                               tags: shareData.tags,
                                               status: shareData.postStatus.rawValue,
                                               siteID: siteID,
                                               localMediaFileURLs: localImageURLs,
                                               requestEnqueued: {
                                                self.tracks.trackExtensionPosted(self.shareData.postStatus.rawValue)
                                                self.dismiss(animated: true, completion: self.dismissalCompletionBlock)
            }, onFailure: {
                let error = self.createErrorWithDescription("Failed to save and upload post with media.")
                self.tracks.trackExtensionError(error)
                self.showAlert()
            })
        } else {
            // No media. just a simple post
            networkService.saveAndUploadPost(title: shareData.title,
                                             body: shareData.contentBody,
                                             tags: shareData.tags,
                                             status: shareData.postStatus.rawValue,
                                             siteID: siteID,
                                             onComplete: {
                                                self.tracks.trackExtensionPosted(self.shareData.postStatus.rawValue)
                                                self.dismiss(animated: true, completion: self.dismissalCompletionBlock)
            }, onFailure: {
                let error = self.createErrorWithDescription("Failed to save and upload post with no media.")
                self.tracks.trackExtensionError(error)
                self.showAlert()
            })
        }
    }

    func showAlert() {
        let title = NSLocalizedString("Sharing Error", comment: "Share extension error dialog title.")
        let message = NSLocalizedString("Whoops, something went wrong while sharing. You can try again, maybe it was a glitch.", comment: "Share extension error dialog text.")
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)

        let acceptButtonText = NSLocalizedString("Try again", comment: "Share extension error dialog retry button label.")
        let acceptAction = UIAlertAction(title: acceptButtonText, style: .default) { (action) in
            self.savePostToRemoteSite()
        }
        alertController.addAction(acceptAction)

        let dismissButtonText = NSLocalizedString("Nevermind", comment: "Share extension error dialog cancel button label.")
        let dismissAction = UIAlertAction(title: dismissButtonText, style: .cancel) { (action) in
            self.showCancellingView()
            self.cleanUpSharedContainer()
            self.dismiss(animated: true, completion: self.dismissalCompletionBlock)
        }
        alertController.addAction(dismissAction)

        present(alertController, animated: true, completion: nil)
    }
}

// MARK: - Table Sections

fileprivate extension ShareModularViewController {
    enum ModulesSection: Int {
        case categories
        case tags
        case summary

        func headerText() -> String {
            switch self {
            case .categories:
                return String()
            case .tags:
                return String()
            case .summary:
                return String()
            }
        }

        func footerText() -> String {
            switch self {
            case .categories:
                return String()
            case .tags:
                return String()
            case .summary:
                return String()
            }
        }

        static let count: Int = {
            var max: Int = 0
            while let _ = ModulesSection(rawValue: max) { max += 1 }
            return max
        }()
    }
}

// MARK: - Constants

fileprivate extension ShareModularViewController {
    struct Constants {
        static let sitesReuseIdentifier    = String(describing: ShareSitesTableViewCell.self)
        static let modulesReuseIdentifier  = String(describing: ShareModularViewController.self)
        static let siteRowHeight           = CGFloat(74.0)
        static let defaultRowHeight        = CGFloat(44.0)
        static let emptyCount              = 0
        static let flashAnimationLength    = 0.2
    }

    struct SummaryText {
        static let summaryPublishing    = NSLocalizedString("Publish post on:", comment: "Text displayed in the share extension's summary view. It describes the publish post action.")
        static let summaryDraftDefault  = NSLocalizedString("Save draft post on:", comment: "Text displayed in the share extension's summary view that describes the save draft post action.")
        static let summaryDraftSingular = NSLocalizedString("Save 1 photo as a draft post on:", comment: "Text displayed in the share extension's summary view that describes the action of saving a single photo in a draft post.")
        static let summaryDraftPlural   = NSLocalizedString("Save %ld photos as a draft post on:", comment: "Text displayed in the share extension's summary view that describes the action of saving multiple photos in a draft post.")
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
