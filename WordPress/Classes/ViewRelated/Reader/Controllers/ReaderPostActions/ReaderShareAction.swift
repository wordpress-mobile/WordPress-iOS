import UIKit

/// Encapsulates a command share a post
final class ReaderShareAction {
    func execute(with post: ReaderPost, anchor: UIPopoverPresentationControllerSourceItem, vc: UIViewController) {
        let sharingController = PostSharingController()

        sharingController.shareReaderPost(post, fromAnchor: anchor, inViewController: vc)
        WPAnalytics.trackReader(.itemSharedReader, properties: ["blog_id": post.siteID as Any])
    }
}
