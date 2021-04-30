
import Foundation
import WordPressKit

@objc class PostServiceRemoteFactory: NSObject {
    @objc func forBlog(_ blog: Blog) -> PostServiceRemote? {
        if blog.supports(.wpComRESTAPI),
           let api = blog.wordPressComRestApi(),
           let dotComID = blog.dotComID {
            return PostServiceRemoteREST(wordPressComRestApi: api, siteID: dotComID)
        }

        if let api = blog.xmlrpcApi,
           let username = blog.username,
           let password = blog.password {
            return PostServiceRemoteXMLRPC(api: api, username: username, password: password)
        }

        return nil
    }

    @objc func restRemoteFor(siteID: NSNumber, context: NSManagedObjectContext) -> PostServiceRemoteREST? {
        guard let api = apiForRESTRequest(using: context) else {
            return nil
        }

        return PostServiceRemoteREST(wordPressComRestApi: api, siteID: siteID)
    }

    // MARK: Private methods

    /// Get the api to use for making REST requests.
    ///
    /// - Returns: an instance of WordPressComRestApi
    private func apiForRESTRequest(using context: NSManagedObjectContext) -> WordPressComRestApi? {
        let accountService = AccountService(managedObjectContext: context)

        guard let account = accountService.defaultWordPressComAccount(),
              let api = account.wordPressComRestApi else {
            return nil
        }

        // return anonymous api when no credentials are available.
        // reference: https://github.com/wordpress-mobile/WordPress-iOS/commit/4507481
        guard api.hasCredentials() else {
            return WordPressComRestApi(oAuthToken: nil,
                                       userAgent: WPUserAgent.wordPress(),
                                       localeKey: WordPressComRestApi.LocaleKeyDefault)
        }

        return api
    }
}
