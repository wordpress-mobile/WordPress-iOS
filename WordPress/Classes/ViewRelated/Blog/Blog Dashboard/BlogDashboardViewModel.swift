import Foundation
import UIKit
import CoreData

class BlogDashboardViewModel {
    private weak var viewController: BlogDashboardViewController?

    enum Section: CaseIterable {
        case quickLinks
        case posts
    }

    // FIXME: temporary placeholder
    private let quickLinks = ["Quick Links"]
    private let posts = ["Posts"]

    typealias DataSource = UICollectionViewDiffableDataSource<Section, String>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, String>
    typealias QuickLinksHostCell = HostCollectionViewCell<QuickLinksView>

    private let managedObjectContext: NSManagedObjectContext
    private let blog: Blog

    private lazy var service: DashboardServiceRemote = {
        let api = WordPressComRestApi.defaultApi(in: managedObjectContext,
                                                 localeKey: WordPressComRestApi.LocaleKeyV2)

        return DashboardServiceRemote(wordPressComRestApi: api)
    }()

    private lazy var dataSource: DataSource? = {
        guard let viewController = viewController else {
            return nil
        }

        return DataSource(collectionView: viewController.collectionView) { [unowned self] collectionView, indexPath, identifier in
            switch identifier {
            case self.quickLinks.first:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: QuickLinksHostCell.defaultReuseID, for: indexPath) as? QuickLinksHostCell
                cell?.hostedView = QuickLinksView(title: self.quickLinks[indexPath.item])
                return cell
            case self.posts.first:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DashboardPostsCardCell.defaultReuseID, for: indexPath) as? DashboardPostsCardCell
                cell?.configure(viewController, blog: blog)
                return cell
            default:
                break
            }
            return UICollectionViewCell()
        }
    }()

    init(viewController: BlogDashboardViewController, managedObjectContext: NSManagedObjectContext = ContextManager.shared.mainContext, blog: Blog) {
        self.viewController = viewController
        self.managedObjectContext = managedObjectContext
        self.blog = blog
    }

    /// Call the API to return cards for the current blog
    func start() {
        guard let dotComID = blog.dotComID?.intValue else {
            return
        }

        viewController?.showLoading()
        applySnapshotForInitialData()

        let cardsToFetch: [String] = DashboardCard.allCases
            .filter { $0.isRemote }
            .map { $0.rawValue }

        service.fetch(cards: cardsToFetch, forBlogID: dotComID, success: { [weak self] _ in
            self?.viewController?.stopLoading()
            self?.applySnapshotWithMockedData()
        }, failure: { _ in

        })
    }
}

// MARK: - Private methods

private extension BlogDashboardViewModel {
    // This is necessary when using an IntrinsicCollectionView
    // Otherwise, the collection view will never update its height
    func applySnapshotForInitialData() {
        let snapshot = Snapshot()
        dataSource?.apply(snapshot, animatingDifferences: false)
    }

    func applySnapshotWithMockedData() {
        var snapshot = Snapshot()
        snapshot.appendSections(Section.allCases)
        snapshot.appendItems(quickLinks, toSection: Section.quickLinks)
        snapshot.appendItems(posts, toSection: Section.posts)
        dataSource?.apply(snapshot, animatingDifferences: false)
    }
}
