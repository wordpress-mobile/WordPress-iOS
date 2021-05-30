import Foundation
import Gutenberg

class GutenbergFeaturedImageHelper: NSObject {
    fileprivate let post: AbstractPost
    fileprivate let gutenberg: Gutenberg

    let mediaIdNoFeaturedImageSet = 0

    init(post: AbstractPost, gutenberg: Gutenberg) {
        self.post = post
        self.gutenberg = gutenberg
        super.init()
    }

    func setFeaturedImage(mediaID: Int32) {
        let media = Media.existingMediaWith(mediaID: NSNumber(value: mediaID), inBlog: post.blog)
        post.featuredImage = media

        if mediaID == mediaIdNoFeaturedImageSet {
            gutenberg.showNotice(NSLocalizedString("Removed as Featured Image", comment: "Featured image removed confirmation message"))

        } else {
            gutenberg.showNotice(NSLocalizedString("Set as Featured Image", comment: "Featured image set confirmation message"))
        }

        gutenberg.featuredImageIdNativeUpdated(mediaId: mediaID)
    }
}
