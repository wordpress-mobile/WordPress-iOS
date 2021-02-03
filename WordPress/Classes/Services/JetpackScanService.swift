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

    func getScanWithFixableThreatsStatus(for blog: Blog, success: @escaping(JetpackScan) -> Void, failure: @escaping(Error?) -> Void) {
        guard let siteID = blog.dotComID?.intValue else {
            failure(JetpackScanServiceError.invalidSiteID)
            return
        }

        service.getScanForSite(siteID, success: { [weak self] scanObj in
            // Only check if we're in the idle state, ie: not scanning or preparing to scan
            // The result does not have any fixable threats, we don't need to get the statuses for them
            guard scanObj.state == .idle, scanObj.hasFixableThreats, let fixableThreats = scanObj.fixableThreats else {
                success(scanObj)
                return
            }

            self?.getFixStatusForThreats(fixableThreats, blog: blog, success: { fixResponse in
                // We're not fixing any threats, just return the original scan object
                guard fixResponse.isFixingThreats else {
                    success(scanObj)
                    return
                }

                // Make a copy of the object so we can modify the state / fixing status
                var returnObj = scanObj
                returnObj.state = .fixingThreats

                // Map the threat Ids to Threats
                let threats = returnObj.fixableThreats ?? []
                var inProgressThreats: [JetpackThreatFixStatus] = []

                for item in fixResponse.threats {
                    // Filter any fixable threats that may not be actively being fixed
                    if item.status == .notStarted {
                        continue
                    }

                    var threat = threats.filter({ $0.id == item.threatId }).first
                    if item.status == .inProgress {
                        threat?.status = .fixing
                    }

                    var fixStatus = item
                    fixStatus.threat = threat
                    inProgressThreats.append(fixStatus)
                }

                returnObj.threatFixStatus = inProgressThreats

                //
                success(returnObj)
            }, failure: failure)
        }, failure: failure)
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
