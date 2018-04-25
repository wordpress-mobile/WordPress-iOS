import Foundation
import WordPressKit


// MARK: - WordPress.com BlogService
//
class WordPressComBlogService {

    /// Returns a new anonymous instance of WordPressComRestApi.
    ///
    private var anonymousAPI: WordPressComRestApi {
        let userAgent = WordPressAuthenticator.shared.configuration.userAgent
        return WordPressComRestApi(oAuthToken: nil, userAgent: userAgent)
    }


    /// Retrieves the WordPressComSiteInfo instance associated to a WordPress.com Site Address.
    ///
    func fetchSiteInfo(for address: String, success: @escaping (WordPressComSiteInfo) -> Void, failure: @escaping (Error) -> Void) {
        let remote = BlogServiceRemoteREST(wordPressComRestApi: anonymousAPI, siteID: 0)

        remote.fetchSiteInfo(forAddress: address, success: { response in
            guard let response = response else {
                failure(ServiceError.unknown)
                return
            }

            let site = WordPressComSiteInfo(remote: response)
            success(site)

        }, failure: { error in
            let result = error ?? ServiceError.unknown
            failure(result)
        })
    }
}


// MARK: - Nested Types
//
extension WordPressComBlogService {

    enum ServiceError: Error {
        case unknown
    }
}
