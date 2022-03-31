import UIKit
import WordPressShared

typealias DashboardCollectionViewCell = UICollectionViewCell & Reusable & BlogDashboardCardConfigurable

protocol BlogDashboardCardConfigurable {
    func configure(blog: Blog, viewController: BlogDashboardViewController?, apiResponse: BlogDashboardRemoteEntity?)
}

final class BlogDashboardViewController: UIViewController {

    var blog: Blog

    private lazy var viewModel: BlogDashboardViewModel = {
        BlogDashboardViewModel(viewController: self, blog: blog)
    }()

    lazy var collectionView: IntrinsicCollectionView = {
        let collectionView = IntrinsicCollectionView(frame: .zero, collectionViewLayout: createLayout())
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()

    /// The "My Site" main scroll view
    var mySiteScrollView: UIScrollView? {
        return view.superview?.superview as? UIScrollView
    }

    @objc init(blog: Blog) {
        self.blog = blog
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
        addNewPostAvailableObserver()
        viewModel.viewDidLoad()

        // Force the view to update its layout immediately, so the content size is calculated correctly
        collectionView.layoutIfNeeded()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        viewModel.loadCards()
        QuickStartTourGuide.shared.currentTourOrigin = .blogDashboard
        startAlertTimer()

        WPAnalytics.track(.mySiteDashboardShown)
    }

    override func viewWillDisappear(_ animated: Bool) {
        stopAlertTimer()
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
        viewModel.loadCardsFromCache()
        viewModel.loadCards()
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
        collectionView.isScrollEnabled = false
        collectionView.backgroundColor = .listBackground
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
        NotificationCenter.default.addObserver(self, selector: #selector(loadCards), name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    private func addQuickStartObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(loadCardsFromCache), name: .QuickStartTourElementChangedNotification, object: nil)
    }

    private func addNewPostAvailableObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(loadCardsFromCache), name: .newPostAvailableForDashboard, object: nil)
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

    /// Load card from cache if view is appearing
    @objc private func loadCardsFromCache() {
        guard view.superview != nil else {
            return
        }

        viewModel.loadCardsFromCache()
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
        let isQuickActionSection = viewModel.card(for: sectionIndex) == .quickActions
        let isLastSection = collectionView.numberOfSections == (sectionIndex + 1)
        let horizontalInset = isQuickActionSection ? 0 : Constants.sectionInset
        let bottomInset = isLastSection ? Constants.sectionInset : 0
        section.contentInsets = NSDirectionalEdgeInsets(top: Constants.sectionInset,
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
            return
        }

        if quickStartGuide.tourInProgress {
            // If tour is in progress, show notice regardless of quickstart is shown in dashboard or my site
            quickStartGuide.suggest(tourToSuggest, for: blog)
        }
        else {
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
        static let sectionInset: CGFloat = 20
        static let cellSpacing: CGFloat = 20
    }
}
