import Foundation


/// Subscriptable protocol to handle site notifications
public protocol SiteNotificationsSubscriptable {
    /// Subscribe action for site notifications
    ///
    /// - Parameters:
    ///   - siteId: A site id
    ///   - success: Success block
    ///   - failure: Failure block
    func subscribeSiteNotifications(with siteId: NSNumber, _ success: @escaping () -> Void, _ failure: @escaping (NSError?) -> Void)
    
    /// Unsubscribe action for site notifications
    ///
    /// - Parameters:
    ///   - siteId: A site id
    ///   - success: Success block
    ///   - failure: Failure block
    func unsubscribeSiteNotifications(with siteId: NSNumber, _ success: @escaping () -> Void, _ failure: @escaping (NSError?) -> Void)
}


/// Subscriptable protocol to handle post email notifications
public protocol SitePostsSubscriptable {
    /// Subscribe action for post emails
    ///
    /// - Parameters:
    ///   - siteId: A site id
    ///   - success: Success block
    ///   - failure: Failure block
    func subscribePostsEmail(with siteId: NSNumber, _ success: @escaping () -> Void, _ failure: @escaping (NSError?) -> Void)
    
    /// Unsubscribe action for post emails
    ///
    /// - Parameters:
    ///   - siteId: A site id
    ///   - success: Success block
    ///   - failure: Failure block
    func unsubscribePostsEmail(with siteId: NSNumber, _ success: @escaping () -> Void, _ failure: @escaping (NSError?) -> Void)
    
    /// Update action for posts email
    ///
    /// - Parameters:
    ///   - siteId: A site id
    ///   - frequency: The frequency value
    ///   - success: Success block
    ///   - failure: Failure block
    func updateFrequencyPostsEmail(with siteId: NSNumber, frequency: ReaderServiceDeliveryFrequency, _ success: @escaping () -> Void, _ failure: @escaping (NSError?) -> Void)
}


/// Subscriptable protocol to handle site comments
public protocol SiteCommentsSubscriptable {
    /// Subscribe action for site comments
    ///
    /// - Parameters:
    ///   - siteId: A site id
    ///   - success: Success block
    ///   - failure: Failure block
    func subscribeSiteComments(with siteId: NSNumber, _ success: @escaping () -> Void, _ failure: @escaping (NSError?) -> Void)
    
    /// Unubscribe action for site comments
    ///
    /// - Parameters:
    ///   - siteId: A site id
    ///   - success: Success block
    ///   - failure: Failure block
    func unsubscribeSiteComments(with siteId: NSNumber, _ success: @escaping () -> Void, _ failure: @escaping (NSError?) -> Void)
}
