import Foundation

/// Protocol representing a service that retrieves the users followed interests/tags
protocol ReaderSiteInfoService: AnyObject {
    /// Returns an API endpoint URL for the given path
    /// Example: https://public-api.wordpress.com/PATH
    /// - Parameter path: The API endpoint path to convert
    func endpointURLString(path: String) -> String
}

extension ReaderTopicService: ReaderSiteInfoService {
    func endpointURLString(path: String) -> String {
        // We have to create a "remote" service to get an accurate path for the endpoint
        let service = ReaderTopicServiceRemote(wordPressComRestApi: apiRequest())

        return service.endpointUrl(forPath: path)
    }

    private func apiRequest() -> WordPressComRestApi {
        let accountService = AccountService(managedObjectContext: managedObjectContext)
        let defaultAccount = accountService.defaultWordPressComAccount()
        let token: String? = defaultAccount?.authToken

        return WordPressComRestApi.defaultApi(oAuthToken: token,
                                              userAgent: WPUserAgent.wordPress())
    }
}
