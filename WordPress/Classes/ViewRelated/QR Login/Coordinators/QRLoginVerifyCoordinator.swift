import Foundation

protocol QRLoginVerifyView {
    func render(response: QRLoginValidationResponse)
    func renderCompletion()

    func showLoading()
    func showAuthenticating()

    func showNoConnectionError()
}

class QRLoginVerifyCoordinator {
    private let parentCoordinator: QRLoginCoordinator
    private let view: QRLoginVerifyView
    private let token: QRLoginToken
    private var state: ViewState = .verifyingCode
    private let service: QRLoginService

    init(token: QRLoginToken,
         view: QRLoginVerifyView,
         parentCoordinator: QRLoginCoordinator,
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
        case done
    }
}

// MARK: - View Interactions
extension QRLoginVerifyCoordinator {
    func start() {
        state = .verifyingCode

        view.showLoading()

        service.validate(token: token) { response in
            self.state = .waitingForUserVerification
            self.view.render(response: response)

        } failure: { error, qrLoginError in
            //TODO: Handle error state
        }

        // Temporary loading -> render
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
        }
    }

    func confirm() {
        // If we're in the done state, dismiss the flow
        if state == .done {
            parentCoordinator.dismiss()
            return
        }

        // TODO: Make network request to log the user in
        view.showAuthenticating()
        state = .authenticating

        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
            self.state = .done
            self.view.renderCompletion()
        }
    }

    func cancel() {
        parentCoordinator.dismiss()
    }
}
