import UIKit
import WordPressMediaLibrary

/// App-target conformer for `MediaDetailNavigator`. Pushes view controllers
/// the module hands it (already wrapped in `UIHostingController`) onto the
/// host's outer `UINavigationController`. Holds the host weakly; production
/// routing constructs the adapter, builds the hosting controller, then
/// calls `attach(host:)` to close the loop — same pattern as
/// `MediaDetailURLOpenerAdapter`.
@MainActor
final class MediaDetailNavigatorAdapter: MediaDetailNavigator {
    private weak var host: UIViewController?

    init() {}

    func attach(host: UIViewController) {
        self.host = host
    }

    func push(_ viewController: UIViewController) {
        host?.navigationController?.pushViewController(viewController, animated: true)
    }
}
