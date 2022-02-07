import Foundation
import UIKit
import CoreData

class BlogDashboardViewModel {
    private weak var viewController: BlogDashboardViewController?

    enum Section: Int, CaseIterable {
        case quickActions
        case posts
    }

    // FIXME: temporary placeholder
    private let quickActions = ["Stats", "Posts", "Media", "Pages"]
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

            guard let section = Section(rawValue: indexPath.section) else {
                return UICollectionViewCell()
            }

            switch section {
            case .quickLinks:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: QuickLinksHostCell.defaultReuseID, for: indexPath) as? QuickLinksHostCell
                cell?.hostedView = QuickLinksView(title: self.quickLinks[indexPath.item])
                return cell
            case .posts:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DashboardPostsCardCell.defaultReuseID, for: indexPath) as? DashboardPostsCardCell
                cell?.configure(viewController, blog: blog)
                return cell
            default:
                break
            }
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

        service.fetch(cards: ["posts", "todays_stats"], forBlogID: dotComID, success: { [weak self] _ in
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
