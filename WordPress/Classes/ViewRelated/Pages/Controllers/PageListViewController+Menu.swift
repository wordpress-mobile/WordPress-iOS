import Foundation
import WordPressShared

extension PageListViewController: InteractivePostViewDelegate {
    func edit(_ apost: AbstractPost) {
        guard let page = apost as? Page else { return }

        PageEditorPresenter.handle(page: page, in: self, entryPoint: .pagesList)
    }

    func view(_ apost: AbstractPost) {
        viewPost(apost)
    }

    func duplicate(_ apost: AbstractPost) {
        guard let page = apost as? Page else { return }
        copyPage(page)
    }

    func draft(_ apost: AbstractPost) {
        moveToDraft(apost)
    }

    func share(_ apost: AbstractPost, fromView view: UIView) {
        guard let page = apost as? Page else { return }

        WPAnalytics.track(.postListShareAction, properties: propertiesForAnalytics())

        let shareController = PostSharingController()
        shareController.sharePage(page, fromView: view, inViewController: self)
    }

    func blaze(_ apost: AbstractPost) {
        BlazeEventsTracker.trackEntryPointTapped(for: .pagesList)
        BlazeFlowCoordinator.presentBlaze(in: self, source: .pagesList, blog: blog, post: apost)
    }

    func comments(_ apost: AbstractPost) {
        // Not available for pages
    }

    func showSettings(for post: AbstractPost) {
        WPAnalytics.track(.postListSettingsAction, properties: propertiesForAnalytics())
        PostSettingsViewController.showStandaloneEditor(for: post, from: self)
    }

    func setHomepage(for apost: AbstractPost) {
        guard let page = apost as? Page else { return }
        WPAnalytics.track(.postListSetAsPostsPageAction)
        setPageAsHomepage(page)
    }

    func setPostsPage(for apost: AbstractPost) {
        guard let page = apost as? Page else { return }
        WPAnalytics.track(.postListSetHomePageAction)
        togglePageAsPostsPage(page)
    }

    func setRegularPage(for apost: AbstractPost) {
        guard let page = apost as? Page else { return }
        WPAnalytics.track(.postListSetAsRegularPageAction)
        togglePageAsPostsPage(page)
    }

    // MARK: - Helpers

    private func copyPage(_ page: Page) {
        // Analytics
        WPAnalytics.track(.postListDuplicateAction, withProperties: propertiesForAnalytics())
        // Copy Page
        let newPage = page.blog.createDraftPage()
        newPage.postTitle = page.postTitle
        newPage.content = page.content
        // Open Editor
        let editorViewController = EditPageViewController(page: newPage)
        present(editorViewController, animated: false)
    }
}
