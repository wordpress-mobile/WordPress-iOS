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
