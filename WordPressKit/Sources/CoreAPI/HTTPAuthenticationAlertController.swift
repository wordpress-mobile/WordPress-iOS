import Foundation
import UIKit

/// URLAuthenticationChallenge Handler: It's up to the Host App to actually use this, whenever `WordPressOrgXMLRPCApi.onChallenge` is hit!
///
open class HTTPAuthenticationAlertController {

    public typealias AuthenticationHandler = (URLSession.AuthChallengeDisposition, URLCredential?) -> Void

    private static var onGoingChallenges = [URLProtectionSpace: [AuthenticationHandler]]()

    static public func controller(for challenge: URLAuthenticationChallenge, handler: @escaping AuthenticationHandler) -> UIAlertController? {
        if var handlers = onGoingChallenges[challenge.protectionSpace] {
            handlers.append(handler)
            onGoingChallenges[challenge.protectionSpace] = handlers
            return nil
        }
        onGoingChallenges[challenge.protectionSpace] = [handler]

        switch challenge.protectionSpace.authenticationMethod {
        case NSURLAuthenticationMethodServerTrust:
            return controllerForServerTrustChallenge(challenge)
        default:
            return controllerForUserAuthenticationChallenge(challenge)
        }
    }

    static func executeHandlerForChallenge(_ challenge: URLAuthenticationChallenge, disposition: URLSession.AuthChallengeDisposition, credential: URLCredential?) {
        guard let handlers = onGoingChallenges[challenge.protectionSpace] else {
            return
        }
        for handler in handlers {
            handler(disposition, credential)
        }
        onGoingChallenges.removeValue(forKey: challenge.protectionSpace)
    }

    private static func controllerForServerTrustChallenge(_ challenge: URLAuthenticationChallenge) -> UIAlertController {
        let title = NSLocalizedString("Certificate error", comment: "Popup title for wrong SSL certificate.")
        let localizedMessage = NSLocalizedString(
            "The certificate for this server is invalid. You might be connecting to a server that is pretending to be “%@” which could put your confidential information at risk.\n\nWould you like to trust the certificate anyway?",
            comment: "Message for when the certificate for the server is invalid. The %@ placeholder will be replaced the a host name, received from the API."
        )
        let message = String(format: localizedMessage, challenge.protectionSpace.host)
        let controller =  UIAlertController(title: title, message: message, preferredStyle: .alert)

        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel button label"),
                                         style: .default,
                                         handler: { (_) in
                                            executeHandlerForChallenge(challenge, disposition: .cancelAuthenticationChallenge, credential: nil)
        })
        controller.addAction(cancelAction)

        let trustAction = UIAlertAction(title: NSLocalizedString("Trust", comment: "Connect when the SSL certificate is invalid"),
                                        style: .default,
                                        handler: { (_) in
                                            let credential = URLCredential(trust: challenge.protectionSpace.serverTrust!)
                                            URLCredentialStorage.shared.setDefaultCredential(credential, for: challenge.protectionSpace)
                                            executeHandlerForChallenge(challenge, disposition: .useCredential, credential: credential)
        })
        controller.addAction(trustAction)
        return controller
    }

    private static func controllerForUserAuthenticationChallenge(_ challenge: URLAuthenticationChallenge) -> UIAlertController {
        let title = String(format: NSLocalizedString("Authentication required for host: %@", comment: "Popup title to ask for user credentials."), challenge.protectionSpace.host)
        let message = NSLocalizedString("Please enter your credentials", comment: "Popup message to ask for user credentials (fields shown below).")
        let controller =  UIAlertController(title: title,
                                            message: message,
                                            preferredStyle: .alert)

        controller.addTextField( configurationHandler: { (textField) in
            textField.placeholder = NSLocalizedString("Username", comment: "Login dialog username placeholder")
        })

        controller.addTextField(configurationHandler: { (textField) in
            textField.placeholder = NSLocalizedString("Password", comment: "Login dialog password placeholder")
            textField.isSecureTextEntry = true
        })

        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel button label"),
                                         style: .default,
                                         handler: { (_) in
                                            executeHandlerForChallenge(challenge, disposition: .cancelAuthenticationChallenge, credential: nil)
        })
        controller.addAction(cancelAction)

        let loginAction = UIAlertAction(title: NSLocalizedString("Log In", comment: "Log In button label."),
                                        style: .default,
                                        handler: { (_) in
                                            guard let username = controller.textFields?.first?.text,
                                                let password = controller.textFields?.last?.text else {
                                                    executeHandlerForChallenge(challenge, disposition: .cancelAuthenticationChallenge, credential: nil)
                                                    return
                                            }
                                            let credential = URLCredential(user: username, password: password, persistence: URLCredential.Persistence.permanent)
                                            URLCredentialStorage.shared.setDefaultCredential(credential, for: challenge.protectionSpace)
                                            executeHandlerForChallenge(challenge, disposition: .useCredential, credential: credential)
        })
        controller.addAction(loginAction)
        return controller
    }

}
