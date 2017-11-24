import AFNetworking
import CocoaLumberjack

@objc public enum WordPressComOAuthError: Int {
    case unknown
    case invalidClient
    case unsupportedGrantType
    case invalidRequest
    case needsMultifactorCode
    case invalidOneTimePassword
    case socialLoginExistingUserUnconnected
    case invalidTwoStepCode
    case unknownUser
}

/// `WordPressComOAuthClient` encapsulates the pattern of authenticating against WordPress.com OAuth2 service.
///
/// Right now it requires a special client id and secret, so this probably won't work for you
/// @see https://developer.wordpress.com/docs/oauth2/
///
public final class WordPressComOAuthClient: NSObject {

    @objc public static let WordPressComOAuthErrorResponseObjectKey = "WordPressComOAuthErrorResponseObjectKey"
    @objc public static let WordPressComOAuthErrorNewNonceKey = "WordPressComOAuthErrorNewNonceKey"
    @objc public static let WordPressComOAuthErrorDomain = "WordPressComOAuthError"
    @objc public static let WordPressComOAuthBaseUrl = "https://public-api.wordpress.com/oauth2"
    @objc public static let WordPressComSocialLoginUrl = "https://wordpress.com/wp-login.php?action=social-login-endpoint&version=1.0"
    @objc public static let WordPressComSocialLogin2FAUrl = "https://wordpress.com/wp-login.php?action=two-step-authentication-endpoint&version=1.0"
    @objc public static let WordPressComSocialLoginNewSMS2FAUrl = "https://wordpress.com/wp-login.php?action=send-sms-code-endpoint"
    @objc public static let WordPressComOAuthRedirectUrl = "https://wordpress.com/"
    @objc public static let WordPressComSocialLoginEndpointVersion = 1.0

    fileprivate let clientID: String
    fileprivate let secret: String

    fileprivate let oauth2SessionManager: AFHTTPSessionManager = {
        return WordPressComOAuthClient.sessionManager(url: WordPressComOAuthClient.WordPressComOAuthBaseUrl)
    }()

    fileprivate let socialSessionManager: AFHTTPSessionManager = {
        return WordPressComOAuthClient.sessionManager(url: WordPressComOAuthClient.WordPressComSocialLoginUrl)
    }()

    fileprivate let social2FASessionManager: AFHTTPSessionManager = {
        return WordPressComOAuthClient.sessionManager(url: WordPressComOAuthClient.WordPressComSocialLogin2FAUrl)
    }()

    fileprivate let socialNewSMS2FASessionmanager: AFHTTPSessionManager = {
        return WordPressComOAuthClient.sessionManager(url: WordPressComOAuthClient.WordPressComSocialLoginNewSMS2FAUrl)
    }()

    fileprivate class func sessionManager(url: String) -> AFHTTPSessionManager {
        let baseURL = URL(string: url)
        let sessionManager = AFHTTPSessionManager(baseURL: baseURL, sessionConfiguration: .ephemeral)
        sessionManager.responseSerializer = WordPressComOAuthResponseSerializer()
        sessionManager.requestSerializer.setValue("application/json", forHTTPHeaderField: "Accept")
        return sessionManager
    }

    /// Creates a WordPresComOAuthClient initialized with the clientID and secret constants defined in the
    /// ApiCredentials singleton
    ///
    @objc public class func client(clientID: String, secret: String) -> WordPressComOAuthClient {
        let client = WordPressComOAuthClient(clientID: clientID, secret: secret)
        return client
    }

    /// Creates a WordPressComOAuthClient using the defined clientID and secret
    ///
    /// - Parameters:
    ///     - clientID: the app oauth clientID
    ///     - secret: the app secret
    ///
    @objc public init(clientID: String, secret: String) {
        self.clientID = clientID
        self.secret = secret
    }

