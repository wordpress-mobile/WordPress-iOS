import Foundation
import UIKit
import CoreData

enum DashboardSection: CaseIterable {
    case quickActions
    case cards
}

enum DashboardItem: Hashable {
    case quickActions
    case cards(DashboardCardModel)
}

typealias DashboardSnapshot = NSDiffableDataSourceSnapshot<DashboardSection, DashboardItem>
typealias DashboardDataSource = UICollectionViewDiffableDataSource<DashboardSection, DashboardItem>

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

        return DashboardDataSource(collectionView: viewController.collectionView) { [unowned self] collectionView, indexPath, item in

            var cellType: DashboardCollectionViewCell.Type
            var apiResponse: BlogDashboardRemoteEntity?
            switch item {
            case .quickActions:
                cellType = DashboardQuickActionsCardCell.self
            case .cards(let cardModel):
                cellType = cardModel.cardType.cell
                apiResponse = cardModel.apiResponse
            }
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellType.defaultReuseID, for: indexPath)

            if let cellConfigurable = cell as? BlogDashboardCardConfigurable {
                cellConfigurable.configure(blog: blog, viewController: viewController, apiResponse: apiResponse)
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
        loadCardsFromCache()
    }

    /// Call the API to return cards for the current blog
    func loadCards(completion: (() -> Void)? = nil) {
        viewController?.showLoading()

        service.fetch(blog: blog, completion: { [weak self] snapshot in
            self?.viewController?.stopLoading()
            self?.apply(snapshot: snapshot)
            completion?()
        }, failure: { [weak self] snapshot in
            self?.viewController?.stopLoading()
            self?.loadingFailure()

            if let snapshot = snapshot {
                self?.apply(snapshot: snapshot)
            }

            completion?()
        })
    }

    func loadCardsFromCache() {
        let snapshot = service.fetchLocal(blog: blog)
        apply(snapshot: snapshot)
    }

    func dashboardItem(for sectionIndex: Int) -> DashboardItem? {
        dataSource?.itemIdentifier(for: IndexPath(row: 0, section: sectionIndex))
    }
}

// MARK: - Private methods

private extension BlogDashboardViewModel {

    func apply(snapshot: DashboardSnapshot) {
        let scrollView = viewController?.mySiteScrollView
        let position = scrollView?.contentOffset

        dataSource?.apply(snapshot, animatingDifferences: false) { [weak self] in
            guard let scrollView = scrollView, let position = position else {
                return
            }

            self?.scroll(scrollView, to: position)
        }
    }

    func scroll(_ scrollView: UIScrollView, to position: CGPoint) {
        if position.y > 0 {
            scrollView.setContentOffset(position, animated: false)
        }
    }
}

// MARK: - Ghost/Skeleton cards and failures

private extension BlogDashboardViewModel {

    func isGhostCardsBeingShown() -> Bool {
        let ghostCells = dataSource?.snapshot().itemIdentifiers.filter({ item in
            switch item {
            case .quickActions:
                return false
            case .cards(let cardModel):
                return cardModel.cardType == .ghost
            }
        })
        let ghostCellsCount = ghostCells?.count ?? 0
        return ghostCellsCount > 0
    }

    func loadingFailure() {
        if blog.dashboardState.hasCachedData {
            viewController?.loadingFailure()
        }
    }
}
