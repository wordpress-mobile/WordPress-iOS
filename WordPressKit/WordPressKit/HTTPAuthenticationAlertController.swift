import Foundation


open class HTTPAuthenticationAlertController {

    public typealias AuthenticationHandler = (URLSession.AuthChallengeDisposition, URLCredential?) -> Void

    fileprivate static var onGoingChallenges = [URLProtectionSpace: [AuthenticationHandler]]()

    static open func presentWithChallenge(_ challenge: URLAuthenticationChallenge, handler: @escaping AuthenticationHandler) {
        if var handlers = onGoingChallenges[challenge.protectionSpace] {
            handlers.append(handler)
            onGoingChallenges[challenge.protectionSpace] = handlers
            return
        }
        onGoingChallenges[challenge.protectionSpace] = [handler]

        let  controller: UIAlertController
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            controller = controllerForServerTrustChallenge(challenge)
        } else {
            controller = controllerForUserAuthenticationChallenge(challenge)
        }

        controller.presentFromRootViewController()
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

    static fileprivate func controllerForServerTrustChallenge(_ challenge: URLAuthenticationChallenge) -> UIAlertController {
        let title = NSLocalizedString("Certificate error", comment: "Popup title for wrong SSL certificate.")
        let message = String(format: NSLocalizedString("The certificate for this server is invalid. You might be connecting to a server that is pretending to be “%@” which could put your confidential information at risk.\n\nWould you like to trust the certificate anyway?", comment: ""), challenge.protectionSpace.host)
        let controller =  UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)

        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel button label"),
                                         style: UIAlertActionStyle.default,
                                         handler: { (action) in
                                            executeHandlerForChallenge(challenge, disposition: .cancelAuthenticationChallenge, credential: nil)
        })
        controller.addAction(cancelAction)

        let trustAction = UIAlertAction(title: NSLocalizedString("Trust", comment: "Connect when the SSL certificate is invalid"),
                                        style: UIAlertActionStyle.default,
                                        handler: { (action) in
                                            let credential = URLCredential(trust: challenge.protectionSpace.serverTrust!)
                                            URLCredentialStorage.shared.setDefaultCredential(credential, for: challenge.protectionSpace)
                                            executeHandlerForChallenge(challenge, disposition: .useCredential, credential: credential)
        })
        controller.addAction(trustAction)
        return controller
    }

    static fileprivate func controllerForUserAuthenticationChallenge(_ challenge: URLAuthenticationChallenge) -> UIAlertController {
        let title = String(format: NSLocalizedString("Authentication required for host: %@", comment: "Popup title to ask for user credentials."), challenge.protectionSpace.host)
        let message = NSLocalizedString("Please enter your credentials", comment: "Popup message to ask for user credentials (fields shown below).")
        let controller =  UIAlertController(title: title,
                                            message: message,
                                            preferredStyle: UIAlertControllerStyle.alert)

        controller.addTextField( configurationHandler: { (textField) in
            textField.placeholder = NSLocalizedString("Username", comment: "Login dialog username placeholder")
        })

        controller.addTextField(configurationHandler: { (textField) in
            textField.placeholder = NSLocalizedString("Password", comment: "Login dialog password placeholder")
            textField.isSecureTextEntry = true
        })

        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel button label"),
                                         style: .default,
                                         handler: { (action) in
                                            executeHandlerForChallenge(challenge, disposition: .cancelAuthenticationChallenge, credential: nil)
        })
        controller.addAction(cancelAction)

        let loginAction = UIAlertAction(title: NSLocalizedString("Log In", comment: "Log In button label."),
                                        style: .default,
                                        handler: { (action) in
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
