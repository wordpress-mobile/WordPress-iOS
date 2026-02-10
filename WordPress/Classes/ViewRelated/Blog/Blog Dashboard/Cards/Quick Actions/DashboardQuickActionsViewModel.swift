import UIKit
import Combine
import WordPressData
import WordPressShared

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
        var actions = DashboardQuickAction.standardActions
            .filter {
                personalizationService.isEnabled($0) &&
                $0.isEligible(for: blog)
            }

        if FeatureFlag.customPostTypes.enabled && blog.supportsCoreRESTAPI {
            let pinned = SiteStorageAccess.pinnedPostTypes(for: TaggedManagedObjectID(blog))
                .map { DashboardQuickAction.postType($0) }
            if let moreIndex = actions.firstIndex(of: .more) {
                actions.insert(contentsOf: pinned, at: moreIndex)
            } else {
                actions.append(contentsOf: pinned)
            }
        }

        let items = actions.map {
            DashboardQuickActionItemViewModel(
                image: $0.image,
                title: $0.localizedTitle,
                action: $0
            )
        }

        if self.items != items {
            self.items = items
        }
    }

    func syncCustomPostTypes() {
        guard let service = CustomPostTypeService(blog: blog) else { return }
        Task { @MainActor [weak self] in
            do {
                try await service.refresh()

                self?.refresh()
            } catch {
                DDLogError("Failed to refresh custom post types: \(error)")
            }
        }
    }

    func viewWillAppear() {
        onViewWillAppear?()
        refresh()
    }

    func viewWillDisappear() {

    }
}

struct DashboardQuickActionItemViewModel: Hashable {
    let image: UIImage?
    let title: String
    var details: String?
    let action: DashboardQuickAction
}

enum DashboardQuickAction: Hashable {
    case stats
    case posts
    case pages
    case media
    case comments
    case more
    case postType(PinnedPostType)

    static let standardActions: [DashboardQuickAction] = [
        .stats, .posts, .pages, .media, .comments, .more
    ]

    var settingsKey: String {
        switch self {
        case .stats: return "stats"
        case .posts: return "posts"
        case .pages: return "pages"
        case .media: return "media"
        case .comments: return "comments"
        case .more: return "more"
        case .postType(let type): return "postType-\(type.slug)"
        }
    }

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
        case .postType(let type):
            return type.name
        }
    }

    var image: UIImage? {
        switch self {
        case .posts:
            return UIImage(named: "site-menu-posts")?.imageFlippedForRightToLeftLayoutDirection()
        case .pages:
            return UIImage(named: "site-menu-pages")
        case .media:
            return UIImage(named: "site-menu-media")
        case .comments:
            return UIImage(named: "site-menu-comments")?.imageFlippedForRightToLeftLayoutDirection()
        case .stats:
            return UIImage(named: "site-menu-stats")
        case .more:
            return UIImage(named: "site-menu-more")
        case .postType(let type):
            return UIImage(dashicon: type.icon)
        }
    }

    var accessibilityIdentifier: String {
        switch self {
        case .stats: "quick_actions_stats"
        case .posts: "quick_actions_posts"
        case .pages: "quick_actions_pages"
        case .media: "quick_actions_media"
        case .comments: "quick_actions_comments"
        case .more: "quick_actions_more"
        case .postType(let type): "quick_actions_post_type_\(type.slug)"
        }
    }

    var isEnabledByDefault: Bool {
        switch self {
        case .posts, .pages, .media, .stats, .more, .postType:
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
        case .posts, .comments, .media, .more, .postType:
            return true
        }
    }

    static let personalizableActions: [DashboardQuickAction] = {
        var actions = standardActions
        actions.removeAll(where: { $0 == .more })
        return actions
    }()
}
