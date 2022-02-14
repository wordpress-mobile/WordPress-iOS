import Foundation
import UIKit
import CoreData

typealias DashboardSnapshot = NSDiffableDataSourceSnapshot<DashboardCardSection, DashboardCardModel>
typealias DashboardDataSource = UICollectionViewDiffableDataSource<DashboardCardSection, DashboardCardModel>

class BlogDashboardViewModel {
    private weak var viewController: BlogDashboardViewController?

    private let managedObjectContext: NSManagedObjectContext
    var blog: Blog

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

            if let cellConfigurable = cell as? BlogDashboardCardConfigurable {
                cellConfigurable.configure(blog: blog, viewController: viewController, dataModel: identifier.cellViewModel)
            }

            return cell

        }
    }()

    init(viewController: BlogDashboardViewController, managedObjectContext: NSManagedObjectContext = ContextManager.shared.mainContext, blog: Blog) {
        self.viewController = viewController
        self.managedObjectContext = managedObjectContext
        self.blog = blog
    }

    /// Apply the initial configuration when the view loaded
    func viewDidLoad() {
        // This is necessary when using an IntrinsicCollectionView
        // Otherwise, the collection view will never update its height
        applySnapshotForInitialData()
    }

    /// Call the API to return cards for the current blog
    func loadCards() {
        guard let dotComID = blog.dotComID?.intValue else {
            return
        }

        viewController?.showLoading()

        service.fetch(wpComID: dotComID, completion: { [weak self] snapshot in
            self?.viewController?.stopLoading()
            self?.apply(snapshot: snapshot)
        })
    }

    func applySnapshotForInitialData() {
        let snapshot = DashboardSnapshot()
        apply(snapshot: snapshot)
    }

    func card(for sectionIndex: Int) -> DashboardCard? {
        dataSource?.itemIdentifier(for: IndexPath(row: 0, section: sectionIndex))?.id
    }
}

// MARK: - Private methods

private extension BlogDashboardViewModel {

    func apply(snapshot: DashboardSnapshot) {
        dataSource?.apply(snapshot, animatingDifferences: false)
    }
}
