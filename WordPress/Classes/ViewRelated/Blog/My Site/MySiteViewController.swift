import WordPressAuthenticator
import UIKit
import SwiftUI

class MySiteViewController: UIViewController, UIScrollViewDelegate, NoSitesViewDelegate {

    enum Section: Int, CaseIterable {
        case dashboard
        case siteMenu

        var title: String {
            switch self {
            case .dashboard:
                return NSLocalizedString("Home", comment: "Title for dashboard view on the My Site screen")
            case .siteMenu:
                return NSLocalizedString("Menu", comment: "Title for the site menu view on the My Site screen")
            }
        }

        var analyticsDescription: String {
            switch self {
            case .dashboard:
                return "dashboard"
            case .siteMenu:
                return "site_menu"
            }
        }
    }

    private var isShowingDashboard: Bool {
        return segmentedControl.selectedSegmentIndex == Section.dashboard.rawValue
    }

    private var currentSection: Section? {
        Section(rawValue: segmentedControl.selectedSegmentIndex)
    }

    @objc
    private(set) lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.refreshControl = refreshControl
        scrollView.delegate = self
        return scrollView
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = 0
        return stackView
    }()

    private lazy var segmentedControlContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var segmentedControl: UISegmentedControl = {
        let segmentedControl = UISegmentedControl(items: Section.allCases.map { $0.title })
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.addTarget(self, action: #selector(segmentedControlValueChangedByUser), for: .valueChanged)
        segmentedControl.selectedSegmentIndex = Section.siteMenu.rawValue
        return segmentedControl
    }()

    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(pulledToRefresh), for: .valueChanged)
        return refreshControl
    }()

    private lazy var siteMenuSpotlightView: UIView = {
        let spotlightView = QuickStartSpotlightView()
        spotlightView.translatesAutoresizingMaskIntoConstraints = false
        spotlightView.isHidden = true
        return spotlightView
    }()

    /// Whether or not to show the spotlight animation to illustrate tapping the site menu.
    var siteMenuSpotlightIsShown: Bool = false {
        didSet {
            siteMenuSpotlightView.isHidden = !siteMenuSpotlightIsShown
        }
    }

    /// A boolean indicating whether a site creation or adding self-hosted site flow has been initiated but not yet displayed.
    var willDisplayPostSignupFlow: Bool = false

    private var createButtonCoordinator: CreateButtonCoordinator?
    private var complianceCoordinator: CompliancePopoverCoordinator?

    private let meScenePresenter: ScenePresenter
    private let blogService: BlogService
    private(set) var mySiteSettings: MySiteSettings

    // MARK: - Initializers

    init(meScenePresenter: ScenePresenter, blogService: BlogService? = nil, mySiteSettings: MySiteSettings = MySiteSettings()) {
        self.meScenePresenter = meScenePresenter
        self.blogService = blogService ?? BlogService(coreDataStack: ContextManager.shared)
        self.mySiteSettings = mySiteSettings

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("Initializer not implemented!")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Blog

    /// Convenience setter and getter for the blog.  This calculated property takes care of showing the appropriate VC, depending
    /// on whether there's a blog to show or not.
    ///
    var blog: Blog? {
        set {
            guard let newBlog = newValue else {
                showBlogDetailsForMainBlogOrNoSites()
                return
            }

            showBlogDetails(for: newBlog)
            showSitePicker(for: newBlog)
            updateNavigationTitle(for: newBlog)
            createFABIfNeeded()
            updateSegmentedControl(for: newBlog, switchTabsIfNeeded: true)
            fetchPrompt(for: newBlog)
        }

        get {
            return sitePickerViewController?.blog
        }
    }

    private(set) weak var sitePickerViewController: SitePickerViewController?
    private(set) weak var blogDetailsViewController: BlogDetailsViewController? {
        didSet {
            blogDetailsViewController?.presentationDelegate = self
        }
    }
    private weak var blogDashboardViewController: BlogDashboardViewController?

    /// When we display a no sites view, we'll do so in a scrollview so that
    /// we can allow pull to refresh to sync the user's list of sites.
    ///
    private var noSitesScrollView: UIScrollView?
    private var noSitesRefreshControl: UIRefreshControl?
    private lazy var noSitesViewController: UIHostingController = {
        let viewModel = NoSitesViewModel(
            appUIType: JetpackFeaturesRemovalCoordinator.currentAppUIType,
            account: defaultAccount()
        )
        let configuration = AddNewSiteConfiguration(
            canCreateWPComSite: defaultAccount() != nil,
            canAddSelfHostedSite: AppConfiguration.showAddSelfHostedSiteButton,
            launchSiteCreation: self.launchSiteCreationFromNoSites,
            launchLoginForSelfHostedSite: self.launchLoginForSelfHostedSite
        )
        let noSiteView = NoSitesView(
            viewModel: viewModel,
            addNewSiteConfiguration: configuration
        )
        return UIHostingController(rootView: noSiteView)
    }()

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
        setupConstraints()
        setupNavigationItem()
        subscribeToPostSignupNotifications()
        subscribeToModelChanges()
        subscribeToContentSizeCategory()
        subscribeToPostPublished()
        startObservingQuickStart()
        startObservingOnboardingPrompt()
        subscribeToWillEnterForeground()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if blog == nil {
            showBlogDetailsForMainBlogOrNoSites()
        }

        setupNavBarAppearance()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        resetNavBarAppearance()
        createButtonCoordinator?.hideCreateButton()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        displayJetpackInstallOverlayIfNeeded()

        displayOverlayIfNeeded()

        workaroundLargeTitleCollapseBug()

        if AppConfiguration.showsWhatIsNew {
            RootViewCoordinator.shared.presentWhatIsNew(on: self)
        }

        FancyAlertViewController.presentCustomAppIconUpgradeAlertIfNecessary(from: self)

        trackNoSitesVisibleIfNeeded()

        setupNavBarAppearance()

        createFABIfNeeded()
        fetchPrompt(for: blog)

        complianceCoordinator = CompliancePopoverCoordinator()
        complianceCoordinator?.presentIfNeeded(on: self)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        createButtonCoordinator?.presentingTraitCollectionWillChange(traitCollection, newTraitCollection: traitCollection)
    }

    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        createButtonCoordinator?.presentingTraitCollectionWillChange(traitCollection, newTraitCollection: newCollection)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        guard let previousTraitCollection = previousTraitCollection,
            let blog = blog else {
            return
        }

        // When switching between compact and regular width, we need to make sure to select the
        // appropriate tab. This ensures the following:
        //
        // 1. Compact -> Regular: If the dashboard tab is selected, switch to the site menu tab
        // so that the site menu is shown in the left pane of the split vc
        //
        // 2. Regular -> Compact: Switch to the default tab
        //

        let isCompactToRegularWidth =
            previousTraitCollection.horizontalSizeClass == .compact &&
            traitCollection.horizontalSizeClass == .regular

        let isRegularToCompactWidth =
            previousTraitCollection.horizontalSizeClass == .regular &&
            traitCollection.horizontalSizeClass == .compact

        if isCompactToRegularWidth, isShowingDashboard {
            segmentedControl.selectedSegmentIndex = Section.siteMenu.rawValue
            segmentedControlValueChanged()
        } else if isRegularToCompactWidth {
            segmentedControl.selectedSegmentIndex = mySiteSettings.defaultSection.rawValue
            segmentedControlValueChanged()
        }

        updateSegmentedControl(for: blog)
    }

    private func subscribeToContentSizeCategory() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didChangeDynamicType),
                                               name: UIContentSizeCategory.didChangeNotification,
                                               object: nil)
    }

    private func subscribeToPostSignupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(launchSiteCreationFromNotification), name: .createSite, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(showAddSelfHostedSite), name: .addSelfHosted, object: nil)
    }

    private func subscribeToPostPublished() {
        NotificationCenter.default.addObserver(self, selector: #selector(handlePostPublished), name: .newPostPublished, object: nil)
    }

    private func subscribeToWillEnterForeground() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(displayOverlayIfNeeded),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
    }

    func updateNavigationTitle(for blog: Blog) {
        let blogName = blog.settings?.name
        let title = blogName != nil && blogName?.isEmpty == false
            ? blogName
            : Strings.mySite
        navigationItem.title = title
    }

    private func updateSegmentedControl(for blog: Blog, switchTabsIfNeeded: Bool = false) {
        // The segmented control should be hidden if the blog is not a WP.com/Atomic/Jetpack site, or if the device doesn't have a horizontally compact view
        let hideSegmentedControl =
            !JetpackFeaturesRemovalCoordinator.jetpackFeaturesEnabled() ||
            !blog.isAccessibleThroughWPCom() ||
            !splitViewControllerIsHorizontallyCompact

        segmentedControlContainerView.isHidden = hideSegmentedControl

        if !hideSegmentedControl && switchTabsIfNeeded {
            switchTab(to: mySiteSettings.defaultSection)
        }
    }

    private func setupView() {
        view.backgroundColor = .listBackground
        configureSegmentedControlFont()
    }

    /// This method builds a layout with the following view hierarchy:
    ///
    /// - Scroll view
    ///   - Stack view
    ///     - Site picker view controller
    ///     - Segmented control container view
    ///       - Segmented control
    ///     - Blog dashboard view controller OR blog details view controller
    ///
    private func setupConstraints() {
        view.addSubview(scrollView)
        view.pinSubviewToAllEdges(scrollView)
        scrollView.addSubview(stackView)
        scrollView.pinSubviewToAllEdges(stackView)
        segmentedControlContainerView.addSubview(segmentedControl)
        stackView.addArrangedSubviews([segmentedControlContainerView])
        view.addSubview(siteMenuSpotlightView)

        let stackViewConstraints = [
            stackView.widthAnchor.constraint(equalTo: view.widthAnchor)
        ]

        let segmentedControlConstraints = [
            segmentedControl.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                                                      constant: Constants.segmentedControlXOffset),
            segmentedControl.centerXAnchor.constraint(equalTo: segmentedControlContainerView.centerXAnchor),
            segmentedControl.topAnchor.constraint(equalTo: segmentedControlContainerView.topAnchor,
                                                  constant: Constants.segmentedControlYOffset),
            segmentedControl.bottomAnchor.constraint(equalTo: segmentedControlContainerView.bottomAnchor),
            segmentedControl.heightAnchor.constraint(equalToConstant: Constants.segmentedControlHeight)
        ]

        let siteMenuSpotlightViewConstraints = [
            siteMenuSpotlightView.trailingAnchor.constraint(equalTo: segmentedControl.trailingAnchor, constant: Constants.siteMenuSpotlightOffset),
            siteMenuSpotlightView.topAnchor.constraint(equalTo: segmentedControl.topAnchor, constant: -Constants.siteMenuSpotlightOffset)
        ]

        NSLayoutConstraint.activate(
            stackViewConstraints +
            segmentedControlConstraints +
            siteMenuSpotlightViewConstraints
        )
    }

    // MARK: - Navigation Item

    /// In iPad and iOS 14, the large-title bar is collapsed when the VC is first loaded.  Call this method from
    /// `viewDidAppear(_:)` to quickly refresh the navigation bar so that it's expanded.
    ///
    private func workaroundLargeTitleCollapseBug() {
        guard !splitViewControllerIsHorizontallyCompact else {
            return
        }

        navigationController?.navigationBar.sizeToFit()
    }

    private func setupNavigationItem() {
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.title = Strings.mySite
        navigationItem.backButtonTitle = Strings.mySite

        // Workaround:
        //
        // Without the next line, the large title was being lost when going into a child VC with a small
        // title and pressing "Back" in the navigation bar.
        //
        // I'm not sure if this makes sense - it doesn't to me right now, so I'm adding instructions to
        // test the issue which will be helpful for removing the issue if the workaround is no longer
        // needed.
        //
        // To see the issue in action, comment the line, run the App, go into "Stats" (or any other
        // child VC that has a small title in the navigation bar), check that the title is small,
        // press back, and check that this VC has a large title.  If this VC still has a
        // large title, you can remove the following line.
        //
        extendedLayoutIncludesOpaqueBars = true

        // Set the nav bar
        navigationController?.navigationBar.accessibilityIdentifier = "my-site-navigation-bar"
    }

    private func setupNavBarAppearance() {
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    private func resetNavBarAppearance() {
        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y >= 60 {
            navigationController?.setNavigationBarHidden(false, animated: true)
        } else {
            navigationController?.setNavigationBarHidden(true, animated: true)
        }
    }

    // MARK: - Account

    private func defaultAccount() -> WPAccount? {
        try? WPAccount.lookupDefaultWordPressComAccount(in: ContextManager.shared.mainContext)
    }

    // MARK: - Main Blog

    /// Convenience method to retrieve the main blog for an account when none is selected.
    ///
    /// - Returns:the main blog for an account (last selected, or first blog in list).
    ///
    private func mainBlog() -> Blog? {
        return Blog.lastUsedOrFirst(in: ContextManager.sharedInstance().mainContext)
    }

    /// This VC is prepared to either show the details for a blog, or show a no-results VC configured to let the user know they have no blogs.
    /// There's no scenario where this is shown empty, for an account that HAS blogs.
    ///
    /// In order to adhere to this logic, if this VC is shown without a blog being set, we will try to load the "main" blog (ie in order: the last used blog,
    /// the account's primary blog, or the first blog we find for the account).
    ///
    private func showBlogDetailsForMainBlogOrNoSites() {
        guard let mainBlog = mainBlog() else {
            showNoSites()
            return
        }

        showBlogDetails(for: mainBlog)
        showSitePicker(for: mainBlog)
        updateNavigationTitle(for: mainBlog)
        updateSegmentedControl(for: mainBlog, switchTabsIfNeeded: true)
    }

    @objc
    private func syncBlogs() {
        guard let account = defaultAccount() else {
            return
        }

        let finishSync = { [weak self] in
            self?.noSitesRefreshControl?.endRefreshing()
        }

        blogService.syncBlogs(for: account) {
            finishSync()
        } failure: { (error) in
            finishSync()
        }
    }

    @objc
    private func pulledToRefresh() {

        guard let blog = blog,
              let section = currentSection else {
                  return
        }

        switch section {
        case .siteMenu:

            blogDetailsViewController?.pulledToRefresh(with: refreshControl) { [weak self] in
                guard let self = self else {
                    return
                }

                self.updateNavigationTitle(for: blog)
                self.sitePickerViewController?.blogDetailHeaderView.blog = blog
            }


        case .dashboard:

            /// The dashboard’s refresh control is intentionally not tied to blog syncing in order to keep
            /// the dashboard updating fast.
            blogDashboardViewController?.pulledToRefresh { [weak self] in
                self?.refreshControl.endRefreshing()
            }

            syncBlogAndAllMetadata(blog)

            /// Update today's prompt if the blog has blogging prompts enabled.
            fetchPrompt(for: blog)
        }

        WPAnalytics.track(.mySitePullToRefresh, properties: [WPAppAnalyticsKeyTabSource: section.analyticsDescription])
    }

    private func syncBlogAndAllMetadata(_ blog: Blog) {
        blogService.syncBlogAndAllMetadata(blog) { [weak self] in
            guard let self = self else {
                return
            }

            self.updateNavigationTitle(for: blog)
            self.sitePickerViewController?.blogDetailHeaderView.blog = blog
            self.blogDashboardViewController?.reloadCardsLocally()
        }
    }

    // MARK: - Segmented Control

    @objc private func segmentedControlValueChangedByUser() {
        guard let section = currentSection else {
            return
        }

        segmentedControlValueChanged()
        WPAnalytics.track(.mySiteTabTapped, properties: ["tab": section.analyticsDescription])
    }

    @objc private func segmentedControlValueChanged() {
        guard let blog = blog,
              let section = currentSection else {
            return
        }

        switch section {
        case .siteMenu:
            siteMenuSpotlightIsShown = false
            hideDashboard()
            showBlogDetails(for: blog)
        case .dashboard:
            hideBlogDetails()
            showDashboard(for: blog)
        }
    }

    /// Changes between the site menu and dashboard
    /// - Parameter section: The section to switch to
    func switchTab(to section: Section) {
        segmentedControl.selectedSegmentIndex = section.rawValue
        segmentedControlValueChanged()
    }

    // MARK: - Child VC logic

    private func embedChildInStackView(_ child: UIViewController) {
        addChild(child)
        stackView.addArrangedSubview(child.view)
        child.didMove(toParent: self)
    }

    private func removeChildFromStackView(_ child: UIViewController) {
        guard child.parent != nil else {
            return
        }

        child.willMove(toParent: nil)
        stackView.removeArrangedSubview(child.view)
        child.view.removeFromSuperview()
        child.removeFromParent()
    }

    // MARK: - No Sites UI logic

    private func hideNoSites() {
        // Only track if the no sites view is currently visible
        if noSitesViewController.view.superview != nil {
            WPAnalytics.track(.mySiteNoSitesViewHidden)
        }

        noSitesViewController.willMove(toParent: nil)
        noSitesViewController.view.removeFromSuperview()
        noSitesViewController.removeFromParent()

        cleanupNoSitesView()
    }

    private func showNoSites() {
        guard AccountHelper.isLoggedIn else {
            WordPressAppDelegate.shared?.windowManager.showFullscreenSignIn()
            return
        }

        hideBlogDetails()
        hideSplitDetailsView()
        blogDetailsViewController = nil

        guard noSitesViewController.view.superview == nil else {
            return
        }

        makeNoSitesScrollView()
        configureNoSitesView()
        addNoSitesViewAndConfigureConstraints()
        createButtonCoordinator?.removeCreateButton()
    }

    private func trackNoSitesVisibleIfNeeded() {
        guard noSitesViewController.view.superview != nil else {
            return
        }

        WPAnalytics.track(.mySiteNoSitesViewDisplayed)
    }

    private func makeNoSitesScrollView() {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = .listBackground

        view.addSubview(scrollView)
        view.pinSubviewToAllEdges(scrollView)

        let refreshControl = UIRefreshControl()
        scrollView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(syncBlogs), for: .valueChanged)
        noSitesRefreshControl = refreshControl

        noSitesScrollView = scrollView
    }

    private func configureNoSitesView() {
        noSitesViewController.rootView.delegate = self
    }

    private func addNoSitesViewAndConfigureConstraints() {
        guard let scrollView = noSitesScrollView else {
            return
        }

        addChild(noSitesViewController)
        scrollView.addSubview(noSitesViewController.view)
        noSitesViewController.view.frame = scrollView.frame

        guard let nrv = noSitesViewController.view else {
            return
        }

        nrv.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            nrv.widthAnchor.constraint(equalTo: view.widthAnchor),
            nrv.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            nrv.topAnchor.constraint(equalTo: scrollView.topAnchor),
            nrv.bottomAnchor.constraint(equalTo: view.safeBottomAnchor)
        ])

        noSitesViewController.didMove(toParent: self)
    }

    private func cleanupNoSitesView() {
        noSitesRefreshControl?.removeFromSuperview()
        noSitesRefreshControl = nil

        noSitesScrollView?.refreshControl = nil
        noSitesScrollView?.removeFromSuperview()
        noSitesScrollView = nil
    }

    // MARK: - FAB

    private func createFABIfNeeded() {
        createButtonCoordinator?.removeCreateButton()
        createButtonCoordinator = makeCreateButtonCoordinator()
        createButtonCoordinator?.add(to: view,
                                    trailingAnchor: view.safeAreaLayoutGuide.trailingAnchor,
                                    bottomAnchor: view.safeAreaLayoutGuide.bottomAnchor)

        if let blog = blog,
           noSitesViewController.view.superview == nil {
            createButtonCoordinator?.showCreateButton(for: blog)
        }
    }

