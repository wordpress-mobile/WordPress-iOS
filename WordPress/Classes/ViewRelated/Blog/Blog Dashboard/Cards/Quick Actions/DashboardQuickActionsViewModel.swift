import UIKit
import Combine

final class DashboardQuickActionsViewModel {
    var onViewWillAppear: (() -> Void)?

    @Published private(set) var items: [DashboardQuickActionItemViewModel] = []

    let blog: Blog

    init(blog: Blog) {
        self.blog = blog
        self.refresh()
    }

    private func refresh() {
        let posts = DashboardQuickActionItemViewModel(
            image: UIImage(named: "site-menu-posts"),
            title: Strings.posts,
            action: .posts
        )

        let pages = DashboardQuickActionItemViewModel(
            image: UIImage(named: "site-menu-pages"),
            title: Strings.pages,
            tourElement: .pages,
            action: .pages
        )

        let media = DashboardQuickActionItemViewModel(
            image: UIImage(named: "site-menu-media"),
            title: Strings.media,
            tourElement: .mediaScreen,
            action: .media
        )

        let comments = DashboardQuickActionItemViewModel(
            image: UIImage(named: "site-menu-comments"),
            title: Strings.comments,
            action: .comments
        )

        let stats = DashboardQuickActionItemViewModel(
            image: UIImage(named: "site-menu-stats"),
            title: Strings.stats,
            tourElement: .stats,
            action: .stats
        )

        let more = DashboardQuickActionItemViewModel(
            image: UIImage(named: "site-menu-more"),
            title: Strings.more,
            tourElement: .siteMenu,
            action: .more
        )

        let items = [
            posts,
            blog.supports(.pages) ? pages : nil,
            media,
            comments,
            blog.supports(.stats) ? stats : nil,
            more
        ].compactMap { $0 }

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

enum DashboardQuickAction {
    case posts
    case pages
    case media
    case comments
    case stats
    case more
}

private enum Strings {
    static let stats = NSLocalizedString("dashboard.menu.stats", value: "Stats", comment: "Title for stats button on dashboard.")
    static let posts = NSLocalizedString("dashboard.menu.posts", value: "Posts", comment: "Title for posts button on dashboard.")
    static let media = NSLocalizedString("dashboard.menu.media", value: "Media", comment: "Title for media button on dashboard.")
    static let comments = NSLocalizedString("dashboard.menu.comments", value: "Comments", comment: "Title for comments button on dashboard.")
    static let pages = NSLocalizedString("dashboard.menu.pages", value: "Pages", comment: "Title for pages button on dashboard.")
    static let more = NSLocalizedString("dashboard.menu.more", value: "More", comment: "Title for more button on dashboard.")
}
