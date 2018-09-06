import Foundation

// MARK: - NotificationBlockGroup: Adapter to match 1 View <> 1 BlockGroup
//
class NotificationBlockGroup {
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
extension NotificationBlockGroup {
    /// Returns the First Block of a specified kind
    ///
    func blockOfKind(_ kind: NotificationBlock.Kind) -> NotificationBlock? {
        return type(of: self).blockOfKind(kind, from: blocks)
    }

    /// Extracts all of the imageUrl's for the blocks of the specified kinds
    ///
    func imageUrlsFromBlocksInKindSet(_ kindSet: Set<NotificationBlock.Kind>) -> Set<URL> {
        let filtered = blocks.filter { kindSet.contains($0.kind) }
        let imageUrls = filtered.flatMap { $0.imageUrls }
        return Set(imageUrls) as Set<URL>
    }
}



// MARK: - Parsers
//
extension NotificationBlockGroup {
    /// Subject: Contains a User + Text Block
    ///
    class func groupFromSubject(_ subject: [[String: AnyObject]], parent: Notification) -> NotificationBlockGroup {
        let blocks = NotificationBlock.blocksFromArray(subject, parent: parent)
        return NotificationBlockGroup(blocks: blocks, kind: .subject)
    }

    /// Header: Contains a User + Text Block
    ///
    class func groupFromHeader(_ header: [[String: AnyObject]], parent: Notification) -> NotificationBlockGroup {
        let blocks = NotificationBlock.blocksFromArray(header, parent: parent)
        return NotificationBlockGroup(blocks: blocks, kind: .header)
    }

    /// Body: May contain different kinds of Groups!
    ///
    class func groupsFromBody(_ body: [[String: AnyObject]], parent: Notification) -> [NotificationBlockGroup] {
        let blocks = NotificationBlock.blocksFromArray(body, parent: parent)

        switch parent.kind {
        case .comment:
            return groupsForCommentBodyBlocks(blocks, parent: parent)
        default:
            return groupsForNonCommentBodyBlocks(blocks, parent: parent)
        }
    }
}


// MARK: - Private Parsing Helpers
//
private extension NotificationBlockGroup {
    /// Non-Comment Body Groups: 1-1 Mapping between Blocks <> BlockGroups
    ///
    ///     -   Notifications of the kind [Follow, Like, CommentLike] may contain a Footer block.
    ///     -   We can assume that whenever the last block is of the type .Text, we're dealing with a footer.
    ///     -   Whenever we detect such a block, we'll map the NotificationBlock into a .Footer group.
    ///     -   Footers are visually represented as `View All Followers` / `View All Likers`
    ///
    class func groupsForNonCommentBodyBlocks(_ blocks: [NotificationBlock], parent: Notification) -> [NotificationBlockGroup] {
        let parentKindsWithFooters: [NotificationKind] = [.follow, .like, .commentLike]
        let parentMayContainFooter = parentKindsWithFooters.contains(parent.kind)

        return blocks.map { block in
            let isFooter = parentMayContainFooter && block.kind == .text && blocks.last == block
            let kind = isFooter ? .footer : Kind.fromBlockKind(block.kind)
            return NotificationBlockGroup(blocks: [block], kind: kind)
        }
    }

    /// Comment Body Blocks:
    ///     -   Required to always render the Actions at the very bottom.
    ///     -   Adapter: a single NotificationBlockGroup can be easily mapped against a single UI entity.
    ///
    class func groupsForCommentBodyBlocks(_ blocks: [NotificationBlock], parent: Notification) -> [NotificationBlockGroup] {
        guard let comment = blockOfKind(.comment, from: blocks), let user = blockOfKind(.user, from: blocks) else {
            return []
        }

        var groups              = [NotificationBlockGroup]()
        let commentGroupBlocks  = [comment, user]
        let middleGroupBlocks   = blocks.filter { return commentGroupBlocks.contains($0) == false }
        let actionGroupBlocks   = [comment]

        // Comment Group: Comment + User Blocks
        groups.append(NotificationBlockGroup(blocks: commentGroupBlocks, kind: .comment))

        // Middle Group(s): Anything
        for block in middleGroupBlocks {
            // Duck Typing Again:
            // If the block contains a range that matches with the metaReplyID field, we'll need to render this
            // with a custom style. Translates into the `You replied to this comment` footer.
            //
            var kind = Kind.fromBlockKind(block.kind)
            if let parentReplyID = parent.metaReplyID, block.notificationRangeWithCommentId(parentReplyID) != nil {
                kind = .footer
            }

            groups.append(NotificationBlockGroup(blocks: [block], kind: kind))
        }

        // Whenever Possible *REMOVE* this workaround. Pingback Notifications require a locally generated block.
        //
        if parent.isPingback, let homeURL = user.metaLinksHome {
            let blockGroup = pingbackReadMoreGroup(for: homeURL)
            groups.append(blockGroup)
        }

        // Actions Group: A copy of the Comment Block (Actions)
        groups.append(NotificationBlockGroup(blocks: actionGroupBlocks, kind: .actions))

        return groups
    }

    /// Returns the First Block of a specified kind.
    ///
    class func blockOfKind(_ kind: NotificationBlock.Kind, from blocks: [NotificationBlock]) -> NotificationBlock? {
        for block in blocks where block.kind == kind {
            return block
        }

        return nil
    }
}


// MARK: - Private Parsing Helpers
//
private extension NotificationBlockGroup {

    /// Returns a BlockGroup containing a single Text Block, which links to the specified URL.
    ///
    class func pingbackReadMoreGroup(for url: URL) -> NotificationBlockGroup {
        let text = NSLocalizedString("Read the source post", comment: "Displayed at the footer of a Pingback Notification.")
        let textRange = NSRange(location: 0, length: text.count)
        let zeroRange = NSRange(location: 0, length: 0)

        let ranges = [
            NotificationRange(kind: .Noticon, range: zeroRange, value: "\u{f442}"),
            NotificationRange(kind: .Link, range: textRange, url: url)
        ]

        let block = NotificationBlock(text: text, ranges: ranges)
        return NotificationBlockGroup(blocks: [block], kind: .footer)
    }
}

// MARK: - NotificationBlockGroup Types
//
extension NotificationBlockGroup {
    /// Known Kinds of Block Groups
    ///
    enum Kind {
        case text
        case image
        case user
        case comment
        case actions
        case subject
        case header
        case footer

        static func fromBlockKind(_ blockKind: NotificationBlock.Kind) -> Kind {
            switch blockKind {
            case .text:     return .text
            case .image:    return .image
            case .user:     return .user
            case .comment:  return .comment
            }
        }
    }
}
