import Foundation

@objc class JetpackRestoreService: CoreDataService {

    private lazy var serviceV1: ActivityServiceRemote_ApiVersion1_0 = {
        let api = coreDataStack.performQuery {
            WordPressComRestApi.defaultApi(in: $0)
        }

        return ActivityServiceRemote_ApiVersion1_0(wordPressComRestApi: api)
    }()

    private lazy var service: ActivityServiceRemote = {
        let api = coreDataStack.performQuery {
            WordPressComRestApi.defaultApi(in: $0, localeKey: WordPressComRestApi.LocaleKeyV2)
        }

        return ActivityServiceRemote(wordPressComRestApi: api)
    }()

    func restoreSite(_ site: JetpackSiteRef,
                     rewindID: String?,
                     restoreTypes: JetpackRestoreTypes? = nil,
                     success: @escaping (String, Int) -> Void,
                     failure: @escaping (Error) -> Void) {
        guard let rewindID = rewindID else {
            return
        }
        serviceV1.restoreSite(site.siteID, rewindID: rewindID, types: restoreTypes, success: success, failure: failure)
    }

    func getRewindStatus(for site: JetpackSiteRef, success: @escaping (RewindStatus) -> Void, failure: @escaping (Error) -> Void) {
        service.getRewindStatus(site.siteID, success: success, failure: failure)
    }

}
