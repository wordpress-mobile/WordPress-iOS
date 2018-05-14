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
    @nonobjc public func subscribeSiteNotifications(with siteId: Int, _ success: @escaping () -> Void, _ failure: @escaping (ReaderTopicServiceError?) -> Void) {
        POST(with: .notifications(siteId: siteId, action: .subscribe), success: success, failure: failure)
    }
    
    /// Unsubscribe action for site notifications
    ///
    /// - Parameters:
    ///   - siteId: A site id
    ///   - success: Success block
    ///   - failure: Failure block
    @nonobjc public func unsubscribeSiteNotifications(with siteId: Int, _ success: @escaping () -> Void, _ failure: @escaping (ReaderTopicServiceError?) -> Void) {
        POST(with: .notifications(siteId: siteId, action: .unsubscribe), success: success, failure: failure)
    }
    
    /// Subscribe action for site comments
    ///
    /// - Parameters:
    ///   - siteId: A site id
    ///   - success: Success block
    ///   - failure: Failure block
    @nonobjc public func subscribeSiteComments(with siteId: Int, _ success: @escaping () -> Void, _ failure: @escaping (ReaderTopicServiceError?) -> Void) {
        POST(with: .comments(siteId: siteId, action: .subscribe), success: success, failure: failure)
    }
    
    /// Unubscribe action for site comments
    ///
    /// - Parameters:
    ///   - siteId: A site id
    ///   - success: Success block
    ///   - failure: Failure block
    @nonobjc public func unsubscribeSiteComments(with siteId: Int, _ success: @escaping () -> Void, _ failure: @escaping (ReaderTopicServiceError?) -> Void) {
        POST(with: .comments(siteId: siteId, action: .unsubscribe), success: success, failure: failure)
    }

    /// Subscribe action for post emails
    ///
    /// - Parameters:
    ///   - siteId: A site id
    ///   - success: Success block
    ///   - failure: Failure block
    @nonobjc public func subscribePostsEmail(with siteId: Int, _ success: @escaping () -> Void, _ failure: @escaping (ReaderTopicServiceError?) -> Void) {
        POST(with: .postsEmail(siteId: siteId, action: .subscribe), success: success, failure: failure)
    }
    
    /// Unsubscribe action for post emails
    ///
    /// - Parameters:
    ///   - siteId: A site id
    ///   - success: Success block
    ///   - failure: Failure block
    @nonobjc public func unsubscribePostsEmail(with siteId: Int, _ success: @escaping () -> Void, _ failure: @escaping (ReaderTopicServiceError?) -> Void) {
        POST(with: .postsEmail(siteId: siteId, action: .unsubscribe), success: success, failure: failure)
    }
    
    /// Update action for posts email
    ///
    /// - Parameters:
    ///   - siteId: A site id
    ///   - frequency: The frequency value
    ///   - success: Success block
    ///   - failure: Failure block
    @nonobjc public func updateFrequencyPostsEmail(with siteId: Int, frequency: ReaderServiceDeliveryFrequency, _ success: @escaping () -> Void, _ failure: @escaping (ReaderTopicServiceError?) -> Void) {
        let parameters = [Delivery.frequency: NSString(string: frequency.rawValue)]
        POST(with: .postsEmail(siteId: siteId, action: .update), parameters: parameters, success: success, failure: failure)
    }
    
    
    // MARK: Private methods
    
    private func POST(with request: ReaderTopicServiceSubscriptionsRequest, parameters: [String: AnyObject]? = nil, success: @escaping () -> Void, failure: @escaping (ReaderTopicServiceError?) -> Void) {
        let urlRequest = path(forEndpoint: request.path, withVersion: request.apiVersion)
        
        DDLogInfo("URL: \(urlRequest)")
        
        wordPressComRestApi.POST(urlRequest, parameters: parameters, success: { (_, response) in
            DDLogInfo("Success \(response?.url?.absoluteString ?? "unknown url")")
            success()
        }) { (error, response) in
            DDLogError("Error: \(error.localizedDescription)")
            let urlAbsoluteString = response?.url?.absoluteString ?? NSLocalizedString("unknown url", comment: "Used when the response doesn't have a valid url to display")
            failure(ReaderTopicServiceError.remoteResponse(message: error.localizedDescription, url: urlAbsoluteString))
        }
    }
}
