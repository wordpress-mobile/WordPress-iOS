import UIKit
import WordPressData

/// Encapsulates a command to navigate to a post's comments
final class ReaderCommentAction {
    func execute(
        post: ReaderPost,
        origin: UIViewController,
        navigateToCommentID: Int? = nil,
        source: ReaderCommentsSource,
        trackingSource: ScreenTrackingSource? = nil
    ) {
        let commentsVC = ReaderCommentsViewController(post: post)
        commentsVC.source = source
        commentsVC.navigateToCommentID = navigateToCommentID as NSNumber?
        commentsVC.hidesBottomBarWhenPushed = true
        if let trackingSource {
            commentsVC.trackingContext.source = trackingSource
        }

        if origin.traitCollection.horizontalSizeClass == .compact {
            let navigationVC = UINavigationController(rootViewController: commentsVC)
            commentsVC.navigationItem.leftBarButtonItem = UIBarButtonItem(title: SharedStrings.Button.close, primaryAction: UIAction { [weak origin] _ in
                origin?.dismiss(animated: true)
            })
            origin.present(navigationVC, animated: true)
        } else {
            origin.navigationController?.pushViewController(commentsVC, animated: true)
        }
    }
}
