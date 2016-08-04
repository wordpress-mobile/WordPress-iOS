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


    ///
    ///
    func blockOfKind(kind: NotificationBlock.Kind) -> NotificationBlock? {
        for block in blocks where block.kind == kind {
            return block
        }

        return nil
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


        var groups = [NotificationBlockGroup]()

        // Comment: Contains a User + Comment Block
        if parent.kind == .Comment {
            //  Note:
            //  I find myself, again, surrounded by the forces of Duck Typing. Comment Notifications are now
            //  required to always render the Actions at the very bottom. This snippet is meant to adapt the backend
            //  data structure, so that a single NotificationBlockGroup can be easily mapped against a single UI entity.
            //
            //  -   NoteBlockGroupTypeComment: NoteBlockTypeComment + NoteBlockTypeUser
            //  -   Anything
            //  -   NoteBlockGroupTypeActions: A copy of the NoteBlockTypeComment block
            //

//                let commentBlock = [NotificationBlock firstBlockOfType:NoteBlockTypeComment fromBlocksArray:blocks];
    //        NotificationBlock *userBlock    = [NotificationBlock firstBlockOfType:NoteBlockTypeUser fromBlocksArray:blocks];
    //        NSArray *commentGroupBlocks     = @[commentBlock, userBlock];
    //        NSArray *actionsGroupBlocks     = @[commentBlock];
    //
    //        NSMutableArray *middleBlocks    = [blocks mutableCopy];
    //        [middleBlocks removeObjectsInArray:commentGroupBlocks];
    //
    //        // Finally, arrange the Block Groups
    //        [groups addObject:[NotificationBlockGroup groupWithBlocks:commentGroupBlocks type:NoteBlockGroupTypeComment]];
    //
    //        for (NotificationBlock *block in middleBlocks) {
    //
    //            // Duck Typing Again:
    //            // If the block contains a range that matches with the metaReplyID field, we'll need to render this
    //            // with a custom style
    //            //
    //            BOOL isReply                = [block notificationRangeWithCommentId:notification.metaReplyID] != nil;
    //            NoteBlockGroupType type     = isReply ? NoteBlockGroupTypeFooter : block.type;
    //
    //            [groups addObject:[NotificationBlockGroup groupWithBlocks:@[block] type:type]];
    //        }
    //
    //        [groups addObject:[NotificationBlockGroup groupWithBlocks:actionsGroupBlocks type:NoteBlockGroupTypeActions]];
    //
    //
        // Rest: 1-1 relationship
        } else {

            //  More Duck Typing:
            //
            //  -   Notifications of the kind [Follow, Like, CommentLike] may contain a Footer block.
            //  -   We can assume that whenever the last block is of the type NoteBlockTypeText, we're dealing with a footer.
            //  -   Whenever we detect such a block, we'll map the NotificationBlock into a NoteBlockGroupTypeFooter group.
            //
            let canContainFooter = parent.kind == .Follow || parent.kind == .Like || parent.kind == .CommentLike

            for (index, block) in blocks.enumerate() {
                let isFooter = canContainFooter && block.kind == .Text && index == blocks.underestimateCount()
                let kind = isFooter ? NotificationBlockGroup.Kind.Footer : blockGroupKindForBlock(block)
                let group = NotificationBlockGroup(blocks: blocks, kind: kind)

                groups.append(group)
            }
        }

        return groups
    }

    private class func blockGroupKindForBlock(block: NotificationBlock) -> NotificationBlockGroup.Kind {
        switch block.kind {
            case .Text:     return .Text
            case .Image:    return .Image
            case .User:     return .User
            case .Comment:  return .Comment
        }
    }
}