    /// Authenticates on WordPress.com with Multifactor code.
    ///
    /// - Parameters:
    ///     - username: the account's username.
    ///     - password: the account's password.
    ///     - multifactorCode: Multifactor Authentication One-Time-Password. If not needed, can be nil
    ///     - success: block to be called if authentication was successful. The OAuth2 token is passed as a parameter.
    ///     - failure: block to be called if authentication failed. The error object is passed as a parameter.
    ///
    @objc public func authenticateWithUsername(_ username: String,
                                  password: String,
                                  multifactorCode: String?,
                                  success: @escaping (_ authToken: String?) -> (),
                                  failure: @escaping (_ error: NSError) -> () ) {
        var parameters: [String: AnyObject] = [
            "username": username as AnyObject,
            "password": password as AnyObject,
            "grant_type": "password" as AnyObject,
            "client_id": clientID as AnyObject,
            "client_secret": secret as AnyObject,
            "wpcom_supports_2fa": true as AnyObject
        ]

        if let multifactorCode = multifactorCode, multifactorCode.count > 0 {
            parameters["wpcom_otp"] = multifactorCode as AnyObject?
        }

        oauth2SessionManager.post("token", parameters: parameters, progress: nil, success: { (task, responseObject) in
            DDLogVerbose("Received OAuth2 response: \(self.cleanedUpResponseForLogging(responseObject as AnyObject? ?? "nil" as AnyObject))")
            guard let responseDictionary = responseObject as? [String: AnyObject],
                let authToken = responseDictionary["access_token"] as? String else {
                    success(nil)
                    return
            }
            success(authToken)

            }, failure: { (task, error) in
                failure(error as NSError)
                DDLogError("Error receiving OAuth2 token: \(error)")
            }
        )
    }

    /// Requests a One Time Code, to be sent via SMS.
    ///
    /// - Parameters:
    ///     - username: the account's username.
    ///     - password: the account's password.
    ///     - success: block to be called if authentication was successful.
    ///     - failure: block to be called if authentication failed. The error object is passed as a parameter.
    ///
    @objc public func requestOneTimeCodeWithUsername(_ username: String, password: String,
                                        success: @escaping () -> (), failure: @escaping (_ error: NSError) -> ()) {
        let parameters = [
            "username": username,
            "password": password,
            "grant_type": "password",
            "client_id": clientID,
            "client_secret": secret,
            "wpcom_supports_2fa": true,
            "wpcom_resend_otp": true
        ] as [String : Any]

        oauth2SessionManager.post("token", parameters: parameters, progress: nil, success: { (task, responseObject) in
            success()
            }, failure: { (task, error) in
                failure(error as NSError)
            }
        )
    }

    /// Request a new SMS code to be sent during social login
    ///
    /// - Parameters:
    ///     - userID: The wpcom user id.
    ///     - nonce: The nonce from a social login attempt.
    ///     - success: block to be called if authentication was successful.
    ///     - failure: block to be called if authentication failed. The error object is passed as a parameter.
    ///
    @objc public func requestSocial2FACodeWithUserID(_ userID: Int,
                                                     nonce: String,
                                                     success: @escaping (_ newNonce: String) -> Void,
                                                     failure: @escaping (_ error: NSError, _ newNonce: String?) -> Void) {
        let parameters = [
            "user_id": userID,
            "two_step_nonce": nonce,
            "client_id": clientID,
            "client_secret": secret,
            "wpcom_supports_2fa": true,
            "wpcom_resend_otp": true
        ] as [String : Any]

        socialNewSMS2FASessionmanager.post("", parameters: parameters, progress: nil, success: { (task, responseObject) in
            let defaultError = NSError(domain: WordPressComOAuthClient.WordPressComOAuthErrorDomain,
                                       code: WordPressComOAuthError.unknown.rawValue,
                                       userInfo: nil)

            guard let responseDictionary = responseObject as? [String: AnyObject],
                let responseData = responseDictionary["data"] as? [String: AnyObject] else {
                    failure(defaultError, nil)
                    return
            }

            let nonceInfo = self.extractNonceInfo(data: responseData)

            success(nonceInfo.nonceSMS)
        }) { (task, error) in
            if let newNonce = (error as NSError).userInfo[WordPressComOAuthClient.WordPressComOAuthErrorNewNonceKey] as? String {
                failure(error as NSError, newNonce)
            } else {
                failure(error as NSError, nil)
            }
        }
    }

