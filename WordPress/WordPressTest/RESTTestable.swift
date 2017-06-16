@testable import WordPressKit

/// Protocol to be used when testing REST Remotes
///
protocol RESTTestable {
    func getRestApi() -> WordPressComRestApi
}

extension RESTTestable {
    func getRestApi() -> WordPressComRestApi {
        return WordPressComRestApi(oAuthToken: nil, userAgent: nil)
    }
}
