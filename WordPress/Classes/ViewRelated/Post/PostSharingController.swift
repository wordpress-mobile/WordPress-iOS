import Foundation
import UIKit
import SVProgressHUD

@objc class PostSharingController: NSObject {

    @objc func shareController(_ title: String?, link: String?) -> UIActivityViewController {
        let url = link.flatMap(URL.init(string:))
        let allItems: [Any?] = [url]
        let nonNilActivityItems = allItems.compactMap({ $0 })

        let activities = WPActivityDefaults.defaultActivities() as! [UIActivity]
        let controller = UIActivityViewController(activityItems: nonNilActivityItems, applicationActivities: activities)

        if let title {
            controller.setValue(title, forKey: "subject")
        }
        controller.completionWithItemsHandler = { (activityType, completed, returnedItems, error) in
            if completed {
                WPActivityDefaults.trackActivityType((activityType).map { $0.rawValue })
            }
        }

        return controller
    }

    @objc func sharePost(_ title: String, link: String?, fromBarButtonItem anchorBarButtonItem: UIBarButtonItem, inViewController viewController: UIViewController) {
        let controller = shareController(title, link: link)

        if !UIDevice.isPad() {
            viewController.present(controller, animated: true)
            return
        }

        // Silly iPad popover rules.
        controller.modalPresentationStyle = .popover
        viewController.present(controller, animated: true)
        if let presentationController = controller.popoverPresentationController {
            presentationController.permittedArrowDirections = .any
            presentationController.barButtonItem = anchorBarButtonItem
        }
    }

    @objc func sharePost(_ title: String?, link: String?, fromView anchorView: UIView, inViewController viewController: UIViewController) {
        sharePost(title, link: link, fromAnchor: anchorView, inViewController: viewController)
    }

    private func sharePost(_ title: String?, link: String?, fromAnchor anchor: UIPopoverPresentationControllerSourceItem, inViewController viewController: UIViewController) {
        let controller = shareController(title, link: link)
        if !UIDevice.isPad() {
            viewController.present(controller, animated: true)
            return
        }

        // Silly iPad popover rules.
        controller.modalPresentationStyle = .popover
        viewController.present(controller, animated: true)
        if let presentationController = controller.popoverPresentationController {
            presentationController.permittedArrowDirections = .any
            presentationController.sourceItem = anchor
        }
    }

    @objc func sharePage(_ page: Page, fromView anchorView: UIView, inViewController viewController: UIViewController) {
        sharePost(
            page.titleForDisplay(),
            link: page.permaLink,
            fromView: anchorView,
            inViewController: viewController)
    }

    @objc func sharePost(_ post: Post, fromBarButtonItem anchorBarButtonItem: UIBarButtonItem, inViewController viewController: UIViewController) {
        sharePost(
            post.titleForDisplay(),
            link: post.permaLink,
            fromBarButtonItem: anchorBarButtonItem,
            inViewController: viewController)
    }

    @objc func sharePost(_ post: Post, fromView anchorView: UIView, inViewController viewController: UIViewController) {
        sharePost(
            post.titleForDisplay(),
            link: post.permaLink,
            fromView: anchorView,
            inViewController: viewController)
    }

    func shareReaderPost(_ post: ReaderPost, fromAnchor anchor: UIPopoverPresentationControllerSourceItem, inViewController viewController: UIViewController) {
        sharePost(
            post.titleForDisplay(),
            link: post.permaLink,
            fromAnchor: anchor,
            inViewController: viewController)
    }

    @objc func shareReaderPost(_ post: ReaderPost, fromView anchorView: UIView, inViewController viewController: UIViewController) {
        sharePost(
            post.titleForDisplay(),
            link: post.permaLink,
            fromView: anchorView,
            inViewController: viewController)
    }

    @objc func shareURL(url: NSURL, fromRect rect: CGRect, inView view: UIView, inViewController viewController: UIViewController) {
        let controller = shareController("", link: url.absoluteString)

        if !UIDevice.isPad() {
            viewController.present(controller, animated: true)
            return
        }

        // Silly iPad popover rules.
        controller.modalPresentationStyle = .popover

        viewController.present(controller, animated: true)

        if let presentationController = controller.popoverPresentationController {
            presentationController.permittedArrowDirections = .any
            presentationController.sourceView = view
            presentationController.sourceRect = rect
        }

    }
}
