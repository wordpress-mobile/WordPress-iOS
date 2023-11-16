import UIKit
import WordPressShared

typealias DashboardCollectionViewCell = UICollectionViewCell & Reusable & BlogDashboardCardConfigurable

final class BlogDashboardViewController: UIViewController {

    var blog: Blog
    var presentedPostStatus: String?

    private let embeddedInScrollView: Bool

    private lazy var viewModel: BlogDashboardViewModel = {
        BlogDashboardViewModel(viewController: self, blog: blog)
    }()

    lazy var collectionView: DynamicHeightCollectionView = {
        let collectionView = DynamicHeightCollectionView(frame: .zero, collectionViewLayout: createLayout())
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        if !embeddedInScrollView {
            collectionView.refreshControl = refreshControl
        }
        return collectionView
    }()

    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshControlPulled), for: .valueChanged)
        return refreshControl
    }()

    /// The "My Site" parent view controller
    var mySiteViewController: MySiteViewController? {
        return parent as? MySiteViewController
    }

    /// The "My Site" main scroll view
    var mySiteScrollView: UIScrollView? {
        return view.superview?.superview as? UIScrollView
    }

    @objc init(blog: Blog, embeddedInScrollView: Bool) {
        self.blog = blog
        self.embeddedInScrollView = embeddedInScrollView
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureDefaultNavigationBarAppearance()
        setupNavigation()
        setupCollectionView()
        addHeightObservers()
        addWillEnterForegroundObserver()
        addQuickStartObserver()
        viewModel.viewDidLoad()

        // Force the view to update its layout immediately, so the content size is calculated correctly
        collectionView.layoutIfNeeded()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        viewModel.viewWillAppear()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        viewModel.loadCards { [weak self] cards in
            guard let trackCardViewed = self?.trackCardViewed else {
                return
            }
            cards.forEach(trackCardViewed)
        }
        QuickStartTourGuide.shared.currentEntryPoint = .blogDashboard
        startAlertTimer()

        WPAnalytics.track(.mySiteDashboardShown)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        viewModel.viewWillDisappear()
        stopAlertTimer()
    }

    func reloadCardsLocally() {
        viewModel.loadCardsFromCache()
    }

    /// If you want to give any feedback when the dashboard
    /// started loading just change this method.
    /// For not, it will be transparent
    ///
    func showLoading() { }

    /// If you want to give any feedback when the dashboard
    /// stops loading just change this method.
    ///
    func stopLoading() { }

    func loadingFailure() {
        displayActionableNotice(title: Strings.failureTitle, actionTitle: Strings.dismiss)
    }

    func update(blog: Blog) {
        guard self.blog.dotComID != blog.dotComID else {
            return
        }

        self.blog = blog
        self.viewModel.update(blog: blog)
    }

    @objc func refreshControlPulled() {
        pulledToRefresh { [weak self] in
            self?.refreshControl.endRefreshing()
        }
    }

    func pulledToRefresh(completion: (() -> Void)? = nil) {
        viewModel.loadCards { _ in
            completion?()
        }
    }

    private func setupNavigation() {
        title = Strings.home
    }

    private func setupCollectionView() {
        collectionView.isScrollEnabled = !embeddedInScrollView
        collectionView.backgroundColor = .listBackground
        collectionView.register(DashboardMigrationSuccessCell.self, forCellWithReuseIdentifier: DashboardMigrationSuccessCell.self.defaultReuseID)
        collectionView.register(DashboardQuickActionsCardCell.self, forCellWithReuseIdentifier: DashboardQuickActionsCardCell.self.defaultReuseID)
        DashboardCard.allCases.forEach {
            collectionView.register($0.cell, forCellWithReuseIdentifier: $0.cell.defaultReuseID)
        }

        view.addSubview(collectionView)
        view.pinSubviewToAllEdges(collectionView)
    }

    private func addHeightObservers() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.updateCollectionViewHeight(notification:)),
                                               name: .dashboardCardTableViewSizeChanged,
                                               object: nil)
    }

    private func addWillEnterForegroundObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    private func addQuickStartObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleQuickStartTourElementChangedNotification(_:)), name: .QuickStartTourElementChangedNotification, object: nil)
    }

    @objc private func handleQuickStartTourElementChangedNotification(_ notification: Foundation.Notification) {
        if let info = notification.userInfo,
           let element = info[QuickStartTourGuide.notificationElementKey] as? QuickStartTourElement {

            switch element {
            case .setupQuickStart:
                self.loadCardsFromCache()
                self.displayQuickStart()
            case .updateQuickStart:
                self.loadCardsFromCache()
            case .stats, .mediaScreen:
                if self.embeddedInScrollView {
                    self.mySiteScrollView?.scrollToTop(animated: true)
                } else {
                    self.collectionView.scrollToTop(animated: true)
                }
            default:
                break
            }
        }
    }

    @objc private func updateCollectionViewHeight(notification: Notification) {
        collectionView.collectionViewLayout.invalidateLayout()
    }

    /// Load cards if view is appearing
    @objc private func loadCards() {
        guard view.superview != nil else {
            return
        }

        viewModel.loadCards()
    }

    /// Load card from cache
    @objc private func loadCardsFromCache() {
        viewModel.loadCardsFromCache()
    }

    @objc private func willEnterForeground() {
        BlogDashboardAnalytics.shared.reset()
        loadCards()
    }

    private func trackCardViewed(_ card: DashboardCardModel) {
        guard let event = card.cardType.viewedAnalytic else {
            return
        }
        WPAnalytics.track(event, properties: [WPAppAnalyticsKeyTabSource: "dashboard"])
    }
}

