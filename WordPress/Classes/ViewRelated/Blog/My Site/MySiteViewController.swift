import WordPressAuthenticator
import UIKit

class MySiteViewController: UIViewController, NoResultsViewHost {

    private enum Section: Int, CaseIterable {
        case siteMenu
        case dashboard

        var title: String {
            switch self {
            case .siteMenu:
                return NSLocalizedString("Site Menu", comment: "Title for the site menu view on the My Site screen")
            case .dashboard:
                return NSLocalizedString("Dashboard", comment: "Title for dashboard view on the My Site screen")
            }
        }
    }

    private var isShowingDashboard: Bool {
        return segmentedControl.selectedSegmentIndex == Section.dashboard.rawValue
    }

    @objc
    private(set) lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.refreshControl = refreshControl
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
        segmentedControl.addTarget(self, action: #selector(segmentedControlValueChanged(_:)), for: .valueChanged)
        segmentedControl.selectedSegmentIndex = 0
        return segmentedControl
    }()

    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(pulledToRefresh), for: .valueChanged)
        return refreshControl
    }()

    private let meScenePresenter: ScenePresenter
    private let blogService: BlogService

    // MARK: - Initializers

    init(meScenePresenter: ScenePresenter, blogService: BlogService? = nil) {
        self.meScenePresenter = meScenePresenter
        self.blogService = blogService ?? BlogService(managedObjectContext: ContextManager.shared.mainContext)

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("Initializer not implemented!")
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

            addSitePickerIfNeeded(for: newBlog)
            showBlogDetails(for: newBlog)
            updateSegmentedControl(for: newBlog)
        }

        get {
            return sitePickerViewController?.blog
        }
    }

    /// The VC for the blog details.  This class is written in a way that this VC will only exist if it's being shown on screen.
    /// Please keep this in mind when making modifications.
    ///
    private(set) var blogDetailsViewController: BlogDetailsViewController?

    private let blogDashboardViewController = BlogDashboardViewController()

    private(set) var sitePickerViewController: SitePickerViewController?

    /// When we display a no results view, we'll do so in a scrollview so that
    /// we can allow pull to refresh to sync the user's list of sites.
    ///
    private var noResultsScrollView: UIScrollView?
    private var noResultsRefreshControl: UIRefreshControl?

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        setupView()
        setupConstraints()
        setupNavigationItem()
        subscribeToPostSignupNotifications()
        subscribeToModelChanges()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if blog == nil {
            showBlogDetailsForMainBlogOrNoSites()
        }

        setupTransparentNavBar()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        setupOpaqueNavBar()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        workaroundLargeTitleCollapseBug()

        if AppConfiguration.showsWhatIsNew {
            WPTabBarController.sharedInstance()?.presentWhatIsNew(on: self)
        }

        FancyAlertViewController.presentCustomAppIconUpgradeAlertIfNecessary(from: self)

        trackNoSitesVisibleIfNeeded()

        setupTransparentNavBar()
    }

    private func subscribeToPostSignupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(launchSiteCreationFromNotification), name: .createSite, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(showAddSelfHostedSite), name: .addSelfHosted, object: nil)
    }

    private func updateSegmentedControl(for blog: Blog) {
        // The segmented control should be hidden if the blog is not a WP.com/Atomic/Jetpack site, or if the device is an iPad
        segmentedControlContainerView.isHidden = !FeatureFlag.mySiteDashboard.enabled || !blog.isAccessibleThroughWPCom() || UIDevice.isPad()
    }

    private func setupView() {
        view.backgroundColor = .listBackground
    }

    /// This method builds a layout with the following view hierarchy:
    ///
    /// - Scroll view
    ///   - Stack view
    ///     - Segmented control container view
    ///       - Segmented control
    ///     - Child view controller
    /// 
    private func setupConstraints() {
        view.addSubview(scrollView)
        view.pinSubviewToAllEdges(scrollView)
        scrollView.addSubview(stackView)
        scrollView.pinSubviewToAllEdges(stackView)
        segmentedControlContainerView.addSubview(segmentedControl)
        stackView.addArrangedSubviews([segmentedControlContainerView])

        NSLayoutConstraint.activate([
            stackView.widthAnchor.constraint(equalTo: view.widthAnchor),
            segmentedControl.leadingAnchor.constraint(equalTo: segmentedControlContainerView.leadingAnchor,
                                                      constant: Constants.segmentedControlXOffset),
            segmentedControl.centerXAnchor.constraint(equalTo: segmentedControlContainerView.centerXAnchor),
            segmentedControl.topAnchor.constraint(equalTo: segmentedControlContainerView.topAnchor,
                                                  constant: Constants.segmentedControlYOffset),
            segmentedControl.bottomAnchor.constraint(equalTo: segmentedControlContainerView.bottomAnchor)
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
        navigationItem.largeTitleDisplayMode = .always
        navigationItem.title = NSLocalizedString("My Site", comment: "Title of My Site tab")

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

    private func setupTransparentNavBar() {
        navigationController?.navigationBar.scrollEdgeAppearance?.configureWithTransparentBackground()
    }

    private func setupOpaqueNavBar() {
        navigationController?.navigationBar.scrollEdgeAppearance?.configureWithOpaqueBackground()
    }

    // MARK: - Account

    private func defaultAccount() -> WPAccount? {
        let context = ContextManager.sharedInstance().mainContext
        let service = AccountService(managedObjectContext: context)

        return service.defaultWordPressComAccount()
    }

    // MARK: - Main Blog

    /// Convenience method to retrieve the main blog for an account when none is selected.
    ///
    /// - Returns:the main blog for an account (last selected, or first blog in list).
    ///
    private func mainBlog() -> Blog? {
        return blogService.lastUsedOrFirstBlog()
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

        addSitePickerIfNeeded(for: mainBlog)
        showBlogDetails(for: mainBlog)
        updateSegmentedControl(for: mainBlog)
    }

    @objc
    private func syncBlogs() {
        guard let account = defaultAccount() else {
            return
        }

        let finishSync = { [weak self] in
            self?.noResultsRefreshControl?.endRefreshing()
        }

        blogService.syncBlogs(for: account) {
            finishSync()
        } failure: { (error) in
            finishSync()
        }
    }

    @objc
    private func pulledToRefresh() {
        blogDetailsViewController?.pulledToRefresh(with: refreshControl) { [weak self] in
            guard let self = self else {
                return
            }

            self.sitePickerViewController?.blogDetailHeaderView.blog = self.blog
        }
    }

    // MARK: - Segmented Control

    @objc private func segmentedControlValueChanged(_ sender: Any) {
        guard let blog = blog,
              let section = Section(rawValue: segmentedControl.selectedSegmentIndex) else {
            return
        }

        switch section {
        case .siteMenu:
            remove(blogDashboardViewController)
            showBlogDetails(for: blog)
        case .dashboard:
            guard let blogDetailVC = blogDetailsViewController else {
                return
            }
            remove(blogDetailVC)
            blogDashboardViewController.blog = blog
            embedChildInStackView(blogDashboardViewController)
        }
    }

    // MARK: - Child VC logic

    private func embedChildInStackView(_ child: UIViewController) {
        addChild(child)
        stackView.addArrangedSubview(child.view)
        child.didMove(toParent: self)
    }

    // MARK: - No Sites UI logic

    private func hideNoSites() {
        // Only track if the no sites view is currently visible
        if noResultsViewController.view.superview != nil {
            WPAnalytics.track(.mySiteNoSitesViewHidden)
        }

        hideNoResults()

        cleanupNoResultsView()
    }

    private func showNoSites() {
        guard AccountHelper.isLoggedIn else {
            WordPressAppDelegate.shared?.windowManager.showFullscreenSignIn()
            return
        }

        hideBlogDetails()

        guard noResultsViewController.view.superview == nil else {
            return
        }

        addMeButtonToNavigationBar(email: defaultAccount()?.email, meScenePresenter: meScenePresenter)

        makeNoResultsScrollView()
        configureNoResultsView()
        addNoResultsViewAndConfigureConstraints()
    }

    private func trackNoSitesVisibleIfNeeded() {
        guard noResultsViewController.view.superview != nil else {
            return
        }

        WPAnalytics.track(.mySiteNoSitesViewDisplayed)
    }

    private func makeNoResultsScrollView() {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = .basicBackground

        view.addSubview(scrollView)
        view.pinSubviewToAllEdges(scrollView)

        let refreshControl = UIRefreshControl()
        scrollView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(syncBlogs), for: .valueChanged)
        noResultsRefreshControl = refreshControl

        noResultsScrollView = scrollView
    }

    private func configureNoResultsView() {
        noResultsViewController.configure(title: NSLocalizedString(
                                            "Create a new site for your business, magazine, or personal blog; or connect an existing WordPress installation.",
                                            comment: "Text shown when the account has no sites."),
                                          buttonTitle: NSLocalizedString(
                                            "Add new site",
                                            comment: "Title of button to add a new site."),
                                          image: "mysites-nosites")
        noResultsViewController.actionButtonHandler = { [weak self] in
            self?.presentInterfaceForAddingNewSite()
            WPAnalytics.track(.mySiteNoSitesViewActionTapped)
        }
    }

    private func addNoResultsViewAndConfigureConstraints() {
        guard let scrollView = noResultsScrollView else {
            return
        }

        addChild(noResultsViewController)
        scrollView.addSubview(noResultsViewController.view)
        noResultsViewController.view.frame = scrollView.frame

        guard let nrv = noResultsViewController.view else {
            return
        }

        nrv.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            nrv.widthAnchor.constraint(equalTo: view.widthAnchor),
            nrv.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            nrv.topAnchor.constraint(equalTo: scrollView.topAnchor),
            nrv.bottomAnchor.constraint(equalTo: view.safeBottomAnchor)
        ])

        noResultsViewController.didMove(toParent: self)
    }

    private func cleanupNoResultsView() {
        noResultsRefreshControl?.removeFromSuperview()
        noResultsRefreshControl = nil

        noResultsScrollView?.refreshControl = nil
        noResultsScrollView?.removeFromSuperview()
        noResultsScrollView = nil
    }

