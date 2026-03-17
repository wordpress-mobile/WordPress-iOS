import SwiftUI
import WordPressData

/// The author filter state for the custom post list.
enum CustomPostAuthorFilter: Int, Codable {
    case everyone
    case mine
}

/// A toolbar button that toggles between showing everyone's posts and
/// only the current user's posts.
///
/// When set to "everyone", the button displays a people icon. When set to
/// "mine", it displays the current user's avatar.
struct AuthorFilterToolbarButton: View {
    @Binding var filter: CustomPostAuthorFilter
    let avatarURL: URL?

    var body: some View {
        Menu {
            Picker(selection: $filter, label: EmptyView()) {
                Label(Strings.everyone, systemImage: "person.2")
                    .tag(CustomPostAuthorFilter.everyone)
                Label(Strings.mine, systemImage: "person")
                    .tag(CustomPostAuthorFilter.mine)
            }
        } label: {
            filterIcon
                .frame(width: 28, height: 28)
        }
        .accessibilityLabel(Strings.accessibilityLabel)
        .accessibilityValue(accessibilityValue)
    }

    @ViewBuilder
    private var filterIcon: some View {
        if filter == .everyone {
            Image(systemName: "person.2")
                .imageScale(.medium)
        } else {
            AvatarView(
                style: .single(avatarURL),
                diameter: 28,
                placeholderImage: Image(systemName: "person.crop.circle.fill")
            )
        }
    }

    private var accessibilityValue: String {
        switch filter {
        case .everyone:
            return Strings.showingEveryone
        case .mine:
            return Strings.showingMine
        }
    }
}

private enum Strings {
    static let accessibilityLabel = NSLocalizedString(
        "customPostList.authorFilter.accessibilityLabel",
        value: "Author Filter",
        comment: "Accessibility label for the author filter button in the custom post list"
    )
    static let showingEveryone = NSLocalizedString(
        "customPostList.authorFilter.showingEveryone",
        value: "Showing everyone's posts",
        comment: "Accessibility value when the author filter shows posts from all authors"
    )
    static let showingMine = NSLocalizedString(
        "customPostList.authorFilter.showingMine",
        value: "Showing only my posts",
        comment: "Accessibility value when the author filter shows only the current user's posts"
    )
    static let everyone = NSLocalizedString(
        "customPostList.authorFilter.everyone",
        value: "Everyone",
        comment: "Menu item to show posts from all authors in the custom post list"
    )
    static let mine = NSLocalizedString(
        "customPostList.authorFilter.mine",
        value: "Mine",
        comment: "Menu item to show only the current user's posts in the custom post list"
    )
}

extension SiteStorage where Value == CustomPostAuthorFilter {
    static func authorFilter(for blog: TaggedManagedObjectID<Blog>) -> Self {
        SiteStorage(wrappedValue: .everyone, "custom-post-author-filter", blog: blog)
    }
}
