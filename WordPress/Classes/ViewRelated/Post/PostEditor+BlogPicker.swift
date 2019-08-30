import UIKit

extension PostEditor where Self: UIViewController {

    func blogPickerWasPressed() {
        assert(isSingleSiteMode == false)
        guard post.hasSiteSpecificChanges() else {
            displayBlogSelector()
            return
        }

        displaySwitchSiteAlert()
    }

    func displayBlogSelector() {
        guard let sourceView = navigationBarManager.blogPickerButton.imageView else {
            fatalError()
        }

        // Setup Handlers
        let successHandler: BlogSelectorSuccessHandler = { selectedObjectID in
            self.dismiss(animated: true)

            guard let blog = self.mainContext.object(with: selectedObjectID) as? Blog else {
                return
            }
            self.recreatePostRevision(in: blog)
            self.mediaLibraryDataSource = MediaLibraryPickerDataSource(post: self.post)
        }

        let dismissHandler: BlogSelectorDismissHandler = {
            self.dismiss(animated: true)
        }

        // Setup Picker
        let selectorViewController = BlogSelectorViewController(selectedBlogObjectID: post.blog.objectID,
                                                                successHandler: successHandler,
                                                                dismissHandler: dismissHandler)
        selectorViewController.title = NSLocalizedString("Select Site", comment: "Blog Picker's Title")
        selectorViewController.displaysPrimaryBlogOnTop = true

        // Note:
        // On iPad Devices, we'll disable the Picker's SearchController's "Autohide Navbar Feature", since
        // upon dismissal, it may force the NavigationBar to show up, even when it was initially hidden.
        selectorViewController.displaysNavigationBarWhenSearching = WPDeviceIdentification.isiPad()

        // Setup Navigation
        let navigationController = AdaptiveNavigationController(rootViewController: selectorViewController)
        navigationController.configurePopoverPresentationStyle(from: sourceView)

        // Done!
        present(navigationController, animated: true)
    }

    func displaySwitchSiteAlert() {
        let alert = UIAlertController(title: SwitchSiteAlert.title, message: SwitchSiteAlert.message, preferredStyle: .alert)

        alert.addDefaultActionWithTitle(SwitchSiteAlert.acceptTitle) { _ in
            self.displayBlogSelector()
        }

        alert.addCancelActionWithTitle(SwitchSiteAlert.cancelTitle)

        present(alert, animated: true)
    }

    // TODO: Rip this and put it into PostService, as well
    func recreatePostRevision(in blog: Blog) {
        let shouldCreatePage = post is Page
        let postService = PostService(managedObjectContext: mainContext)
        let newPost = shouldCreatePage ? postService.createDraftPage(for: blog) : postService.createDraftPost(for: blog)

        newPost.content = contentByStrippingMediaAttachments()
        newPost.postTitle = post.postTitle
        newPost.password = post.password
        newPost.dateCreated = post.dateCreated
        newPost.dateModified = post.dateModified
        newPost.status = post.status

        if let source = post as? Post, let target = newPost as? Post {
            target.tags = source.tags
        }

        discardChanges()
        post = newPost
        createRevisionOfPost()
        RecentSitesService().touch(blog: blog)

        // TODO: Add this snippet, if needed, once we've relocated this helper to PostService
        //[self syncOptionsIfNecessaryForBlog:blog afterBlogChanged:YES];
    }
}

private struct SwitchSiteAlert {
    static let title                    = NSLocalizedString("Change Site", comment: "Title of an alert prompting the user that they are about to change the blog they are posting to.")
    static let message                  = NSLocalizedString("Choosing a different site will lose edits to site specific content like media and categories. Are you sure?", comment: "And alert message warning the user they will loose blog specific edits like categories, and media if they change the blog being posted to.")

    static let acceptTitle              = NSLocalizedString("OK", comment: "Accept Action")
    static let cancelTitle              = NSLocalizedString("Cancel", comment: "Cancel Action")
}
