import WordPressAuthenticator
import UIKit
import SwiftUI

final class MySiteViewController: UIViewController, UIScrollViewDelegate, NoSitesViewDelegate {
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

    private var currentSection: Section = .dashboard

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

    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(pulledToRefresh), for: .valueChanged)
        return refreshControl
    }()

    /// A boolean indicating whether a site creation or adding self-hosted site flow has been initiated but not yet displayed.
    var willDisplayPostSignupFlow: Bool = false

    private var createButtonCoordinator: CreateButtonCoordinator?
    private var complianceCoordinator: CompliancePopoverCoordinator?

    private let meScenePresenter: ScenePresenter
    private let blogService: BlogService

    private let viewModel: MySiteViewModel

    // MARK: - Initializers

    init(meScenePresenter: ScenePresenter, blogService: BlogService? = nil) {
        self.meScenePresenter = meScenePresenter
        self.blogService = blogService ?? BlogService(coreDataStack: ContextManager.shared)
        self.viewModel = MySiteViewModel()

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
            createFABIfNeeded()
            fetchPrompt(for: newBlog)
            configure(for: newBlog)
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
        let noSitesViewModel = NoSitesViewModel(
            appUIType: JetpackFeaturesRemovalCoordinator.currentAppUIType,
            account: viewModel.defaultAccount
        )
        let configuration = AddNewSiteConfiguration(
            canCreateWPComSite: viewModel.defaultAccount != nil,
            canAddSelfHostedSite: AppConfiguration.showAddSelfHostedSiteButton,
            launchSiteCreation: self.launchSiteCreationFromNoSites,
            launchLoginForSelfHostedSite: self.launchLoginForSelfHostedSite
        )
        let noSiteView = NoSitesView(
            viewModel: noSitesViewModel,
            addNewSiteConfiguration: configuration
        )
        return UIHostingController(rootView: noSiteView)
    }()

    private var isNavigationBarHidden = false

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
        setupConstraints()
        setupNavigationItem()
        subscribeToPostSignupNotifications()
        subscribeToModelChanges()
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

        configureNavBarAppearance(animated: false)
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

    private func setupView() {
        view.backgroundColor = .listBackground
    }

    /// This method builds a layout with the following view hierarchy:
    ///
    /// - Scroll view
    ///   - Stack view
    ///     - Site picker view controller
    ///     - Blog dashboard view controller OR blog details view controller
    ///
    private func setupConstraints() {
        view.addSubview(scrollView)
        view.pinSubviewToAllEdges(scrollView)
        scrollView.addSubview(stackView)
        scrollView.pinSubviewToAllEdges(stackView)

        NSLayoutConstraint.activate([
            stackView.widthAnchor.constraint(equalTo: view.widthAnchor)
        ])
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

    private func configureNavBarAppearance(animated: Bool) {
        #warning("TEMP")
        guard !UIDevice.isPad() else { return }

        if scrollView.contentOffset.y >= 60 {
            if isNavigationBarHidden {
                navigationController?.setNavigationBarHidden(false, animated: animated)
            }
            isNavigationBarHidden = false
        } else {
            if !isNavigationBarHidden {
                navigationController?.setNavigationBarHidden(true, animated: animated)
            }
            isNavigationBarHidden = true
        }
    }

    private func resetNavBarAppearance() {
        navigationController?.setNavigationBarHidden(false, animated: false)
        isNavigationBarHidden = false
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        configureNavBarAppearance(animated: true)
    }

    // MARK: - Main Blog

    /// This VC is prepared to either show the details for a blog, or show a no-results VC configured to let the user know they have no blogs.
    /// There's no scenario where this is shown empty, for an account that HAS blogs.
    ///
    /// In order to adhere to this logic, if this VC is shown without a blog being set, we will try to load the "main" blog (ie in order: the last used blog,
    /// the account's primary blog, or the first blog we find for the account).
    ///
    private func showBlogDetailsForMainBlogOrNoSites() {
        guard let mainBlog = viewModel.mainBlog else {
            showNoSites()
            return
        }
        configure(for: mainBlog)
    }

    private func configure(for blog: Blog) {
        showSitePicker(for: blog)
        updateNavigationTitle(for: blog)

        let section = viewModel.getSection(
            for: blog,
            jetpackFeaturesEnabled: JetpackFeaturesRemovalCoordinator.jetpackFeaturesEnabled(),
            splitViewControllerIsHorizontallyCompact: splitViewControllerIsHorizontallyCompact,
            isSplitViewEnabled: MySitesCoordinator.isSplitViewEnabled
        )

        self.currentSection = section
        switch section {
        case .siteMenu:
            hideDashboard()
            showBlogDetails(for: blog)
        case .dashboard:
            // It has to be allocated, otherwise deep links are not going to work
            showBlogDetails(for: blog)

            hideBlogDetails()
            showDashboard(for: blog)
        }
    }

    @objc
    private func syncBlogs() {
        guard let account = viewModel.defaultAccount else {
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
        guard let blog = blog else {
            return
        }
        switch currentSection {
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

        WPAnalytics.track(.mySitePullToRefresh, properties: [WPAppAnalyticsKeyTabSource: currentSection.analyticsDescription])
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

        hideSplitDetailsView()

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
        guard !UIDevice.isPad() else {
            return
        }

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
        if MySitesCoordinator.isSplitViewEnabled {
            showDetailViewController(meViewController, sender: self)
        } else {
            navigationController?.pushViewController(meViewController, animated: true)
        }
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
        let blogDetailsViewController = BlogDetailsViewController()
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
            self.configure(for: blog)
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
        switch currentSection {
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
        createButtonCoordinator?.showCreateSheet()
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
        switch currentSection {
        case .dashboard:
            blogDashboardViewController?.startAlertTimer()
        case .siteMenu:
            blogDetailsViewController?.startAlertTimer()
        }
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

    // TODO: Refactor presentation from routes
    // More context: https://github.com/wordpress-mobile/WordPress-iOS/issues/21759
    func presentBlogDetailsViewController(_ viewController: UIViewController) {
        viewController.loadViewIfNeeded()
        if MySitesCoordinator.isSplitViewEnabled {
            switch currentSection {
            case .dashboard:
                blogDashboardViewController?.showDetailViewController(viewController, sender: blogDashboardViewController)
            case .siteMenu:
                blogDetailsViewController?.showDetailViewController(viewController, sender: blogDetailsViewController)
            }
        } else {
            switch currentSection {
            case .dashboard:
                blogDashboardViewController?.show(viewController, sender: blogDashboardViewController)
            case .siteMenu:
                blogDetailsViewController?.show(viewController, sender: blogDetailsViewController)
            }
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
