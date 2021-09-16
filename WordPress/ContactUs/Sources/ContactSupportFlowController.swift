import SwiftUI
import UIKit

public class ContactSupportFlowController {

    private let onSupportRequested: () -> Void
    private let onHelpPageLoaded: (URL) -> Void

    public init(
        onSupportRequested: @escaping () -> Void,
        onHelpPageLoaded: @escaping (URL) -> Void
    ) {
        self.onSupportRequested = onSupportRequested
        self.onHelpPageLoaded = onHelpPageLoaded
    }

    public func present(
        from viewController: UIViewController,
        animated: Bool = true,
        completion: (() -> Void)?
    ) {
        viewController.present(
            UIHostingController(rootView: ContactSupportFlowView()),
            animated: animated,
            completion: completion
        )
    }
}
