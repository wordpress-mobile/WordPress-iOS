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
    case notifications(siteId: Int, action: ServiceRequestAction)
    case postsEmail(siteId: Int, action: ServiceRequestAction)
    case comments(siteId: Int, action: ServiceRequestAction)
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
            return "read/sites/\(siteId)/notification-subscriptions/\(action.rawValue)/"
            
        case .postsEmail(let siteId, let action):
            return "read/site/\(siteId)/post_email_subscriptions/\(action.rawValue)/"
            
        case .comments(let siteId, let action):
            return "read/site/\(siteId)/comment_email_subscriptions/\(action.rawValue)/"
        }
    }
}
