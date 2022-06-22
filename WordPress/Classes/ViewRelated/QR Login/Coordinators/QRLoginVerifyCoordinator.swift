import Foundation
import WordPressKit

class QRLoginVerifyCoordinator {
    private let parentCoordinator: QRLoginParentCoordinator
    private let view: QRLoginVerifyView
    private let token: QRLoginToken
    private var state: ViewState = .verifyingCode
    private let service: QRLoginService

    init(token: QRLoginToken,
         view: QRLoginVerifyView,
         parentCoordinator: QRLoginParentCoordinator,
         service: QRLoginService? = nil,
         context: NSManagedObjectContext = ContextManager.sharedInstance().mainContext) {
        self.token = token
        self.view = view
        self.parentCoordinator = parentCoordinator
        self.service = service ?? QRLoginService(managedObjectContext: context)
    }

    enum ViewState {
        case verifyingCode
        case waitingForUserVerification
        case authenticating
        case error
        case done
    }
}

// MARK: - View Interactions
extension QRLoginVerifyCoordinator {
    func start() {
        parentCoordinator.track(.qrLoginVerifyCodeDisplayed)
        state = .verifyingCode

        view.showLoading()

        service.validate(token: token) { response in
            self.parentCoordinator.track(.qrLoginVerifyCodeTokenValidated)
            self.state = .waitingForUserVerification
            self.view.render(response: response)
        } failure: { _, qrLoginError in
            self.state = .error

            // Check if we have no connection
            let appDelegate = WordPressAppDelegate.shared

            guard
                let connectionAvailable = appDelegate?.connectionAvailable, connectionAvailable == true
            else {
                self.parentCoordinator.track(.qrLoginVerifyCodeFailed, properties: ["error": "no_internet"])
                self.view.showNoConnectionError()
                return
            }

            let errorType: String
            switch qrLoginError {
            case .invalidData:
                errorType = "invalid_data"
            case .expired:
                errorType = "expired_token"
            case .none:
                errorType = "unknown"
            }

            self.parentCoordinator.track(.qrLoginVerifyCodeFailed, properties: ["error": errorType])
            self.view.showQRLoginError(error: qrLoginError)
        }
    }

    func confirm() {
        // If we're in the done state, dismiss the flow
        // If we're in the error state, do something
        switch state {
            case .done:
                parentCoordinator.track(.qrLoginVerifyCodeDismissed)
                parentCoordinator.dismiss()
                return
            case .error:
                parentCoordinator.track(.qrLoginVerifyCodeScanAgain)
                parentCoordinator.scanAgain()
                return

            default: break
        }

        parentCoordinator.track(.qrLoginVerifyCodeApproved)

        view.showAuthenticating()
        state = .authenticating

        service.authenticate(token: token) { success in
            self.parentCoordinator.track(.qrLoginAuthenticated)
            self.state = .done
            self.view.renderCompletion()
        } failure: { error in
            self.state = .error

            // Check if we have no connection
            let appDelegate = WordPressAppDelegate.shared

            guard
                let connectionAvailable = appDelegate?.connectionAvailable, connectionAvailable == true
            else {
                self.parentCoordinator.track(.qrLoginVerifyCodeFailed, properties: ["error": "no_internet"])
                self.view.showNoConnectionError()
                return
            }

            self.view.showAuthenticationFailedError()
            self.parentCoordinator.track(.qrLoginVerifyCodeFailed, properties: ["error": "authentication_failed"])
        }
    }

    func cancel() {
        parentCoordinator.track(.qrLoginVerifyCodeCancelled)
        parentCoordinator.dismiss()
    }
}
