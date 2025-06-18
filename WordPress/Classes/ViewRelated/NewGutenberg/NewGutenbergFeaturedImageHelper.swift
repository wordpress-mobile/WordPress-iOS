import Foundation
import WordPressShared

struct NewGutenbergFeaturedImageHelper {
    private let post: AbstractPost
    let event: WPAnalyticsEvent = .editorPostFeaturedImageChanged

    init(post: AbstractPost) {
        self.post = post
    }

    func setFeaturedImage(mediaID: Int) {
        let media = Media.existingOrStubMediaWith(mediaID: NSNumber(value: mediaID), inBlog: post.blog)
        post.featuredImage = media
        WPAnalytics.track(event, properties: [
            "via": "gutenberg_kit",
            "action": "added"
        ])
    }
}
