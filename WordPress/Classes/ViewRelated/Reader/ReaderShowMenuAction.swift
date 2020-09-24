/// Encapsulates a command to create and handle the extended menu for each post in Reader
final class ReaderShowMenuAction {
    private let isLoggedIn: Bool

    init(loggedIn: Bool) {
        isLoggedIn = loggedIn
    }

    func execute(with post: ReaderPost, context: NSManagedObjectContext, topic: ReaderSiteTopic? = nil, readerTopic: ReaderAbstractTopic?, anchor: UIView, vc: UIViewController) {
        // Create the action sheet
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addCancelActionWithTitle(ReaderPostMenuButtonTitles.cancel, handler: nil)


        // Block button
        if shouldShowBlockSiteMenuItem(readerTopic: readerTopic) {
            alertController.addActionWithTitle(ReaderPostMenuButtonTitles.blockSite,
                                               style: .destructive,
                                               handler: { (action: UIAlertAction) in
                                                if let post: ReaderPost = ReaderActionHelpers.existingObject(for: post.objectID, in: context) {
                                                    ReaderBlockSiteAction(asBlocked: true).execute(with: post, context: context, completion: {})
                                                }
            })
        }

        // Report button
        if shouldShowReportPostMenuItem(readerTopic: readerTopic) {
            alertController.addActionWithTitle(ReaderPostMenuButtonTitles.reportPost,
                                               style: .default,
                                               handler: { (action: UIAlertAction) in
                                                if let post: ReaderPost = ReaderActionHelpers.existingObject(for: post.objectID, in: context) {
                                                    ReaderReportPostAction().execute(with: post, context: context, origin: vc)
                                                }
            })
        }

        // Notification
        if let topic = topic, isLoggedIn, post.isFollowing {
            let isSubscribedForPostNotifications = topic.isSubscribedForPostNotifications
            let buttonTitle = isSubscribedForPostNotifications ? ReaderPostMenuButtonTitles.unsubscribe : ReaderPostMenuButtonTitles.subscribe
            alertController.addActionWithTitle(buttonTitle,
                                               style: .default,
                                               handler: { (action: UIAlertAction) in
                                                if let topic: ReaderSiteTopic = ReaderActionHelpers.existingObject(for: topic.objectID, in: context) {
                                                    ReaderSubscribingNotificationAction().execute(for: topic.siteID, context: context, value: !topic.isSubscribedForPostNotifications)
                                                }
            })
        }

        // Following
        if isLoggedIn {
            let buttonTitle = post.isFollowing ? ReaderPostMenuButtonTitles.unfollow : ReaderPostMenuButtonTitles.follow
            alertController.addActionWithTitle(buttonTitle,
                                               style: .default,
                                               handler: { (action: UIAlertAction) in
                                                if let post: ReaderPost = ReaderActionHelpers.existingObject(for: post.objectID, in: context) {
                                                    ReaderFollowAction().execute(with: post, context: context) {
                                                        guard let vc = vc as? ReaderStreamViewController else {
                                                            return
                                                        }
                                                        vc.updateStreamHeaderIfNeeded()
                                                    }
                                                }
            })
        }

        // Visit
        alertController.addActionWithTitle(ReaderPostMenuButtonTitles.visit,
                                           style: .default,
                                           handler: { (action: UIAlertAction) in
                                            ReaderVisitSiteAction().execute(with: post, context: context, origin: vc)
        })

        // Share
        alertController.addActionWithTitle(ReaderPostMenuButtonTitles.share,
                                           style: .default,
                                           handler: { (action: UIAlertAction) in
                                            ReaderShareAction().execute(with: post, context: context, anchor: anchor, vc: vc)
        })

        if WPDeviceIdentification.isiPad() {
            alertController.modalPresentationStyle = .popover
            vc.present(alertController, animated: true)
            if let presentationController = alertController.popoverPresentationController {
                presentationController.permittedArrowDirections = .any
                presentationController.sourceView = anchor
                presentationController.sourceRect = anchor.bounds
            }

        } else {
            vc.present(alertController, animated: true)
        }

        WPAnalytics.track(.postCardMoreTapped)
    }

    fileprivate func shouldShowBlockSiteMenuItem(readerTopic: ReaderAbstractTopic?) -> Bool {
        guard let topic = readerTopic else {
            return false
        }
        if isLoggedIn {
            return ReaderHelpers.isTopicTag(topic) || (ReaderHelpers.topicIsDiscover(topic) && FeatureFlag.readerImprovementsPhase2.enabled)
                || ReaderHelpers.topicIsFreshlyPressed(topic)
        }
        return false
    }

    fileprivate func shouldShowReportPostMenuItem(readerTopic: ReaderAbstractTopic?) -> Bool {
        return shouldShowBlockSiteMenuItem(readerTopic: readerTopic)
    }
}
