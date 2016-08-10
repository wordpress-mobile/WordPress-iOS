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
        return self.dynamicType.blockOfKind(kind, from: blocks)
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
    ///     -   Notifications of the kind [Follow, Like, CommentLike] may contain a Footer block.
    ///     -   We can assume that whenever the last block is of the type .Text, we're dealing with a footer.
    ///     -   Whenever we detect such a block, we'll map the NotificationBlock into a .Footer group.
    ///     -   Footers are visually represented as `View All Followers` / `View All Likers`
    ///
    class func groupsForNonCommentBodyBlocks(blocks: [NotificationBlock], parent: Notification) -> [NotificationBlockGroup] {
        let parentKindsWithFooters: [Notification.Kind] = [.Follow, .Like, .CommentLike]
        let parentMayContainFooter = parentKindsWithFooters.contains(parent.kind)

        return blocks.map { block in
            let isFooter = parentMayContainFooter && block.kind == .Text && blocks.last == block
            let kind = isFooter ? .Footer : Kind.fromBlockKind(block.kind)
            return NotificationBlockGroup(blocks: [block], kind: kind)
        }
    }

    /// Comment Body Blocks:
    ///     -   Required to always render the Actions at the very bottom.
    ///     -   Adapter: a single NotificationBlockGroup can be easily mapped against a single UI entity.
    ///
    class func groupsForCommentBodyBlocks(blocks: [NotificationBlock], parent: Notification) -> [NotificationBlockGroup] {
        guard let comment = blockOfKind(.Comment, from: blocks), let user = blockOfKind(.User, from: blocks) else {
            return []
        }

        var groups              = [NotificationBlockGroup]()
        let commentGroupBlocks  = [comment, user]
        let middleGroupBlocks   = blocks.filter { return commentGroupBlocks.contains($0) == false }
        let actionGroupBlocks   = [comment]

        // Comment Group: Comment + User Blocks
        groups.append(NotificationBlockGroup(blocks: commentGroupBlocks, kind: .Comment))

        // Middle Group(s): Anything
        for block in middleGroupBlocks {
            // Duck Typing Again:
            // If the block contains a range that matches with the metaReplyID field, we'll need to render this
            // with a custom style. Translates into the `You replied to this comment` footer.
            //
            var kind = Kind.fromBlockKind(block.kind)
            if let parentReplyID = parent.metaReplyID where block.notificationRangeWithCommentId(parentReplyID) != nil {
                kind = .Footer
            }

            groups.append(NotificationBlockGroup(blocks: [block], kind: kind))
        }

        // Actions Group: A copy of the Comment Block (Actions)
        groups.append(NotificationBlockGroup(blocks: actionGroupBlocks, kind: .Actions))

        return groups
    }

    /// Returns the First Block of a specified kind.
    ///
    class func blockOfKind(kind: NotificationBlock.Kind, from blocks: [NotificationBlock]) -> NotificationBlock? {
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

        static func fromBlockKind(blockKind: NotificationBlock.Kind) -> Kind {
            switch blockKind {
            case .Text:     return .Text
            case .Image:    return .Image
            case .User:     return .User
            case .Comment:  return .Comment
            }
        }
    }
}
