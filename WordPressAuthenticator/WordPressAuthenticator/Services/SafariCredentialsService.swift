// MARK: - SafariCredentialsService
//
class SafariCredentialsService {

    @objc static let LoginSharedWebCredentialFQDN: CFString = "wordpress.com" as CFString
    typealias SharedWebCredentialsCallback = (_ credentialsFound: Bool, _ username: String?, _ password: String?) -> ()


    /// Update safari stored credentials.
    ///
    /// - Parameter loginFields: An instance of LoginFields
    ///
    class func updateSafariCredentialsIfNeeded(with loginFields: LoginFields) {
        // Paranioa. Don't try and update credentials for self-hosted.
        if !loginFields.meta.userIsDotCom {
            return
        }

        // If the user changed screen names, don't try and update/create a new shared web credential.
        // We'll let Safari handle creating newly saved usernames/passwords.
        if loginFields.storedCredentials?.storedUserameHash != loginFields.username.hash {
            return
        }

        // If the user didn't change the password from previousl filled password no update is needed.
        if loginFields.storedCredentials?.storedPasswordHash == loginFields.password.hash {
            return
        }

        // Update the shared credential
        let username: CFString = loginFields.username as CFString
        let password: CFString = loginFields.password as CFString

        SecAddSharedWebCredential(LoginSharedWebCredentialFQDN, username, password, { (error: CFError?) in
            guard error == nil else {
                let err = error
                DDLogError("Error occurred updating shared web credential: \(String(describing: err?.localizedDescription))")
                return
            }
            DispatchQueue.main.async(execute: {
                WordPressAuthenticator.track(.loginAutoFillCredentialsUpdated)
            })
        })
    }

    /// Request shared safari credentials if they exist.
    ///
    /// - Parameter completion: A completion block.
    ///
    class func requestSharedWebCredentials(_ completion: @escaping SharedWebCredentialsCallback) {
        SecRequestSharedWebCredential(LoginSharedWebCredentialFQDN, nil, { (credentials: CFArray?, error: CFError?) in
            DDLogInfo("Completed requesting shared web credentials")
            guard error == nil else {
                let err = error as Error?
                if let error = err as NSError?, error.code == -25300 {
                    // An OSStatus of -25300 is expected when no saved credentails are found.
                    DDLogInfo("No shared web credenitals found.")
                } else {
                    DDLogError("Error requesting shared web credentials: \(String(describing: err?.localizedDescription))")
                }
                DispatchQueue.main.async {
                    completion(false, nil, nil)
                }
                return
            }

            guard let credentials = credentials, CFArrayGetCount(credentials) > 0 else {
                // Saved credentials exist but were not selected.
                DispatchQueue.main.async(execute: {
                    completion(true, nil, nil)
                })
                return
            }

            // What a chore!
            let unsafeCredentials = CFArrayGetValueAtIndex(credentials, 0)
            let credentialsDict = unsafeBitCast(unsafeCredentials, to: CFDictionary.self)

            let unsafeUsername = CFDictionaryGetValue(credentialsDict, Unmanaged.passUnretained(kSecAttrAccount).toOpaque())
            let usernameStr = unsafeBitCast(unsafeUsername, to: CFString.self) as String

            let unsafePassword = CFDictionaryGetValue(credentialsDict, Unmanaged.passUnretained(kSecSharedPassword).toOpaque())
            let passwordStr = unsafeBitCast(unsafePassword, to: CFString.self) as String

            DispatchQueue.main.async {
                completion(true, usernameStr, passwordStr)
            }
        })
    }
}
