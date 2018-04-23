import Foundation


/// Enumeration to identify a service action
enum ServiceRequestAction: String {
    case subscribe = "new"
    case unsubscribe = "delete"
    case update = "update"
}


/// A protocol for a Service request
protocol ServiceRequest {
    /// Returns a valid url path
    var path: String { get }
    
    /// Returns the used API version
    var apiVersion: ServiceRemoteWordPressComRESTApiVersion { get }
}


/// Reader Topic Service request
enum ReaderTopicServiceSubscriptionsRequest {
    case notifications(siteId: NSNumber, action: ServiceRequestAction)
    case postsEmail(siteId: NSNumber, action: ServiceRequestAction)
    case comments(siteId: NSNumber, action: ServiceRequestAction)
    
    
    // MARK: Private methods
    
    /// Private method to build a base URL string
    ///
    /// - Parameter siteId: A site id
    /// - Returns: A valid base URL string
    private func baseUrlPath(with siteId: NSNumber) -> String {
        return "read/sites/\(siteId.stringValue)/"
    }
}


extension ReaderTopicServiceSubscriptionsRequest: ServiceRequest {
    var apiVersion: ServiceRemoteWordPressComRESTApiVersion {
        switch self {
        case .notifications: return ._2_0
        case .postsEmail: return ._1_2
        case .comments: return ._1_2
        }
    }
    
    var path: String {
        switch self {
        case .notifications(let siteId, let action):
            return baseUrlPath(with: siteId) + "notification-subscriptions/\(action.rawValue)/"
            
        case .postsEmail(let siteId, let action):
            return baseUrlPath(with: siteId) + "post_email_subscriptions/\(action.rawValue)/"
            
        case .comments(let siteId, let action):
            return baseUrlPath(with: siteId) + "comment_email_subscriptions/\(action.rawValue)/"
        }
    }
}
