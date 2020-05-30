import Foundation

class ReaderDetailCoordinator {

    /// A post to be displayed
    var post: ReaderPost?

    /// Reader Post Service
    private let service: ReaderPostService

    /// Post Sharing Controller
    private let sharingController: PostSharingController

    /// Reader View
    private weak var view: ReaderDetailView?

    /// A post ID to fetch
    private(set) var postID: NSNumber?

    /// A site ID to be used to fetch a post
    private(set) var siteID: NSNumber?

    /// If the site is an external feed (not hosted at WPcom and not using Jetpack)
    private(set) var isFeed: Bool?

    /// Initialize the Reader Detail Coordinator
    ///
    /// - Parameter service: a Reader Post Service
    init(service: ReaderPostService = ReaderPostService(managedObjectContext: ContextManager.sharedInstance().mainContext),
         sharingController: PostSharingController = PostSharingController(),
         view: ReaderDetailView) {
        self.service = service
        self.sharingController = sharingController
        self.view = view
    }

    /// Start the cordinator
    ///
    func start() {
        if let post = post {
            view?.render(post)
            view?.show(title: post.postTitle)
        } else if let siteID = siteID, let postID = postID, let isFeed = isFeed {
            fetch(postID: postID, siteID: siteID, isFeed: isFeed)
        }
    }

    /// Share the current post
    ///
    func share(fromView anchorView: UIView) {
        guard let post = post, let view = view as? UIViewController else {
            return
        }

        sharingController.shareReaderPost(post, fromView: anchorView, inViewController: view)
    }

    /// Set a postID, siteID and isFeed
    ///
    /// - Parameter postID: A post ID to fetch
    /// - Parameter siteID: A site ID to fetch
    /// - Parameter isFeed: If the site is an external feed (not hosted at WPcom and not using Jetpack)
    func set(postID: NSNumber, siteID: NSNumber, isFeed: Bool) {
        self.postID = postID
        self.siteID = siteID
        self.isFeed = isFeed
    }

    /// Requests a ReaderPost from the service and updates the View.
    ///
    /// Use this method to fetch a ReaderPost.
    /// - Parameter postID: a post identification
    /// - Parameter siteID: a site identification
    /// - Parameter isFeed: a Boolean indicating if the site is an external feed (not hosted at WPcom and not using Jetpack)
    private func fetch(postID: NSNumber, siteID: NSNumber, isFeed: Bool) {
        service.fetchPost(postID.uintValue,
                          forSite: siteID.uintValue,
                          isFeed: isFeed,
                          success: { [weak self] post in
                            guard let post = post else {
                                return
                            }

                            self?.post = post
                            self?.view?.render(post)
                            self?.view?.show(title: post.postTitle)
        }, failure: { [weak self] _ in
            self?.view?.showError()
        })
    }
}

extension ReaderDetailCoordinator: ReaderDetailHeaderViewDelegate {
    func didTapBlogName() {
        /// TODO: Preview site
    }

    func didTapMenuButton() {
        /// TODO: Show menu
    }

    func didTapTagButton() {
        /// TODO: Show tag
    }

    func didTapHeaderAvatar() {
        /// TODO: Preview site
    }

    func didTapFeaturedImage() {
        // Show image
    }
}
