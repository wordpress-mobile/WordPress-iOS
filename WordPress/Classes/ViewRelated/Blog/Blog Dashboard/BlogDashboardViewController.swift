import UIKit

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
        viewModel.viewDidLoad()

        // Force the view to update its layout immediately, so the content size is calculated correctly
        collectionView.layoutIfNeeded()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        viewModel.loadCards()
        QuickStartTourGuide.shared.currentTourOrigin = .blogDashboard
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
        NotificationCenter.default.addObserver(self, selector: #selector(toggleQuickStart), name: .QuickStartTourElementChangedNotification, object: nil)    }

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

    /// Show or hide Quick Start if needed
    @objc private func toggleQuickStart() {
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
        let horizontalInset = isQuickActionSection ? 0 : Constants.sectionInset
        section.contentInsets = NSDirectionalEdgeInsets(top: Constants.sectionInset,
                                                        leading: horizontalInset,
                                                        bottom: 0,
                                                        trailing: horizontalInset)

        section.interGroupSpacing = Constants.cellSpacing

        return section
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
