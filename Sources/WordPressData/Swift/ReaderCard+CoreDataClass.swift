import Foundation
import CoreData
import WordPressKit

public class ReaderCard: NSManagedObject {
    public enum CardType {
        case post
        case topics
        case sites
        case unknown
    }

   public var type: CardType {
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

    public var isRecommendationCard: Bool {
        switch type {
        case .topics, .sites:
            return true
        default:
            return false
        }
    }

    public var topicsArray: [ReaderTagTopic] {
        topics?.array as? [ReaderTagTopic] ?? []
    }

    public var sitesArray: [ReaderSiteTopic] {
        sites?.array as? [ReaderSiteTopic] ?? []
    }

    public static func createOrReuse(context: NSManagedObjectContext, from remoteCard: RemoteReaderCard) -> ReaderCard? {
        guard remoteCard.type != .unknown else {
            return nil
        }

        switch remoteCard.type {
        case .post:
            let post: ReaderPost
            if let remotePost = remoteCard.post {
                post = PostHelper.createOrReplace(fromRemotePost: remotePost, for: nil, context: context)
            } else {
                return nil
            }

            // Check if a card already exists with this post to prevent duplicates
            if let existingCard = findExistingCard(with: post, context: context) {
                return existingCard
            }

            let card = ReaderCard(context: context)
            card.post = post
            return card

        case .interests:
            return nil // Disabled in v26.5
        case .sites:
            let card = ReaderCard(context: context)
            card.sites = NSOrderedSet(array: remoteCard.sites?.prefix(3).map {
                ReaderSiteTopic.createIfNeeded(from: $0, context: context)
            } ?? [])
            return card

        default:
            return nil
        }
    }

    private static func findExistingCard(with post: ReaderPost?, context: NSManagedObjectContext) -> ReaderCard? {
        guard let post else {
            return nil
        }

        let fetchRequest = ReaderCard.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "post = %@", post)
        fetchRequest.fetchLimit = 1

        return try? context.fetch(fetchRequest).first
    }
}
