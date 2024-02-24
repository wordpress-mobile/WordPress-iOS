import Foundation

public struct JetpackInstallError: LocalizedError, Equatable {
    public enum ErrorType: String {
        case invalidCredentials = "INVALID_CREDENTIALS"
        case forbidden = "FORBIDDEN"
        case installFailure = "INSTALL_FAILURE"
        case installResponseError = "INSTALL_RESPONSE_ERROR"
        case loginFailure = "LOGIN_FAILURE"
        case siteIsJetpack = "SITE_IS_JETPACK"
        case activationOnInstallFailure = "ACTIVATION_ON_INSTALL_FAILURE"
        case activationResponseError = "ACTIVATION_RESPONSE_ERROR"
        case activationFailure = "ACTIVATION_FAILURE"
        case unknown

        init(error key: String) {
            self = ErrorType(rawValue: key) ?? .unknown
        }
    }

    public var title: String?
    public var code: Int
    public var type: ErrorType

    public static var unknown: JetpackInstallError {
        return JetpackInstallError(type: .unknown)
    }

    public init(title: String? = nil, code: Int = 0, key: String? = nil) {
        self.init(title: title, code: code, type: ErrorType(error: key ?? ""))
    }

    public init(title: String? = nil, code: Int = 0, type: ErrorType = .unknown) {
        self.title = title
        self.code = code
        self.type = type
    }
}

public class JetpackServiceRemote: ServiceRemoteWordPressComREST {
    public enum ResponseError: Error {
        case decodingFailed
    }

    public func checkSiteHasJetpack(_ url: URL,
                                          success: @escaping (Bool) -> Void,
                                          failure: @escaping (Error?) -> Void) {
        let path = self.path(forEndpoint: "connect/site-info", withVersion: ._1_0)
        let parameters = ["url": url.absoluteString as AnyObject]
        wordPressComRestApi.GET(path,
                                parameters: parameters,
                                success: { [weak self] (response: AnyObject, _: HTTPURLResponse?) in
                                    do {
                                        let hasJetpack = try self?.hasJetpackMapping(object: response)
                                        success(hasJetpack ?? false)
                                    } catch {
                                        failure(error)
                                    }
        }) { (error: NSError, _: HTTPURLResponse?) in
            failure(error)
        }
    }

    public func installJetpack(url: String,
                        username: String,
                        password: String,
                        completion: @escaping (Bool, JetpackInstallError?) -> Void) {
        guard let escapedURL = url.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else {
            completion(false, .unknown)
            return
        }
        let path = String(format: "jetpack-install/%@/", escapedURL)
        let requestUrl = self.path(forEndpoint: path, withVersion: ._1_0)
        let parameters = ["user": username,
                          "password": password]

        wordPressComRestApi.POST(requestUrl,
                                 parameters: parameters as [String: AnyObject],
                                 success: { (response: AnyObject, _: HTTPURLResponse?) in
                                    if let response = response as? [String: Bool],
                                        let success = response[Constants.status] {
                                        completion(success, nil)
                                    } else {
                                        completion(false, JetpackInstallError(type: .installResponseError))
                                    }
        }) { (error: NSError, _: HTTPURLResponse?) in
            let key = error.userInfo[WordPressComRestApi.ErrorKeyErrorCode] as? String
            let jetpackError = JetpackInstallError(title: error.localizedDescription,
                                                   code: error.code,
                                                   key: key)
            completion(false, jetpackError)
        }
    }

    private enum Constants {
        static let hasJetpack = "hasJetpack"
        static let status = "status"
    }
}

private extension JetpackServiceRemote {
    func hasJetpackMapping(object: AnyObject) throws -> Bool {
        guard let response = object as? [String: AnyObject],
            let hasJetpack = response[Constants.hasJetpack] as? NSNumber else {
                throw ResponseError.decodingFailed
        }
        return hasJetpack.boolValue
    }
}
