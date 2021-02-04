/// Encapsulates a command to create and handle the extended menu for each post in Reader
final class ReaderShowMenuAction {
    private let isLoggedIn: Bool

    init(loggedIn: Bool) {
        isLoggedIn = loggedIn
    }

    func execute(with post: ReaderPost,
                 context: NSManagedObjectContext,
                 siteTopic: ReaderSiteTopic? = nil,
                 readerTopic: ReaderAbstractTopic? = nil,
                 anchor: UIView,
                 vc: UIViewController) {

        // Create the action sheet
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addCancelActionWithTitle(ReaderPostMenuButtonTitles.cancel, handler: nil)


        // Block button
        if shouldShowBlockSiteMenuItem(readerTopic: readerTopic, post: post) {
            alertController.addActionWithTitle(ReaderPostMenuButtonTitles.blockSite,
                                               style: .destructive,
                                               handler: { (action: UIAlertAction) in
                                                if let post: ReaderPost = ReaderActionHelpers.existingObject(for: post.objectID, in: context) {
                                                    ReaderBlockSiteAction(asBlocked: true).execute(with: post, context: context, completion: {})
                                                }
            })
        }

        // Report button
        if shouldShowReportPostMenuItem(readerTopic: readerTopic, post: post) {
            alertController.addActionWithTitle(ReaderPostMenuButtonTitles.reportPost,
                                               style: .default,
                                               handler: { (action: UIAlertAction) in
                                                if let post: ReaderPost = ReaderActionHelpers.existingObject(for: post.objectID, in: context) {
                                                    ReaderReportPostAction().execute(with: post, context: context, origin: vc)
                                                }
            })
        }

        // Notification
        if let siteTopic = siteTopic, isLoggedIn, post.isFollowing {
            let isSubscribedForPostNotifications = siteTopic.isSubscribedForPostNotifications
            let buttonTitle = isSubscribedForPostNotifications ? ReaderPostMenuButtonTitles.unsubscribe : ReaderPostMenuButtonTitles.subscribe
            alertController.addActionWithTitle(buttonTitle,
                                               style: .default,
                                               handler: { (action: UIAlertAction) in
                                                if let topic: ReaderSiteTopic = ReaderActionHelpers.existingObject(for: siteTopic.objectID, in: context) {
                                                    ReaderSubscribingNotificationAction().execute(for: topic.siteID, context: context, subscribe: !topic.isSubscribedForPostNotifications)
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
                                                    ReaderFollowAction().execute(with: post,
                                                                                 context: context,
                                                                                 completion: {
                                                                                    if post.isFollowing {
                                                                                        vc.dispatchSubscribingNotificationNotice(with: post.blogNameForDisplay(), siteID: post.siteID)
                                                                                    }

                                                                                    (vc as? ReaderStreamViewController)?.updateStreamHeaderIfNeeded()
                                                                                 },
                                                                                 failure: nil)
                                                }
                                               })
        }

        // Seen
        if FeatureFlag.unseenPosts.enabled {
            if post.isSeenSupported {
                alertController.addActionWithTitle(post.isSeen ? ReaderPostMenuButtonTitles.markUnseen : ReaderPostMenuButtonTitles.markSeen,
                                                   style: .default,
                                                   handler: { (action: UIAlertAction) in
                                                    if let post: ReaderPost = ReaderActionHelpers.existingObject(for: post.objectID, in: context) {
                                                        ReaderSeenAction().execute(with: post, context: context, failure: { _ in
                                                            ReaderHelpers.dispatchToggleSeenError(post: post)
                                                        })
                                                    }
                                                   })
            }
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

        WPAnalytics.trackReader(.postCardMoreTapped)
    }

    fileprivate func shouldShowBlockSiteMenuItem(readerTopic: ReaderAbstractTopic?, post: ReaderPost) -> Bool {
        guard let topic = readerTopic,
              isLoggedIn else {
            return false
        }

        return ReaderHelpers.isTopicTag(topic) ||
            ReaderHelpers.topicIsDiscover(topic) ||
            ReaderHelpers.topicIsFreshlyPressed(topic) ||
            (ReaderHelpers.topicIsFollowing(topic) && !post.isFollowing)
    }

    fileprivate func shouldShowReportPostMenuItem(readerTopic: ReaderAbstractTopic?, post: ReaderPost) -> Bool {
        return shouldShowBlockSiteMenuItem(readerTopic: readerTopic, post: post)
    }

}
