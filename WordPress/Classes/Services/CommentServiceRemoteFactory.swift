import Foundation
import WordPressKit


/// Provides service remote instances for CommentService
@objc class CommentServiceRemoteFactory: NSObject {

    /// Returns a CommentServiceRemote for a given Blog object
    ///
    /// - Parameter blog: A valid Blog object
    /// - Returns: A CommentServiceRemote instance
    @objc func remote(blog: Blog) -> CommentServiceRemote? {
        if blog.supports(.wpComRESTAPI),
           let api = blog.wordPressComRestApi(),
           let dotComID = blog.dotComID {
            return CommentServiceRemoteREST(wordPressComRestApi: api, siteID: dotComID)
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
    @objc func restRemote(siteID: NSNumber, api: WordPressComRestApi) -> CommentServiceRemoteREST {
        return CommentServiceRemoteREST(wordPressComRestApi: api, siteID: siteID)
    }

}
