import UIKit

final class BlogDashboardViewController: UIViewController {

    enum Section: CaseIterable {
        case quickLinks
    }

    // FIXME: temporary placeholder
    private let quickLinks = ["Quick Links"]

    typealias DataSource = UICollectionViewDiffableDataSource<Section, String>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, String>
    typealias QuickLinksHostCell = HostCollectionViewCell<QuickLinksView>

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()

    private lazy var dataSource: DataSource = {
        return DataSource(collectionView: collectionView) { collectionView, indexPath, identifier in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: QuickLinksHostCell.defaultReuseID, for: indexPath) as? QuickLinksHostCell
            cell?.hostedView = QuickLinksView(title: self.quickLinks[indexPath.item])
            return cell
        }
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        applySnapshotForInitialData()
    }

    private func setupCollectionView() {
        collectionView.backgroundColor = .listBackground
        collectionView.register(QuickLinksHostCell.self, forCellWithReuseIdentifier: QuickLinksHostCell.defaultReuseID)

        view.addSubview(collectionView)
        view.pinSubviewToAllEdges(collectionView)
    }

    private func applySnapshotForInitialData() {
        var snapshot = Snapshot()
        snapshot.appendSections(Section.allCases)
        snapshot.appendItems(quickLinks, toSection: Section.quickLinks)
        dataSource.apply(snapshot, animatingDifferences: false)
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
