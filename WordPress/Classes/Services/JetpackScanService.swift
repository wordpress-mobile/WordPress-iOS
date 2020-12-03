import Foundation

@objc class JetpackScanService: LocalCoreDataService {
    private lazy var service: JetpackScanServiceRemote = {
        return JetpackScanServiceRemote(wordPressComRestApi: defaultApi())
    }()

    @objc func getScanAvailable(for blog: Blog, success: @escaping(Bool) -> Void, failure: @escaping(Error) -> Void) {
        guard let siteID = blog.dotComID?.intValue else {
            return
        }

        service.getScanAvailableForSite(siteID, success: success, failure: failure)
    }

    private func defaultApi() -> WordPressComRestApi {
        let accountService = AccountService(managedObjectContext: managedObjectContext)
        let defaultAccount = accountService.defaultWordPressComAccount()
        let token: String? = defaultAccount?.authToken

        return WordPressComRestApi.defaultApi(oAuthToken: token,
                                              userAgent: WPUserAgent.wordPress())
    }
}