// MARK: - Add Site Alert

    func didTapAccountAndSettingsButton() {
        let meViewController = MeViewController()
        showDetailViewController(meViewController, sender: self)
    }

    @objc
    func presentInterfaceForAddingNewSite() {
        noSitesViewController.rootView.handleAddNewSiteButtonTapped()
    }

    private func launchSiteCreationFromNoSites() {
        launchSiteCreation(source: "my_site_no_sites")
    }

    private func launchLoginForSelfHostedSite() {
        WordPressAuthenticator.showLoginForSelfHostedSite(self)
    }

    @objc
    func didChangeDynamicType() {
        configureSegmentedControlFont()
    }

    private func configureSegmentedControlFont() {
        let font = WPStyleGuide.fontForTextStyle(.subheadline)
        segmentedControl.setTitleTextAttributes([NSAttributedString.Key.font: font], for: .normal)
    }

    @objc
    func launchSiteCreationFromNotification() {
        self.launchSiteCreation(source: "signup_epilogue")
        willDisplayPostSignupFlow = false
    }

    func launchSiteCreation(source: String) {
        JetpackFeaturesRemovalCoordinator.presentSiteCreationOverlayIfNeeded(in: self, source: source, onDidDismiss: {
            guard JetpackFeaturesRemovalCoordinator.siteCreationPhase() != .two else {
                return
            }

            // Display site creation flow if not in phase two
            let wizardLauncher = SiteCreationWizardLauncher()
            guard let wizard = wizardLauncher.ui else {
                return
            }
            self.present(wizard, animated: true)
            SiteCreationAnalyticsHelper.trackSiteCreationAccessed(source: source)
        })
    }

    @objc
    private func showAddSelfHostedSite() {
        WordPressAuthenticator.showLoginForSelfHostedSite(self)
        willDisplayPostSignupFlow = false
    }

    @objc
    func toggleSpotlightOnSitePicker() {
        sitePickerViewController?.toggleSpotlightOnHeaderView()
    }

    // MARK: - Blog Details UI Logic

    private func hideBlogDetails() {
        guard let blogDetailsViewController = blogDetailsViewController else {
            return
        }

        removeChildFromStackView(blogDetailsViewController)
    }

    /// Shows a `BlogDetailsViewController` for the specified `Blog`.  If the VC doesn't exist, this method also takes care
    /// of creating it.
    ///
    /// - Parameters:
    ///         - blog: The blog to show the details of.
    ///
    private func showBlogDetails(for blog: Blog) {
        hideNoSites()

        let blogDetailsViewController = self.blogDetailsViewController(for: blog)

        embedChildInStackView(blogDetailsViewController)

        // This ensures that the spotlight views embedded in the site picker don't get clipped.
        stackView.sendSubviewToBack(blogDetailsViewController.view)

        blogDetailsViewController.showInitialDetailsForBlog()
    }

    private func blogDetailsViewController(for blog: Blog) -> BlogDetailsViewController {
        guard let blogDetailsViewController = blogDetailsViewController else {
            let blogDetailsViewController = makeBlogDetailsViewController(for: blog)
            self.blogDetailsViewController = blogDetailsViewController
            return blogDetailsViewController
        }

        blogDetailsViewController.switch(to: blog)
        return blogDetailsViewController
    }

    private func makeBlogDetailsViewController(for blog: Blog) -> BlogDetailsViewController {
        let blogDetailsViewController = BlogDetailsViewController(meScenePresenter: meScenePresenter)
        blogDetailsViewController.blog = blog

        return blogDetailsViewController
    }

    private func showSitePicker(for blog: Blog) {
        guard let sitePickerViewController = sitePickerViewController else {

            let sitePickerViewController = makeSitePickerViewController(for: blog)
            self.sitePickerViewController = sitePickerViewController

            addChild(sitePickerViewController)
            stackView.insertArrangedSubview(sitePickerViewController.view, at: 0)
            sitePickerViewController.didMove(toParent: self)

            return
        }

        sitePickerViewController.blog = blog
    }

    private func makeSitePickerViewController(for blog: Blog) -> SitePickerViewController {
        let sitePickerViewController = SitePickerViewController(blog: blog, meScenePresenter: meScenePresenter)

        sitePickerViewController.onBlogSwitched = { [weak self] blog in

            guard let self = self else {
                return
            }

            if !blog.isAccessibleThroughWPCom() && self.isShowingDashboard {
                self.switchTab(to: .siteMenu)
            }

            self.updateNavigationTitle(for: blog)
            self.updateSegmentedControl(for: blog)
            self.updateChildViewController(for: blog)
            self.createFABIfNeeded()
            self.fetchPrompt(for: blog)
        }

        sitePickerViewController.onBlogListDismiss = { [weak self] in
            self?.displayJetpackInstallOverlayIfNeeded()
        }

        return sitePickerViewController
    }

    private func updateChildViewController(for blog: Blog) {
        guard let section = currentSection else {
            return
        }

        switch section {
        case .siteMenu:
            blogDetailsViewController?.blog = blog
            blogDetailsViewController?.configureTableViewData()
            blogDetailsViewController?.tableView.reloadData()
            blogDetailsViewController?.preloadMetadata()
            blogDetailsViewController?.showInitialDetailsForBlog()
        case .dashboard:
            syncBlogAndAllMetadata(blog)
            blogDashboardViewController?.update(blog: blog)
        }
    }

    func presentCreateSheet() {
        blogDetailsViewController?.createButtonCoordinator?.showCreateSheet()
    }

    // MARK: Dashboard UI Logic

    private func hideDashboard() {
        guard let blogDashboardViewController = blogDashboardViewController else {
            return
        }

        removeChildFromStackView(blogDashboardViewController)
    }

    /// Shows a `BlogDashboardViewController` for the specified `Blog`.  If the VC doesn't exist, this method also takes care
    /// of creating it.
    ///
    /// - Parameters:
    ///         - blog: The blog to show the details of.
    ///
    private func showDashboard(for blog: Blog) {
        let blogDashboardViewController = self.blogDashboardViewController ?? BlogDashboardViewController(blog: blog, embeddedInScrollView: true)
        blogDashboardViewController.update(blog: blog)
        embedChildInStackView(blogDashboardViewController)
        self.blogDashboardViewController = blogDashboardViewController
        stackView.sendSubviewToBack(blogDashboardViewController.view)
    }

    // MARK: - Model Changes

    private func subscribeToModelChanges() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDataModelChange(notification:)),
            name: .NSManagedObjectContextObjectsDidChange,
            object: ContextManager.shared.mainContext)
    }

    @objc
    private func handleDataModelChange(notification: NSNotification) {
        if let blog = blog {
            handlePossibleDeletion(of: blog, notification: notification)
        } else {
            handlePossiblePrimaryBlogCreation(notification: notification)
        }
    }

    // MARK: - Model Changes: Blog Deletion

    /// This method takes care of figuring out if the selected blog was deleted, and to address any side effect
    /// of the selected blog being deleted.
    ///
    private func handlePossibleDeletion(of selectedBlog: Blog, notification: NSNotification) {
        guard let deletedObjects = notification.userInfo?[NSDeletedObjectsKey] as? Set<NSManagedObject>,
           deletedObjects.contains(selectedBlog) else {
            return
        }

        self.blog = nil
    }

    // MARK: - Model Changes: Blog Creation

    /// This method ensures that the received notification includes inserted blogs.
    /// It's useful because when we call `lastUsedOrFirstBlog()` a chain of calls that ends with:
    ///
    ///     `AccountService.defaultWordPressComAccount()`
    ///     > `AccountService.accountWithUUID()`
    ///     > `NSManagedObjectContext.executeFetchRequest(...)`.
    ///
    /// The issue is that `executeFetchRequest` updates the managed object context, thus triggering
    /// a `NSManagedObjectContextObjectsDidChange` notification, which caused a neverending
    /// loop in the observer in this VC.
    ///
    private func verifyThatBlogsWereInserted(in notification: NSNotification) -> Bool {
        guard let insertedObjects = notification.userInfo?[NSInsertedObjectsKey] as? Set<NSManagedObject>,
              insertedObjects.contains(where: { $0 as? Blog != nil }) else {
            return false
        }

        return true
    }

    /// This method takes care of figuring out if a primary blog was created, in order to show the details for such
    /// blog.
    ///
    private func handlePossiblePrimaryBlogCreation(notification: NSNotification) {
        // WORKAROUND: At first sight this guard should not be needed.
        // Please read the documentation for this method carefully.
        guard verifyThatBlogsWereInserted(in: notification) else {
            return
        }

        guard let blog = Blog.lastUsedOrFirst(in: ContextManager.sharedInstance().mainContext) else {
            return
        }

        self.blog = blog
    }

    // MARK: - Blogging Prompts

    @objc func handlePostPublished() {
        fetchPrompt(for: blog)
    }

    func fetchPrompt(for blog: Blog?) {
        guard FeatureFlag.bloggingPrompts.enabled,
              let blog = blog,
              blog.isAccessibleThroughWPCom(),
              let promptsService = BloggingPromptsService(blog: blog),
              let siteID = blog.dotComID?.intValue else {
            return
        }

        let dashboardPersonalization = BlogDashboardPersonalizationService(siteID: siteID)
        guard dashboardPersonalization.isEnabled(.prompts) else {
            return
        }

        promptsService.fetchTodaysPrompt()
    }

    // MARK: - Constants

    private enum Constants {
        static let segmentedControlXOffset: CGFloat = 20
        static let segmentedControlYOffset: CGFloat = 24
        static let segmentedControlHeight: CGFloat = 32
        static let siteMenuSpotlightOffset: CGFloat = 8
    }

    private enum Strings {
        static let mySite = NSLocalizedString("My Site", comment: "Title of My Site tab")
    }
}

