import UIKit
import SwiftUI

extension BlogDetailsViewController {
    func presentBloggingRemindersSettingsFlow() {
        // TODO: Check whether we've already presented this flow to the user. @frosty
        let coordinator = BlogRemindersCoordinator()
        coordinator.presenter = self

        let navigationController = BloggingRemindersNavigationController(rootViewController: BloggingRemindersSettingsContainerViewController(coordinator: coordinator),
                                                                         viewControllerDrawerPositions: [.collapsed, .expanded, .collapsed])

        let bottomSheet = BottomSheetViewController(childViewController: navigationController,
                                                    customHeaderSpacing: 0)
        bottomSheet.show(from: self)
    }
}
