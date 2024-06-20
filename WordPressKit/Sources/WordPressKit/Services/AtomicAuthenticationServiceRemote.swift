import Foundation

public class AtomicAuthenticationServiceRemote: ServiceRemoteWordPressComREST {

    public enum ResponseError: Error {
        case responseIsNotADictionary(response: Any)
        case decodingFailure(response: [String: AnyObject])
        case couldNotInstantiateCookie(name: String, value: String, domain: String, path: String, expires: Date)
    }

    public func getAuthCookie(
        siteID: Int,
        success: @escaping (_ cookie: HTTPCookie) -> Void,
        failure: @escaping (Error) -> Void) {

        let endpoint = "sites/\(siteID)/atomic-auth-proxy/read-access-cookies"
        let path = self.path(forEndpoint: endpoint, withVersion: ._2_0)

        wordPressComRESTAPI.get(path,
                parameters: nil,
                success: { responseObject, _ in
                    do {
                        let settings = try self.cookie(from: responseObject)
                        success(settings)
                    } catch {
                        failure(error)
                    }
            },
                failure: { error, _ in
                    failure(error)
        })
    }

    // MARK: - Result Parsing

    private func date(from expiration: Int) -> Date {
        return Date(timeIntervalSince1970: TimeInterval(expiration))
    }

    private func cookie(from responseObject: Any) throws -> HTTPCookie {
        guard let response = responseObject as? [String: AnyObject] else {
            let error = ResponseError.responseIsNotADictionary(response: responseObject)
            WPKitLogError("❗️Error: \(error)")
            throw error
        }

        guard let cookies = response["cookies"] as? [[String: Any]] else {
            let error = ResponseError.decodingFailure(response: response)
            WPKitLogError("❗️Error: \(error)")
            throw error
        }

        let cookieDictionary = cookies[0]

        guard let name = cookieDictionary["name"] as? String,
            let value = cookieDictionary["value"] as? String,
            let domain = cookieDictionary["domain"] as? String,
            let path = cookieDictionary["path"] as? String,
            let expires = cookieDictionary["expires"] as? Int else {

                let error = ResponseError.decodingFailure(response: response)
                WPKitLogError("❗️Error: \(error)")
                throw error
        }

        let expirationDate = date(from: expires)

        guard let cookie = HTTPCookie(properties: [
            .name: name,
            .value: value,
            .domain: domain,
            .path: path,
            .expires: expirationDate
        ]) else {
            let error = ResponseError.couldNotInstantiateCookie(name: name, value: value, domain: domain, path: path, expires: expirationDate)
            WPKitLogError("❗️Error: \(error)")
            throw error
        }

        return cookie
    }
}
