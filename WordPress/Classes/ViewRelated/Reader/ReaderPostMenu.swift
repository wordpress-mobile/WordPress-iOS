import Foundation
import SVProgressHUD


struct ReaderPostMenuButtonTitles {
    static let cancel = NSLocalizedString("Cancel", comment: "The title of a cancel button.")
    static let blockSite = NSLocalizedString("Block This Site", comment: "The title of a button that triggers blocking a site from the user's reader.")
    static let reportPost = NSLocalizedString("Report This Post", comment: "The title of a button that triggers reporting of a post from the user's reader.")
    static let share = NSLocalizedString("Share", comment: "Verb. Title of a button. Pressing lets the user share a post to others.")
    static let visit = NSLocalizedString("Visit", comment: "An option to visit the site to which a specific post belongs")
    static let unfollow = NSLocalizedString("Unfollow Site", comment: "Verb. An option to unfollow a site.")
    static let follow = NSLocalizedString("Follow Site", comment: "Verb. An option to follow a site.")
    static let subscribe = NSLocalizedString("Turn on site notifications", comment: "Verb. An option to switch on site notifications.")
    static let unsubscribe = NSLocalizedString("Turn off site notifications", comment: "Verb. An option to switch off site notifications.")
}


open class ReaderPostMenu {
    public static let BlockSiteNotification = "ReaderPostMenuBlockSiteNotification"

    open class func showMenuForPost(_ post: ReaderPost, topic: ReaderSiteTopic? = nil, fromView anchorView: UIView, inViewController viewController: UIViewController?) {

        guard let viewController = viewController else {
            return
        }

        // Create the action sheet
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addCancelActionWithTitle(ReaderPostMenuButtonTitles.cancel, handler: nil)

        // Block button
        if shouldShowBlockSiteMenuItemForPost(post) {
            alertController.addActionWithTitle(ReaderPostMenuButtonTitles.blockSite,
                style: .destructive,
                handler: { (action: UIAlertAction) in
                    self.blockSiteForPost(post)
            })
        }

        // Notification
        if let topic = topic,
            post.isFollowing {
            let isSubscribedForPostNotifications = topic.isSubscribedForPostNotifications
            let buttonTitle = isSubscribedForPostNotifications ? ReaderPostMenuButtonTitles.unsubscribe : ReaderPostMenuButtonTitles.subscribe
            alertController.addActionWithTitle(buttonTitle,
                                               style: .default,
                                               handler: { (action: UIAlertAction) in
                                                if let topic: ReaderSiteTopic = self.existingObject(for: topic.objectID, context: topic.managedObjectContext) {
                                                    self.toggleSubscribingNotifications(for: topic)
                                                }
            })
        }

        // Following
        let buttonTitle = post.isFollowing ? ReaderPostMenuButtonTitles.unfollow : ReaderPostMenuButtonTitles.follow
        alertController.addActionWithTitle(buttonTitle,
            style: .default,
            handler: { (action: UIAlertAction) in
                if let post: ReaderPost = self.existingObject(for: post.objectID, context: post.managedObjectContext) {
                    self.toggleFollowingForPost(post, viewController)
                }
        })

        // Visit site
        alertController.addActionWithTitle(ReaderPostMenuButtonTitles.visit,
            style: .default,
            handler: { (action: UIAlertAction) in
                self.visitSiteForPost(post, presentingViewController: viewController)
        })

        // Share
        alertController.addActionWithTitle(ReaderPostMenuButtonTitles.share,
            style: .default,
            handler: { (action: UIAlertAction) in
                let sharingController = PostSharingController()

                sharingController.shareReaderPost(post, fromView: anchorView, inViewController: viewController)
        })

        if UIDevice.isPad() {
            alertController.modalPresentationStyle = .popover
            viewController.present(alertController, animated: true)
            if let presentationController = alertController.popoverPresentationController {
                presentationController.permittedArrowDirections = .any
                presentationController.sourceView = anchorView
                presentationController.sourceRect = anchorView.bounds
            }

        } else {
            viewController.present(alertController, animated: true)
        }

        WPAnalytics.track(.readerArticleDetailMoreTapped)
    }

