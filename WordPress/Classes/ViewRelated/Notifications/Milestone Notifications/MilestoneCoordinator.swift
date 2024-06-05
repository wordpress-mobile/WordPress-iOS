import SwiftUI
import UIKit

final class MilestoneCoordinator {
    private let notification: Notification

    init(notification: Notification) {
        self.notification = notification
    }

    func createHostingController() -> MilestoneHostingController<MilestoneView> {
        let hostingController = MilestoneHostingController(
            rootView: MilestoneView(
                milestoneImageURL: notification.iconURL,
                accentColor: .DS.Foreground.brand(isJetpack: AppConfiguration.isJetpack),
                title: "Happy aniversary with WordPress! "
            )
        )
        hostingController.navigationItem.largeTitleDisplayMode = .never
        hostingController.hidesBottomBarWhenPushed = true
        return hostingController
    }
}
