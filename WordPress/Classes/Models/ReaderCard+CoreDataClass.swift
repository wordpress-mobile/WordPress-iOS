import Foundation
import CoreData

public class ReaderCard: NSManagedObject {
    enum CardType {
        case post
        case topics
        case unknown
    }

    var type: CardType {
        if post != nil {
            return .post
        }

        if topics != nil {
            return .topics
        }

        return .unknown
    }

    var topicsArray: [ReaderTagTopic] {
        topics?.array as? [ReaderTagTopic] ?? []
    }

    convenience init?(context: NSManagedObjectContext, from remoteCard: RemoteReaderCard) {
        guard remoteCard.type != .unknown else {
            return nil
        }

        self.init(context: context)

        switch remoteCard.type {
        case .post:
            post = ReaderPost.createOrReplace(fromRemotePost: remoteCard.post, for: nil, context: managedObjectContext)
        case .interests:
            topics = NSOrderedSet(array: remoteCard.interests?.map {
                ReaderTagTopic.createIfNeeded(from: $0, context: context)
            } ?? [])
        default:
            break
        }
    }
}