    /// Authenticate on WordPress.com with a social service's ID token.
    /// Only google is supported at this time.
    ///
    /// - Parameters:
    ///     - token: A social ID token obtained from a supported social service.
    ///     - success: block to be called if authentication was successful. The OAuth2 token is passed as a parameter.
    ///     - needsMultifactor: block to be called if a 2fa token is needed to complete the auth process.
    ///     - failure: block to be called if authentication failed. The error object is passed as a parameter.
    ///
    @objc public func authenticateWithIDToken(_ token: String,
                                        success: @escaping (_ authToken: String?) -> Void,
                                        needsMultifactor: @escaping (_ userID: Int, _ nonceInfo: SocialLogin2FANonceInfo) -> Void,
                                        existingUserNeedsConnection: @escaping (_ email: String) -> Void,
                                        failure: @escaping (_ error: NSError) -> Void ) {
        let parameters = [
            "client_id": clientID,
            "client_secret": secret,
            "service": "google",
            "get_bearer_token": true,
            "id_token" : token,
        ] as [String : Any]

        // Passes an empty string for the path. The session manager was composed with the full endpoint path.
        socialSessionManager.post("", parameters: parameters, progress: nil, success: { (task, responseObject) in
            DDLogVerbose("Received Social Login Oauth response: \(self.cleanedUpResponseForLogging(responseObject as AnyObject? ?? "nil" as AnyObject))")

            let defaultError = NSError(domain: WordPressComOAuthClient.WordPressComOAuthErrorDomain,
                                       code: WordPressComOAuthError.unknown.rawValue,
                                       userInfo: nil)

            // Make sure we received expected data.
            guard let responseDictionary = responseObject as? [String: AnyObject],
                let responseData = responseDictionary["data"] as? [String: AnyObject] else {
                    failure(defaultError)
                    return
            }

            // Check for a bearer token. If one is found then we're authed.
            if let authToken = responseData["bearer_token"] as? String {
                success(authToken)
                return
            }

            // If there is no bearer token, check for 2fa enabled.
            guard let userID = responseData["user_id"] as? Int,
                let _ = responseData["two_step_nonce_backup"] else {
                failure(defaultError)
                return
            }

            let nonceInfo = self.extractNonceInfo(data: responseData)
            needsMultifactor(userID, nonceInfo)

            }, failure: { (task, error) in
                let err = error as NSError

                // Inspect the error and handle the case of an existing user.
                if err.code == WordPressComOAuthError.socialLoginExistingUserUnconnected.rawValue &&
                    err.domain == WordPressComOAuthClient.WordPressComOAuthErrorDomain {
                    // Get the responseObject from the userInfo dict.
                    // Extract the email address for the callback.
                    if let responseDict = err.userInfo[WordPressComOAuthClient.WordPressComOAuthErrorResponseObjectKey] as? [String: AnyObject],
                        let data = responseDict["data"] as? [String: AnyObject],
                        let email = data["email"] as? String {

                        existingUserNeedsConnection(email)
                        return
                    }
                }
                failure(err)
            }
        )
    }

