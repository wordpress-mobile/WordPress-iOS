import Foundation

@objc class JetpackScanService: LocalCoreDataService {
    private lazy var service: JetpackScanServiceRemote = {
        let api = WordPressComRestApi.defaultApi(in: managedObjectContext,
                                                 localeKey: WordPressComRestApi.LocaleKeyV2)

        return JetpackScanServiceRemote(wordPressComRestApi: api)
    }()

    @objc func getScanAvailable(for blog: Blog, success: @escaping(Bool) -> Void, failure: @escaping(Error) -> Void) {
        guard let siteID = blog.dotComID?.intValue else {
            return
        }

        service.getScanAvailableForSite(siteID, success: success, failure: failure)
    }
}
