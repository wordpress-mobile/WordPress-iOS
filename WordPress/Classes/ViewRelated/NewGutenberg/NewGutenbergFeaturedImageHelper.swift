import Foundation
import WordPressShared

class NewGutenbergFeaturedImageHelper: NSObject {
    fileprivate let post: AbstractPost

    let event: WPAnalyticsEvent = .editorPostFeaturedImageChanged

    init(post: AbstractPost) {
        self.post = post
        super.init()
    }

    func setFeaturedImage(mediaID: Int) {
        let media = Media.existingMediaWith(mediaID: NSNumber(value: mediaID), inBlog: post.blog)
        post.featuredImage = media
        WPAnalytics.track(event, properties: [
            "via": "gutenberg_kit",
            "action": "added"
        ])
    }
}
