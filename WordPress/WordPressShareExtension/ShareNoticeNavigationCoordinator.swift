import UIKit

/// This class simply exists to coordinate the display of various sections of
/// the app in response to actions taken by the user from share/app extension notifications.
///
class ShareNoticeNavigationCoordinator {
    static func presentEditor(with userInfo: NSDictionary) {
        fetchPost(from: userInfo, onSuccess: { post in
            if let post = post {
                presentEditor(for: post, source: ShareNoticeConstants.notificationSourceSuccess)
            }
        }, onFailure: {
            DDLogError("Could not fetch post from share notification.")
        })
    }

    static func presentEditor(for post: Post, source: String) {
        WPAppAnalytics.track(.notificationsShareSuccessEditPost, with: post)

        let editor = EditPostViewController.init(post: post)
        editor.modalPresentationStyle = .fullScreen
        RootViewCoordinator.sharedPresenter.rootViewController.present(editor, animated: false)
    }

    static func navigateToPostList(with userInfo: NSDictionary) {
        fetchPost(from: userInfo, onSuccess: { post in
            if let post = post {
                RootViewCoordinator.sharedPresenter.showPosts(for: post.blog)
            }
        }, onFailure: {
            DDLogError("Could not fetch post from share notification.")
        })
    }

    static func navigateToBlogDetails(with userInfo: NSDictionary) {
        fetchBlog(from: userInfo, onSuccess: { blog in
            if let blog = blog {
                RootViewCoordinator.sharedPresenter.showBlogDetails(for: blog)
            }
        }, onFailure: {
            DDLogError("Could not fetch blog from share notification.")
        })
    }

    private static func fetchPost(from userInfo: NSDictionary,
                                  onSuccess: @escaping (_ post: Post?) -> Void,
                                  onFailure: @escaping () -> Void) {
        let context = ContextManager.sharedInstance().mainContext

        guard let postIDString = userInfo[ShareNoticeUserInfoKey.postID] as? String,
            let postID = NumberFormatter().number(from: postIDString),
            let siteIDString = userInfo[ShareNoticeUserInfoKey.blogID] as? String,
            let siteID = NumberFormatter().number(from: siteIDString),
            let blog = Blog.lookup(withID: siteID, in: context) else {
                onFailure()
                return
        }

        let repository = PostRepository(coreDataStack: ContextManager.shared)
        let blogID = TaggedManagedObjectID(blog)
        Task { @MainActor in
            do {
                let postObjectID = try await repository.getPost(withID: postID, from: blogID)
                let postObject = try ContextManager.shared.mainContext.existingObject(with: postObjectID)
                guard let post = postObject as? Post else {
                    onFailure()
                    return
                }
                onSuccess(post)
            } catch {
                onFailure()
            }
        }
    }

    private static func fetchBlog(from userInfo: NSDictionary,
                                  onSuccess: @escaping (_ blog: Blog?) -> Void,
                                  onFailure: @escaping () -> Void) {
        guard let siteIDString = userInfo[ShareNoticeUserInfoKey.blogID] as? String,
            let siteID = NumberFormatter().number(from: siteIDString) else {
                onFailure()
                return
        }

        let context = ContextManager.shared.mainContext
        onSuccess(Blog.lookup(withID: siteID, in: context))
    }
}