// MARK: - Collection view layout

extension BlogDashboardViewController {

    private func createLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { [weak self] sectionIndex, layoutEnvironment in
            self?.createLayoutSection(for: sectionIndex)
        }
    }

    private func createLayoutSection(for sectionIndex: Int) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                              heightDimension: .estimated(Constants.estimatedHeight))

        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let group = NSCollectionLayoutGroup.vertical(layoutSize: itemSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        let isQuickActionSection = viewModel.isQuickActionsSection(sectionIndex)
        let isMigrationSuccessCardSection = viewModel.isMigrationSuccessCardSection(sectionIndex)
        let horizontalInset = Constants.horizontalSectionInset
        let bottomInset = isQuickActionSection || isMigrationSuccessCardSection ? 0 : Constants.bottomSectionInset
        section.contentInsets = NSDirectionalEdgeInsets(top: Constants.verticalSectionInset,
                                                        leading: horizontalInset,
                                                        bottom: bottomInset,
                                                        trailing: horizontalInset)

        section.interGroupSpacing = Constants.cellSpacing
        section.contentInsetsReference = .readableContent

        return section
    }
}

private var alertWorkItem: DispatchWorkItem?

extension BlogDashboardViewController {
    @objc func startAlertTimer() {
        let newWorkItem = DispatchWorkItem { [weak self] in
            self?.showNoticeAsNeeded()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: newWorkItem)
        alertWorkItem = newWorkItem
    }

    @objc func stopAlertTimer() {
        alertWorkItem?.cancel()
        alertWorkItem = nil
    }

    private func showNoticeAsNeeded() {
        let quickStartGuide = QuickStartTourGuide.shared

        guard let tourToSuggest = quickStartGuide.tourToSuggest(for: blog) else {
            quickStartGuide.showCongratsNoticeIfNeeded(for: blog)
            return
        }

        if quickStartGuide.tourInProgress {
            // If tour is in progress, show notice regardless of quickstart is shown in dashboard or my site
            quickStartGuide.suggest(tourToSuggest, for: blog)
        } else {
            guard shouldShowQuickStartChecklist() else {
                return
            }
            // Show initial notice only if quick start is shown in the dashboard
            quickStartGuide.suggest(tourToSuggest, for: blog)
        }
    }

    private func shouldShowQuickStartChecklist() -> Bool {
        return DashboardCard.quickStart.shouldShow(for: blog)
    }

    private func displayQuickStart() {
        let currentCollections = QuickStartFactory.collections(for: blog)
        guard let collectionToShow = currentCollections.first else {
            return
        }
        let checklist = QuickStartChecklistViewController(blog: blog, collection: collectionToShow)
        let navigationViewController = UINavigationController(rootViewController: checklist)
        present(navigationViewController, animated: true)

        QuickStartTourGuide.shared.visited(.checklist)
    }
}

extension BlogDashboardViewController {

    private enum Strings {
        static let home = NSLocalizedString("Home", comment: "Title for the dashboard screen.")
        static let failureTitle = NSLocalizedString("Couldn't update. Check that you're online and refresh.", comment: "Content show when the dashboard fails to load")
        static let dismiss = NSLocalizedString(
            "blogDashboard.dismiss",
            value: "Dismiss",
            comment: "Action shown in a bottom notice to dismiss it."
        )
    }


    private enum Constants {
        static let estimatedWidth: CGFloat = 100
        static let estimatedHeight: CGFloat = 44
        static let horizontalSectionInset: CGFloat = 12
        static let verticalSectionInset: CGFloat = 20
        static var bottomSectionInset: CGFloat {
            // Make room for FAB on iPhone
            WPDeviceIdentification.isiPad() ? verticalSectionInset : 86
        }
        static let cellSpacing: CGFloat = 20
    }
}

// MARK: - Helper functions

private extension Collection where Element == DashboardCardModel {
    var hasPrompts: Bool {
        contains(where: { $0.cardType == .prompts })
    }
}

// MARK: - Jetpack Remote Install Delegate

extension BlogDashboardViewController: JetpackRemoteInstallDelegate {
    func jetpackRemoteInstallCompleted() {
        dismiss(animated: true) {
            self.pulledToRefresh()
        }
    }

    func jetpackRemoteInstallCanceled() {
        dismiss(animated: true) {
            self.pulledToRefresh()
        }
    }

    func jetpackRemoteInstallWebviewFallback() {
        // No op
    }
}
