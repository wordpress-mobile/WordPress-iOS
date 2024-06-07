import SwiftUI
import UIKit

protocol NotificationDetailArrowDelegate: AnyObject {
    func previousNotificationTapped(notification: Notification?)
    func nextNotificationTapped(notification: Notification?)
}

final class MilestoneCoordinator {
    let shouldShowPrevious: Bool
    let shouldShowNext: Bool
    private let notification: Notification
    private weak var coordinatorDelegate: NotificationDetailArrowDelegate?

    init(notification: Notification, 
         shouldShowPrevious: Bool,
         shouldShowNext: Bool,
         coordinatorDelegate: NotificationDetailArrowDelegate?) {
        self.notification = notification
        self.shouldShowPrevious = shouldShowPrevious
        self.shouldShowNext = shouldShowNext
        self.coordinatorDelegate = coordinatorDelegate
    }

    func createHostingController() -> MilestoneHostingController<MilestoneView> {
        let hostingController = MilestoneHostingController(
            rootView: MilestoneView(
                milestoneImageURL: notification.iconURL,
                accentColor: .DS.Foreground.brand(isJetpack: AppConfiguration.isJetpack),
                title: "Happy aniversary with WordPress! "
            ),
            milestoneCoordinator: self,
            notification: notification
        )
        hostingController.navigationItem.largeTitleDisplayMode = .never
        hostingController.hidesBottomBarWhenPushed = true
        return hostingController
    }
}

extension MilestoneCoordinator: CommentDetailsNotificationDelegate {
    func previousNotificationTapped(current: Notification?) {
        WPAnalytics.track(.notificationsPreviousTapped)
        coordinatorDelegate?.previousNotificationTapped(notification: current)
    }

    func nextNotificationTapped(current: Notification?) {
        WPAnalytics.track(.notificationsNextTapped)
        coordinatorDelegate?.nextNotificationTapped(notification: current)
    }

    func commentWasModerated(for notification: Notification?) {}
}
