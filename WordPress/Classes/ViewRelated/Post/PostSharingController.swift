import Foundation
import SVProgressHUD

@objc class PostSharingController : NSObject {

    func shareController(title:String?, summary:String?, tags:String?, link:String?) -> UIActivityViewController {
        var activityItems = [AnyObject]()
        let postDictionary = NSMutableDictionary()

        if let str = title {
            postDictionary["title"] = str
        }
        if let str = summary {
            postDictionary["summary"] = str
        }
        if let str = tags {
            postDictionary["tags"] = str
        }

        activityItems.append(postDictionary)
        if let urlPath = link, url = NSURL(string: urlPath) {
            activityItems.append(url)
        }

        let activities = WPActivityDefaults.defaultActivities() as! [UIActivity]
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: activities)
        if let str = title {
            controller.setValue(str, forKey:"subject")
        }
        controller.completionWithItemsHandler = {
            (activityType:String?, completed:Bool, items: [AnyObject]?, error: NSError?) in

            if completed {
                WPActivityDefaults.trackActivityType(activityType)
            }
        }

        return controller
    }

    func sharePost(title: String, summary: String, tags: String?, link: String?, fromBarButtonItem anchorBarButtonItem:UIBarButtonItem, inViewController viewController:UIViewController) {
        let controller = shareController(
            title,
            summary: summary,
            tags: tags,
            link: link)

        if !UIDevice.isPad() {
            viewController.presentViewController(controller, animated: true, completion: nil)
            return
        }

        // Silly iPad popover rules.
        controller.modalPresentationStyle = .Popover
        viewController.presentViewController(controller, animated: true, completion: nil)
        if let presentationController = controller.popoverPresentationController {
            presentationController.permittedArrowDirections = .Any
            presentationController.barButtonItem = anchorBarButtonItem
        }
    }

    func sharePost(title: String, summary: String, tags: String?, link: String?, fromView anchorView:UIView, inViewController viewController:UIViewController) {
        let controller = shareController(
            title,
            summary: summary,
            tags: tags,
            link: link)

        if !UIDevice.isPad() {
            viewController.presentViewController(controller, animated: true, completion: nil)
            return
        }

        // Silly iPad popover rules.
        controller.modalPresentationStyle = .Popover
        viewController.presentViewController(controller, animated: true, completion: nil)
        if let presentationController = controller.popoverPresentationController {
            presentationController.permittedArrowDirections = .Any
            presentationController.sourceView = anchorView
            presentationController.sourceRect = anchorView.bounds
        }
    }

    func sharePost(post: Post, fromBarButtonItem anchorBarButtonItem:UIBarButtonItem, inViewController viewController:UIViewController) {

        sharePost(
            post.titleForDisplay(),
            summary: post.contentPreviewForDisplay(),
            tags: post.tags,
            link: post.permaLink,
            fromBarButtonItem: anchorBarButtonItem,
            inViewController: viewController)
    }

    func sharePost(post: Post, fromView anchorView:UIView, inViewController viewController:UIViewController) {

        sharePost(
            post.titleForDisplay(),
            summary: post.contentPreviewForDisplay(),
            tags: post.tags,
            link: post.permaLink,
            fromView: anchorView,
            inViewController: viewController)
    }

    func shareReaderPost(post: ReaderPost, fromView anchorView:UIView, inViewController viewController:UIViewController) {

        sharePost(
            post.titleForDisplay(),
            summary: post.contentPreviewForDisplay(),
            tags: post.tags,
            link: post.permaLink,
            fromView: anchorView,
            inViewController: viewController)
    }
}
