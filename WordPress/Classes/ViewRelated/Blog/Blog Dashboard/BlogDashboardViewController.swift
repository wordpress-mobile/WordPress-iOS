import UIKit

final class BlogDashboardViewController: UIViewController {

    var blog: Blog?

    private var viewModel: BlogDashboardViewModel!

    typealias QuickLinksHostCell = HostCollectionViewCell<QuickLinksView>

    lazy var collectionView: IntrinsicCollectionView = {
        let collectionView = IntrinsicCollectionView(frame: .zero, collectionViewLayout: createLayout())
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        viewModel = BlogDashboardViewModel(viewController: self, blog: blog!)
        viewModel.start()
        addHeightObservers()

        // Force the view to update its layout immediately, so the content size is calculated correctly
        collectionView.layoutIfNeeded()
    }

    private func setupCollectionView() {
        collectionView.isScrollEnabled = false
        collectionView.backgroundColor = .listBackground
        collectionView.register(QuickLinksHostCell.self, forCellWithReuseIdentifier: QuickLinksHostCell.defaultReuseID)
        collectionView.register(DashboardPostsCardCell.self, forCellWithReuseIdentifier: DashboardPostsCardCell.defaultReuseID)

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

// MARK: - Collection view layout

extension BlogDashboardViewController {

    private func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout {
            (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in

            return self.createQuickLinksSection()
        }
        return layout
    }

    private func createQuickLinksSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                              heightDimension: .estimated(Constants.estimatedHeight))

        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let group = NSCollectionLayoutGroup.vertical(layoutSize: itemSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: Constants.sectionInset,
                                                        leading: Constants.sectionInset,
                                                        bottom: Constants.sectionInset,
                                                        trailing: Constants.sectionInset)
        section.interGroupSpacing = Constants.interGroupSpacing

        return section
    }
}

extension BlogDashboardViewController {

    private enum Constants {
        static let estimatedHeight: CGFloat = 44
        static let sectionInset: CGFloat = 16
        static let interGroupSpacing: CGFloat = 8
    }
}
