import SwiftUI
import UIKit

/// This allows us to dismiss the UIKit-presented SwiftUI flow.
/// We'll pass it through the screens as an environment object.
///
final class BlogRemindersCoordinator: ObservableObject {
    var presenter: UIViewController?

    func dismiss() {
        presenter?.dismiss(animated: true)
    }
}

/// UIKit container for the SwiftUI-based reminders setting flow.
///
class BloggingRemindersSettingsContainerViewController: UIViewController, DrawerPresentable {
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .basicBackground

        let rootView = Text("").environmentObject(makeCoordinator())
        let host = UIHostingController(rootView: rootView)

        host.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(host)
        view.addSubview(host.view)
        view.pinSubviewToAllEdges(host.view)
        host.didMove(toParent: self)
    }

    func makeCoordinator() -> BlogRemindersCoordinator {
        let coordinator = BlogRemindersCoordinator()
        coordinator.presenter = self
        return coordinator
    }

    var collapsedHeight: DrawerHeight {
        .intrinsicHeight
    }

    var allowsDragToDismiss: Bool {
        true
    }
}
