import Foundation


extension ReaderTopicServiceRemote {
    private func POST(with request: ReaderTopicServiceSubscriptionsRequest, parameters: [String: AnyObject]? = nil, success: @escaping SuccessBlock, failure: @escaping FailureBlock) {
        guard let urlRequest = path(forEndpoint: request.path, withVersion: request.apiVersion) else {
            let error = NSError(domain: "ReaderTopicServiceRemote", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid url request"])
            failure(error)
            return
        }
        
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
    @nonobjc public func subscribeSiteNotifications(with siteId: NSNumber, _ success: @escaping SuccessBlock, _ failure: @escaping FailureBlock) {
        POST(with: .notifications(siteId: siteId, action: .subscribe), success: success, failure: failure)
    }
    
    @nonobjc public func unsubscribeSiteNotifications(with siteId: NSNumber, _ success: @escaping SuccessBlock, _ failure: @escaping FailureBlock) {
        POST(with: .notifications(siteId: siteId, action: .unsubscribe), success: success, failure: failure)
    }
}


extension ReaderTopicServiceRemote: SiteCommentsSubscriptable {
    @nonobjc public func subscribeSiteComments(with siteId: NSNumber, _ success: @escaping SuccessBlock, _ failure: @escaping FailureBlock) {
        POST(with: .comments(siteId: siteId, action: .subscribe), success: success, failure: failure)
    }
    
    @nonobjc public func unsubscribeSiteComments(with siteId: NSNumber, _ success: @escaping SuccessBlock, _ failure: @escaping FailureBlock) {
        POST(with: .comments(siteId: siteId, action: .unsubscribe), success: success, failure: failure)
    }
}


extension ReaderTopicServiceRemote: SitePostsSubscriptable {
    @nonobjc public func subscribePostsEmail(with siteId: NSNumber, _ success: @escaping SuccessBlock, _ failure: @escaping FailureBlock) {
        POST(with: .postsEmail(siteId: siteId, action: .subscribe), success: success, failure: failure)
    }
    
    @nonobjc public func unsubscribePostsEmail(with siteId: NSNumber, _ success: @escaping SuccessBlock, _ failure: @escaping FailureBlock) {
        POST(with: .postsEmail(siteId: siteId, action: .unsubscribe), success: success, failure: failure)
    }
    
    @nonobjc public func updateFrequencyPostsEmail(with siteId: NSNumber, frequency: ReaderServiceDeliveryFrequency, _ success: @escaping SuccessBlock, _ failure: @escaping FailureBlock) {
        let parameters = [WordPressKitConstants.SiteSubscription.Delivery.frequency: NSString(string: frequency.rawValue)]
        POST(with: .postsEmail(siteId: siteId, action: .update), parameters: parameters, success: success, failure: failure)
    }
}
