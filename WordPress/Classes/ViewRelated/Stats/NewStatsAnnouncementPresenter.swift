import UIKit
import SwiftUI

enum NewStatsAnnouncementPresenter {

    private static let hasShownKey = "jetpackNewStatsAnnouncementShownKey"

    static func presentIfNeeded(in viewController: UIViewController, _ onContinue: @escaping () -> Void) {
        // Don't show it for users who already opted-in
        guard !FeatureFlag.newStats.enabled else {
            UserDefaults.standard.set(true, forKey: hasShownKey)
            return
        }
        guard !UserDefaults.standard.bool(forKey: hasShownKey) else {
            return
        }
        UserDefaults.standard.set(true, forKey: hasShownKey)

        let view = NewStatsAnnouncementView {
            viewController.dismiss(animated: true) {
                onContinue()
            }
        }
        let hostingController = UIHostingController(rootView: view)
        viewController.present(hostingController, animated: true)
    }
}