    fileprivate class func existingObject<T>(for objectID: NSManagedObjectID?, context: NSManagedObjectContext?) -> T? {
        guard let objectID = objectID, let context = context else {
            return nil
        }

        do {
            return (try context.existingObject(with: objectID)) as? T
        } catch let error as NSError {
            DDLogError(error.localizedDescription)
            return nil
        }
    }

    fileprivate class func toggleSubscribingNotifications(for topic: ReaderSiteTopic) {
        if let context = topic.managedObjectContext {
            let subscribe = !topic.isSubscribedForPostNotifications
            let event: WPAnalyticsStat = subscribe ? .readerListNotificationMenuOn : .readerListNotificationMenuOff
            let service = ReaderTopicService(managedObjectContext: context)
            service.toggleSubscribingNotifications(for: topic.siteID.intValue, subscribe: subscribe, {
                WPAnalytics.track(event)
            })
        }
    }

    fileprivate class func shouldShowBlockSiteMenuItemForPost(_ post: ReaderPost) -> Bool {
        if let topic = post.topic {
            if ReaderHelpers.isLoggedIn() {
                return ReaderHelpers.isTopicTag(topic) || ReaderHelpers.topicIsFreshlyPressed(topic)
            }
        }
        return false
    }


    fileprivate class func blockSiteForPost(_ post: ReaderPost) {
        // TODO: Dispatch notification to block the site for the specified post.
        // The list and the detail will need to handle this separately
        NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: BlockSiteNotification), object: nil, userInfo: ["post": post])
    }


    fileprivate class func toggleFollowingForPost(_ post: ReaderPost, _ viewController: UIViewController) {
        guard let context = post.managedObjectContext else {
            return
        }

        let generator = UINotificationFeedbackGenerator()
        generator.prepare()

        var errorMessage: String!
        var errorTitle: String!
        if post.isFollowing {
            errorTitle = NSLocalizedString("Problem Unfollowing Site", comment: "Title of a prompt")
            errorMessage = NSLocalizedString("There was a problem unfollowing the site. If the problem persists you can contact us via the Me > Help & Support screen.", comment: "Short notice that there was a problem unfollowing a site and instructions on how to notify us of the problem.")
        } else {
            errorTitle = NSLocalizedString("Problem Following Site", comment: "Title of a prompt")
            errorMessage = NSLocalizedString("There was a problem following the site.  If the problem persists you can contact us via the Me > Help & Support screen.", comment: "Short notice that there was a problem following a site and instructions on how to notify us of the problem.")

            generator.notificationOccurred(.success)
        }

        let siteTitle = post.blogNameForDisplay()
        let siteID = post.siteID
        let toFollow = !post.isFollowing

        let postService = ReaderPostService(managedObjectContext: context)
        let topicService = ReaderTopicService(managedObjectContext: postService.managedObjectContext)

        if !toFollow {
            topicService.toggleSubscribingNotifications(for: siteID?.intValue, subscribe: false, {
                WPAnalytics.track(.readerListNotificationMenuOff)
            })
        }


        postService.toggleFollowing(for: post, success: { () in
            if toFollow {
                viewController.dispatchSubscribingNotificationNotice(with: siteTitle, siteID: siteID)
            }
        }, failure: { (error: Error?) in
                generator.notificationOccurred(.error)

                let cancelTitle = NSLocalizedString("OK", comment: "Text of an OK button to dismiss a prompt.")
                let alertController = UIAlertController(title: errorTitle,
                    message: errorMessage,
                    preferredStyle: .alert)
                alertController.addCancelActionWithTitle(cancelTitle, handler: nil)
                alertController.presentFromRootViewController()
        })
    }


    fileprivate class func visitSiteForPost(_ post: ReaderPost, presentingViewController viewController: UIViewController) {
        guard
            let permalink = post.permaLink,
            let siteURL = URL(string: permalink) else {
                return
        }

        let configuration = WebViewControllerConfiguration(url: siteURL)
        configuration.addsWPComReferrer = true
        configuration.authenticateWithDefaultAccount()
        let controller = WebViewControllerFactory.controller(configuration: configuration)
        let navController = UINavigationController(rootViewController: controller)
        viewController.present(navController, animated: true)
    }
}
