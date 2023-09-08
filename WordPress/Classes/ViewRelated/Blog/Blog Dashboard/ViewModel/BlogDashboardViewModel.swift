import Foundation
import UIKit
import CoreData

enum DashboardSection: Int, CaseIterable {
    case migrationSuccess
    case quickActions
    case cards
}

typealias BlogID = Int

enum DashboardItem: Hashable {
    case migrationSuccess
    case quickActions(BlogID)
    case cards(DashboardCardModel)
}

typealias DashboardSnapshot = NSDiffableDataSourceSnapshot<DashboardSection, DashboardItem>
typealias DashboardDataSource = UICollectionViewDiffableDataSource<DashboardSection, DashboardItem>

final class BlogDashboardViewModel {
    private weak var viewController: BlogDashboardViewController?

    private let managedObjectContext: NSManagedObjectContext

    private var blog: Blog

    private var currentCards: [DashboardCardModel] = []

    private lazy var draftStatusesToSync: [String] = {
        return PostListFilter.draftFilter().statuses.strings
    }()

    private lazy var scheduledStatusesToSync: [String] = {
        return PostListFilter.scheduledFilter().statuses.strings
    }()

    private lazy var pageStatusesToSync: [String] = {
        return PostListFilter.allNonTrashedFilter().statuses.strings
    }()

    private lazy var service: BlogDashboardService = {
        return BlogDashboardService(managedObjectContext: managedObjectContext)
    }()

    private lazy var dataSource: DashboardDataSource? = {
        guard let viewController = viewController else {
            return nil
        }

        return DashboardDataSource(collectionView: viewController.collectionView) { [unowned self, unowned viewController] collectionView, indexPath, item in

            var cellType: DashboardCollectionViewCell.Type
            var cardType: DashboardCard
            var apiResponse: BlogDashboardRemoteEntity?
            switch item {
            case .quickActions:
                let cellType = DashboardQuickActionsCardCell.self
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellType.defaultReuseID, for: indexPath) as! DashboardQuickActionsCardCell
                cell.configure(viewModel: quickActionsViewModel, viewController: viewController)
                return cell
            case .cards(let cardModel):
                let cellType = cardModel.cardType.cell
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellType.defaultReuseID, for: indexPath)
                if var cellConfigurable = cell as? BlogDashboardCardConfigurable {
                    cellConfigurable.row = indexPath.row
                    cellConfigurable.configure(blog: blog, viewController: viewController, apiResponse: cardModel.apiResponse)
                }
                (cell as? DashboardBlazeCardCell)?.configure(blazeViewModel)
                return cell
            case .migrationSuccess:
                let cellType = DashboardMigrationSuccessCell.self
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellType.defaultReuseID, for: indexPath) as? DashboardMigrationSuccessCell
                cell?.configure(with: viewController)
                return cell
            }
        }
    }()

    private var blazeViewModel: DashboardBlazeCardCellViewModel
    private var quickActionsViewModel: DashboardQuickActionsViewModel
    private let personalizationService: BlogDashboardPersonalizationService

    init(viewController: BlogDashboardViewController, managedObjectContext: NSManagedObjectContext = ContextManager.shared.mainContext, blog: Blog) {
        self.viewController = viewController
        self.managedObjectContext = managedObjectContext
        self.blog = blog
        self.personalizationService = BlogDashboardPersonalizationService(siteID: blog.dotComID?.intValue ?? 0)
        self.blazeViewModel = DashboardBlazeCardCellViewModel(blog: blog)
        self.quickActionsViewModel = DashboardQuickActionsViewModel(blog: blog, personalizationService: personalizationService)
        registerNotifications()
    }

    /// Apply the initial configuration when the view loaded
    func viewDidLoad() {
        loadCardsFromCache()
    }

    func viewWillAppear() {
        quickActionsViewModel.viewWillAppear()
    }

    func viewWillDisappear() {
        quickActionsViewModel.viewWillDisappear()
    }

    /// Update to display the selected blog.
    func update(blog: Blog) {
        BlogDashboardAnalytics.shared.reset()
        self.blog = blog
        self.blazeViewModel = DashboardBlazeCardCellViewModel(blog: blog)
        self.quickActionsViewModel = DashboardQuickActionsViewModel(blog: blog, personalizationService: personalizationService)
        self.loadCardsFromCache()
        self.loadCards()
    }

    /// Call the API to return cards for the current blog
    func loadCards(completion: (([DashboardCardModel]) -> Void)? = nil) {
        viewController?.showLoading()

        service.fetch(blog: blog, completion: { [weak self] cards in
            self?.viewController?.stopLoading()
            self?.updateCurrentCards(cards: cards)
            completion?(cards)
        }, failure: { [weak self] cards in
            self?.viewController?.stopLoading()
            self?.loadingFailure()
            self?.updateCurrentCards(cards: cards)

            completion?(cards)
        })

        blazeViewModel.refresh()
    }

    @objc func loadCardsFromCache() {
        let cards = service.fetchLocal(blog: blog)
        updateCurrentCards(cards: cards)
    }

    func isQuickActionsSection(_ sectionIndex: Int) -> Bool {
        let showMigration = MigrationSuccessCardView.shouldShowMigrationSuccessCard && !WPDeviceIdentification.isiPad()
        let targetIndex = showMigration ? DashboardSection.quickActions.rawValue : DashboardSection.quickActions.rawValue - 1
        return sectionIndex == targetIndex
    }

    func isMigrationSuccessCardSection(_ sectionIndex: Int) -> Bool {
        let showMigration = MigrationSuccessCardView.shouldShowMigrationSuccessCard && !WPDeviceIdentification.isiPad()
        return showMigration ? sectionIndex == DashboardSection.migrationSuccess.rawValue : false
    }
}

