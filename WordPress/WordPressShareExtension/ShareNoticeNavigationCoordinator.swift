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
        WPTabBarController.sharedInstance().present(editor, animated: false, completion: nil)
    }

    static func navigateToPostList(with userInfo: NSDictionary) {
        fetchPost(from: userInfo, onSuccess: { post in
            if let post = post {
                WPTabBarController.sharedInstance().switchTabToPostsList(for: post)
            }
        }, onFailure: {
            DDLogError("Could not fetch post from share notification.")
        })
    }

    private static func fetchPost(from userInfo: NSDictionary,
                                  onSuccess: @escaping (_ post: Post?) -> Void,
                                  onFailure: @escaping () -> Void) {
        let context = ContextManager.sharedInstance().mainContext
        let blogService = BlogService(managedObjectContext: context)
        let postService = PostService(managedObjectContext: context)

        guard let postIDString = userInfo[ShareNoticeUserInfoKey.postID] as? String,
            let postID = NumberFormatter().number(from: postIDString),
            let siteIDString = userInfo[ShareNoticeUserInfoKey.blogID] as? String,
            let siteID = NumberFormatter().number(from: siteIDString),
            let blog = blogService.blog(byBlogId: siteID) else {
                onFailure()
                return
        }

        postService.getPostWithID(postID, for: blog, success: { apost in
            guard let post = apost as? Post else {
                onFailure()
                return
            }
            onSuccess(post)
        }, failure: { error in
            onFailure()
        })
    }
}
