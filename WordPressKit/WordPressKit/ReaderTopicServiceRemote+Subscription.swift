import Foundation


extension ReaderTopicServiceRemote {
    private struct Delivery {
        static let frequency = "delivery_frequency"
    }
    
    /// Subscribe action for site notifications
    ///
    /// - Parameters:
    ///   - siteId: A site id
    ///   - success: Success block
    ///   - failure: Failure block
    @nonobjc public func subscribeSiteNotifications(with siteId: NSNumber, _ success: @escaping () -> Void, _ failure: @escaping (NSError?) -> Void) {
        POST(with: .notifications(siteId: siteId, action: .subscribe), success: success, failure: failure)
    }
    
    /// Unsubscribe action for site notifications
    ///
    /// - Parameters:
    ///   - siteId: A site id
    ///   - success: Success block
    ///   - failure: Failure block
    @nonobjc public func unsubscribeSiteNotifications(with siteId: NSNumber, _ success: @escaping () -> Void, _ failure: @escaping (NSError?) -> Void) {
        POST(with: .notifications(siteId: siteId, action: .unsubscribe), success: success, failure: failure)
    }
    
    /// Subscribe action for site comments
    ///
    /// - Parameters:
    ///   - siteId: A site id
    ///   - success: Success block
    ///   - failure: Failure block
    @nonobjc public func subscribeSiteComments(with siteId: NSNumber, _ success: @escaping () -> Void, _ failure: @escaping (NSError?) -> Void) {
        POST(with: .comments(siteId: siteId, action: .subscribe), success: success, failure: failure)
    }
    
    /// Unubscribe action for site comments
    ///
    /// - Parameters:
    ///   - siteId: A site id
    ///   - success: Success block
    ///   - failure: Failure block
    @nonobjc public func unsubscribeSiteComments(with siteId: NSNumber, _ success: @escaping () -> Void, _ failure: @escaping (NSError?) -> Void) {
        POST(with: .comments(siteId: siteId, action: .unsubscribe), success: success, failure: failure)
    }

    /// Subscribe action for post emails
    ///
    /// - Parameters:
    ///   - siteId: A site id
    ///   - success: Success block
    ///   - failure: Failure block
    @nonobjc public func subscribePostsEmail(with siteId: NSNumber, _ success: @escaping () -> Void, _ failure: @escaping (NSError?) -> Void) {
        POST(with: .postsEmail(siteId: siteId, action: .subscribe), success: success, failure: failure)
    }
    
    /// Unsubscribe action for post emails
    ///
    /// - Parameters:
    ///   - siteId: A site id
    ///   - success: Success block
    ///   - failure: Failure block
    @nonobjc public func unsubscribePostsEmail(with siteId: NSNumber, _ success: @escaping () -> Void, _ failure: @escaping (NSError?) -> Void) {
        POST(with: .postsEmail(siteId: siteId, action: .unsubscribe), success: success, failure: failure)
    }
    
    /// Update action for posts email
    ///
    /// - Parameters:
    ///   - siteId: A site id
    ///   - frequency: The frequency value
    ///   - success: Success block
    ///   - failure: Failure block
    @nonobjc public func updateFrequencyPostsEmail(with siteId: NSNumber, frequency: ReaderServiceDeliveryFrequency, _ success: @escaping () -> Void, _ failure: @escaping (NSError?) -> Void) {
        let parameters = [Delivery.frequency: NSString(string: frequency.rawValue)]
        POST(with: .postsEmail(siteId: siteId, action: .update), parameters: parameters, success: success, failure: failure)
    }
    
    
    // MARK: Private methods
    
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