    /// A helper method to get an instance of SocialLogin2FANonceInfo and populate 
    /// it with the supplied data.
    ///
    /// - Parameters:
    ///     - data: The dictionary to use to populate the instance.
    ///
    /// - Return: SocialLogin2FANonceInfo
    ///
    private func extractNonceInfo(data:[String: AnyObject]) -> SocialLogin2FANonceInfo {
        let nonceInfo = SocialLogin2FANonceInfo()

        if let nonceAuthenticator = data["two_step_nonce_authenticator"] as? String {
            nonceInfo.nonceAuthenticator = nonceAuthenticator
        }

        // atm, the only use of the more vague "two_step_nonce" key is when requesting a new SMS code
        if let nonce = data["two_step_nonce"] as? String {
            nonceInfo.nonceSMS = nonce
        }

        if let nonce = data["two_step_nonce_sms"] as? String {
            nonceInfo.nonceSMS = nonce
        }

        if let nonce = data["two_step_nonce_backup"] as? String {
            nonceInfo.nonceBackup = nonce
        }

        if let notification = data["two_step_notification_sent"] as? String {
            nonceInfo.notificationSent = notification
        }

        if let authTypes = data["two_step_supported_auth_types"] as? [String] {
            nonceInfo.supportedAuthTypes = authTypes
        }

        if let phone = data["phone_number"] as? String {
            nonceInfo.phoneNumber = phone
        }

        return nonceInfo
    }

    /// Completes a social login that has 2fa enabled.
    ///
    /// - Parameters:
    ///     - userID: The wpcom user id.
    ///     - authType: The type of 2fa authentication being used. (sms|backup|authenticator)
    ///     - twoStepCode: The user's 2fa code.
    ///     - twoStepNonce: The nonce returned from a social login attempt.
    ///     - success: block to be called if authentication was successful. The OAuth2 token is passed as a parameter.
    ///     - failure: block to be called if authentication failed. The error object is passed as a parameter.
    ///
    @objc public func authenticateSocialLoginUser(_ userID: Int,
                                            authType: String,
                                            twoStepCode: String,
                                            twoStepNonce: String,
                                            success: @escaping (_ authToken: String?) -> Void,
                                            failure: @escaping (_ error: NSError) -> Void ) {
        let parameters = [
            "user_id" : userID,
            "auth_type" : authType,
            "two_step_code": twoStepCode,
            "two_step_nonce": twoStepNonce,
            "get_bearer_token": true,
            "client_id": clientID,
            "client_secret": secret,
            ] as [String : Any]

        // Passes an empty string for the path. The session manager was composed with the full endpoint path.
        social2FASessionManager.post("", parameters: parameters, progress: nil, success: { (task, responseObject) in
            DDLogVerbose("Received Social Login Oauth response: \(self.cleanedUpResponseForLogging(responseObject as AnyObject? ?? "nil" as AnyObject))")
            guard let responseDictionary = responseObject as? [String: AnyObject],
                let responseData = responseDictionary["data"] as? [String: AnyObject],
                let authToken = responseData["bearer_token"] as? String else {
                    failure(NSError(domain: WordPressComOAuthClient.WordPressComOAuthErrorDomain,
                                               code: WordPressComOAuthError.unknown.rawValue,
                                               userInfo: nil))
                    return
            }

            success(authToken)

        }, failure: { (task, error) in
            failure(error as NSError)
        }
        )
    }

    fileprivate func cleanedUpResponseForLogging(_ response: AnyObject) -> AnyObject {
        guard var responseDictionary = response as? [String: AnyObject],
            let _ = responseDictionary["access_token"]
            else {
                return response
        }

        responseDictionary["access_token"] = "*** REDACTED ***" as AnyObject?
        return responseDictionary as AnyObject
    }

}

/// A custom serializer to handle standard 400 error responses coming from the OAUTH server
///
final class WordPressComOAuthResponseSerializer: AFJSONResponseSerializer {

    override init() {
        super.init()
        var extraStatusCodes = self.acceptableStatusCodes!
        extraStatusCodes.insert(400)
        self.acceptableStatusCodes = extraStatusCodes
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }


