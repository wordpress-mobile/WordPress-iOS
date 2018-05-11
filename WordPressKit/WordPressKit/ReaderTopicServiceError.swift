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
            return "Topic not found for id: \(id)"
            
        case .remoteResponse(let message, let url):
            return message ?? "an error occurred while processing your request \(url)"
        }
    }
}
