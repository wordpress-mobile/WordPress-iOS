import UIKit
import SwiftUI
import WordPressData
import WordPressShared
import WordPressUI

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
            return wpAssertionFailure("presenter missing")
        }

        let controller = PreviewWebKitViewController(post: page, source: "post_notice_preview")
        controller.trackOpenEvent()
        controller.navigationItem.title = NSLocalizedString("View", comment: "Verb. The screen title shown when viewing a post inside the app.")
        presenter.presentCoveringWindow(controller)
    }

    private static func presentPostEpilogue(for post: Post) {
        guard let presenter = UIApplication.shared.delegate?.window??.topmostPresentedViewController else {
            return wpAssertionFailure("presenter missing")
        }

        let context = PostNoticePublishSuccessView.Context()
        let view = PostNoticePublishSuccessView(post: post, context: context) {
            presenter.dismiss(animated: true)
        }
        let viewController = UIHostingController(rootView: view)
        presenter.presentAdaptiveSheet(
            viewController,
            formSheetSize: CGSize(width: 460, height: 460),
            compactDetents: [.custom { _ in 420 }],
            compactCornerRadius: 20
        )
        context.viewController = viewController
    }

    private static func post(from userInfo: NSDictionary) -> AbstractPost? {
        let context = ContextManager.shared.mainContext

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
