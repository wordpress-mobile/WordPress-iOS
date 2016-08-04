import Foundation



// MARK: - Block Group: Multiple Blocks can be mapped to a single view
//
class NotificationBlockGroup
{
    ///
    ///
    enum Kind {
        case Text
        case Image
        case User
        case Comment    // Blocks: User  + Comment
        case Actions    // Blocks: Comment
        case Subject    // Blocks: Text  + Text
        case Header     // Blocks: Image + Text
        case Footer     // Blocks: Text
    }

    ///
    ///
    private (set) var blocks: [NotificationBlock]

    ///
    ///
    private (set) var kind: Kind

    ///
    ///
    init(blocks: [NotificationBlock], kind: Kind) {
        self.blocks = blocks
        self.kind = kind
    }
}



// MARK: - Block Group Methods
//
extension NotificationBlockGroup
{
    ///
    ///
    func blockOfKind(kind: NotificationBlock.Kind) -> NotificationBlock? {
        return self.dynamicType.firstBlockOfKind(kind, fromBlocksArray: blocks)
    }

    ///
    ///
    func imageUrlsFromBlocksInKindSet(kindSet: Set<NotificationBlock.Kind>) -> Set<NSURL> {
        let filtered = blocks.filter { kindSet.contains($0.kind) }
        let imageUrls = filtered.flatMap { $0.imageUrls }
        return Set(imageUrls)
    }

    ///
    ///
    class func subjectGroupFromArray(rawBlocks: [AnyObject], parent: Notification) -> NotificationBlockGroup? {
        // Subject: Contains a User + Text Block
        guard let blocks = NotificationBlock.blocksFromArray(rawBlocks, parent: parent) else {
            return nil
        }

        return NotificationBlockGroup(blocks: blocks, kind: .Subject)
    }

    ///
    ///
    class func headerGroupFromArray(rawBlocks: [AnyObject], parent: Notification) -> NotificationBlockGroup? {
        // Header: Contains a User + Text Block
        guard let blocks = NotificationBlock.blocksFromArray(rawBlocks, parent: parent) else {
            return nil
        }

        return NotificationBlockGroup(blocks: blocks, kind: .Header)
    }

    ///
    ///
    class func bodyGroupsFromArray(rawBlocks: [AnyObject], parent: Notification) -> [NotificationBlockGroup]? {
        guard let blocks = NotificationBlock.blocksFromArray(rawBlocks, parent: parent) else {
            return nil
        }

        // Non-Comment Scenario:
        //  -   1-1 Mapping between Blocks <> BlockGroups
        //
        guard parent.kind == .Comment else {
            let lastBlock = blocks.last

            return blocks.map { block in
                let isLastBlock = (lastBlock == block)
                let kind = blockGroupKindForBlock(block, parent: parent, isLastBlock: isLastBlock)
                return NotificationBlockGroup(blocks: [block], kind: kind)
            }
        }

        // Comment Scenario:
        //  -   Comment Notifications are required to always render the Actions at the very bottom.
        //      This snippet is meant to adapt the backend data structure, so that a single NotificationBlockGroup
        //      can be easily mapped against a single UI entity.
        //
        guard let commentBlock = firstBlockOfKind(.Comment, fromBlocksArray: blocks),
            let userBlock = firstBlockOfKind(.User, fromBlocksArray: blocks) else
        {
            return nil
        }

        var groups = [NotificationBlockGroup]()
        let headerBlocks = [commentBlock, userBlock]
        let middleBlocks = blocks.filter { headerBlocks.indexOf($0) == nil }
        let footerBlocks = [commentBlock]

        // Header Group: Comment + User Blocks
        let headerGroup = NotificationBlockGroup(blocks: headerBlocks, kind: .Comment)
        groups.append(headerGroup)

        // Middle Group: Anything
        for block in middleBlocks {
            let kind = blockGroupKindForBlock(block, parent: parent)
            let group = NotificationBlockGroup(blocks: [block], kind: kind)
            groups.append(group)
        }

        // Footer Group: A copy of the Comment Block (Actions)
        let footerGroup = NotificationBlockGroup(blocks: footerBlocks, kind: .Actions)
        groups.append(footerGroup)

        return groups
    }

    ///
    ///
    private class func blockGroupKindForBlock(block: NotificationBlock, parent: Notification, isLastBlock: Bool = false) -> Kind {
        // Reply: Translates into the `You replied to this comment` footer
        //
        if let parentReplyID = parent.metaReplyID where block.notificationRangeWithCommentId(parentReplyID) != nil {
            return .Footer
        }

        // Follow / Likes: Translates into `View All Followers` / `View All Likers` footer
        //
        let canContainFooter = parent.kind == .Follow || parent.kind == .Like || parent.kind == .CommentLike
        if canContainFooter && block.kind == .Text && isLastBlock {
            return .Footer
        }

        // Direct Mapping
        //
        switch block.kind {
            case .Text:     return .Text
            case .Image:    return .Image
            case .User:     return .User
            case .Comment:  return .Comment
        }
    }

    ///
    ///
    private class func firstBlockOfKind(kind: NotificationBlock.Kind, fromBlocksArray blocks: [NotificationBlock]) -> NotificationBlock? {
        for block in blocks where block.kind == kind {
            return block
        }

        return nil
    }
}
