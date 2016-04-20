import Foundation
import SVProgressHUD

public class ReaderPostMenu
{
    public static let BlockSiteNotification = "ReaderPostMenuBlockSiteNotification"

    struct ReaderPostMenuButtonTitles
    {
        static let cancel = NSLocalizedString("Cancel", comment:"The title of a cancel button.")
        static let blockSite = NSLocalizedString("Block This Site", comment:"The title of a button that triggers blocking a site from the user's reader.")
        static let share = NSLocalizedString("Share", comment:"Verb. Title of a button. Pressing the lets the user share a post to others.")
        static let visit = NSLocalizedString("Visit Site", comment:"An option to visit the site to which a specific post belongs")
        static let unfollow = NSLocalizedString("Unfollow Site", comment:"Verb. An option to unfollow a site.")
        static let follow = NSLocalizedString("Follow Site", comment:"Verb. An option to follow a site.")
    }


    public class func showMenuForPost(post:ReaderPost, fromView anchorView:UIView, inViewController viewController:UIViewController) {
        // Create the action sheet
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        alertController.addCancelActionWithTitle(ReaderPostMenuButtonTitles.cancel, handler: nil)

        // Block button
        if shouldShowBlockSiteMenuItemForPost(post) {
            alertController.addActionWithTitle(ReaderPostMenuButtonTitles.blockSite,
                style: .Destructive,
                handler: { (action:UIAlertAction) in
                    self.blockSiteForPost(post)
            })
        }

        // Following
        let buttonTitle = post.isFollowing ? ReaderPostMenuButtonTitles.unfollow : ReaderPostMenuButtonTitles.follow
        alertController.addActionWithTitle(buttonTitle,
            style: .Default,
            handler: { (action:UIAlertAction) in
                self.toggleFollowingForPost(post)
        })

        // Visit site
        alertController.addActionWithTitle(ReaderPostMenuButtonTitles.visit,
            style: .Default,
            handler: { (action:UIAlertAction) in
                self.visitSiteForPost(post, presentingViewController: viewController)
        })

        // Share
        alertController.addActionWithTitle(ReaderPostMenuButtonTitles.share,
            style: .Default,
            handler: { (action:UIAlertAction) in
                ReaderHelpers.sharePost(post, fromView: anchorView, inViewController: viewController)
        })

        if UIDevice.isPad() {
            alertController.modalPresentationStyle = .Popover
            viewController.presentViewController(alertController, animated: true, completion: nil)
            if let presentationController = alertController.popoverPresentationController {
                presentationController.permittedArrowDirections = .Any
                presentationController.sourceView = anchorView
                presentationController.sourceRect = anchorView.bounds
            }

        } else {
            viewController.presentViewController(alertController, animated: true, completion: nil)
        }
    }


    private class func shouldShowBlockSiteMenuItemForPost(post:ReaderPost) -> Bool {
        if let topic = post.topic {
            if (ReaderHelpers.isLoggedIn()) {
                return ReaderHelpers.isTopicTag(topic) || ReaderHelpers.topicIsFreshlyPressed(topic)
            }
        }
        return false
    }


    private class func blockSiteForPost(post:ReaderPost) {
        // TODO: Dispatch notification to block the site for the specified post.
        // The list and the detail will need to handle this separately
        NSNotificationCenter.defaultCenter().postNotificationName(BlockSiteNotification, object: nil, userInfo: ["post":post])
    }


    private class func toggleFollowingForPost(post:ReaderPost) {
        var successMessage:String!
        var errorMessage:String!
        var errorTitle:String!
        if post.isFollowing {
            successMessage = NSLocalizedString("Unfollowed site", comment: "Short confirmation that unfollowing a site was successful")
            errorTitle = NSLocalizedString("Problem Unfollowing Site", comment: "Title of a prompt")
            errorMessage = NSLocalizedString("There was a problem unfollowing the site. If the problem persists you can contact us via the Me > Help & Support screen.", comment: "Short notice that there was a problem unfollowing a site and instructions on how to notify us of the problem.")
        } else {
            successMessage = NSLocalizedString("Followed site", comment: "Short confirmation that unfollowing a site was successful")
            errorTitle = NSLocalizedString("Problem Following Site", comment: "Title of a prompt")
            errorMessage = NSLocalizedString("There was a problem following the site.  If the problem persists you can contact us via the Me > Help & Support screen.", comment: "Short notice that there was a problem following a site and instructions on how to notify us of the problem.")
        }

        SVProgressHUD.show()
        let postService = ReaderPostService(managedObjectContext: post.managedObjectContext)
        postService.toggleFollowingForPost(post, success: { () in
            SVProgressHUD.showSuccessWithStatus(successMessage)
            }, failure: { (error:NSError!) in
                SVProgressHUD.dismiss()

                let cancelTitle = NSLocalizedString("OK", comment: "Text of an OK button to dismiss a prompt.")
                let alertController = UIAlertController(title: errorTitle,
                    message: errorMessage,
                    preferredStyle: .Alert)
                alertController.addCancelActionWithTitle(cancelTitle, handler: nil)
                alertController.presentFromRootViewController()
        })
    }


    private class func visitSiteForPost(post:ReaderPost, presentingViewController viewController:UIViewController) {
        let siteURL = NSURL(string: post.blogURL)!
        let controller = WPWebViewController(URL: siteURL)
        let navController = UINavigationController(rootViewController: controller)
        viewController.presentViewController(navController, animated: true, completion: nil)
    }
}
