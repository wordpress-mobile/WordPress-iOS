import Foundation
import CoreData

public class ReaderCard: NSManagedObject {
    convenience init?(context: NSManagedObjectContext, from remoteCard: RemoteReaderCard) {
        guard remoteCard.type != .unknown else {
            return nil
        }

        self.init(context: context)

        switch remoteCard.type {
        case .post:
            post = ReaderPost.createOrReplace(fromRemotePost: remoteCard.post, for: nil, context: managedObjectContext)
        case .interests:
            interests = Set(remoteCard.interests?.map {
                ReaderInterest(context: context, from: $0)
            } ?? [])
        default:
            break
        }
    }
}
