import Foundation


extension ReaderTopicServiceRemote {
    private func POST(with request: ReaderTopicServiceSubscriptionsRequest, parameters: [String: AnyObject]? = nil, success: @escaping () -> Void, failure: @escaping (NSError?) -> Void) {
        let urlRequest = path(forEndpoint: request.path, withVersion: request.apiVersion)
        
        DDLogInfo("URL: \(urlRequest)")
        
        wordPressComRestApi.POST(urlRequest, parameters: parameters, success: { (_, response) in
            DDLogInfo("Success \(response?.url?.absoluteString ?? "unknown response url")")
            success()
        }) { (error, _) in
            DDLogError("Error: \(error.localizedDescription)")
            failure(error)
        }
    }
}


extension ReaderTopicServiceRemote: SiteNotificationsSubscriptable {
    @nonobjc public func subscribeSiteNotifications(with siteId: NSNumber, _ success: @escaping () -> Void, _ failure: @escaping (NSError?) -> Void) {
        POST(with: .notifications(siteId: siteId, action: .subscribe), success: success, failure: failure)
    }
    
    @nonobjc public func unsubscribeSiteNotifications(with siteId: NSNumber, _ success: @escaping () -> Void, _ failure: @escaping (NSError?) -> Void) {
        POST(with: .notifications(siteId: siteId, action: .unsubscribe), success: success, failure: failure)
    }
}


extension ReaderTopicServiceRemote: SiteCommentsSubscriptable {
    @nonobjc public func subscribeSiteComments(with siteId: NSNumber, _ success: @escaping () -> Void, _ failure: @escaping (NSError?) -> Void) {
        POST(with: .comments(siteId: siteId, action: .subscribe), success: success, failure: failure)
    }
    
    @nonobjc public func unsubscribeSiteComments(with siteId: NSNumber, _ success: @escaping () -> Void, _ failure: @escaping (NSError?) -> Void) {
        POST(with: .comments(siteId: siteId, action: .unsubscribe), success: success, failure: failure)
    }
}


extension ReaderTopicServiceRemote: SitePostsSubscriptable {
    @nonobjc public func subscribePostsEmail(with siteId: NSNumber, _ success: @escaping () -> Void, _ failure: @escaping (NSError?) -> Void) {
        POST(with: .postsEmail(siteId: siteId, action: .subscribe), success: success, failure: failure)
    }
    
    @nonobjc public func unsubscribePostsEmail(with siteId: NSNumber, _ success: @escaping () -> Void, _ failure: @escaping (NSError?) -> Void) {
        POST(with: .postsEmail(siteId: siteId, action: .unsubscribe), success: success, failure: failure)
    }
    
    @nonobjc public func updateFrequencyPostsEmail(with siteId: NSNumber, frequency: ReaderServiceDeliveryFrequency, _ success: @escaping () -> Void, _ failure: @escaping (NSError?) -> Void) {
        let parameters = [WordPressKitConstants.SiteSubscription.Delivery.frequency: NSString(string: frequency.rawValue)]
        POST(with: .postsEmail(siteId: siteId, action: .update), parameters: parameters, success: success, failure: failure)
    }
}