extension MySiteViewController: WPSplitViewControllerDetailProvider {
    func initialDetailViewControllerForSplitView(_ splitView: WPSplitViewController) -> UIViewController? {
        guard let blogDetailsViewController = blogDetailsViewController as? WPSplitViewControllerDetailProvider else {
            let emptyViewController = UIViewController()
            WPStyleGuide.configureColors(view: emptyViewController.view, tableView: nil)
            return emptyViewController
        }

        return blogDetailsViewController.initialDetailViewControllerForSplitView(splitView)
    }

    /// Removes all view controllers from the details view controller stack and leaves split view details in an empty state.
    ///
    private func hideSplitDetailsView() {
        if let splitViewController = splitViewController as? WPSplitViewController,
           splitViewController.viewControllers.count > 1,
           let detailsNavigationController = splitViewController.viewControllers.last as? UINavigationController {
            detailsNavigationController.setViewControllers([], animated: false)
        }
    }
}

// MARK: - UIViewControllerTransitioningDelegate
//
extension MySiteViewController: UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        guard presented is FancyAlertViewController else {
            return nil
        }

        return FancyAlertPresentationController(presentedViewController: presented, presenting: presenting)
    }
}

// MARK: - QuickStart
//
extension MySiteViewController {
    func startAlertTimer() {
        blogDetailsViewController?.startAlertTimer()
    }
}

