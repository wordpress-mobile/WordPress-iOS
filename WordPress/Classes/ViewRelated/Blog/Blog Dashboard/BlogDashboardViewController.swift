import UIKit
import WordPressShared

typealias DashboardCollectionViewCell = UICollectionViewCell & Reusable & BlogDashboardCardConfigurable

protocol BlogDashboardCardConfigurable {
    func configure(blog: Blog, viewController: BlogDashboardViewController?, apiResponse: BlogDashboardRemoteEntity?)
}

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
        setupNavigation()
        setupCollectionView()
        addHeightObservers()
        addWillEnterForegroundObserver()
        addQuickStartObserver()
        viewModel.viewDidLoad()

        // Force the view to update its layout immediately, so the content size is calculated correctly
        collectionView.layoutIfNeeded()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        viewModel.loadCards()
        QuickStartTourGuide.shared.currentEntryPoint = .blogDashboard
        startAlertTimer()

        WPAnalytics.track(.mySiteDashboardShown)
    }

    override func viewWillDisappear(_ animated: Bool) {
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
        viewModel.blog = blog
        BlogDashboardAnalytics.shared.reset()
        viewModel.loadCardsFromCache()
        viewModel.loadCards()
    }

    @objc func refreshControlPulled() {
        pulledToRefresh { [weak self] in
            self?.refreshControl.endRefreshing()
        }
    }

    func pulledToRefresh(completion: (() -> Void)? = nil) {
        viewModel.loadCards {
            completion?()
        }
    }

    private func setupNavigation() {
        title = Strings.home
    }

    private func setupCollectionView() {
        collectionView.isScrollEnabled = !embeddedInScrollView
        collectionView.backgroundColor = .listBackground
        collectionView.register(DashboardQuickActionsCardCell.self, forCellWithReuseIdentifier: DashboardQuickActionsCardCell.self.defaultReuseID)
        DashboardCard.allCases.forEach {
            collectionView.register($0.cell, forCellWithReuseIdentifier: $0.cell.defaultReuseID)
        }

        view.addSubview(collectionView)
        view.pinSubviewToAllEdges(collectionView)
    }

    private func addHeightObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateCollectionViewHeight(notification:)), name: .postCardTableViewSizeChanged, object: nil)
    }

    private func addWillEnterForegroundObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    private func addQuickStartObserver() {
        NotificationCenter.default.addObserver(forName: .QuickStartTourElementChangedNotification, object: nil, queue: nil) { [weak self] notification in

            guard let self = self else {
                return
            }

            if let info = notification.userInfo,
               let element = info[QuickStartTourGuide.notificationElementKey] as? QuickStartTourElement {

                switch element {
                case .setupQuickStart, .removeQuickStart:
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
        let horizontalInset = isQuickActionSection ? 0 : Constants.horizontalSectionInset
        let bottomInset = isQuickActionSection ? 0 : Constants.verticalSectionInset
        section.contentInsets = NSDirectionalEdgeInsets(top: Constants.verticalSectionInset,
                                                        leading: horizontalInset,
                                                        bottom: bottomInset,
                                                        trailing: horizontalInset)

        section.interGroupSpacing = Constants.cellSpacing

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
}

extension BlogDashboardViewController {

    private enum Strings {
        static let home = NSLocalizedString("Home", comment: "Title for the dashboard screen.")
        static let failureTitle = NSLocalizedString("Couldn't update. Check that you're online and refresh.", comment: "Content show when the dashboard fails to load")
        static let dismiss = NSLocalizedString("Dismiss", comment: "Action shown in a bottom notice to dismiss it.")
    }


    private enum Constants {
        static let estimatedWidth: CGFloat = 100
        static let estimatedHeight: CGFloat = 44
        static let horizontalSectionInset: CGFloat = 20
        static let verticalSectionInset: CGFloat = 20
        static let cellSpacing: CGFloat = 20
    }
}

// MARK: - UI Popover Delegate

/// This view controller may host a `DashboardPromptsCardCell` that requires presenting a `MenuSheetViewController`,
/// a fallback implementation of `UIMenu` for iOS 13. For more details, see the docs on `MenuSheetViewController`.
///
/// NOTE: This should be removed once we drop support for iOS 13.
///
extension BlogDashboardViewController: UIPopoverPresentationControllerDelegate {
    // Force popover views to be presented as a popover (instead of being presented as a form sheet on iPhones).
    public func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
}
