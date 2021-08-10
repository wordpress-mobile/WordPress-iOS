import Foundation
import Gutenberg

class GutenbergFeaturedImageHelper: NSObject {
    fileprivate let post: AbstractPost
    fileprivate let gutenberg: Gutenberg

    static let mediaIdNoFeaturedImageSet = 0

    let event: WPAnalyticsEvent = .editorPostFeaturedImageChanged

    init(post: AbstractPost, gutenberg: Gutenberg) {
        self.post = post
        self.gutenberg = gutenberg
        super.init()
    }

    func setFeaturedImage(mediaID: Int32) {
        let media = Media.existingMediaWith(mediaID: NSNumber(value: mediaID), inBlog: post.blog)
        post.featuredImage = media

        if mediaID == GutenbergFeaturedImageHelper.mediaIdNoFeaturedImageSet {
            gutenberg.showNotice(NSLocalizedString("Removed as featured image", comment: "Notice confirming that an image has been removed as the post's featured image."))
            WPAnalytics.track(event, properties: [
                "via": "gutenberg",
                "action": "removed"
            ])
        } else {
            gutenberg.showNotice(NSLocalizedString("Set as featured image", comment: "Notice confirming that an image has been set as the post's featured image."))
            WPAnalytics.track(event, properties: [
                "via": "gutenberg",
                "action": "added"
            ])
        }

        gutenberg.featuredImageIdNativeUpdated(mediaId: mediaID)
    }
}
