import Foundation

@objc class JetpackScanService: LocalCoreDataService {
    private lazy var service: JetpackScanServiceRemote = {
        let api = WordPressComRestApi.defaultApi(in: managedObjectContext,
                                                 localeKey: WordPressComRestApi.LocaleKeyV2)

        return JetpackScanServiceRemote(wordPressComRestApi: api)
    }()

    @objc func getScanAvailable(for blog: Blog, success: @escaping(Bool) -> Void, failure: @escaping(Error?) -> Void) {
        guard let siteID = blog.dotComID?.intValue else {
            failure(JetpackScanServiceError.invalidSiteID)
            return
        }

        service.getScanAvailableForSite(siteID, success: success, failure: failure)
    }

    func getScan(for blog: Blog, success: @escaping(JetpackScan) -> Void, failure: @escaping(Error?) -> Void) {
        guard let siteID = blog.dotComID?.intValue else {
            failure(JetpackScanServiceError.invalidSiteID)
            return
        }

        service.getScanForSite(siteID, success: success, failure: failure)
    }

    func startScan(for blog: Blog, success: @escaping(Bool) -> Void, failure: @escaping(Error?) -> Void) {
        guard let siteID = blog.dotComID?.intValue else {
            failure(JetpackScanServiceError.invalidSiteID)
            return
        }

        service.startScanForSite(siteID, success: success, failure: failure)
    }

    // MARK: - Threats
    func fixThreats(_ threats: [JetpackScanThreat], blog: Blog, success: @escaping(JetpackThreatFixResponse) -> Void, failure: @escaping(Error) -> Void) {
        guard let siteID = blog.dotComID?.intValue else {
            failure(JetpackScanServiceError.invalidSiteID)
            return
        }

        service.fixThreats(threats, siteID: siteID, success: success, failure: failure)
    }

    func fixThreat(_ threat: JetpackScanThreat, blog: Blog, success: @escaping(JetpackThreatFixStatus) -> Void, failure: @escaping(Error) -> Void) {
        guard let siteID = blog.dotComID?.intValue else {
            failure(JetpackScanServiceError.invalidSiteID)
            return
        }

        service.fixThreat(threat, siteID: siteID, success: success, failure: failure)
    }

    public func getFixStatusForThreats(_ threats: [JetpackScanThreat], blog: Blog, success: @escaping(JetpackThreatFixResponse) -> Void, failure: @escaping(Error) -> Void) {
        guard let siteID = blog.dotComID?.intValue else {
            failure(JetpackScanServiceError.invalidSiteID)
            return
        }

        service.getFixStatusForThreats(threats, siteID: siteID, success: success, failure: failure)
    }

    func ignoreThreat(_ threat: JetpackScanThreat, blog: Blog, success: @escaping() -> Void, failure: @escaping(Error) -> Void) {
        guard let siteID = blog.dotComID?.intValue else {
            failure(JetpackScanServiceError.invalidSiteID)
            return
        }

        service.ignoreThreat(threat, siteID: siteID, success: success, failure: failure)
    }

    // MARK: - History
    func getHistory(for blog: Blog, success: @escaping(JetpackScanHistory) -> Void, failure: @escaping(Error) -> Void) {
        guard let siteID = blog.dotComID?.intValue else {
            failure(JetpackScanServiceError.invalidSiteID)
            return
        }

        service.getHistoryForSite(siteID, success: success, failure: failure)
    }

    // MARK: - Helpers
    enum JetpackScanServiceError: Error {
        case invalidSiteID
    }
}
