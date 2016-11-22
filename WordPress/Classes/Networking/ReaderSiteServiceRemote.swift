import Foundation
import AFNetworking

enum ReaderSiteServiceRemoteError: Int {
    case invalidHost
    case unsuccessfulFollowSite
    case unsuccessfulUnfollowSite
    case unsuccessfulBlockSite
    case parseError
}

let ReaderSiteServiceRemoteErrorDomain = "ReaderSiteServiceRemoteErrorDomain"

@objc class ReaderSiteServiceRemote: ServiceRemoteWordPressComREST {

    typealias ReaderSiteSuccessClosure = (Void) -> Void
    typealias ReaderSiteFailureClosure = (NSError) -> Void
}

// MARK: - Follow/Unfollow sites
extension ReaderSiteServiceRemote {

    /**
     Get a list of the sites the user follows.

    - Parameters:
        - success: Closure called on a successful fetch.
        - failure: Closure called if there is any error. `error` can be any underlying network error.
     */
    func fetchFollowedSitesWithSuccess(success: ([RemoteReaderSite]) -> Void, failure: ReaderSiteFailureClosure) {

        let path = "read/following/mine?meta=site,feed"
        let requestURL = pathForEndpoint(path, withVersion: .Version_1_1)
        self.wordPressComRestApi.GET(requestURL, parameters: nil, success: {

            guard let response = $0.responseObject as? [String: AnyObject],
            let subscriptions = response["subscriptions"] as? [[String : AnyObject]]  else {
                failure(self.parseError())
                return
            }

            let sites = subscriptions.map(self.remoteFollowedSite)
            success(sites)

        }, failure: {
            failure($0.error)
        })
    }

    /**
     Follow a wpcom site.

     - Parameters:
        - siteID: The ID of the site.
        - success: closure called on a successful follow.
        - failure: closure called if there is any error. `error` can be any underlying network error.
     */
    func followSiteWithID(siteID: UInt, success: ReaderSiteSuccessClosure, failure: ReaderSiteFailureClosure) {

        let path = "sites/\(siteID)/follows/new"
        let requestURL = pathForEndpoint(path, withVersion: .Version_1_1)
        self.wordPressComRestApi.POST(requestURL, parameters: nil, success: { _ in
            success()
        }, failure: {
            failure($0.error)
        })
    }

    /**
    Unfollow a wpcom site

    - Parameters:
        - siteID: The ID of the site.
        - success: closure called on a successful unfollow.
        - failure: closure called if there is any error. `error` can be any underlying network error.
    */
    func unfollowSiteWithID(siteID: UInt, success: ReaderSiteSuccessClosure, failure: ReaderSiteFailureClosure) {

        let path = "sites/\(siteID)/follows/mine/delete"
        let requestURL = pathForEndpoint(path, withVersion: .Version_1_1)
        self.wordPressComRestApi.POST(requestURL, parameters: nil, success: { _ in
            success()
        }, failure: {
            failure($0.error)
        })
    }

    /**
     Follow a wporg site.

     - Parameters:
        - siteURL: The URL of the site as a string.
        - success: closure called on a successful follow.
        - failure: closure called if there is any error. `error` can be any underlying network error.
     */
    func followSiteAtURL(siteURL: String, success: ReaderSiteSuccessClosure, failure: ReaderSiteFailureClosure) {

        let path = "read/following/mine/new?url=\(siteURL)"
        let requestURL = pathForEndpoint(path, withVersion: .Version_1_1)
        let params = ["url" : siteURL]
        self.wordPressComRestApi.POST(requestURL, parameters: params, success: {

            guard let response = $0.responseObject as? [String: AnyObject],
                let subscribed = response["subscribed"] as? Bool else {
                    failure(self.parseError())
                    return
            }

            guard subscribed else {
                failure(self.unsuccessfulFollowSiteError())
                return
            }

            success()

        }, failure: {
            failure($0.error)
        })
    }

    /**
     Unfollow a wporg site

     - Parameters:
        - siteURL: The URL of the site as a string.
        - success: closure called on a successful unfollow.
        - failure: closure called if there is any error. `error` can be any underlying network error.
     */
    func unfollowSiteAtURL(siteURL: String, success: ReaderSiteSuccessClosure, failure: ReaderSiteFailureClosure) {

        let path = "read/following/mine/delete?url=\(siteURL)"
        let requestURL = pathForEndpoint(path, withVersion: .Version_1_1)
        let params = ["url" : siteURL]
        self.wordPressComRestApi.POST(requestURL, parameters: params, success: {

            guard let response = $0.responseObject as? [String: AnyObject],
                let subscribed = response["subscribed"] as? Bool else {
                    failure(self.parseError())
                    return
            }

            guard !subscribed else {
                failure(self.unsuccessfulUnfollowSiteError())
                return
            }

            success()

            }, failure: {
                failure($0.error)
        })
    }
}

