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

        service.fetch(blog: blog, completion: { [weak self] cards in
            self?.viewController?.stopLoading()
            self?.updateCurrentCards(cards: cards)
            completion?()
        }, failure: { [weak self] cards in
            self?.viewController?.stopLoading()
            self?.loadingFailure()
            self?.updateCurrentCards(cards: cards)

            completion?()
        })
    }

    func loadCardsFromCache() {
        let cards = service.fetchLocal(blog: blog)
        updateCurrentCards(cards: cards)
    }

    func dashboardItem(for sectionIndex: Int) -> DashboardItem? {
        dataSource?.itemIdentifier(for: IndexPath(row: 0, section: sectionIndex))
    }
}

// MARK: - Private methods

private extension BlogDashboardViewModel {

    func updateCurrentCards(cards: [DashboardItem]) {
        let snapshot = createSnapshot(from: cards)
        let scrollView = viewController?.mySiteScrollView
        let position = scrollView?.contentOffset

        dataSource?.apply(snapshot, animatingDifferences: false) { [weak self] in
            guard let scrollView = scrollView, let position = position else {
                return
            }

            self?.scroll(scrollView, to: position)
        }
    }

    func createSnapshot(from cards: [DashboardItem]) -> DashboardSnapshot {
        var snapshot = DashboardSnapshot()
        snapshot.appendSections(DashboardSection.allCases)
        snapshot.appendItems([.quickActions], toSection: .quickActions)
        snapshot.appendItems(cards, toSection: .cards)
        return snapshot
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
