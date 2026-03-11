import Foundation
import WordPressData

@MainActor
final class AbstractPostSettingsDataProvider: PostSettingsDataProvider {
    let post: AbstractPost

    var blog: Blog {
        post.blog
    }

    var capabilities: PostSettingsCapabilities {
        post is Post ? .post() : .page()
    }

    var postContent: String {
        post.content ?? ""
    }

    var navigationTitle: String {
        isPost ? Strings.postSettingsTitle : Strings.pageSettingsTitle
    }

    var isScheduled: Bool {
        post.getOriginal().status == .scheduled
    }

    var isDraftOrPending: Bool {
        post.getOriginal().isStatus(in: [.draft, .pending])
    }

    var isPost: Bool {
        post is Post
    }

    var authorFallbackDisplayName: String {
        post.author?.makePlainText() ?? ""
    }

    var suggestedSlug: String? {
        post.suggested_slug
    }

    var permalinkTemplate: String? {
        post.permalinkTemplateURL
    }

    init(post: AbstractPost) {
        self.post = post
    }
}

// MARK: - Localized Strings

private enum Strings {
    static let postSettingsTitle = NSLocalizedString(
        "postSettings.navigationTitle.post",
        value: "Post Settings",
        comment: "The title of the Post Settings screen."
    )

    static let pageSettingsTitle = NSLocalizedString(
        "postSettings.navigationTitle.page",
        value: "Page Settings",
        comment: "The title of the Page Settings screen."
    )
}