// MARK: - Find/Check sites
extension ReaderSiteServiceRemote {

    /**
     Find the WordPress.com site ID for the site at the specified URL.

     - Parameters:
        - siteURL: the URL of the site.
        - success: closure called on a successful fetch. The found siteID is passed to the success block.
        - failure: closure called if there is any error. `error` can be any underlying network error.
     */
    func findSiteIDForURL(siteURL: NSURL, success: (UInt) -> Void, failure: ReaderSiteFailureClosure) {

        guard let host = siteURL.host else {
            failure(invalidHostError())
            return
        }

        let successClosure: (responseObject: AnyObject, response: NSHTTPURLResponse?) -> Void = {

            guard let response = $0.responseObject as? [String: AnyObject],
                let siteID = response["ID"] as? UInt else {
                    failure(self.parseError())
                    return
            }
            success(siteID)
        }

        let failureClosure: (error: NSError, response: NSHTTPURLResponse?) -> Void = {
            failure($0.error)
        }

        let path = "sites/\(host)"
        let requestUrl = pathForEndpoint(path, withVersion: .Version_1_1)
        self.wordPressComRestApi.GET(requestUrl, parameters: nil, success: successClosure, failure: { _ in

            var newHost = host
            if host.hasPrefix("www.") {
                newHost = host.substringFromIndex(host.startIndex.advancedBy(4))
            } else {
                newHost = "www.\(host)"
            }

            let newPath = "sites/\(newHost)"
            let newUrl = self.pathForEndpoint(newPath, withVersion: .Version_1_1)
            self.wordPressComRestApi.GET(newUrl, parameters: nil, success: successClosure, failure: failureClosure)
        })
    }

    /**
     Test a URL to see if a site exists.

     - Parameters:
        - siteURL: the URL of the site.
        - success: closure called on a successful request.
        - failure: closure called if there is any error. `error` can be any underlying network error.
     */
    func checkSiteExistsAtURL(siteURL: NSURL, success: ReaderSiteSuccessClosure, failure: ReaderSiteFailureClosure) {

        let manager = AFHTTPSessionManager()
        let urlString = siteURL.absoluteString ?? ""
        manager.HEAD(urlString, parameters: nil, success: {_ in
            success()
        }, failure: { _, error in
            failure(error)
        })
    }
}

// MARK: - Subscribed sites
extension ReaderSiteServiceRemote {

    /**
     Check whether a site is already subscribed

     - Parameters:
        - siteID: The ID of the site.
        - success: closure called on a successful check. A boolean is returned indicating if the site is followed or not.
        - failure: closure called if there is any error. `error` can be any underlying network error.
     */
    func checkSubscribedToSiteByID(siteID: UInt, success: (Bool) -> Void, failure: ReaderSiteFailureClosure) {

        let path = "sites/\(siteID)/follows/mine"
        let requestUrl = pathForEndpoint(path, withVersion: .Version_1_1)
        self.wordPressComRestApi.GET(requestUrl, parameters: nil, success: {

            guard let response = $0.responseObject as? [String: AnyObject],
                let follows = response["is_following"] as? Bool else {
                    failure(self.parseError())
                    return
            }

            success(follows)

        }, failure: {
            failure($0.error)
        })
    }

    /**
     Check whether a feed is already subscribed

     - Parameters:
        - siteURL: the URL of the site.
        - success: closure called on a successful check. A boolean is returned indicating if the feed is followed or not.
        - failure: closure called if there is any error. `error` can be any underlying network error.
     */
    func checkSubscribedToFeedByURL(siteURL: NSURL, success: (Bool) -> Void, failure: ReaderSiteFailureClosure) {

        let path = "read/following/mine"
        let requestUrl = pathForEndpoint(path, withVersion: .Version_1_1)
        self.wordPressComRestApi.GET(requestUrl, parameters: nil, success: {

            let responseString = $0.responseObject.description.stringByRemovingPercentEncoding ?? ""
            let follows = responseString.containsString(siteURL.absoluteString ?? siteURL.description)
            success(follows)

        }, failure: {
            failure($0.error)
        })
    }
}

// MARK: - Block/Unblock Sites
extension ReaderSiteServiceRemote {

