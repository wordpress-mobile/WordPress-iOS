import SwiftUI
import UIKit

public class ContactSupportFlowController {

    private let externalSupportPresenter: ExternalSupportConversationPresenter
    private let eventLogger: EventLogger

    public init(
        onSupportRequested: @escaping () -> Void,
        onHelpPageLoaded: @escaping (URL) -> Void
    ) {
        externalSupportPresenter = ExternalSupportConversationPresenter(
            onStartSupportRequest: onSupportRequested
        )
        eventLogger = EventLogger(onHelpPageLoaded: onHelpPageLoaded)
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
                    .environmentObject(eventLogger)
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

class EventLogger: ObservableObject {

    private let onHelpPageLoaded: (URL) -> Void

    init(onHelpPageLoaded: @escaping (URL) -> Void) {
        self.onHelpPageLoaded = onHelpPageLoaded
    }

    func logHelpPageLoaded(with url: URL) {
        onHelpPageLoaded(url)
    }
}
