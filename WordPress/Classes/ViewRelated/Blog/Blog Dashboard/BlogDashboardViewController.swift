import UIKit

typealias DashboardCollectionViewCell = UICollectionViewCell & Reusable & BlogDashboardCardConfigurable

protocol BlogDashboardCardConfigurable {
    func configure(blog: Blog, viewController: BlogDashboardViewController?, dataModel: NSDictionary?)
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

    lazy var activityIndicatorView: UIActivityIndicatorView = {
        UIActivityIndicatorView()
    }()

    init(blog: Blog) {
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
        setupCollectionView()
        viewModel.start()
        addHeightObservers()

        // Force the view to update its layout immediately, so the content size is calculated correctly
        collectionView.layoutIfNeeded()
    }

    func showLoading() {
        view.addSubview(activityIndicatorView)
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        view.pinSubviewAtCenter(activityIndicatorView)
        activityIndicatorView.startAnimating()
    }

    func stopLoading() {
        activityIndicatorView.stopAnimating()
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

    @objc private func updateCollectionViewHeight(notification: Notification) {
        collectionView.collectionViewLayout.invalidateLayout()
    }
}

// MARK: - Quick Actions

extension BlogDashboardViewController {

    func showStats() {
        // TODO: Track event / source

        let controller = StatsViewController()
        controller.blog = blog
        controller.navigationItem.largeTitleDisplayMode = .never
        showDetailViewController(controller, sender: self)

        QuickStartTourGuide.shared.visited(.stats)
    }

    func showPostList() {
        // TODO: Track event / source

        let controller = PostListViewController.controllerWithBlog(blog)
        controller.navigationItem.largeTitleDisplayMode = .never
        showDetailViewController(controller, sender: self)

        QuickStartTourGuide.shared.visited(.blogDetailNavigation)
    }

    func showMediaLibrary() {
        // TODO: Track event / source

        let controller = MediaLibraryViewController(blog: blog)
        controller.navigationItem.largeTitleDisplayMode = .never
        showDetailViewController(controller, sender: self)

        QuickStartTourGuide.shared.visited(.blogDetailNavigation)
    }

    func showPageList() {
        // TODO: Track event / source

        let controller = PageListViewController.controllerWithBlog(blog)
        controller.navigationItem.largeTitleDisplayMode = .never
        showDetailViewController(controller, sender: self)

        QuickStartTourGuide.shared.visited(.pages)
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
        return section
    }
}

extension BlogDashboardViewController {

    private enum Constants {
        static let estimatedWidth: CGFloat = 100
        static let estimatedHeight: CGFloat = 44
        static let sectionInset: CGFloat = 20
        static let interGroupSpacing: CGFloat = 12
    }
}
