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

class BlogDashboardViewModel {
    private weak var viewController: BlogDashboardViewController?

    private let managedObjectContext: NSManagedObjectContext

    var blog: Blog

    private var currentCards: [DashboardCardModel] = []

    private lazy var draftStatusesToSync: [String] = {
        return PostListFilter.draftFilter().statuses.strings
    }()

    private lazy var scheduledStatusesToSync: [String] = {
        return PostListFilter.scheduledFilter().statuses.strings
    }()

    private lazy var service: BlogDashboardService = {
        return BlogDashboardService(managedObjectContext: managedObjectContext)
    }()

    private lazy var dataSource: DashboardDataSource? = {
        guard let viewController = viewController else {
            return nil
        }

        return DashboardDataSource(collectionView: viewController.collectionView) { [unowned self] collectionView, indexPath, item in

            var cellType: DashboardCollectionViewCell.Type
            var cardType: DashboardCard
            var apiResponse: BlogDashboardRemoteEntity?
            switch item {
            case .quickActions:
                let cellType = DashboardQuickActionsCardCell.self
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellType.defaultReuseID, for: indexPath) as? DashboardQuickActionsCardCell
                cell?.configureQuickActionButtons(for: blog, with: viewController)
                return cell
            case .cards(let cardModel):
                let cellType = cardModel.cardType.cell
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellType.defaultReuseID, for: indexPath)
                if let cellConfigurable = cell as? BlogDashboardCardConfigurable {
                    cellConfigurable.configure(blog: blog, viewController: viewController, apiResponse: cardModel.apiResponse)
                }
                return cell
            case .migrationSuccess:
                let cellType = DashboardMigrationSuccessCell.self
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellType.defaultReuseID, for: indexPath) as? DashboardMigrationSuccessCell
                return cell
            }

        }
    }()

    init(viewController: BlogDashboardViewController, managedObjectContext: NSManagedObjectContext = ContextManager.shared.mainContext, blog: Blog) {
        self.viewController = viewController
        self.managedObjectContext = managedObjectContext
        self.blog = blog
        registerNotifications()
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
        NotificationCenter.default.addObserver(self, selector: #selector(showNextPostCardIfNeeded), name: .newPostPublished, object: nil)
    }

    func updateCurrentCards(cards: [DashboardCardModel]) {
        currentCards = cards
        syncPosts(for: cards)
        applySnapshot(for: cards)
    }

    func syncPosts(for cards: [DashboardCardModel]) {
        if cards.hasDrafts {
            DashboardPostsSyncManager.shared.syncPosts(blog: blog, statuses: draftStatusesToSync)
        }
        if cards.hasScheduled {
            DashboardPostsSyncManager.shared.syncPosts(blog: blog, statuses: scheduledStatusesToSync)
        }
    }

    func applySnapshot(for cards: [DashboardCardModel]) {
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

    func createSnapshot(from cards: [DashboardCardModel]) -> DashboardSnapshot {
        let items = cards.map { DashboardItem.cards($0) }
        let dotComID = blog.dotComID?.intValue ?? 0
        var snapshot = DashboardSnapshot()
        if MigrationSuccessCardView.shouldShowMigrationSuccessCard, !WPDeviceIdentification.isiPad() {
            snapshot.appendSections(DashboardSection.allCases)
            snapshot.appendItems([.migrationSuccess], toSection: .migrationSuccess)
        } else {
            snapshot.appendSections([.quickActions, .cards])
        }

        snapshot.appendItems([.quickActions(dotComID)], toSection: .quickActions)
        snapshot.appendItems(items, toSection: .cards)
        return snapshot
    }

    func scroll(_ scrollView: UIScrollView, to position: CGPoint) {
        if position.y > 0 {
            scrollView.setContentOffset(position, animated: false)
        }
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

    // In case a post is published and create_first card
    // is showing, we replace it with the create_next card.
    @objc func showNextPostCardIfNeeded() {
        if !currentCards.contains(where: { $0.cardType == .createPost }) {
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
}
