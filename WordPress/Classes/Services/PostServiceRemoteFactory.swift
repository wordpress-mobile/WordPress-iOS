
import Foundation
import WordPressKit

@objc class PostServiceRemoteFactory: NSObject {
    @objc func forBlog(_ blog: Blog) -> PostServiceRemote? {
        if blog.supports(.wpComRESTAPI),
            let api = blog.wordPressComRestApi(),
            let dotComID = blog.dotComID {
            return PostServiceRemoteREST(wordPressComRestApi: api, siteID: dotComID)
        } else if let api = blog.xmlrpcApi,
            let username = blog.username,
            let password = blog.password {
            return PostServiceRemoteXMLRPC(api: api, username: username, password: password)
        } else {
            return nil
        }
    }
}
