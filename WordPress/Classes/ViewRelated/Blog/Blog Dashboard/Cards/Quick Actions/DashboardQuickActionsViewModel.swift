import UIKit
import Combine

final class DashboardQuickActionsViewModel {
    var onViewWillAppear: (() -> Void)?

    @Published private(set) var items: [DashboardQuickActionItemViewModel] = []

    let blog: Blog

    private let personalizationService: BlogDashboardPersonalizationService

    init(blog: Blog, personalizationService: BlogDashboardPersonalizationService) {
        self.blog = blog
        self.personalizationService = personalizationService

        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: .blogDashboardPersonalizationSettingsChanged, object: nil)

        self.refresh()
    }

    @objc private func refresh() {
        let items = DashboardQuickAction.allCases
            .filter(personalizationService.isEnabled)
            .map {
                DashboardQuickActionItemViewModel(
                    image: $0.image,
                    title: $0.localizedTitle,
                    tourElement: $0.tourElement,
                    action: $0
                )
            }

        if self.items != items {
            self.items = items
        }
    }

    func viewWillAppear() {
        onViewWillAppear?()
    }

    func viewWillDisappear() {

    }
}

struct DashboardQuickActionItemViewModel: Hashable {
    let image: UIImage?
    let title: String
    var details: String?
    var tourElement: QuickStartTourElement?
    let action: DashboardQuickAction
}

enum DashboardQuickAction: String, CaseIterable {
    case posts
    case pages
    case media
    case comments
    case stats
    case more

    var localizedTitle: String {
        switch self {
        case .posts:
            return NSLocalizedString("dashboard.menu.posts", value: "Posts", comment: "Title for posts button on dashboard.")
        case .pages:
            return NSLocalizedString("dashboard.menu.pages", value: "Pages", comment: "Title for pages button on dashboard.")
        case .media:
            return NSLocalizedString("dashboard.menu.media", value: "Media", comment: "Title for media button on dashboard.")
        case .comments:
            return NSLocalizedString("dashboard.menu.comments", value: "Comments", comment: "Title for comments button on dashboard.")
        case .stats:
            return NSLocalizedString("dashboard.menu.stats", value: "Stats", comment: "Title for stats button on dashboard.")
        case .more:
            return NSLocalizedString("dashboard.menu.more", value: "More", comment: "Title for more button on dashboard.")
        }
    }

    var image: UIImage? {
        switch self {
        case .posts:
            return UIImage(named: "site-menu-posts")
        case .pages:
            return UIImage(named: "site-menu-pages")
        case .media:
            return UIImage(named: "site-menu-media")
        case .comments:
            return UIImage(named: "site-menu-comments")
        case .stats:
            return UIImage(named: "site-menu-stats")
        case .more:
            return UIImage(named: "site-menu-more")
        }
    }

    var tourElement: QuickStartTourElement? {
        switch self {
        case .posts:
            return nil
        case .pages:
            return .pages
        case .media:
            return .mediaScreen
        case .comments:
            return nil
        case .stats:
            return .stats
        case .more:
            return .siteMenu
        }
    }

    var isEnabledByDefault: Bool {
        switch self {
        case .posts, .pages, .media, .stats, .more:
            return true
        case .comments:
            return false
        }
    }

    func isEligible(for blog: Blog) -> Bool {
        switch self {
        case .pages:
            return blog.supports(.pages)
        case .stats:
            return blog.supports(.stats)
        case .posts, .comments, .media, .more:
            return true
        }
    }

    static let personalizableActions: [DashboardQuickAction] = {
        var actions = DashboardQuickAction.allCases
        actions.removeAll(where: { $0 == .more })
        return actions
    }()
}
