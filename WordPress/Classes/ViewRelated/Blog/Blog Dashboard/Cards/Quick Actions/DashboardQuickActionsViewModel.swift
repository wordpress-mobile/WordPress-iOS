import UIKit
import Combine

#warning("TODO: add details labels")
#warning("TODO: make sure that hashable works as intended")
#warning("TODO: make sure it reloads when blog changes")

final class DashboardQuickActionsViewModel {
    var onViewWillAppear: (() -> Void)?

    @Published private(set) var items: [DashboardQuickActionItemViewModel] = []

    let blog: Blog

    init(blog: Blog) {
        self.blog = blog
        self.refresh(blog: blog)
    }

    private func refresh(blog: Blog) {
        var items: [DashboardQuickActionItemViewModel] = []

        items.append(.init(image: UIImage(named: "site-menu-posts"), title: Strings.posts, details: nil, action: .posts))
        if blog.supports(.pages) {
            items.append(.init(image: UIImage(named: "site-menu-pages"), title: Strings.pages, details: nil, action: .pages))
        }
        items.append(.init(image: UIImage(named: "site-menu-media"), title: Strings.media, details: nil, action: .media))
        if blog.supports(.stats) {
            items.append(.init(image: UIImage(named: "site-menu-stats"), title: Strings.stats, details: nil, action: .stats))
        }
        items.append(.init(image: UIImage(named: "site-menu-more"), title: Strings.more, details: nil, action: .more))

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
    let details: String?
    let action: DashboardQuickAction
}

enum DashboardQuickAction {
    case posts
    case pages
    case media
    case stats
    case more
}

private enum Strings {
    static let stats = NSLocalizedString("dashboard.menu.stats", value: "Stats", comment: "Title for stats button on dashboard.")
    static let posts = NSLocalizedString("dashboard.menu.posts", value: "Posts", comment: "Title for posts button on dashboard.")
    static let media = NSLocalizedString("dashboard.menu.media", value: "Media", comment: "Title for media button on dashboard.")
    static let pages = NSLocalizedString("dashboard.menu.pages", value: "Pages", comment: "Title for pages button on dashboard.")
    static let more = NSLocalizedString("dashboard.menu.more", value: "More", comment: "Title for more button on dashboard.")
}
