import Foundation

class RelatedPostsViewController: UIViewController {

    var post: ReaderPost? {
        didSet {
            fetchRelatedPostsIfNeeded()
        }
    }


    open class func controllerWithPost(_ post: ReaderPost) -> RelatedPostsViewController {
        let controller = RelatedPostsViewController()
        controller.post = post
        return controller
    }


    func fetchRelatedPostsIfNeeded() {
        guard let post = post else {
            return
        }
        if post.relatedPosts.count > 0 {
            // TODO: Configure view.
            return
        }

        let context = ContextManager.sharedInstance().newDerivedContext()
        let service = ReaderPostService(managedObjectContext: context)
        service.fetchRelatedPosts(for: post, success: {
            print("\(post)")
            // TODO: Configure view.
        }, failure: { (error) in
            print("\(error)")
            // Silently fail.
        })

    }

}
