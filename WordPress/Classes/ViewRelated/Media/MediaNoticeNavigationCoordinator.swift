import UIKit

class MediaNoticeNavigationCoordinator {
    private static let blogIDKey = "blog_id"

    static func presentEditor(with userInfo: NSDictionary) {
        let context = ContextManager.sharedInstance().mainContext

        if let blogID = userInfo[MediaNoticeNavigationCoordinator.blogIDKey] as? String,
            let URIRepresentation = URL(string: blogID),
            let objectID = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: URIRepresentation),
            let managedObject = try? context.existingObject(with: objectID),
            let blog = managedObject as? Blog {
            presentEditor(for: blog, source: "media_upload_notification")
        }
    }

    static func presentEditor(for blog: Blog, source: String) {
        let editor = EditPostViewController(blog: blog)
        editor.modalPresentationStyle = .fullScreen
        WPTabBarController.sharedInstance().present(editor, animated: false, completion: nil)
        WPAppAnalytics.track(.editorCreatedPost, withProperties: ["tap_source": source], with: blog)
    }
}
