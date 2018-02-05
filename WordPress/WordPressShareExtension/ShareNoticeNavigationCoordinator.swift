import UIKit

/// This class simply exists to coordinate the display of various sections of
/// the app in response to actions taken by the user from share/app extension notifications.
///
class ShareNoticeNavigationCoordinator {
    static func presentEditor(with userInfo: NSDictionary) {
        guard let post = post(from: userInfo) else {
            return
        }

        presentEditor(for: post, source: "share_upload_notification")
    }

    static func presentEditor(for post: Post, source: String) {
        WPAppAnalytics.track(.notificationsShareSuccessEditPost, with: post)

        let editor = EditPostViewController.init(post: post)
        editor.modalPresentationStyle = .fullScreen
        WPTabBarController.sharedInstance().present(editor, animated: false, completion: nil)
    }

    private static func post(from userInfo: NSDictionary) -> Post? {
        let context = ContextManager.sharedInstance().mainContext

        guard let postID = userInfo[ShareNoticeUserInfoKey.postID] as? String,
            let URIRepresentation = URL(string: postID),
            let objectID = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: URIRepresentation),
            let managedObject = try? context.existingObject(with: objectID),
            let post = managedObject as? Post else {
                return nil
        }

        return post
    }
}
