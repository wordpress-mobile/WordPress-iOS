import Foundation
import WordPressShared

public class JetpackScanServiceRemote: ServiceRemoteWordPressComREST {
    // MARK: - Scanning
    public func getScanAvailableForSite(_ siteID: Int, success: @escaping(Bool) -> Void, failure: @escaping(Error) -> Void) {
        getScanForSite(siteID, success: { (scan) in
            success(scan.isEnabled)
        }, failure: failure)
    }

    public func getCurrentScanStatusForSite(_ siteID: Int, success: @escaping(JetpackScanStatus?) -> Void, failure: @escaping(Error) -> Void) {
        getScanForSite(siteID, success: { scan in
            success(scan.current)
        }, failure: failure)
    }

    /// Starts a scan for a site
    public func startScanForSite(_ siteID: Int, success: @escaping(Bool) -> Void, failure: @escaping(Error) -> Void) {
        let path = self.scanPath(for: siteID, with: "enqueue")

        wordPressComRestApi.POST(path, parameters: nil, success: { (response, _) in
            guard let responseValue = response["success"] as? Bool else {
                success(false)
                return
            }

            success(responseValue)
        }, failure: { (error, _) in
            failure(error)
        })
    }

    /// Gets the main scan object
    public func getScanForSite(_ siteID: Int, success: @escaping(JetpackScan) -> Void, failure: @escaping(Error) -> Void) {
        let path = self.scanPath(for: siteID)

        wordPressComRestApi.GET(path, parameters: nil, success: { (response, _) in
            do {
                let decoder = JSONDecoder.apiDecoder
                let data = try JSONSerialization.data(withJSONObject: response, options: [])
                let envelope = try decoder.decode(JetpackScan.self, from: data)

                success(envelope)
            } catch {
                failure(error)
            }

        }, failure: { (error, _) in
            failure(error)
        })
    }

    // MARK: - Threats
    public enum ThreatError: Swift.Error {
        case invalidResponse
    }

    public func getThreatsForSite(_ siteID: Int, success: @escaping([JetpackScanThreat]?) -> Void, failure: @escaping(Error) -> Void) {
        getScanForSite(siteID, success: { scan in
            success(scan.threats)
        }, failure: failure)
    }

    /// Begins the fix process for multiple threats
    public func fixThreats(_ threats: [JetpackScanThreat], siteID: Int, success: @escaping(JetpackThreatFixResponse) -> Void, failure: @escaping(Error) -> Void) {
        let path = self.path(forEndpoint: "sites/\(siteID)/alerts/fix", withVersion: ._2_0)
        let parameters = ["threat_ids": threats.map { $0.id as AnyObject }] as [String: AnyObject]

        wordPressComRestApi.POST(path, parameters: parameters, success: { (response, _) in
            do {
                let decoder = JSONDecoder.apiDecoder
                let data = try JSONSerialization.data(withJSONObject: response, options: [])
                let envelope = try decoder.decode(JetpackThreatFixResponse.self, from: data)

                success(envelope)
            } catch {
                failure(error)
            }
        }, failure: { (error, _) in
            failure(error)
        })
    }

    /// Begins the fix process for a single threat
    public func fixThreat(_ threat: JetpackScanThreat, siteID: Int, success: @escaping(JetpackThreatFixStatus) -> Void, failure: @escaping(Error) -> Void) {
        fixThreats([threat], siteID: siteID, success: { response in
            guard let status = response.threats.first else {
                failure(ThreatError.invalidResponse)
                return
            }

            success(status)
        }, failure: { error in
            failure(error)
        })
    }

    /// Begins the ignore process for a single threat
    public func ignoreThreat(_ threat: JetpackScanThreat, siteID: Int, success: @escaping () -> Void, failure: @escaping(Error) -> Void) {
        let path = self.path(forEndpoint: "sites/\(siteID)/alerts/\(threat.id)", withVersion: ._2_0)
        let parameters = ["ignore": true] as [String: AnyObject]

        wordPressComRestApi.POST(path, parameters: parameters, success: { (_, _) in
            success()
        }, failure: { (error, _) in
            failure(error)
        })
    }

    /// Returns the fix status for multiple threats
    public func getFixStatusForThreats(_ threats: [JetpackScanThreat], siteID: Int, success: @escaping(JetpackThreatFixResponse) -> Void, failure: @escaping(Error) -> Void) {
        let path = self.path(forEndpoint: "sites/\(siteID)/alerts/fix", withVersion: ._2_0)
        let parameters = ["threat_ids": threats.map { $0.id as AnyObject }] as [String: AnyObject]

        wordPressComRestApi.GET(path, parameters: parameters, success: { (response, _) in
            do {
                let decoder = JSONDecoder.apiDecoder
                let data = try JSONSerialization.data(withJSONObject: response, options: [])
                let envelope = try decoder.decode(JetpackThreatFixResponse.self, from: data)

                success(envelope)
            } catch {
                failure(error)
            }
        }, failure: { (error, _) in
            failure(error)
        })
    }

    // MARK: - History
    public func getHistoryForSite(_ siteID: Int, success: @escaping(JetpackScanHistory) -> Void, failure: @escaping(Error) -> Void) {
        let path = scanPath(for: siteID, with: "history")

        wordPressComRestApi.GET(path, parameters: nil, success: { (response, _) in
            do {
                let decoder = JSONDecoder.apiDecoder
                let data = try JSONSerialization.data(withJSONObject: response, options: [])
                let envelope = try decoder.decode(JetpackScanHistory.self, from: data)

                success(envelope)
            } catch {
                failure(error)
            }
        }, failure: { (error, _) in
            failure(error)
        })
    }

    // MARK: - Private
    private func scanPath(for siteID: Int, with path: String? = nil) -> String {
        var endpoint = "sites/\(siteID)/scan/"

        if let path = path {
            endpoint = endpoint.appending(path)
        }

        return self.path(forEndpoint: endpoint, withVersion: ._2_0)
    }
}