    /**
    Block/unblock a site from showing its posts in the reader

    - Parameters:
        - siteID: The ID of the site (not feed).
        - blocked: Boolean value. Yes if the site should be blocked. NO if the site should be unblocked.
        - success: closure called on a successful check.
        - failure: closure called if there is any error. `error` can be any underlying network error.
    */
    func flagSiteWithID(siteID: UInt, asBlocked: Bool, success: ReaderSiteSuccessClosure, failure: ReaderSiteFailureClosure) {

        var path = "me/block/sites/\(siteID)/delete"
        if asBlocked {
            path = "me/block/sites/\(siteID)/new"
        }

        let requestUrl = pathForEndpoint(path, withVersion: .Version_1_1)
        self.wordPressComRestApi.POST(requestUrl, parameters: nil, success: {

            guard let response = $0.responseObject as? [String: AnyObject],
                let succeeded = response["success"] as? Bool else {
                    failure(self.parseError())
                    return
            }

            guard succeeded else {
                let error = asBlocked ? self.unsuccessfulBlockSiteError() : self.unsuccessfulUnblockSiteError()
                failure(error)
                return
            }

            success()

        }, failure: {
            failure($0.error)
        })
    }
}

// MARK: - Parsing
extension ReaderSiteServiceRemote {

    private func remoteFollowedSite(dict: [String: AnyObject]) -> RemoteReaderSite {
        let site = remoteReaderSite(dict)
        site.isSubscribed = true
        return site
    }

    private func remoteReaderSite(dict: [String: AnyObject]) -> RemoteReaderSite {

        let meta = metaFromDictionary(dict)
        let site = RemoteReaderSite()
        site.recordID = dict["ID"] as? NSNumber
        site.path = dict["URL"] as? String
        site.siteID = meta["ID"] as? NSNumber
        site.feedID = meta["feed_ID"] as? NSNumber
        site.name = meta["name"] as? String
        site.icon = meta["icon.img"] as? String

        if site.name == nil || site.name.characters.isEmpty {
            site.name = site.path
        }

        return site
    }

    private func metaFromDictionary(dict: [String: AnyObject]) -> [String: AnyObject] {

        let dictionary = NSDictionary(dictionary: dict)
        guard let meta = dictionary.valueForKeyPath("meta.data.site") as? [String: AnyObject] else {
            guard let meta = dictionary.valueForKeyPath("meta.data.feed") as? [String: AnyObject] else {
                return [:]
            }
            return meta
        }
        return meta
    }
}

// MARK: - Errors
extension ReaderSiteServiceRemote {

    private func parseError() -> NSError {

        let description = NSLocalizedString("Parse Error", comment: "Error message when parsing fails")
        let userInfo = [NSLocalizedDescriptionKey : description]
        return NSError(domain: ReaderSiteServiceRemoteErrorDomain,
                       code: ReaderSiteServiceRemoteError.parseError.rawValue,
                       userInfo: userInfo)
    }

    private func invalidHostError() -> NSError {

        let description = NSLocalizedString("The URL is missing a valid host.",
                                            comment: "Error message describing a problem with a URL.")
        let userInfo = [NSLocalizedDescriptionKey : description]
        return NSError(domain: ReaderSiteServiceRemoteErrorDomain,
                       code: ReaderSiteServiceRemoteError.invalidHost.rawValue,
                       userInfo: userInfo)
    }

    private func unsuccessfulFollowSiteError() -> NSError {

        let description = NSLocalizedString("Could not follow the site at the address specified.",
                                            comment: "Error message informing the user that there was a problem subscribing to a site or feed.")
        let userInfo = [NSLocalizedDescriptionKey : description]
        return NSError(domain: ReaderSiteServiceRemoteErrorDomain,
                       code: ReaderSiteServiceRemoteError.unsuccessfulFollowSite.rawValue,
                       userInfo: userInfo)
    }

    private func unsuccessfulUnfollowSiteError() -> NSError {

        let description = NSLocalizedString("Could not unfollow the site at the address specified.",
                                            comment: "Error message informing the user that there was a problem unsubscribing to a site or feed.")
        let userInfo = [NSLocalizedDescriptionKey : description]
        return NSError(domain: ReaderSiteServiceRemoteErrorDomain,
                       code: ReaderSiteServiceRemoteError.unsuccessfulUnfollowSite.rawValue,
                       userInfo: userInfo)
    }

    private func unsuccessfulBlockSiteError() -> NSError {

        let description = NSLocalizedString("There was a problem blocking posts from the specified site.",
                                            comment: "Error message informing the user that there was a problem blocking posts from a site from their reader.")
        let userInfo = [NSLocalizedDescriptionKey : description]
        return NSError(domain: ReaderSiteServiceRemoteErrorDomain,
                       code: ReaderSiteServiceRemoteError.unsuccessfulBlockSite.rawValue,
                       userInfo: userInfo)
    }

    private func unsuccessfulUnblockSiteError() -> NSError {

        let description = NSLocalizedString("There was a problem removing the block for specified site.",
                                            comment: "Error message informing the user that there was a problem clearing the block on site preventing its posts from displaying in the reader.")
        let userInfo = [NSLocalizedDescriptionKey : description]
        return NSError(domain: ReaderSiteServiceRemoteErrorDomain,
                       code: ReaderSiteServiceRemoteError.unsuccessfulBlockSite.rawValue,
                       userInfo: userInfo)
    }
}
