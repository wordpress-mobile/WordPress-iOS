import Foundation
import UIKit
import CoreData

typealias DashboardSnapshot = NSDiffableDataSourceSnapshot<DashboardCardSection, DashboardCardModel>
typealias DashboardDataSource = UICollectionViewDiffableDataSource<DashboardCardSection, DashboardCardModel>

class BlogDashboardViewModel {
    private weak var viewController: BlogDashboardViewController?

    enum Section: CaseIterable {
        case quickLinks
        case posts
    }

    // FIXME: temporary placeholder
    private let quickLinks = ["Quick Links"]
    private let posts = ["Posts"]

    typealias QuickLinksHostCell = HostCollectionViewCell<QuickLinksView>

    private let managedObjectContext: NSManagedObjectContext
    private let blog: Blog

    private lazy var service: BlogDashboardService = {
        return BlogDashboardService(managedObjectContext: managedObjectContext)
    }()

    private lazy var dataSource: DashboardDataSource? = {
        guard let viewController = viewController else {
            return nil
        }

        return DashboardDataSource(collectionView: viewController.collectionView) { [unowned self] collectionView, indexPath, identifier in

            let cellType = identifier.id.cell
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellType.defaultReuseID, for: indexPath)
            (cell as? BlogDashboardCardConfigurable)?.configure(blog: blog, viewController: viewController, dataModel: identifier.cellViewModel)
            return cell

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

        service.fetch(wpComID: dotComID, completion: { [weak self] snapshot in
            self?.viewController?.stopLoading()
            self?.apply(snapshot: snapshot)
        })
    }
}

// MARK: - Private methods

private extension BlogDashboardViewModel {
    // This is necessary when using an IntrinsicCollectionView
    // Otherwise, the collection view will never update its height
    func applySnapshotForInitialData() {
        let snapshot = DashboardSnapshot()
        dataSource?.apply(snapshot, animatingDifferences: false)
    }

    func apply(snapshot: DashboardSnapshot) {
        dataSource?.apply(snapshot, animatingDifferences: false)
    }
}
