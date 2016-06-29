import AFNetworking

@objc public enum WordPressComOAuthError: Int {
    case Unknown
    case InvalidClient
    case UnsupportedGrantType
    case InvalidRequest
    case NeedsMultifactorCode
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

    private let sessionManager: AFHTTPSessionManager = {
        let baseURL = NSURL(string:WordPressComOAuthClient.WordPressComOAuthBaseUrl)
        let sessionConfiguration = NSURLSessionConfiguration.ephemeralSessionConfiguration()
        let sessionManager = AFHTTPSessionManager(baseURL:baseURL, sessionConfiguration:sessionConfiguration)
        sessionManager.responseSerializer = WordPressComOAuthResponseSerializer()
        sessionManager.requestSerializer.setValue("application/json", forHTTPHeaderField:"Accept")
        return sessionManager
    }()

    private let clientID: String
    private let secret: String

    /// Creates a WordPresComOAuthClient initialized with the clientID and secret constants defined in the
    /// ApiCredentials singleton
    ///
    public class func client() -> WordPressComOAuthClient {
        let client = WordPressComOAuthClient(clientID:ApiCredentials.client(), secret: ApiCredentials.secret())
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
    public func authenticateWithUsername(username: String,
                                  password: String,
                                  multifactorCode: String?,
                                  success:(authToken: String?) -> (),
                                  failure:(error: NSError) -> () )
    {
        var parameters: [String:AnyObject] = [
            "username": username,
            "password": password,
            "grant_type": "password",
            "client_id": clientID,
            "client_secret": secret,
            "wpcom_supports_2fa": true
        ]

        if let multifactorCode = multifactorCode where !multifactorCode.isEmpty() {
            parameters["wpcom_otp"] = multifactorCode
        }

        sessionManager.POST("token", parameters: parameters, progress: nil, success: { (task, responseObject) in
            DDLogSwift.logVerbose("Received OAuth2 response: \(self.cleanedUpResponseForLogging(responseObject ?? "nil"))")
            guard let responseDictionary = responseObject as? [String:AnyObject],
                let authToken = responseDictionary["access_token"] as? String else {
                    success(authToken: nil)
                    return
            }
            success(authToken: authToken)

            }, failure: { (task, error) in
                failure(error: error)
                DDLogSwift.logError("Error receiving OAuth2 token: \(error)")
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
    public func requestOneTimeCodeWithUsername(username: String, password:String,
                                        success: () -> (), failure: (error: NSError) -> ())
    {
        let parameters = [
            "username": username,
            "password": password,
            "grant_type": "password",
            "client_id": clientID,
            "client_secret": secret,
            "wpcom_supports_2fa": true,
            "wpcom_resend_otp": true
        ]

        sessionManager.POST("token", parameters:parameters, progress:nil, success:{ (task, responseObject) in
            success()
            }, failure: { (task, error) in
                failure(error: error)
            }
        )
    }

    private func cleanedUpResponseForLogging(response: AnyObject) -> AnyObject {
        guard var responseDictionary = response as? [String:AnyObject],
            let _ = responseDictionary["access_token"]
            else {
                return response
        }

        responseDictionary["access_token"] = "*** REDACTED ***"
        return responseDictionary
    }

}

/// A custom serializer to handle standard 400 error responses coming from the OAUTH server
///
final class WordPressComOAuthResponseSerializer: AFJSONResponseSerializer {

    override init() {
        super.init()
        let extraStatusCodes = NSMutableIndexSet(indexSet: self.acceptableStatusCodes!)
        extraStatusCodes.addIndex(400)
        self.acceptableStatusCodes = extraStatusCodes
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func responseObjectForResponse(response: NSURLResponse?, data: NSData?, error: NSErrorPointer) -> AnyObject? {
        let responseObject = super.responseObjectForResponse(response, data: data, error: error)

        guard let httpResponse = response as? NSHTTPURLResponse where httpResponse.statusCode == 400,
            let responseDictionary = responseObject as? [String:AnyObject],
            let errorCode = responseDictionary["error"] as? String,
            let errorDescription = responseDictionary["error_description"] as? String
            else {
                return responseObject
        }

        /// Possible errors:
        ///     - invalid_client: client_id is missing or wrong, it shouldn't happen
        ///     - unsupported_grant_type: client_id doesn't support password grants
        ///     - invalid_request: A required field is missing/malformed
        ///     - invalid_request: Authentication failed
        ///     - needs_2fa: Multifactor Authentication code is required
        ///
        let errorsMap = [
            "invalid_client" : WordPressComOAuthError.InvalidClient,
            "unsupported_grant_type" : WordPressComOAuthError.UnsupportedGrantType,
            "invalid_request" : WordPressComOAuthError.InvalidRequest,
            "needs_2fa" : WordPressComOAuthError.NeedsMultifactorCode
        ]

        let mappedCode = errorsMap[errorCode]?.rawValue ?? WordPressComOAuthError.Unknown.rawValue

        error.memory = NSError(domain:WordPressComOAuthClient.WordPressComOAuthErrorDomain,
                       code:mappedCode,
                       userInfo:[NSLocalizedDescriptionKey: errorDescription])
        return responseObject
    }
}
