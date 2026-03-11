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

    init(post: AbstractPost) {
        self.post = post
    }
}
