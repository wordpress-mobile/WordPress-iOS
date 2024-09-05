import Foundation

final class PageListItemViewModel {
    let page: Page
    let title: NSAttributedString
    let badgeIcon: UIImage?
    let badges: NSAttributedString
    let imageURL: URL?
    let syncStateViewModel: PostSyncStateViewModel

    init(page: Page) {
        self.page = page
        self.title = makeContentAttributedString(for: page)
        self.badgeIcon = makeBadgeIcon(for: page)
        self.badges = makeBadgesString(for: page)
        self.imageURL = page.featuredImageURL
        self.syncStateViewModel = PostSyncStateViewModel(post: page)
    }
}

private func makeContentAttributedString(for page: Page) -> NSAttributedString {
    let page = page.hasRevision() ? page.revision : page
    let title = page?.titleForDisplay() ?? ""
    return NSAttributedString(string: title, attributes: [
        .font: WPStyleGuide.fontForTextStyle(.callout, fontWeight: .semibold),
        .foregroundColor: UIColor.label
    ])
}

private func makeBadgeIcon(for page: Page) -> UIImage? {
    if page.isSiteHomepage {
        return UIImage(named: "home")
    }
    if page.isSitePostsPage {
        return UIImage(named: "posts")
    }
    return nil
}

private func makeBadgesString(for page: Page) -> NSAttributedString {
    var badges: [String] = []
    var colors: [Int: UIColor] = [:]
    if page.isSiteHomepage {
        badges.append(Strings.badgeHomepage)
    } else if page.isSitePostsPage {
        badges.append(Strings.badgePosts)
    }
    if let date = AbstractPostHelper.getLocalizedStatusWithDate(for: page) {
        if page.status == .trash {
            colors[badges.endIndex] = .systemRed
        }
        badges.append(date)
    }
    if page.status == .publishPrivate {
        badges.append(Strings.badgePrivatePage)
    }
    if page.status == .pending {
        badges.append(Strings.badgePendingReview)
    }
    return AbstractPostHelper.makeBadgesString(with: badges.enumerated().map { index, badge in
        (badge, colors[index])
    })
}

private enum Strings {
    static let badgeHomepage = NSLocalizedString("pageList.badgeHomepage", value: "Homepage", comment: "Badge for page cells")
    static let badgePosts = NSLocalizedString("pageList.badgePosts", value: "Posts page", comment: "Badge for page cells")
    static let badgePrivatePage = NSLocalizedString("pageList.badgePrivate", value: "Private", comment: "Badge for page cells")
    static let badgePendingReview = NSLocalizedString("pageList.badgePendingReview", value: "Pending review", comment: "Badge for page cells")
}
