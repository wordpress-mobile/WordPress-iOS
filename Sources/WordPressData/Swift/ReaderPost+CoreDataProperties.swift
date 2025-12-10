import Foundation
import CoreData

extension ReaderPost {

    // MARK: - Attributes

    @NSManaged public var authorDisplayName: String?
    @NSManaged public var authorEmail: String?
    @NSManaged public var authorURL: String?
    @NSManaged public var siteIconURL: String?
    @NSManaged public var blogName: String?
    @NSManaged public var blogDescription: String?
    @NSManaged public var blogURL: String?
    @NSManaged public var commentCount: NSNumber?
    @NSManaged public var commentsOpen: Bool
    @NSManaged public var featuredImage: String?
    @NSManaged public var feedID: NSNumber?
    @NSManaged public var feedItemID: NSNumber?
    @NSManaged public var globalID: String?
    @NSManaged public var isBlogAtomic: Bool
    @NSManaged public var isBlogPrivate: Bool
    @NSManaged public var isFollowing: Bool
    @NSManaged public var isLiked: Bool
    @NSManaged public var isReblogged: Bool
    @NSManaged public var isWPCom: Bool
    @NSManaged public var isSavedForLater: Bool
    @NSManaged public var isSeen: Bool
    @NSManaged public var isSeenSupported: Bool
    @NSManaged public var organizationID: NSNumber
    @NSManaged public var likeCount: NSNumber?
    @NSManaged public var score: NSNumber?
    @NSManaged public var siteID: NSNumber?
    @NSManaged public var sortRank: NSNumber
    @NSManaged public var sortDate: Date?
    @NSManaged public var summary: String?
    @NSManaged public var tags: String?
    @NSManaged public var isLikesEnabled: Bool
    @NSManaged public var isSharingEnabled: Bool
    @NSManaged public var isSiteBlocked: Bool
    @NSManaged public var isSubscribedComments: Bool
    @NSManaged public var canSubscribeComments: Bool
    @NSManaged public var receivesCommentNotifications: Bool
    @NSManaged public var primaryTag: String?
    @NSManaged public var primaryTagSlug: String?
    @NSManaged public var isExternal: Bool
    @NSManaged public var isJetpack: Bool
    @NSManaged public var wordCount: NSNumber?
    @NSManaged public var readingTime: NSNumber?
    @NSManaged public var railcar: String?
    @NSManaged public var inUse: Bool

    // MARK: - Relationships

    @NSManaged public var topic: ReaderAbstractTopic?
    @NSManaged public var card: Set<ReaderCard>?
    @NSManaged public var sourceAttribution: SourcePostAttribution?
    @NSManaged public var crossPostMeta: ReaderCrossPostMeta?
}

// MARK: - Generated Accessors for card

extension ReaderPost {
    @objc(addCardObject:)
    @NSManaged public func addToCard(_ value: ReaderCard)

    @objc(removeCardObject:)
    @NSManaged public func removeFromCard(_ value: ReaderCard)

    @objc(addCard:)
    @NSManaged public func addToCard(_ values: Set<ReaderCard>)

    @objc(removeCard:)
    @NSManaged public func removeFromCard(_ values: Set<ReaderCard>)
}
