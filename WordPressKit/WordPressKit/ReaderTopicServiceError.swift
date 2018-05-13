import Foundation


public enum ReaderTopicServiceError: Error {
    case invalidId
    case topicNotfound(id: Int)
    case remoteResponse(message: String?, url: String)
    
    public var description: String {
        switch self {
        case .invalidId:
            return "Invalid id: an id must be valid or not nil"
            
        case .topicNotfound(let id):
            let localizedString = NSLocalizedString("Topic not found for id:",
                                                    comment: "Used when a Reader Topic is not found for a specific id")
            return localizedString + " \(id)"
            
        case .remoteResponse(let message, let url):
            let localizedString = NSLocalizedString("An error occurred while processing your request: ",
                                                    comment: "Used when a remote response doesn't have a specific message for a specific request")
            return message ?? localizedString + " \(url)"
        }
    }
}
