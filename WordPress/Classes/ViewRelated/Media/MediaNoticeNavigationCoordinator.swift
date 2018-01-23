import UIKit

/// This class simply exists to coordinate the display of various sections of
/// the app in response to actions taken by the user from Media notifications.
///
class MediaNoticeNavigationCoordinator {
    private static let blogIDKey = "blog_id"

    static func presentEditor(with userInfo: NSDictionary) {
        if let blog = blog(from: userInfo) {
            presentEditor(for: blog, source: "media_upload_notification")
        }
    }

    static func presentEditor(for blog: Blog, source: String) {
        let editor = EditPostViewController(blog: blog)
        editor.modalPresentationStyle = .fullScreen
        WPTabBarController.sharedInstance().present(editor, animated: false, completion: nil)
        WPAppAnalytics.track(.editorCreatedPost, withProperties: ["tap_source": source], with: blog)
    }

    static func navigateToMediaLibrary(with userInfo: NSDictionary) {
        if let blog = blog(from: userInfo) {
            WPTabBarController.sharedInstance().switchMySitesTabToMedia(for: blog)
        }
    }

    private static func blog(from userInfo: NSDictionary) -> Blog? {
        let context = ContextManager.sharedInstance().mainContext

        guard let blogID = userInfo[MediaNoticeNavigationCoordinator.blogIDKey] as? String,
            let URIRepresentation = URL(string: blogID),
            let objectID = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: URIRepresentation),
            let managedObject = try? context.existingObject(with: objectID),
            let blog = managedObject as? Blog else {
                return nil
        }

        return blog
    }
}
