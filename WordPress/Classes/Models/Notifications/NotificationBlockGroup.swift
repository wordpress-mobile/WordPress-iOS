import Foundation



// MARK: - NotificationBlockGroup: Adapter to match 1 View <> 1 BlockGroup
//
class NotificationBlockGroup
{
    /// Grouped Blocks
    ///
    let blocks: [NotificationBlock]

    /// Kind of the current Group
    ///
    let kind: Kind

    /// Designated Initializer
    ///
    init(blocks: [NotificationBlock], kind: Kind) {
        self.blocks = blocks
        self.kind = kind
    }
}



// MARK: - Helpers Methods
//
extension NotificationBlockGroup
{
    /// Returns the First Block of a specified kind
    ///
    func blockOfKind(kind: NotificationBlock.Kind) -> NotificationBlock? {
        return self.dynamicType.firstBlockOfKind(kind, from: blocks)
    }

    /// Extracts all of the imageUrl's for the blocks of the specified kinds
    ///
    func imageUrlsFromBlocksInKindSet(kindSet: Set<NotificationBlock.Kind>) -> Set<NSURL> {
        let filtered = blocks.filter { kindSet.contains($0.kind) }
        let imageUrls = filtered.flatMap { $0.imageUrls }
        return Set(imageUrls)
    }
}



// MARK: - Parsers
//
extension NotificationBlockGroup
{
    /// Subject: Contains a User + Text Block
    ///
    class func groupFromSubject(subject: [[String: AnyObject]], parent: Notification) -> NotificationBlockGroup {
        let blocks = NotificationBlock.blocksFromArray(subject, parent: parent)
        return NotificationBlockGroup(blocks: blocks, kind: .Subject)
    }

    /// Header: Contains a User + Text Block
    ///
    class func groupFromHeader(header: [[String: AnyObject]], parent: Notification) -> NotificationBlockGroup {
        let blocks = NotificationBlock.blocksFromArray(header, parent: parent)
        return NotificationBlockGroup(blocks: blocks, kind: .Header)
    }

    /// Body: May contain different kinds of Groups!
    ///
    class func groupsFromBody(body: [[String: AnyObject]], parent: Notification) -> [NotificationBlockGroup] {
        let blocks = NotificationBlock.blocksFromArray(body, parent: parent)

        switch parent.kind {
        case .Comment:
            return groupsForCommentBodyBlocks(blocks, parent: parent)
        default:
            return groupsForNonCommentBodyBlocks(blocks, parent: parent)
        }
    }
}


// MARK: - Private Parsing Helpers
//
private extension NotificationBlockGroup
{
    /// Non-Comment Body Groups: 1-1 Mapping between Blocks <> BlockGroups
    ///
    class func groupsForNonCommentBodyBlocks(blocks: [NotificationBlock], parent: Notification) -> [NotificationBlockGroup] {
        return blocks.map { block in
            let kind = groupKindForBlock(block, parent: parent, isLastBlock: (block == blocks.last))
            return NotificationBlockGroup(blocks: [block], kind: kind)
        }
    }

    /// Comment Body Blocks:
    ///  -   Required to always render the Actions at the very bottom.
    ///  -   This helper is meant to adapt the backend data structure, so that a single NotificationBlockGroup
    ///      can be easily mapped against a single UI entity.
    ///
    class func groupsForCommentBodyBlocks(blocks: [NotificationBlock], parent: Notification) -> [NotificationBlockGroup] {
        guard let comment = firstBlockOfKind(.Comment, from: blocks), let user = firstBlockOfKind(.User, from: blocks) else {
            return []
        }

        var groups = [NotificationBlockGroup]()

        // Comment Group: Comment + User Blocks
        groups.append(NotificationBlockGroup(blocks: [comment, user], kind: .Comment))

        // Middle Group(s): Anything
        let middle = blocks.filter { return $0 != comment && $0 != user }

        for block in middle {
            let kind = groupKindForBlock(block, parent: parent)
            groups.append(NotificationBlockGroup(blocks: [block], kind: kind))
        }

        // Actions Group: A copy of the Comment Block (Actions)
        groups.append(NotificationBlockGroup(blocks: [comment], kind: .Actions))

        return groups
    }

    /// Infers the NotificationBlockGroup.Kind associated to a single Block instance. *SORRY* about the duck typing!!!
    ///
    class func groupKindForBlock(block: NotificationBlock, parent: Notification, isLastBlock: Bool = false) -> Kind {
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

        // Direct Mapping: Block.Kind > BlockGroup.Kind
        //
        switch block.kind {
            case .Text:     return .Text
            case .Image:    return .Image
            case .User:     return .User
            case .Comment:  return .Comment
        }
    }

    /// Returns the First Block of a specified kind.
    ///
    class func firstBlockOfKind(kind: NotificationBlock.Kind, from blocks: [NotificationBlock]) -> NotificationBlock? {
        for block in blocks where block.kind == kind {
            return block
        }

        return nil
    }
}


// MARK: - NotificationBlockGroup Types
//
extension NotificationBlockGroup
{
    /// Known Kinds of Block Groups
    ///
    enum Kind {
        case Text
        case Image
        case User
        case Comment
        case Actions
        case Subject
        case Header
        case Footer
    }
}
