import Foundation
import WordPressData
import WordPressKit

/// Provides service remote instances for CommentService
@objc public class CommentServiceRemoteFactory: NSObject {

    /// Returns a CommentServiceRemote for a given Blog object
    ///
    /// - Parameter blog: A valid Blog object
    /// - Returns: A CommentServiceRemote instance
    @objc public func remote(blog: Blog) -> CommentServiceRemote? {
        if blog.supports(.wpComRESTAPI),
           let api = blog.wordPressComRestApi,
           let dotComID = blog.dotComID {
            return CommentServiceRemoteREST(wordPressComRestApi: api, siteID: dotComID)
        }

        // The REST API does not have information about comment "likes". We'll continue to use WordPress.com API for now.
        if let site = try? WordPressSite(blog: blog) {
            return CommentServiceRemoteCoreRESTAPI(client: WordPressClientFactory.shared.instance(for: site))
        }

        if let api = blog.xmlrpcApi,
           let username = blog.username,
           let password = blog.password {
            return CommentServiceRemoteXMLRPC(api: api, username: username, password: password)
        }

        return nil
    }

    /// Returns a REST remote for a given site ID.
    ///
    /// - Parameters:
    ///   - siteID: A valid siteID
    ///   - api: An instance of WordPressComRestAPI
    /// - Returns: An instance of CommentServiceRemoteREST
    @objc public func restRemote(siteID: NSNumber, api: WordPressComRestApi) -> CommentServiceRemoteREST {
        return CommentServiceRemoteREST(wordPressComRestApi: api, siteID: siteID)
    }

}
