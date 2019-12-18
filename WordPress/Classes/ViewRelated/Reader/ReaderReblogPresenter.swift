/// Presents the appropriate reblog scene, depending on the number of available sites
class ReaderReblogPresenter {
    private let postService: PostService

    private struct NoSitesConfiguration {
        static let noSitesTitle = NSLocalizedString("No available sites",
                                                    comment: "A short message that informs the user no sites could be found.")
        static let noSitesSubtitle = NSLocalizedString("Once you create a site, you can reblog content that you like to your own site.",
                                                       comment: "A subtitle with more detailed info for the user when no sites could be found.")
        static let manageSitesLabel = NSLocalizedString("Manage Sites",
                                                        comment: "Button title. Tapping lets the user manage the sites they follow.")
        static let backButtonTitle = NSLocalizedString("Back",
                                                       comment: "Back button title.")
    }

    init(postService: PostService? = nil) {

        // fallback for self.postService
        func makePostService() -> PostService {
            let context = ContextManager.sharedInstance().mainContext
            return PostService(managedObjectContext: context)
        }
        self.postService = postService ?? makePostService()
    }

    /// Presents the reblog screen(s)
    func presentReblog(blogService: BlogService,
                       readerPost: ReaderPost,
                       origin: UIViewController) {

        let blogCount = blogService.blogCountForAllAccounts()

        switch blogCount {
        case 0:
            presentNoSitesScene(origin: origin)
        case 1:
            guard let blog = blogService.blogsForAllAccounts().first else {
                return
            }
            presentEditor(with: readerPost, blog: blog, origin: origin)
        default:
            guard let blog = blogService.lastUsedOrFirstBlog() else {
                return
            }
            presentEditor(with: readerPost, blog: blog, origin: origin, presentBlogSelector: true)
        }
    }

    /// presents the editor when users have at least one blog site. If they have more than one
    /// the blog selector is presented.
    private func presentEditor(with readerPost: ReaderPost,
                               blog: Blog,
                               origin: UIViewController,
                               presentBlogSelector: Bool = false) {

        let post = postService.createDraftPost(for: blog)
        post.prepareForReblog(with: readerPost)

        let editor = EditPostViewController(post: post, loadAutosaveRevision: false)
        editor.modalPresentationStyle = .fullScreen
        editor.openWithBlogSelector = presentBlogSelector
        editor.postIsReblogged = true

        origin.present(editor, animated: false)
    }

    /// presents the no sites screen, with related actions
    private func presentNoSitesScene(origin: UIViewController) {
        let controller = NoResultsViewController.controllerWith(title: NoSitesConfiguration.noSitesTitle,
                                                                buttonTitle: NoSitesConfiguration.manageSitesLabel,
                                                                subtitle: NoSitesConfiguration.noSitesSubtitle)
        // add handlers to NoResultsController
        controller.actionButtonHandler = { [weak origin] in
            guard let tabBarController = origin?.tabBarController as? WPTabBarController else {
                return
            }
            controller.dismiss(animated: true) {
                tabBarController.showMySitesTab()
            }
        }
        controller.dismissButtonHandler = {
            controller.dismiss(animated: true)
        }

        controller.showDismissButton(title: NoSitesConfiguration.backButtonTitle)

        let navigationController = AdaptiveNavigationController(rootViewController: controller)

        if #available(iOS 13.0, *) {
            navigationController.modalPresentationStyle = .automatic
        } else {
            // suits both iPad and iPhone
            navigationController.modalPresentationStyle = .pageSheet
        }
        origin.present(navigationController, animated: true)
    }
}

// MARK: - Post updates
fileprivate extension Post {
    /// Formats the new Post content for reblogging, using an existing ReaderPost
    func prepareForReblog(with readerPost: ReaderPost) {
        // update the post
        update(with: readerPost)
        // initialize the content
        var content = String()
        // add the quoted summary to the content, if it exists
        if let summary = readerPost.summary {
            var citation: String?
            // add the optional citation
            if let permaLink = readerPost.permaLink, let title = readerPost.titleForDisplay() {
                citation = ReaderReblogFormatter.hyperLink(url: permaLink, text: title)
            }
            content = self.blog.isGutenbergEnabled ? ReaderReblogFormatter.gutenbergQuote(text: summary, citation: citation) :
                ReaderReblogFormatter.aztecQuote(text: summary, citation: citation)
        }
        // insert the image on top of the content
        if let image = readerPost.featuredImage, image.isValidURL() {
            content = self.blog.isGutenbergEnabled ? ReaderReblogFormatter.gutenbergImage(image: image) + content :
                ReaderReblogFormatter.aztecImage(image: image) + content
        }
        self.content = content
    }

    func update(with readerPost: ReaderPost) {
        self.postTitle = readerPost.titleForDisplay()
        self.pathForDisplayImage = readerPost.featuredImage
        self.permaLink = readerPost.permaLink
    }
}
