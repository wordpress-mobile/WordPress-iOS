import Foundation

protocol QRLoginVerifyView {
    // TODO: Pass view model to the render
    func render()
    func renderCompletion()

    func showLoading()
    func showAuthenticating()

    func showNoConnectionError()
}

class QRLoginVerifyCoordinator {
    private let parentCoordinator: QRLoginCoordinator
    private let view: QRLoginVerifyView
    private let loginCode: String
    private var state: ViewState = .verifyingCode

    init(loginCode: String, view: QRLoginVerifyView, parentCoordinator: QRLoginCoordinator) {
        self.loginCode = loginCode
        self.view = view
        self.parentCoordinator = parentCoordinator
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

        //TODO: Make network request to validate the code and get the browser info
        view.showLoading()

        // Temporary loading -> render
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
            self.state = .waitingForUserVerification
            self.view.render()
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
