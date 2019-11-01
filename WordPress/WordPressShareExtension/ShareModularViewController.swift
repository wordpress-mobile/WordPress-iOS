import UIKit
import WordPressKit
import WordPressShared

class ShareModularViewController: ShareExtensionAbstractViewController {

    // MARK: - Private Properties

    fileprivate var isPublishingPost: Bool = false
    fileprivate var isFetchingCategories: Bool = false

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

    /// Activity indicator used when loading categories
    ///
    fileprivate lazy var categoryActivityIndicator = UIActivityIndicatorView(style: .gray)

    /// No results view
    ///
    fileprivate lazy var noResultsViewController = NoResultsViewController.controller()

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Initialize Interface
        setupNavigationBar()
        setupSitesTableView()
        setupModulesTableView()

        // Setup Autolayout
        view.setNeedsUpdateConstraints()

        // Load Data
        loadContentIfNeeded()
        setupPrimarySiteIfNeeded()
        setupCategoriesIfNeeded()
        reloadSitesIfNeeded()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        verifyAuthCredentials(onSuccess: nil)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        view.setNeedsUpdateConstraints()
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

                share.images.forEach({ extractedImage in
                    let imageURL = extractedImage.url
                    self.shareData.sharedImageDict.updateValue(UUID().uuidString, forKey: imageURL)

                    // Use the filename as the uploadID here.
                    if extractedImage.insertionState == .requiresInsertion {
                        self.shareData.contentBody = self.shareData.contentBody.stringByAppendingMediaURL(mediaURL: imageURL.absoluteString, uploadID: imageURL.lastPathComponent)
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

    fileprivate func setupCategoriesIfNeeded() {
        if shareData.allCategoriesForSelectedSite == nil {
            // Set to `true` so, on first load, the publish button is not enabled until the
            // catagories for the selected site are fully loaded
            isFetchingCategories = true
        }
        refreshModulesTable()
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
        modulesTableView.estimatedRowHeight = Constants.defaultRowHeight

        // Hide the separators, whenever the table is empty
        modulesTableView.tableFooterView = UIView()

        // Style!
        WPStyleGuide.configureColors(view: view, tableView: modulesTableView)
        WPStyleGuide.configureAutomaticHeightRows(for: modulesTableView)

        view.layoutIfNeeded()
    }

    fileprivate func setupSitesTableView() {
        // Register the cells
        sitesTableView.register(ShareSitesTableViewCell.self, forCellReuseIdentifier: Constants.sitesReuseIdentifier)
        sitesTableView.estimatedRowHeight = Constants.siteRowHeight

        // Hide the separators, whenever the table is empty
        sitesTableView.tableFooterView = UIView()

        // Refresh Control
        sitesTableView.refreshControl = refreshControl

        // Style!
        WPStyleGuide.configureColors(view: view, tableView: sitesTableView)
        WPStyleGuide.configureAutomaticHeightRows(for: sitesTableView)

        sitesTableView.separatorColor = .divider
    }

    override func updateViewConstraints() {
        super.updateViewConstraints()

        // Update the height constraint to match the number of modules * row height
        let modulesTableHeight = modulesTableView.rectForRow(at: IndexPath(row: 0, section: 0)).height
        modulesHeightConstraint.constant = (CGFloat(ModulesSection.count) * modulesTableHeight)
    }
}

// MARK: - Actions

extension ShareModularViewController {
    fileprivate func dismiss() {
        // In regular width size classes (iPad), action extensions are displayed
        // in a small modal, which looks strange when this VC is dismissed
        // before the main / presenting controller with its white background.
        // This workaround simply dismisses the modular VC along with the main extension VC.
        // See https://github.com/wordpress-mobile/WordPress-iOS/issues/8646 for more info.
        guard UIDevice.isPad() == false && originatingExtension != .saveToDraft else {
            dismissalCompletionBlock?()
            return
        }

        dismiss(animated: true, completion: dismissalCompletionBlock)
    }

    @objc func cancelWasPressed() {
        tracks.trackExtensionCancelled()
        cleanUpSharedContainerAndCache()
        dismiss()
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
        ShareExtensionAbstractViewController.clearCache()
        isFetchingCategories = true
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
        guard let siteID = shareData.selectedSiteID,
            let allSiteCategories = shareData.allCategoriesForSelectedSite,
            isFetchingCategories == false,
            isPublishingPost == false else {
            return
        }

        let categoryInfo = SiteCategories(siteID: siteID, allCategories: allSiteCategories, selectedCategories: shareData.userSelectedCategories, defaultCategoryID: shareData.defaultCategoryID)
        let categoriesPicker = ShareCategoriesPickerViewController(categoryInfo: categoryInfo)
        categoriesPicker.onValueChanged = { [weak self] categoryInfo in
            self?.shareData.allCategoriesForSelectedSite = categoryInfo.allCategories
            self?.shareData.userSelectedCategories = categoryInfo.selectedCategories
            self?.tracks.trackExtensionCategoriesSelected(self?.shareData.selectedCategoriesNameString ?? "")
            self?.refreshModulesTable()
        }
        tracks.trackExtensionCategoriesOpened()
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
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return tableView.estimatedRowHeight
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
            if isFetchingCategories {
                cell.isUserInteractionEnabled = false
                cell.accessoryType = .none
                cell.accessoryView = categoryActivityIndicator
                categoryActivityIndicator.startAnimating()
            } else {
                switch shareData.categoryCountForSelectedSite {
                case 0, 1:
                    categoryActivityIndicator.stopAnimating()
                    cell.accessoryView = nil
                    cell.accessoryType = .none
                    cell.isUserInteractionEnabled = false
                default:
                    categoryActivityIndicator.stopAnimating()
                    cell.accessoryView = nil
                    cell.accessoryType = .disclosureIndicator
                    cell.isUserInteractionEnabled = true
                }
            }

            cell.detailTextLabel?.text = shareData.selectedCategoriesNameString
            if (shareData.userSelectedCategories == nil || shareData.userSelectedCategories?.count == 0)
                && shareData.defaultCategoryID == Constants.unknownDefaultCategoryID {
                cell.detailTextLabel?.textColor = .neutral(.shade30)
            } else {
                cell.detailTextLabel?.textColor = .neutral(.shade70)
            }
        case ModulesSection.tags.rawValue:
            WPStyleGuide.Share.configureModuleCell(cell)
            cell.textLabel?.text = NSLocalizedString("Tags", comment: "Tags menu item in share extension.")
            cell.accessoryType = .disclosureIndicator
            cell.accessibilityLabel = "Tags"
            if let tags = shareData.tags, !tags.isEmpty {
                cell.detailTextLabel?.text = tags
                cell.detailTextLabel?.textColor = .neutral(.shade70)
            } else {
                cell.detailTextLabel?.text =  NSLocalizedString("Add tags", comment: "Placeholder text for tags module in share extension.")
                cell.detailTextLabel?.textColor = .neutral(.shade30)
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
            if shareData.categoryCountForSelectedSite > 1 {
                modulesTableView.flashRowAtIndexPath(indexPath,
                                                     scrollPosition: .none,
                                                     flashLength: Constants.flashAnimationLength,
                                                     completion: nil)
                showCategoriesPicker()
            }
            return
        case .tags:
            modulesTableView.flashRowAtIndexPath(indexPath,
                                                 scrollPosition: .none,
                                                 flashLength: Constants.flashAnimationLength,
                                                 completion: nil)
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

    func refreshModulesTable(categoriesLoaded: Bool = false) {
        if categoriesLoaded {
            self.isFetchingCategories = false
            self.updatePublishButtonStatus()
        }
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
            cell.imageView?.downloadBlavatar(from: siteIconUrl)
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
        sitesTableView.flashRowAtIndexPath(indexPath,
                                           scrollPosition: .none,
                                           flashLength: Constants.flashAnimationLength,
                                           completion: nil)

        guard let cell = sitesTableView.cellForRow(at: indexPath),
            let site = siteForRowAtIndexPath(indexPath),
            site.blogID.intValue != shareData.selectedSiteID else {
            return
        }

        clearAllSelectedSiteRows()
        cell.accessoryType = .checkmark
        shareData.selectedSiteID = site.blogID.intValue
        shareData.selectedSiteName = (site.name?.count)! > 0 ? site.name : URL(string: site.url)?.host
        fetchCategoriesForSelectedSite()
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
        configureAndDisplayStatus(title: StatusText.loadingTitle, accessoryView: NoResultsViewController.loadingAccessoryView())
    }

    func showPublishingView() {
        let title: String = {
            if self.originatingExtension == .share {
                return StatusText.publishingTitle
            }
            return StatusText.savingTitle
        }()

        updatePublishButtonStatus()
        configureAndDisplayStatus(title: title, accessoryView: NoResultsViewController.loadingAccessoryView())
    }

    func showCancellingView() {
        updatePublishButtonStatus()
        configureAndDisplayStatus(title: StatusText.cancellingTitle, accessoryView: NoResultsViewController.loadingAccessoryView())
    }

    func showEmptySitesIfNeeded() {
        updatePublishButtonStatus()
        noResultsViewController.removeFromView()
        refreshControl.endRefreshing()

        guard !hasSites else {
            return
        }

        configureAndDisplayStatus(title: StatusText.noSitesTitle)
    }

    func configureAndDisplayStatus(title: String, accessoryView: UIView? = nil) {
        noResultsViewController.removeFromView()
        noResultsViewController.configure(title: title, accessoryView: accessoryView)
        addChild(noResultsViewController)
        view.addSubview(noResultsViewController.view)
        noResultsViewController.didMove(toParent: self)
    }

    func updatePublishButtonStatus() {
        guard hasSites, shareData.selectedSiteID != nil, shareData.allCategoriesForSelectedSite != nil,
            isFetchingCategories == false, isPublishingPost == false else {
            publishButton.isEnabled = false
            return
        }
        publishButton.isEnabled = true
    }
}

// MARK: - Backend Interaction

fileprivate extension ShareModularViewController {
    func fetchCategoriesForSelectedSite() {
        guard let _ = oauth2Token, let siteID = shareData.selectedSiteID else {
            return
        }

        isFetchingCategories = true
        clearCategoriesAndRefreshModulesTable()
        if let cachedCategories = ShareExtensionAbstractViewController.cachedCategoriesForSite(NSNumber(value: siteID)), !cachedCategories.isEmpty {
            shareData.allCategoriesForSelectedSite = cachedCategories
            self.fetchDefaultCategoryForSelectedSite(onSuccess: { defaultCategoryID in
                self.loadDefaultCategory(defaultCategoryID, from: cachedCategories)
            }, onFailure: {
                self.loadDefaultCategory(Constants.unknownDefaultCategoryID, from: cachedCategories)
            })
        } else {
            let networkService = AppExtensionsService()
            networkService.fetchCategoriesForSite(siteID, onSuccess: { categories in
                ShareExtensionAbstractViewController.storeCategories(categories, for: NSNumber(value: siteID))
                self.shareData.allCategoriesForSelectedSite = categories
                self.fetchDefaultCategoryForSelectedSite(onSuccess: { defaultCategoryID in
                    self.loadDefaultCategory(defaultCategoryID, from: categories)
                }, onFailure: {
                    self.loadDefaultCategory(Constants.unknownDefaultCategoryID, from: categories)
                })
            }, onFailure: { error in
                let error = self.createErrorWithDescription("Could not successfully fetch categories for site: \(siteID). Error: \(String(describing: error))")
                self.tracks.trackExtensionError(error)
                self.loadDefaultCategory(Constants.unknownDefaultCategoryID, from: [])
            })
        }
    }

    func fetchDefaultCategoryForSelectedSite (onSuccess: @escaping (NSNumber) -> (), onFailure: @escaping () -> ()) {
        guard let _ = oauth2Token, let siteID = shareData.selectedSiteID else {
            return
        }

        if let cachedDefaultCategoryID = ShareExtensionAbstractViewController.cachedDefaultCategoryIDForSite(NSNumber(value: siteID)) {
            onSuccess(cachedDefaultCategoryID)
        } else {
            let networkService = AppExtensionsService()
            networkService.fetchSettingsForSite(siteID, onSuccess: { settings in
                guard let settings = settings, let defaultCategoryID = settings.defaultCategoryID else {
                    onFailure()
                    return
                }
                ShareExtensionAbstractViewController.storeDefaultCategoryID(defaultCategoryID, for: NSNumber(value: siteID))
                onSuccess(defaultCategoryID)
            }) { error in
                // The current user probably does not have permissions to access site settings OR needs to be VPNed.
                let error = self.createErrorWithDescription("Could not successfully fetch the settings for site: \(siteID). Error: \(String(describing: error))")
                self.tracks.trackExtensionError(error)
                onFailure()
            }
        }
    }

    func loadDefaultCategory(_ defaultCategoryID: NSNumber, from categories: [RemotePostCategory]) {
        if defaultCategoryID == Constants.unknownDefaultCategoryID {
            self.shareData.setDefaultCategory(categoryID: defaultCategoryID, categoryName: Constants.unknownDefaultCategoryName)
        } else {
            let defaultCategoryArray = categories.filter { $0.categoryID == defaultCategoryID }
            if !defaultCategoryArray.isEmpty, let defaultCategory = defaultCategoryArray.first {
                self.shareData.setDefaultCategory(categoryID: defaultCategoryID, categoryName: defaultCategory.name)
            }
        }
        self.refreshModulesTable(categoriesLoaded: true)
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
                self.fetchCategoriesForSelectedSite()
            }
        }) {
            DispatchQueue.main.async {
                self.sites = [RemoteBlog]()
                self.sitesTableView.reloadData()
                self.showEmptySitesIfNeeded()
                self.refreshModulesTable(categoriesLoaded: true)
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

        guard let _ = sites else {
            let error = createErrorWithDescription("Could not save post to remote site: remote sites list missing.")
            self.tracks.trackExtensionError(error)
            return
        }

        // Next, save the selected site for later use
        if let selectedSiteName = shareData.selectedSiteName {
            ShareExtensionService.configureShareExtensionLastUsedSiteID(siteID, lastUsedSiteName: selectedSiteName)
        }

        // Then proceed uploading the actual post
        let localImageURLs = [URL](shareData.sharedImageDict.keys)
        if localImageURLs.isEmpty {
            // No media. just a simple post
            saveAndUploadSimplePost(siteID: siteID)
        } else {
            // We have media, so let's upload it with the post
            uploadPostAndMedia(siteID: siteID, localImageURLs: localImageURLs)
        }
    }

    func prepareForPublishing() {
        // We are preemptively logging the Tracks posted event here because if handled in a completion handler,
        // there is a good chance iOS will invalidate that network call and the event is never received server-side.
        // See https://github.com/wordpress-mobile/WordPress-iOS/issues/9789 for more details.
        self.tracks.trackExtensionPosted(self.shareData.postStatus.rawValue)
        ////

        isPublishingPost = true
        sitesTableView.refreshControl = nil
        clearSiteDataAndRefreshSitesTable()
        showPublishingView()
        ShareExtensionAbstractViewController.clearCache()
    }

    func saveAndUploadSimplePost(siteID: Int) {
        let service = AppExtensionsService()

        prepareForPublishing()
        service.saveAndUploadPost(title: shareData.title,
                                         body: shareData.contentBody,
                                         tags: shareData.tags,
                                         categories: shareData.selectedCategoriesIDString,
                                         status: shareData.postStatus.rawValue,
                                         siteID: siteID,
                                         onComplete: {
                                            self.dismiss()
        }, onFailure: {
            let error = self.createErrorWithDescription("Failed to save and upload post with no media.")
            self.tracks.trackExtensionError(error)
            self.showRetryAlert()
        })
    }

    func uploadPostAndMedia(siteID: Int, localImageURLs: [URL]) {
        guard let siteList = sites else {
            return
        }

        let service = AppExtensionsService()
        let isAuthorizedToUploadFiles = service.isAuthorizedToUploadMedia(in: siteList, for: siteID)
        guard isAuthorizedToUploadFiles else {
            // Error: this role is unable to upload media.
            let error = self.createErrorWithDescription("This role is unable to upload media.")
            self.tracks.trackExtensionError(error)
            showPermissionsAlert()
            return
        }

        prepareForPublishing()
        service.uploadPostWithMedia(title: shareData.title,
                                    body: shareData.contentBody,
                                    tags: shareData.tags,
                                    categories: shareData.selectedCategoriesIDString,
                                    status: shareData.postStatus.rawValue,
                                    siteID: siteID,
                                    localMediaFileURLs: localImageURLs,
                                    requestEnqueued: {
                                        self.dismiss()
        }, onFailure: {
            let error = self.createErrorWithDescription("Failed to save and upload post with media.")
            self.tracks.trackExtensionError(error)
            self.showRetryAlert()
        })
    }

    func showRetryAlert() {
        let title: String = NSLocalizedString("Sharing Error", comment: "Share extension error dialog title.")
        let message: String = NSLocalizedString("Whoops, something went wrong while sharing. You can try again, maybe it was a glitch.", comment: "Share extension error dialog text.")
        let dismiss: String = NSLocalizedString("Dismiss", comment: "Share extension error dialog cancel button label.")
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)

        let acceptButtonText = NSLocalizedString("Try again", comment: "Share extension error dialog retry button label.")
        let acceptAction = UIAlertAction(title: acceptButtonText, style: .default) { (action) in
            self.savePostToRemoteSite()
        }
        alertController.addAction(acceptAction)

        let dismissButtonText = dismiss
        let dismissAction = UIAlertAction(title: dismissButtonText, style: .cancel) { (action) in
            self.showCancellingView()
            self.cleanUpSharedContainerAndCache()
            self.dismiss()
        }
        alertController.addAction(dismissAction)

        present(alertController, animated: true)
    }

    func showPermissionsAlert() {
        let title = NSLocalizedString("Sharing Error", comment: "Share extension error dialog title.")
        let message = NSLocalizedString("Your account does not have permission to upload media to this site. The Site Administrator can change these permissions.", comment: "Share extension error dialog text.")
        let dismiss = NSLocalizedString("Return to post", comment: "Share extension error dialog cancel button text")

        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)

        let dismissAction = UIAlertAction(title: dismiss, style: .cancel) { [weak self] (action) in
            self?.noResultsViewController.removeFromView()
        }
        alertController.addAction(dismissAction)

        present(alertController, animated: true)
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
        static let unknownDefaultCategoryID     = NSNumber(value: -1)
        static let unknownDefaultCategoryName   = NSLocalizedString("Default", comment: "Placeholder text displayed in the share extension's summary view. It lets the user know the default category will be used on their post.")
    }

    struct SummaryText {
        static let summaryPublishing    = NSLocalizedString("Publish post on:", comment: "Text displayed in the share extension's summary view. It describes the publish post action.")
        static let summaryDraftDefault  = NSLocalizedString("Save draft post on:", comment: "Text displayed in the share extension's summary view that describes the save draft post action.")
        static let summaryDraftSingular = NSLocalizedString("Save 1 photo as a draft post on:", comment: "Text displayed in the share extension's summary view that describes the action of saving a single photo in a draft post.")
        static let summaryDraftPlural   = NSLocalizedString("Save %ld photos as a draft post on:", comment: "Text displayed in the share extension's summary view that describes the action of saving multiple photos in a draft post.")
    }

    struct StatusText {
        static let loadingTitle = NSLocalizedString("Fetching sites...", comment: "A short message to inform the user data for their sites are being fetched.")
        static let publishingTitle = NSLocalizedString("Publishing post...", comment: "A short message that informs the user a post is being published to the server from the share extension.")
        static let savingTitle = NSLocalizedString("Saving post…", comment: "A short message that informs the user a draft post is being saved to the server from the share extension.")
        static let cancellingTitle = NSLocalizedString("Canceling...", comment: "A short message that informs the user the share extension is being canceled.")
        static let noSitesTitle = NSLocalizedString("No available sites", comment: "A short message that informs the user no sites could be loaded in the share extension.")
    }
}

// MARK: - UITableView Cells

class ShareSitesTableViewCell: WPTableViewCell {

    // MARK: - Initializers
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    public required override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    }

    public convenience init() {
        self.init(style: .subtitle, reuseIdentifier: nil)
    }
}
