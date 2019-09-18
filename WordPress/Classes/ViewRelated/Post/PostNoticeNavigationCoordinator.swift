import UIKit

/// This class simply exists to coordinate the display of various sections of
/// the app in response to actions taken by the user from Post notifications.
///
class PostNoticeNavigationCoordinator {
    static func presentPostEpilogue(with userInfo: NSDictionary) {
        if let post = self.post(from: userInfo) {
            presentPostEpilogue(for: post)
        }
    }

    static func presentPostEpilogue(for post: AbstractPost) {
        if let page = post as? Page {
            presentViewPage(for: page)
        } else if let post = post as? Post {
            presentPostEpilogue(for: post)
        }
    }

    private static func presentViewPage(for page: Page) {
        guard let presenter = UIApplication.shared.delegate?.window??.topmostPresentedViewController else {
                return
        }

        let controller = PostPreviewViewController(post: page)
        controller.navigationItem.title = NSLocalizedString("View", comment: "Verb. The screen title shown when viewing a post inside the app.")
        controller.hidesBottomBarWhenPushed = true

        let navigationController = UINavigationController(rootViewController: controller)
        navigationController.modalPresentationStyle = .formSheet
        presenter.present(navigationController, animated: true)
    }

    private static func presentPostEpilogue(for post: Post) {
        guard let presenter = UIApplication.shared.delegate?.window??.topmostPresentedViewController else {
                return
        }

        let editor = EditPostViewController(post: post)
        editor.modalPresentationStyle = .fullScreen
        editor.openWithPostPost = true
        editor.onClose = { _ in
        }
        presenter.present(editor, animated: true)
    }

    static func retryPostUpload(with userInfo: NSDictionary) {
        if let post = self.post(from: userInfo) {
            PostCoordinator.shared.save(post)
        }
    }

    private static func post(from userInfo: NSDictionary) -> AbstractPost? {
        let context = ContextManager.sharedInstance().mainContext

        guard let postID = userInfo[PostNoticeUserInfoKey.postID] as? String,
            let URIRepresentation = URL(string: postID),
            let objectID = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: URIRepresentation),
            let managedObject = try? context.existingObject(with: objectID),
            let post = managedObject as? AbstractPost else {
                return nil
        }

        return post
    }
}
