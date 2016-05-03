import AFNetworking

@objc public enum WordPressComOAuthError: Int {
    case Unknown
    case InvalidClient
    case UnsupportedGrantType
    case InvalidRequest
    case NeedsMultifactorCode
}

/**
 `WordPressComOAuthClient` encapsulates the pattern of authenticating against WordPress.com OAuth2 service.

 Right now it requires a special client id and secret, so this probably won't work for you

 @see https://developer.wordpress.com/docs/oauth2/
 */

public class WordPressComOAuthClient: NSObject {

    public static let WordPressComOAuthErrorDomain = "WordPressComOAuthError"
    public static let WordPressComOAuthKeychainServiceName = "public-api.wordpress.com"
    public static let WordPressComOAuthBaseUrl = "https://public-api.wordpress.com/oauth2"
    public static let WordPressComOAuthRedirectUrl = "https://wordpress.com/"

    private let sessionManager: AFHTTPSessionManager = {
        let baseURL = NSURL(string:WordPressComOAuthClient.WordPressComOAuthBaseUrl)
        let sessionConfiguration = NSURLSessionConfiguration.ephemeralSessionConfiguration()
        let sessionManager = AFHTTPSessionManager(baseURL:baseURL, sessionConfiguration:sessionConfiguration)
        sessionManager.responseSerializer = AFJSONResponseSerializer()
        sessionManager.requestSerializer.setValue("application/json", forHTTPHeaderField:"Accept")
        return sessionManager
    }()

    private let clientID: String
    private let secret: String

    /// Creates a WordPresComOAuthClient initialized with the clientID and secret constants defined in the ApiCredentials singleton
    public class func client() -> WordPressComOAuthClient {
        let client = WordPressComOAuthClient(clientID:ApiCredentials.client(), secret: ApiCredentials.secret())
        return client
    }

    /**
     Creates a WordPressComOAuthClient using the defined clientID and secret

     - Parameters:
       - clientID the app oauth clientID
       - secret the app secret
     */
    public init(clientID: String, secret: String) {
        self.clientID = clientID
        self.secret = secret

    }

    /**
     Authenticates on WordPress.com with Multifactor code.

     - Parameters:
       - username the account's username.
       - password the account's password.
       - multifactorCode Multifactor Authentication One-Time-Password. If not needed, can be nil
       - success block to be called if authentication was successful. The OAuth2 token is passed as a parameter.
       - failure block to be called if authentication failed. The error object is passed as a parameter.
     */
    public func authenticateWithUsername(username: String,
                                  password: String,
                                  multifactorCode: String?,
                                  success:(authToken: String) -> (),
                                  failure:(error: NSError) -> () )
    {
        var parameters: [String:AnyObject] = [
            "username": username,
            "password": password,
            "grant_type": "password",
            "client_id": ApiCredentials.client(),
            "client_secret": ApiCredentials.secret(),
            "wpcom_supports_2fa": true
        ]

        if let multifactorCode = multifactorCode where !multifactorCode.isEmpty() {
            parameters["wpcom_otp"] = multifactorCode;
        }

        sessionManager.POST("token", parameters: parameters, success: { (task, responseObject) in
            DDLogSwift.logVerbose("Received OAuth2 response: \(self.cleanedUpResponseForLogging(responseObject))")
            guard let responseDictionary = responseObject as? [String:AnyObject],
                let authToken = responseDictionary["access_token"] as? String else {
                    success(authToken: "")
                    return
            }
            success(authToken: authToken)

            }, failure: { (task, error) in
                if let httpURLResponse = task?.response as? NSHTTPURLResponse {
                    let processedError = self.processError(error, response:httpURLResponse)
                    failure(error: processedError)
                    DDLogSwift.logError("Error receiving OAuth2 token: \(processedError)");
                } else {
                    failure(error: error)
                    DDLogSwift.logError("Error receiving OAuth2 token: \(error)");
                }
            }
        )
    }

    /** Requests a One Time Code, to be sent via SMS.
     
     - Parameters:
        - username the account's username.
        - password the account's password.
        - success block to be called if authentication was successful.
        - failure block to be called if authentication failed. The error object is passed as a parameter.
    */
    public func requestOneTimeCodeWithUsername(username: String, password:String,
                                        success: () -> (), failure: (error: NSError) -> ())
    {
        let parameters = [
            "username": username,
            "password": password,
            "grant_type": "password",
            "client_id": ApiCredentials.client(),
            "client_secret": ApiCredentials.secret(),
            "wpcom_supports_2fa": true,
            "wpcom_resend_otp": true
        ]

        sessionManager.POST("token", parameters:parameters, success:{ (task, responseObject) in
            success()
            }, failure: { (task, error) in
                guard let httpURLResponse = task?.response as? NSHTTPURLResponse
                else {
                    failure(error: error)
                    return
                }
                let processedError = self.processError(error, response:httpURLResponse)
                // SORRY:
                // SMS Requests will still return WordPressComOAuthErrorNeedsMultifactorCode. In which case,
                // we should hit the success callback.
                if processedError.code == WordPressComOAuthError.NeedsMultifactorCode.rawValue {
                    success()
                } else {
                    failure(error: error)
                }
        })
    }

    private func processError(error: NSError, response:NSHTTPURLResponse) -> NSError {
        guard response.statusCode >= 400 && response.statusCode < 500 && error.domain == AFURLResponseSerializationErrorDomain,
        let responseData = error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] as? NSData,
        let responseDictionary = (try? NSJSONSerialization.JSONObjectWithData(responseData, options:NSJSONReadingOptions())) as? [String:AnyObject],
        let errorCode = responseDictionary["error"] as? String,
        let errorDescription = responseDictionary["error_description"] as? String
        else {
            return error
        }
        /*
         Possible errors:
         - invalid_client: client_id is missing or wrong, it shouldn't happen
         - unsupported_grant_type: client_id doesn't support password grants
         - invalid_request: A required field is missing/malformed
         - invalid_request: Authentication failed
         - needs_2fa: Multifactor Authentication code is required
         */

        let errorsMap = [
            "invalid_client" : WordPressComOAuthError.InvalidClient,
            "unsupported_grant_type" : WordPressComOAuthError.UnsupportedGrantType,
            "invalid_request" : WordPressComOAuthError.InvalidRequest,
            "needs_2fa" : WordPressComOAuthError.NeedsMultifactorCode
        ]

        let mappedCode = errorsMap[errorCode]?.rawValue ?? WordPressComOAuthError.Unknown.rawValue;

        return NSError(domain:self.dynamicType.WordPressComOAuthErrorDomain,
                       code:mappedCode,
                       userInfo:[NSLocalizedDescriptionKey: errorDescription])

    }

    private func cleanedUpResponseForLogging(response: AnyObject) -> AnyObject {
        guard var responseDictionary = response as? [String:AnyObject],
            let _ = responseDictionary["access_token"]
            else {
                return response;
        }
        
        responseDictionary["access_token"] = "*** REDACTED ***"
        return responseDictionary;
    }
    
}
