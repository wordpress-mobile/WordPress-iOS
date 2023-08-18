import Foundation
import WordPressAuthenticator

final class SupportCoordinator {
    private weak var controllerToShowFrom: UIViewController?
    private var tag: WordPressSupportSourceTag?

    private var navigationController: UINavigationController? {
        guard let navigationController = (controllerToShowFrom as? UINavigationController) ?? controllerToShowFrom?.navigationController else {
            return nil
        }

        return navigationController
    }

    init(controllerToShowFrom: UIViewController?,
         tag: WordPressSupportSourceTag? = nil) {
        self.controllerToShowFrom = controllerToShowFrom
        self.tag = tag
    }

    func showSupport(onIdentityUpdated: (() -> ())? = nil) {
        guard let controllerToShowFrom = controllerToShowFrom else { return }

        if AppConfiguration.isJetpack && RemoteFeatureFlag.contactSupportChatbot.enabled() {
            let chatBotViewController = SupportChatBotViewController(viewModel: .init(), delegate: self)
            if let navigationController = navigationController {
                navigationController.pushViewController(chatBotViewController, animated: true)
            } else {
                let navigationController = UINavigationController(rootViewController: chatBotViewController)
                controllerToShowFrom.present(navigationController, animated: true)
            }
        } else {
            ZendeskUtils.sharedInstance.showNewRequestIfPossible(from: controllerToShowFrom, with: tag) { identityUpdated in
                if identityUpdated {
                    onIdentityUpdated?()
                }
            }
        }
    }

    func showTicketView(onIdentityUpdated: (() -> ())? = nil) {
        guard let controllerToShowFrom = controllerToShowFrom else { return }

        ZendeskUtils.pushNotificationRead()
        ZendeskUtils.sharedInstance.showTicketListIfPossible(from: controllerToShowFrom, with: tag) { identityUpdated in
            if identityUpdated {
                onIdentityUpdated?()
            }
        }
    }
}

extension SupportCoordinator: SupportChatBotCreatedTicketDelegate {
    func onTicketCreated() {
        if let navigationController = navigationController {
            navigationController.popViewController(animated: true)
            showTicketView()
        } else {
            controllerToShowFrom?.dismiss(animated: true) { [weak self] in
                self?.showTicketView()
            }
        }
    }
}