// MARK: - Private methods

private extension BlogDashboardViewModel {

    func registerNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(showDraftsCardIfNeeded), name: .newPostCreated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(showScheduledCardIfNeeded), name: .newPostScheduled, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(loadCardsFromCache), name: .blogDashboardPersonalizationSettingsChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(loadCardsFromCache), name: .domainsServiceDomainsRefreshed, object: nil)
    }

    func updateCurrentCards(cards: [DashboardCardModel]) {
        currentCards = cards
        syncPosts(for: cards)
        applySnapshot(for: cards)
    }

    func syncPosts(for cards: [DashboardCardModel]) {
        if cards.hasDrafts {
            DashboardPostsSyncManager.shared.syncPosts(blog: blog, postType: .post, statuses: draftStatusesToSync)
        }
        if cards.hasScheduled {
            DashboardPostsSyncManager.shared.syncPosts(blog: blog, postType: .post, statuses: scheduledStatusesToSync)
        }
        if cards.hasPages {
            DashboardPostsSyncManager.shared.syncPosts(blog: blog, postType: .page, statuses: pageStatusesToSync)
        }
    }

    func applySnapshot(for cards: [DashboardCardModel]) {
        let snapshot = createSnapshot(from: cards)
        dataSource?.apply(snapshot, animatingDifferences: false)
    }

    func createSnapshot(from cards: [DashboardCardModel]) -> DashboardSnapshot {
        let items = cards.map { DashboardItem.cards($0) }
        let dotComID = blog.dotComID?.intValue ?? 0
        var snapshot = DashboardSnapshot()
        if MigrationSuccessCardView.shouldShowMigrationSuccessCard, !WPDeviceIdentification.isiPad() {
            snapshot.appendSections([.migrationSuccess])
            snapshot.appendItems([.migrationSuccess], toSection: .migrationSuccess)
        }
        if !WPDeviceIdentification.isiPad() {
            snapshot.appendSections([.quickActions])
            snapshot.appendItems([.quickActions(dotComID)], toSection: .quickActions)
        }
        snapshot.appendSections([.cards])
        snapshot.appendItems(items, toSection: .cards)
        return snapshot
    }

    // In case a draft is saved and the drafts card
    // is not appearing, we show it.
    @objc func showDraftsCardIfNeeded() {
        if !currentCards.contains(where: { $0.cardType == .draftPosts }) {
            loadCardsFromCache()
        }
    }

    // In case a post is scheduled and the scheduled card
    // is not appearing, we show it.
    @objc func showScheduledCardIfNeeded() {
        if !currentCards.contains(where: { $0.cardType == .scheduledPosts }) {
            loadCardsFromCache()
        }
    }

}

// MARK: - Ghost/Skeleton cards and failures

private extension BlogDashboardViewModel {

    func loadingFailure() {
        if blog.dashboardState.hasCachedData {
            viewController?.loadingFailure()
        }
    }
}

private extension Collection where Element == DashboardCardModel {
    var hasDrafts: Bool {
        return contains(where: { $0.cardType == .draftPosts })
    }

    var hasScheduled: Bool {
        return contains(where: { $0.cardType == .scheduledPosts })
    }

    var hasPages: Bool {
        return contains(where: { $0.cardType == .pages })
    }
}
