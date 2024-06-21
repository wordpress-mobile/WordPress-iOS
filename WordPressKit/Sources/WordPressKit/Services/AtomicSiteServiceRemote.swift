import Foundation

public final class AtomicSiteServiceRemote: ServiceRemoteWordPressComREST {
    /// - parameter scrollID: Pass the scroll ID from the previous response to
    /// fetch the next page.
    public func getErrorLogs(siteID: Int,
                             range: Range<Date>,
                             severity: AtomicErrorLogEntry.Severity? = nil,
                             scrollID: String? = nil,
                             pageSize: Int = 50,
                             success: @escaping (AtomicErrorLogsResponse) -> Void,
                             failure: @escaping (Error) -> Void) {
        let path = self.path(forEndpoint: "sites/\(siteID)/hosting/error-logs/", withVersion: ._2_0)
        var parameters = [
            "start": "\(Int(range.lowerBound.timeIntervalSince1970))",
            "end": "\(Int(range.upperBound.timeIntervalSince1970))",
            "sort_order": "desc",
            "page_size": "\(pageSize)"
        ] as [String: String]
        if let severity {
            parameters["filter[severity][]"] = severity.rawValue
        }
        if let scrollID {
            parameters["scroll_id"] = scrollID
        }
        wordPressComRESTAPI.get(path, parameters: parameters as [String: AnyObject]) { responseObject, httpResponse in
            guard (200..<300).contains(httpResponse?.statusCode ?? 0),
                  let data = (responseObject as? [String: AnyObject])?["data"],
                  JSONSerialization.isValidJSONObject(data) else {
                failure(URLError(.unknown))
                return
            }
            do {
                let data = try JSONSerialization.data(withJSONObject: data)
                let response = try JSONDecoder.apiDecoder.decode(AtomicErrorLogsResponse.self, from: data)
                success(response)
            } catch {
                WPKitLogError("Error parsing campaigns response: \(error), \(responseObject)")
                failure(error)
            }
        } failure: { error, _ in
            failure(error)
        }
    }

    public func getWebServerLogs(siteID: Int,
                                 range: Range<Date>,
                                 httpMethod: String? = nil,
                                 statusCode: Int? = nil,
                                 scrollID: String? = nil,
                                 pageSize: Int = 50,
                                 success: @escaping (AtomicWebServerLogsResponse) -> Void,
                                 failure: @escaping (Error) -> Void) {
        let path = self.path(forEndpoint: "sites/\(siteID)/hosting/logs/", withVersion: ._2_0)
        var parameters = [
            "start": "\(Int(range.lowerBound.timeIntervalSince1970))",
            "end": "\(Int(range.upperBound.timeIntervalSince1970))",
            "sort_order": "desc",
            "page_size": "\(pageSize)"
        ] as [String: String]
        if let httpMethod {
            parameters["filter[request_type][]"] = httpMethod.uppercased()
        }
        if let statusCode {
            parameters["filter[status][]"] = "\(statusCode)"
        }
        if let scrollID {
            parameters["scroll_id"] = scrollID
        }
        wordPressComRESTAPI.get(path, parameters: parameters as [String: AnyObject]) { responseObject, httpResponse in
            guard (200..<300).contains(httpResponse?.statusCode ?? 0),
                  let data = (responseObject as? [String: AnyObject])?["data"],
                  JSONSerialization.isValidJSONObject(data) else {
                failure(URLError(.unknown))
                return
            }
            do {
                let data = try JSONSerialization.data(withJSONObject: data)
                let response = try JSONDecoder.apiDecoder.decode(AtomicWebServerLogsResponse.self, from: data)
                success(response)
            } catch {
                WPKitLogError("Error parsing campaigns response: \(error), \(responseObject)")
                failure(error)
            }
        } failure: { error, _ in
            failure(error)
        }
    }
}