// MARK: - Presentation
/// Supporting presentation of BlogDetailsSubsection from both BlogDashboard and BlogDetails
extension MySiteViewController: BlogDetailsPresentationDelegate {

    /// Shows the specified `BlogDetailsSubsection` for a `Blog`.
    ///
    /// - Parameters:
    ///         - subsection: The specific subsection to show.
    ///
    func showBlogDetailsSubsection(_ subsection: BlogDetailsSubsection) {
        blogDetailsViewController?.showDetailView(for: subsection)
    }

    func presentBlogDetailsViewController(_ viewController: UIViewController) {
        switch currentSection {
        case .dashboard:
            blogDashboardViewController?.showDetailViewController(viewController, sender: blogDashboardViewController)
        case .siteMenu:
            blogDetailsViewController?.showDetailViewController(viewController, sender: blogDetailsViewController)
        case .none:
            return
        }
    }
}

// MARK: Jetpack Features Removal

private extension MySiteViewController {
    @objc func displayOverlayIfNeeded() {
        if isViewOnScreen(), !willDisplayPostSignupFlow {
            let didReloadUI = RootViewCoordinator.shared.reloadUIIfNeeded(blog: self.blog)
            if !didReloadUI {
                let phase = JetpackFeaturesRemovalCoordinator.generalPhase()
                let source: JetpackFeaturesRemovalCoordinator.JetpackOverlaySource = phase == .four ? .phaseFourOverlay : .appOpen
                JetpackFeaturesRemovalCoordinator.presentOverlayIfNeeded(in: self, source: source, blog: self.blog)
            }
        }
    }
}

// MARK: Jetpack Install Plugin Overlay

private extension MySiteViewController {
    func displayJetpackInstallOverlayIfNeeded() {
        JetpackInstallPluginHelper.presentOverlayIfNeeded(in: self, blog: blog, delegate: self)
    }

    func dismissOverlayAndRefresh() {
        dismiss(animated: true) {
            self.pulledToRefresh()
        }
    }
}

extension MySiteViewController: JetpackRemoteInstallDelegate {
    func jetpackRemoteInstallCompleted() {
        dismissOverlayAndRefresh()
    }

    func jetpackRemoteInstallCanceled() {
        dismissOverlayAndRefresh()
    }

    func jetpackRemoteInstallWebviewFallback() {
        // no op
    }
}
