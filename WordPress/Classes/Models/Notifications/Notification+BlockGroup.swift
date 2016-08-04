import Foundation



// MARK: - Block Group
//
extension Notification
{
    //// Adapter Class: Multiple Blocks can be mapped to a single view
    class BlockGroup
    {
        ///
        ///
        private (set) var blocks: [Block]

        ///
        ///
        private (set) var kind: Kind

        ///
        ///
        enum Kind {
            case Text       // = NoteBlockTypeText,
            case Image      // = NoteBlockTypeImage,
            case User       // = NoteBlockTypeUser,
            case Comment    // = NoteBlockTypeComment,      // Blocks: User  + Comment
            case Actions    // = 100,                       // Blocks: Comment
            case Subject    // = 200,                       // Blocks: Text  + Text
            case Header     // = 300,                       // Blocks: Image + Text
            case Footer     // = 400                        // Blocks: Text
        }


        ///
        ///
        init(blocks: [Block], kind: Kind) {
            self.blocks = blocks
            self.kind = kind
        }


        ///
        ///
        func blockOfKind(kind: Kind) -> Block? {
//            for block in blocks where block.kind == kind {
//                return block
//            }

            return nil
        }

        ///
        ///
        func imageUrlsFromBlocksInKindSet(kindSet: Set<Block.Kind>) -> Set<NSURL> {
            return Set()
//            let filtered = blocks.filter { kindSet.contains($0.kind) }
//            let urls = filtered.flatMap { $0.imageUrls }
//
//            return urls
        }

        ///
        ///
        class func subjectGroupFromArray(rawBlocks: [AnyObject]?, notification: Notification) -> BlockGroup? {
            // Subject: Contains a User + Text Block
        //    NSArray *blocks = [NotificationBlock blocksFromArray:rawBlocks notification:notification];
        //    if (blocks.count == 0) {
        //        return nil;
        //    }
        //
        //    return [NotificationBlockGroup groupWithBlocks:blocks type:NoteBlockGroupTypeSubject];
            return nil
        }

        ///
        ///
        class func headerGroupFromArray(rawBlocks: [AnyObject]?, notification: Notification) -> BlockGroup? {
            // Header: Contains a User + Text Block
        //    NSArray *blocks = [NotificationBlock blocksFromArray:rawBlocks notification:notification];
        //    if (blocks.count == 0) {
        //        return nil;
        //    }
        //
        //    return [NotificationBlockGroup groupWithBlocks:blocks type:NoteBlockGroupTypeHeader];
            return nil
        }

        ///
        ///
        class func bodyGroupsFromArray(rawBlocks: [AnyObject]?, notification: Notification) -> [BlockGroup] {
        //    NSArray *blocks         = [NotificationBlock blocksFromArray:rawBlocks notification:notification];
        //    NSMutableArray *groups  = [NSMutableArray array];
        //
        //    if (blocks.count == 0) {
        //        return groups;
        //    }
        //
        //    // Comment: Contains a User + Comment Block
        //    if (notification.isComment) {
        //
        //        //  Note:
        //        //  I find myself, again, surrounded by the forces of Duck Typing. Comment Notifications are now
        //        //  required to always render the Actions at the very bottom. This snippet is meant to adapt the backend
        //        //  data structure, so that a single NotificationBlockGroup can be easily mapped against a single UI entity.
        //        //
        //        //  -   NoteBlockGroupTypeComment: NoteBlockTypeComment + NoteBlockTypeUser
        //        //  -   Anything
        //        //  -   NoteBlockGroupTypeActions: A copy of the NoteBlockTypeComment block
        //
        //        NotificationBlock *commentBlock = [NotificationBlock firstBlockOfType:NoteBlockTypeComment fromBlocksArray:blocks];
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
        //    // Rest: 1-1 relationship
        //    } else {
        //
        //        //  More Duck Typing:
        //        //
        //        //  -   Notifications of the kind [Follow, Like, CommentLike] may contain a Footer block.
        //        //  -   We can assume that whenever the last block is of the type NoteBlockTypeText, we're dealing with a footer.
        //        //  -   Whenever we detect such a block, we'll map the NotificationBlock into a NoteBlockGroupTypeFooter group.
        //        //
        //        BOOL canContainFooter = notification.isFollow || notification.isLike || notification.isCommentLike;
        //
        //        for (NotificationBlock *block in blocks) {
        //            BOOL isFooter               = canContainFooter && block.type == NoteBlockTypeText && blocks.lastObject == block;
        //            NoteBlockGroupType type     = isFooter ? NoteBlockGroupTypeFooter : block.type;
        //
        //            [groups addObject:[NotificationBlockGroup groupWithBlocks:@[block] type:type]];
        //        }
        //    }
        //
        //    return groups;
            return []
        }
    }
}
