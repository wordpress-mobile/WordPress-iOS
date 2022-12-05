import UIKit

struct MigrationSuccessActionHandler {

    private let tracker: MigrationAnalyticsTracker

    init(tracker: MigrationAnalyticsTracker = .init()) {
        self.tracker = tracker
    }

    func showDeleteWordPressOverlay(with viewController: UIViewController) {
        tracker.track(.pleaseDeleteWordPressCardTapped)
        let destination = MigrationDeleteWordPressViewController()
        viewController.present(UINavigationController(rootViewController: destination), animated: true)
    }
}
