import Foundation
import Logging
import SwiftUI
import UIKit

@MainActor
public final class AddConnectionCoordinator {
    private let connectionsService: SiteSocialConnectionsService
    private let authenticator: any SocialOAuthAuthenticator
    private weak var presenter: UIViewController?

    private var navController: UINavigationController?
    private var confirmationHost: UIHostingController<AccountConfirmationView>?

    private static let log = Logger(label: "org.wordpress.jetpack-social.add-connection")

    public init(
        connectionsService: SiteSocialConnectionsService,
        authenticator: any SocialOAuthAuthenticator,
        presenter: UIViewController
    ) {
        self.connectionsService = connectionsService
        self.authenticator = authenticator
        self.presenter = presenter
    }

    public func start() {
        let pickerView = SocialServicePickerView(
            connections: connectionsService,
            onPick: { [weak self] service in
                self?.handlePick(service)
            },
            onCancel: { [weak self] in
                self?.cancelAndDismiss()
            }
        )
        let host = UIHostingController(rootView: pickerView)
        let nav = UINavigationController(rootViewController: host)
        nav.modalPresentationStyle = .formSheet
        navController = nav
        presenter?.present(nav, animated: true)
    }

    // MARK: - Forward transitions

    private func handlePick(_ service: SocialService) {
        guard let nav = navController else { return }
        guard let connectURL = service.connectURL else {
            Self.log.error("Social picker tapped \(service.id) but the service has no connect URL")
            return
        }
        let web = SocialOAuthWebViewController(
            startURL: connectURL,
            serviceLabel: service.label,
            authenticator: authenticator
        ) { [weak self] outcome in
            Task { @MainActor in
                self?.handleOAuth(outcome: outcome, for: service)
            }
        }
        nav.pushViewController(web, animated: true)
    }

    private func handleOAuth(
        outcome: SocialOAuthWebViewController.Outcome,
        for service: SocialService
    ) {
        switch outcome {
        case .success:
            pushConfirmation(for: service)
        case .cancelled:
            cancelAndDismiss()
        case .failure(let error):
            dismissAndAlertFailure(.network(error))
        }
    }

    private func pushConfirmation(for service: SocialService) {
        guard let nav = navController else { return }
        let view = makeConfirmationView(for: service)
        let host = UIHostingController(rootView: view)
        confirmationHost = host
        // Replace the stack (picker + OAuth) with just the confirmation screen.
        // `hidesBackButton` is unreliable when SwiftUI also sets `.toolbar`
        // items, and backing up into OAuth would require re-running it for no
        // gain — so there is nothing to back to, and Cancel is the only exit.
        nav.setViewControllers([host], animated: true)
    }

    private func makeConfirmationView(for service: SocialService) -> AccountConfirmationView {
        AccountConfirmationView(
            service: service,
            connectionsService: connectionsService,
            onCancel: { [weak self] in
                self?.cancelAndDismiss()
            },
            onFinish: { [weak self] result in
                guard let self else { return }
                switch result {
                case .success:
                    self.dismissNav()
                case .failure(let error):
                    self.dismissAndAlertFailure(error)
                }
            }
        )
    }

    // MARK: - Dismissal

    private func cancelAndDismiss() {
        dismissNav()
    }

    private func dismissAndAlertFailure(_ error: SocialSharingError) {
        dismissNav { [weak self] in
            self?.presentFailureAlert(error: error)
        }
    }

    private func dismissNav(_ completion: (() -> Void)? = nil) {
        confirmationHost = nil
        let nav = navController
        navController = nil
        nav?.dismiss(animated: true, completion: completion)
    }

    private func presentFailureAlert(error: SocialSharingError) {
        guard let presenter else { return }
        let alert = UIAlertController(
            title: Strings.ServiceDetail.failureAlertTitle,
            message: error.errorDescription,
            preferredStyle: .alert
        )
        alert.addAction(
            UIAlertAction(
                title: Strings.ServiceDetail.failureAlertRetry,
                style: .default,
                handler: { [weak self] _ in
                    self?.start()
                }
            )
        )
        alert.addAction(
            UIAlertAction(
                title: Strings.ServiceDetail.failureAlertCancel,
                style: .cancel
            )
        )
        presenter.present(alert, animated: true)
    }
}
