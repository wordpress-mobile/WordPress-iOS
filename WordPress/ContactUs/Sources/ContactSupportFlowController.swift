import SwiftUI
import UIKit

public class ContactSupportFlowController {

    private let externalSupportPresenter: ExternalSupportConversationPresenter
    private let onHelpPageLoaded: (URL) -> Void

    public init(
        onSupportRequested: @escaping () -> Void,
        onHelpPageLoaded: @escaping (URL) -> Void
    ) {
        externalSupportPresenter = ExternalSupportConversationPresenter(
            onStartSupportRequest: onSupportRequested
        )
        self.onHelpPageLoaded = onHelpPageLoaded
    }

    public func present(
        from viewController: UIViewController,
        animated: Bool = true,
        completion: (() -> Void)? = .none
    ) {
        viewController.present(
            UIHostingController(
                rootView: ContactSupportFlowView()
                    .environmentObject(externalSupportPresenter)
            ),
            animated: animated,
            completion: completion
        )
    }
}

class ExternalSupportConversationPresenter: ObservableObject {

    private let onStartSupportRequest: () -> Void

    init(onStartSupportRequest: @escaping () -> Void) {
        self.onStartSupportRequest = onStartSupportRequest
    }

    func startExternalSupportConversation() {
        onStartSupportRequest()
    }
}
