import Foundation
import AuthenticationServices

/// Thin wrapper around `ASAuthorizationController` to avoid having to set delegate methods in the VC
/// and to modularize / abstract the logic to show Apple's UI for picking the stored credentials.
///
/// This picker takes care of returning the credentials that were picked (and authorized by the iOS) through a closure.
/// It's not within the scope of this class to take care of what happens after the credentials are picked.
///
class StoredCredentialsPicker: NSObject {

    typealias CompletionClosure = (Result<ASAuthorization, Error>) -> Void

    /// The closure that will be executed once the credentials are picked and returned by the OS,
    /// or once there's an Error.
    ///
    private var onComplete: CompletionClosure!

    /// The window where the quick authentication flow will be shown.
    ///
    private var window: UIWindow!

    func show(in window: UIWindow, onComplete: @escaping CompletionClosure) {

        self.onComplete = onComplete
        self.window = window

        let requests = [ASAuthorizationPasswordProvider().createRequest()]
        let controller = ASAuthorizationController(authorizationRequests: requests)

        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension StoredCredentialsPicker: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        onComplete(.success(authorization))
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        onComplete(.failure(error))
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension StoredCredentialsPicker: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return window
    }
}
