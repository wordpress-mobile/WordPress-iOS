import Foundation
import SVProgressHUD

@objc class PostSharingController: NSObject {

    @objc func shareController(_ title: String?, summary: String?, link: String?) -> UIActivityViewController {
        let url = link.flatMap(URL.init(string:))
        let allItems: [Any?] = [title, summary, url]
        let nonNilActivityItems = allItems.compactMap({ $0 })

        var activities: [UIActivity] = [CopyLinkActivity()]
        activities.append(contentsOf: WPActivityDefaults.defaultActivities() as! [UIActivity])
        let controller = UIActivityViewController(activityItems: nonNilActivityItems, applicationActivities: activities)

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

    @objc func sharePost(_ title: String, summary: String, link: String?, fromBarButtonItem anchorBarButtonItem: UIBarButtonItem, inViewController viewController: UIViewController) {
        let controller = shareController(
            title,
            summary: summary,
            link: link)

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

    @objc func sharePost(_ title: String?, summary: String?, link: String?, fromView anchorView: UIView, inViewController viewController: UIViewController) {
        sharePost(title, summary: summary, link: link, fromAnchor: .view(anchorView), inViewController: viewController)
    }

    private func sharePost(_ title: String?, summary: String?, link: String?, fromAnchor anchor: PopoverAnchor, inViewController viewController: UIViewController) {
        let controller = shareController(
            title,
            summary: summary,
            link: link)

        if !UIDevice.isPad() {
            viewController.present(controller, animated: true)
            return
        }

        // Silly iPad popover rules.
        controller.modalPresentationStyle = .popover
        viewController.present(controller, animated: true)
        if let presentationController = controller.popoverPresentationController {
            presentationController.permittedArrowDirections = .any
            switch anchor {
            case .barButtonItem(let item):
                presentationController.barButtonItem = item
            case .view(let anchorView):
                presentationController.sourceView = anchorView
                presentationController.sourceRect = anchorView.bounds
            }
        }
    }

    @objc func sharePage(_ page: Page, fromView anchorView: UIView, inViewController viewController: UIViewController) {

        sharePost(
            page.titleForDisplay(),
            summary: page.contentPreviewForDisplay(),
            link: page.permaLink,
            fromView: anchorView,
            inViewController: viewController)
    }

    @objc func sharePost(_ post: Post, fromBarButtonItem anchorBarButtonItem: UIBarButtonItem, inViewController viewController: UIViewController) {

        sharePost(
            post.titleForDisplay(),
            summary: post.contentPreviewForDisplay(),
            link: post.permaLink,
            fromBarButtonItem: anchorBarButtonItem,
            inViewController: viewController)
    }

    @objc func sharePost(_ post: Post, fromView anchorView: UIView, inViewController viewController: UIViewController) {

        sharePost(
            post.titleForDisplay(),
            summary: post.contentPreviewForDisplay(),
            link: post.permaLink,
            fromView: anchorView,
            inViewController: viewController)
    }

    func shareReaderPost(_ post: ReaderPost, fromAnchor anchor: PopoverAnchor, inViewController viewController: UIViewController) {

        sharePost(
            post.titleForDisplay(),
            summary: post.contentPreviewForDisplay(),
            link: post.permaLink,
            fromAnchor: anchor,
            inViewController: viewController)
    }

    @objc func shareReaderPost(_ post: ReaderPost, fromView anchorView: UIView, inViewController viewController: UIViewController) {

        sharePost(
            post.titleForDisplay(),
            summary: post.contentPreviewForDisplay(),
            link: post.permaLink,
            fromView: anchorView,
            inViewController: viewController)
    }

    @objc func shareURL(url: NSURL, fromRect rect: CGRect, inView view: UIView, inViewController viewController: UIViewController) {
        let controller = shareController("", summary: "", link: url.absoluteString)

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

    typealias PopoverAnchor = UIPopoverPresentationController.PopoverAnchor
}

private class CopyLinkActivity: UIActivity {
    var activityItems = [Any]()
    private var url = URL(string: "")

    override var activityTitle: String? {
        return NSLocalizedString(
            "share.sheet.copy.link.title",
            value: "Copy Link",
            comment: "Title for the \"Copy Link\" action in Share Sheet."
        )
    }

    override var activityImage: UIImage? {
        return UIImage(systemName: "link")
    }

    override var activityType: UIActivity.ActivityType? {
        return UIActivity.ActivityType(rawValue: "copy.link.activity")
    }

    override class var activityCategory: UIActivity.Category {
       return .action
   }

    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        for activityItem in activityItems {
           if let _ = activityItem as? URL {
              return true
           }
        }
        return false
    }

   override func prepare(withActivityItems activityItems: [Any]) {
       for activityItem in activityItems {
           if let url = activityItem as? URL {
               self.url = url
           }
       }
       self.activityItems = activityItems
   }

   override func perform() {
       guard let url else {
           return
       }
       UIPasteboard.general.string = url.absoluteString
       activityDidFinish(true)
   }
}
