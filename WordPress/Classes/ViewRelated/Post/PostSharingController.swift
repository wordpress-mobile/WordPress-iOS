import Foundation
import SVProgressHUD

@objc class PostSharingController: NSObject {

    func shareController(_ title: String?, summary: String?, link: String?) -> UIActivityViewController {
        var activityItems = [AnyObject]()
        let url = link.flatMap(URL.init(string:))
        let post = SharePost(title: title, summary: summary, url: url?.absoluteString)
        activityItems.append(post)

        let activities = WPActivityDefaults.defaultActivities() as! [UIActivity]
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: activities)
        if let str = title {
            controller.setValue(str, forKey: "subject")
        }
        controller.completionWithItemsHandler = { (activityType, completed, returnedItems, error) in
            if completed {
                WPActivityDefaults.trackActivityType((activityType).map { $0.rawValue })
            }
        }

        return controller
    }

    func sharePost(_ title: String, summary: String, link: String?, fromBarButtonItem anchorBarButtonItem: UIBarButtonItem, inViewController viewController: UIViewController) {
        let controller = shareController(
            title,
            summary: summary,
            link: link)

        if !UIDevice.isPad() {
            viewController.present(controller, animated: true, completion: nil)
            return
        }

        // Silly iPad popover rules.
        controller.modalPresentationStyle = .popover
        viewController.present(controller, animated: true, completion: nil)
        if let presentationController = controller.popoverPresentationController {
            presentationController.permittedArrowDirections = .any
            presentationController.barButtonItem = anchorBarButtonItem
        }
    }

    func sharePost(_ title: String, summary: String, link: String?, fromView anchorView: UIView, inViewController viewController: UIViewController) {
        let controller = shareController(
            title,
            summary: summary,
            link: link)

        if !UIDevice.isPad() {
            viewController.present(controller, animated: true, completion: nil)
            return
        }

        // Silly iPad popover rules.
        controller.modalPresentationStyle = .popover
        viewController.present(controller, animated: true, completion: nil)
        if let presentationController = controller.popoverPresentationController {
            presentationController.permittedArrowDirections = .any
            presentationController.sourceView = anchorView
            presentationController.sourceRect = anchorView.bounds
        }
    }

    func sharePost(_ post: Post, fromBarButtonItem anchorBarButtonItem: UIBarButtonItem, inViewController viewController: UIViewController) {

        sharePost(
            post.titleForDisplay(),
            summary: post.contentPreviewForDisplay(),
            link: post.permaLink,
            fromBarButtonItem: anchorBarButtonItem,
            inViewController: viewController)
    }

    func sharePost(_ post: Post, fromView anchorView: UIView, inViewController viewController: UIViewController) {

        sharePost(
            post.titleForDisplay(),
            summary: post.contentPreviewForDisplay(),
            link: post.permaLink,
            fromView: anchorView,
            inViewController: viewController)
    }

    func shareReaderPost(_ post: ReaderPost, fromView anchorView: UIView, inViewController viewController: UIViewController) {

        sharePost(
            post.titleForDisplay(),
            summary: post.contentPreviewForDisplay(),
            link: post.permaLink,
            fromView: anchorView,
            inViewController: viewController)
    }

    func shareURL(url: NSURL, fromRect rect: CGRect, inView view: UIView, inViewController viewController: UIViewController) {
        let controller = shareController("", summary: "", link: url.absoluteString)

        if !UIDevice.isPad() {
            viewController.present(controller, animated: true, completion: nil)
            return
        }

        // Silly iPad popover rules.
        controller.modalPresentationStyle = .popover

        viewController.present(controller, animated: true, completion: nil)
        if let presentationController = controller.popoverPresentationController {
            presentationController.permittedArrowDirections = .any
            presentationController.sourceView = view
            presentationController.sourceRect = rect
        }

    }
}
