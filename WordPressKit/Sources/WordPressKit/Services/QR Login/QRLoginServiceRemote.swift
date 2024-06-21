import Foundation
import WordPressShared

open class QRLoginServiceRemote: ServiceRemoteWordPressComREST {
    /// Validates the incoming QR Login token and retrieves the requesting browser, and location
    open func validate(token: String, data: String, success: @escaping (QRLoginValidationResponse) -> Void, failure: @escaping (Error?, QRLoginError?) -> Void) {
        let path = self.path(forEndpoint: "auth/qr-code/validate", withVersion: ._2_0)
        let parameters = [ "token": token, "data": data ] as [String: AnyObject]

        wordPressComRESTAPI.post(path, parameters: parameters as [String: AnyObject], success: { (response, _) in
            do {
                let decoder = JSONDecoder.apiDecoder
                let data = try JSONSerialization.data(withJSONObject: response, options: [])
                let envelope = try decoder.decode(QRLoginValidationResponse.self, from: data)

                success(envelope)
            } catch {
                failure(nil, .invalidData)
            }
        }, failure: { (error, response) in
            guard let response = response else {
                failure(error, .invalidData)
                return
            }

            let statusCode = response.statusCode
            failure(error, QRLoginError(statusCode: statusCode))
        })
    }

    /// Authenticates the users browser
    open func authenticate(token: String, data: String, success: @escaping(Bool) -> Void, failure: @escaping(Error) -> Void) {
        let path = self.path(forEndpoint: "auth/qr-code/authenticate", withVersion: ._2_0)
        let parameters = [ "token": token, "data": data ] as [String: AnyObject]

        wordPressComRESTAPI.post(path, parameters: parameters, success: { (response, _) in
            guard let responseDict = response as? [String: Any],
                let authenticated = responseDict["authenticated"] as? Bool else {
                success(false)
                return
            }

            success(authenticated)
        }, failure: { (error, _) in
            failure(error)
        })
    }
}

public enum QRLoginError {
    case invalidData
    case expired

    init(statusCode: Int) {
        switch statusCode {
        case 401:
            self = .expired

        default:
            self = .invalidData
        }
    }
}