    /// Possible 400 errors:
    ///     - invalid_client: client_id is missing or wrong, it shouldn't happen
    ///     - unsupported_grant_type: client_id doesn't support password grants
    ///     - invalid_request: A required field is missing/malformed
    ///     - invalid_request: Authentication failed
    ///     - needs_2fa: Multifactor Authentication code is required
    ///     - user_exists: Returned by the social login endpoint if a wpcom user is found, but not connected to a social service.
    ///
    let errorsMap = [
        "invalid_client": WordPressComOAuthError.invalidClient,
        "unsupported_grant_type": WordPressComOAuthError.unsupportedGrantType,
        "invalid_request": WordPressComOAuthError.invalidRequest,
        "needs_2fa": WordPressComOAuthError.needsMultifactorCode,
        "invalid_otp": WordPressComOAuthError.invalidOneTimePassword,
        "user_exists": WordPressComOAuthError.socialLoginExistingUserUnconnected,
        "invalid_two_step_code": WordPressComOAuthError.invalidTwoStepCode,
        "unknown_user": WordPressComOAuthError.unknownUser
    ]


    /// Overridden to provide custom error handling. Some HTTP requests include
    /// a response body even in a failure scenario. Since AFNetworking does not
    /// pass a responseObject (if any) to a failure block this method ensures
    /// it is available via an error's userInfo dictionary.
    ///
    /// - Parameters:
    ///   - response: The URL response.
    ///   - data: Data returned from the request.
    ///   - error: A pointer to an error (if any).
    /// - Returns: The response object or nil.
    override func responseObject(for response: URLResponse?, data: Data?, error: NSErrorPointer) -> Any? {
        let responseObject = super.responseObject(for: response, data: data, error: error)

        guard let httpResponse = response as? HTTPURLResponse else {
            return responseObject
        }

        if [400, 409, 403].contains(httpResponse.statusCode),
            let responseDictionary = responseObject as? [String: AnyObject] {
            error?.pointee = parseError(from: responseDictionary)
        }

        return responseObject as AnyObject?
    }

    /// Create the NSError from the response dictionary
    private func parseError(from responseDict: [String: AnyObject]) -> NSError {
        var errorCode = ""
        var errorDescription = ""
        var newNonce: String?

        // there's either a data object, or an error.
        if  let errorStr = responseDict["error"] as? String {
            errorCode = errorStr
            errorDescription = responseDict["error_description"] as? String ?? ""
        } else if let data = responseDict["data"] as? [String: AnyObject],
            let errors = data["errors"] as? NSArray,
            let err = errors[0] as? [String: AnyObject] {
            errorCode = err["code"] as? String ?? ""
            errorDescription = err["message"] as? String ?? ""
            newNonce = data["two_step_nonce"] as? String
        }

        return errorFor(errorCode: errorCode, errorDescription: errorDescription, responseObject: responseDict, newNonce: newNonce)
    }

    /// Creates an NSError from the supplied arguements. The response object is
    /// added to the error's userInfo dictionary.
    ///
    /// - Parameters:
    ///   - errorCode: A string representing the error code. This is not the same as an HTTP status code.
    ///   - errorDescription: A description of the error.
    ///   - responseObject: The responseObject (if any) that was passed with the error.
    ///   - newNonce: *optional* The new nonce provided when a 2FA fails
    /// - Returns: An NSError.
    @objc func errorFor(errorCode: String, errorDescription: String, responseObject: Any?, newNonce: String? = nil) -> NSError {
        var userInfo:[String: AnyObject] = [NSLocalizedDescriptionKey: errorDescription as AnyObject]
        if let responseObject = responseObject {
            userInfo[WordPressComOAuthClient.WordPressComOAuthErrorResponseObjectKey] = responseObject as AnyObject
        }
        if let newNonce = newNonce {
            userInfo[WordPressComOAuthClient.WordPressComOAuthErrorNewNonceKey] = newNonce as AnyObject
        }
        let mappedCode = errorsMap[errorCode]?.rawValue ?? WordPressComOAuthError.unknown.rawValue
        return NSError(domain: WordPressComOAuthClient.WordPressComOAuthErrorDomain,
                       code: mappedCode,
                       userInfo: userInfo)
    }
}
