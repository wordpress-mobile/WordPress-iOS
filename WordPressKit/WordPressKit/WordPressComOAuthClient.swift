import AFNetworking

@objc public enum WordPressComOAuthError: Int {
    case unknown
    case invalidClient
    case unsupportedGrantType
    case invalidRequest
    case needsMultifactorCode
}

/// `WordPressComOAuthClient` encapsulates the pattern of authenticating against WordPress.com OAuth2 service.
///
/// Right now it requires a special client id and secret, so this probably won't work for you
/// @see https://developer.wordpress.com/docs/oauth2/
///
public final class WordPressComOAuthClient: NSObject {

    public static let WordPressComOAuthErrorDomain = "WordPressComOAuthError"
    public static let WordPressComOAuthBaseUrl = "https://public-api.wordpress.com/oauth2"
    public static let WordPressComOAuthRedirectUrl = "https://wordpress.com/"

    fileprivate let sessionManager: AFHTTPSessionManager = {
        let baseURL = URL(string: WordPressComOAuthClient.WordPressComOAuthBaseUrl)
        let sessionConfiguration = URLSessionConfiguration.ephemeral
        let sessionManager = AFHTTPSessionManager(baseURL: baseURL, sessionConfiguration: sessionConfiguration)
        sessionManager.responseSerializer = WordPressComOAuthResponseSerializer()
        sessionManager.requestSerializer.setValue("application/json", forHTTPHeaderField: "Accept")
        return sessionManager
    }()

    fileprivate let clientID: String
    fileprivate let secret: String

    /// Creates a WordPresComOAuthClient initialized with the clientID and secret constants defined in the
    /// ApiCredentials singleton
    ///
    public class func client(clientID: String, secret: String) -> WordPressComOAuthClient {
        let client = WordPressComOAuthClient(clientID: clientID, secret: secret)
        return client
    }

    /// Creates a WordPressComOAuthClient using the defined clientID and secret
    ///
    /// - Parameters:
    ///     - clientID: the app oauth clientID
    ///     - secret: the app secret
    ///
    public init(clientID: String, secret: String) {
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
    public func authenticateWithUsername(_ username: String,
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

        if let multifactorCode = multifactorCode, multifactorCode.characters.count > 0 {
            parameters["wpcom_otp"] = multifactorCode as AnyObject?
        }

        sessionManager.post("token", parameters: parameters, progress: nil, success: { (task, responseObject) in
            //DDLogSwift.logVerbose("Received OAuth2 response: \(self.cleanedUpResponseForLogging(responseObject as AnyObject? ?? "nil" as AnyObject))")
            guard let responseDictionary = responseObject as? [String: AnyObject],
                let authToken = responseDictionary["access_token"] as? String else {
                    success(nil)
                    return
            }
            success(authToken)

            }, failure: { (task, error) in
                failure(error as NSError)
                //DDLogSwift.logError("Error receiving OAuth2 token: \(error)")
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
    public func requestOneTimeCodeWithUsername(_ username: String, password: String,
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

        sessionManager.post("token", parameters: parameters, progress: nil, success: { (task, responseObject) in
            success()
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

    override func responseObject(for response: URLResponse?, data: Data?, error: NSErrorPointer) -> Any? {
        let responseObject = super.responseObject(for: response, data: data, error: error)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 400,
            let responseDictionary = responseObject as? [String: AnyObject],
            let errorCode = responseDictionary["error"] as? String,
            let errorDescription = responseDictionary["error_description"] as? String
            else {
                return responseObject as AnyObject?
        }

        /// Possible errors:
        ///     - invalid_client: client_id is missing or wrong, it shouldn't happen
        ///     - unsupported_grant_type: client_id doesn't support password grants
        ///     - invalid_request: A required field is missing/malformed
        ///     - invalid_request: Authentication failed
        ///     - needs_2fa: Multifactor Authentication code is required
        ///
        let errorsMap = [
            "invalid_client": WordPressComOAuthError.invalidClient,
            "unsupported_grant_type": WordPressComOAuthError.unsupportedGrantType,
            "invalid_request": WordPressComOAuthError.invalidRequest,
            "needs_2fa": WordPressComOAuthError.needsMultifactorCode
        ]

        let mappedCode = errorsMap[errorCode]?.rawValue ?? WordPressComOAuthError.unknown.rawValue

        error?.pointee = NSError(domain: WordPressComOAuthClient.WordPressComOAuthErrorDomain,
                       code: mappedCode,
                       userInfo: [NSLocalizedDescriptionKey: errorDescription])
        return responseObject as AnyObject?
    }
}