// MARK: - Add Site Alert

    @objc
    func presentInterfaceForAddingNewSite() {
        let addSiteAlert = AddSiteAlertFactory().makeAddSiteAlert(source: "my_site_no_sites", canCreateWPComSite: defaultAccount() != nil) { [weak self] in
            self?.launchSiteCreation(source: "my_site_no_sites")
        } addSelfHostedSite: {
            WordPressAuthenticator.showLoginForSelfHostedSite(self)
        }

        if let sourceView = noResultsViewController.actionButton,
           let popoverPresentationController = addSiteAlert.popoverPresentationController {

            popoverPresentationController.sourceView = sourceView
            popoverPresentationController.sourceRect = sourceView.bounds
            popoverPresentationController.permittedArrowDirections = .up
        }

        present(addSiteAlert, animated: true)
    }

    @objc
    func launchSiteCreationFromNotification() {
        self.launchSiteCreation(source: "signup_epilogue")
    }

    func launchSiteCreation(source: String) {
        let wizardLauncher = SiteCreationWizardLauncher()
        guard let wizard = wizardLauncher.ui else {
            return
        }
        present(wizard, animated: true)
        WPAnalytics.track(.enhancedSiteCreationAccessed, withProperties: ["source": source])
    }

    @objc
    private func showAddSelfHostedSite() {
        WordPressAuthenticator.showLoginForSelfHostedSite(self)
    }

    // MARK: - Blog Details UI Logic

    private func hideBlogDetails() {
        guard let blogDetailsViewController = blogDetailsViewController else {
            return
        }

        remove(blogDetailsViewController)
        self.blogDetailsViewController = nil
    }

    /// Shows the specified `BlogDetailsSubsection` for a `Blog`.
    ///
    /// - Parameters:
    ///         - subsection: The specific subsection to show.
    ///
    func showBlogDetailsSubsection(_ subsection: BlogDetailsSubsection) {
        blogDetailsViewController?.showDetailView(for: subsection)
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

        addMeButtonToNavigationBar(email: blog.account?.email, meScenePresenter: meScenePresenter)

        embedChildInStackView(blogDetailsViewController)

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

    private func addSitePickerIfNeeded(for blog: Blog) {
        guard sitePickerViewController == nil else {
            return
        }

        let sitePickerViewController = makeSitePickerViewController(for: blog)
        self.sitePickerViewController = sitePickerViewController

        addChild(sitePickerViewController)
        stackView.insertArrangedSubview(sitePickerViewController.view, at: 0)
        sitePickerViewController.didMove(toParent: self)
    }

    private func makeSitePickerViewController(for blog: Blog) -> SitePickerViewController {
        let sitePickerViewController = SitePickerViewController(blog: blog, meScenePresenter: meScenePresenter)

        sitePickerViewController.onBlogSwitched = { [weak self] blog in

            guard let self = self else {
                return
            }

            if !blog.isAccessibleThroughWPCom() && self.isShowingDashboard {
                self.segmentedControl.selectedSegmentIndex = Section.siteMenu.rawValue
                self.segmentedControl.sendActions(for: .valueChanged)
            }

            self.updateSegmentedControl(for: blog)
            self.updateChildViewController(for: blog)
        }

        return sitePickerViewController
    }

    private func updateChildViewController(for blog: Blog) {
        guard let section = Section(rawValue: segmentedControl.selectedSegmentIndex) else {
            return
        }

        switch section {
        case .siteMenu:
            blogDetailsViewController?.blog = blog
            blogDetailsViewController?.showInitialDetailsForBlog()
            blogDetailsViewController?.tableView.reloadData()
            blogDetailsViewController?.preloadMetadata()
        case .dashboard:
            // TODO: Update blog dashboard vc
            break
        }
    }

    func presentCreateSheet() {
        blogDetailsViewController?.createButtonCoordinator?.showCreateSheet()
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

        guard let blog = blogService.lastUsedOrFirstBlog() else {
            return
        }

        self.blog = blog
    }

    private enum Constants {
        static let segmentedControlXOffset: CGFloat = 20
        static let segmentedControlYOffset: CGFloat = 24
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
}

// MARK: - My site detail views
extension MySiteViewController {

    func showDetailView(for section: BlogDetailsSubsection) {
        blogDetailsViewController?.showDetailView(for: section)
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
