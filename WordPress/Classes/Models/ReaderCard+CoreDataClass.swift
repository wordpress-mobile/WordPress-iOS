import Foundation
import CoreData

public class ReaderCard: NSManagedObject {
    enum CardType {
        case post
        case topics
        case sites
        case unknown
    }

    var type: CardType {
        if post != nil {
            return .post
        }

        if topicsArray.count > 0 {
            return .topics
        }

        if sitesArray.count > 0 {
            return .sites
        }

        return .unknown
    }

    var topicsArray: [ReaderTagTopic] {
        topics?.array as? [ReaderTagTopic] ?? []
    }

    var sitesArray: [ReaderSiteTopic] {
        sites?.array as? [ReaderSiteTopic] ?? []
    }

    convenience init?(context: NSManagedObjectContext, from remoteCard: RemoteReaderCard) {
        guard remoteCard.type != .unknown else {
            return nil
        }

        self.init(context: context)

        switch remoteCard.type {
        case .post:
            post = ReaderPost.createOrReplace(fromRemotePost: remoteCard.post, for: nil, context: context)
        case .interests:
            topics = NSOrderedSet(array: remoteCard.interests?.map {
                ReaderTagTopic.createOrUpdateIfNeeded(from: $0, context: context)
            } ?? [])
        case .sites:
            sites = NSOrderedSet(array: remoteCard.sites?.map {
                ReaderSiteTopic.createIfNeeded(from: $0, context: context)
            } ?? [])

        default:
            break
        }
    }
}
