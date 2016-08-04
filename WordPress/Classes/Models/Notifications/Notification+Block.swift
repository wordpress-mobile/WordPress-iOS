import Foundation



//@interface NotificationBlock (Internals)
//
// Dynamic Attribute Cache: used internally by the Interface Extension, as an optimization.
// - (void)setCacheValue:(id)value forKey:(NSString *)key;
//- (id)cacheValueForKey:(NSString *)key;
//

extension Notification
{
    class Block
    {
        ///
        ///
        enum Kind {
            case Text
            case Image  // BlockTypesImage: Includes Badges and Images
            case User
            case Comment
        }

        ///
        ///
        enum Action {
            case Follow
            case Like
            case Spam
            case Trash
            case Reply
            case Approve
            case Edit
        }


        ///
        ///
        private(set) var text: String?

        ///
        ///
        private(set) var ranges: [NotificationRange]

        ///
        ///
        private(set) var media: [NotificationMedia]

        ///
        ///
        private(set) var meta: [String: AnyObject]

        ///
        ///
        private(set) var actions: [String: AnyObject]

        ///
        ///
        private(set) var kind: Kind


        ///
        ///
        var textOverride: String? {
            didSet {
                parent?.didChangeOverrides()
            }
        }

        ///
        ///
        private weak var parent: Notification?

        //@property (nonatomic, strong, readwrite) NSMutableDictionary    *actionsOverride;
        //@property (nonatomic, strong, readwrite) NSMutableDictionary    *dynamicAttributesCache;



        init(dictionary: [String: AnyObject]) {
        //        NSArray *rawRanges          = [rawBlock arrayForKey:NoteRangesKey];
        //        NSArray *rawMedia           = [rawBlock arrayForKey:NoteMediaKey];
        //
        //		_text                       = [rawBlock stringForKey:NoteTextKey];
        //		_ranges                     = [NotificationRange rangesFromArray:rawRanges];
        //		_media                      = [NotificationMedia mediaFromArray:rawMedia];
        //        _meta                       = [rawBlock dictionaryForKey:NoteMetaKey];
        //        _actions                    = [rawBlock dictionaryForKey:NoteActionsKey];
        //        _dynamicAttributesCache     = [NSMutableDictionary dictionary];
            ranges = []
            media = []
            meta = [:]
            actions = [:]
            kind = .Comment
        }

        var metaSiteID: NSNumber? {
        //    return [[self.meta dictionaryForKey:NoteIdsKey] numberForKey:NoteSiteKey];
            return nil
        }

        var metaCommentID: NSNumber? {
        //    return [[self.meta dictionaryForKey:NoteIdsKey] numberForKey:NoteCommentKey];
            return nil
        }

        var metaLinksHome: NSURL? {
        //    NSString *rawLink = [[self.meta dictionaryForKey:NoteLinksKey] stringForKey:NoteHomeKey];
        //    if (!rawLink) {
        //        return nil;
        //    }
        //
        //    return [NSURL URLWithString:rawLink];
            return nil
        }

        var metaTitlesHome: String? {
        //    return [[self.meta dictionaryForKey:NoteTitlesKey] stringForKey:NoteHomeKey];
            return nil
        }


        /// Finds the first NotificationRange instance that maps to a given URL.
        ///
        /// -   Parameter url: The URL mapped by the NotificationRange instance we need to find.
        /// -   Returns: A NotificationRange instance mapping to a given URL.
        ///
        func notificationRangeWithUrl(url: NSURL) -> NotificationRange? {
//            for range in ranges where range.url.isEqual(url) {
//                return range
//            }

            return nil
        }


        /// Finds the first NotificationRange instance that maps to a given CommentID.
        ///
        /// -   Parameter commentID: The CommentID mapped by the NotificationRange instance we need to find.
        /// -   Returns: A NotificationRange instance referencing to a given commentID.
        ///
        func notificationRangeWithCommentId(commentID: NSNumber) -> NotificationRange? {
        //    for (NotificationRange *range in self.ranges) {
        //        if ([range.commentID isEqual:commentId]) {
        //            return range;
        //        }
        //    }
        //
            return nil
        }

        /// Returns all of the Image URL's referenced by the NotificationMedia instances
        ///
        var imageUrls: [NSURL] {
        //    NSMutableArray *urls = [NSMutableArray array];
        //
        //    for (NotificationMedia *media in self.media) {
        //        if (media.isImage && media.mediaURL != nil) {
        //            [urls addObject:media.mediaURL];
        //        }
        //    }
        //
        //    return urls;
            return []
        }

        /// Returns YES if the associated comment (if any) is approved. NO otherwise.
        ///
        var isCommentApproved: Bool {
        //    return [self isActionOn:NoteActionApprove] || ![self isActionEnabled:NoteActionApprove];
            return false
        }

        ///**
        // *	@brief      Allows us to set a local override for a remote value. This is used to fake the UI, while
        // *              there's a BG call going on.
        // *
        // *	@param		value       The local "Temporary" value.
        // *	@param		action      The action that should get a temporary 'Override' value
        // */
        func setOverrideValue(value: NSNumber, forAction action: Action) {
        //    if (!_actionsOverride) {
        //        _actionsOverride = [NSMutableDictionary dictionary];
        //    }
        //
        //    NSString *key = [self keyForAction:action];
        //    _actionsOverride[key] = value;
        //    [self.parent didChangeOverrides];
        }

        /// Removes any local (temporary) value that might have been set by means of *setActionOverrideValue*.
        ///
        func removeOverrideValueForAction(action: Action) {
        //    NSString *key = [self keyForAction:action];
        //    [_actionsOverride removeObjectForKey:key];
        //    [self.parent didChangeOverrides];
        }

        /// Returns the Notification Block status for a given action. If there's any local override,
        /// the (override) value will be returned.
        ///
        func actionForKey(key: String) -> NSNumber? {
        //    return [self.actionsOverride numberForKey:key] ?: [self.actions numberForKey:key];
            return nil
        }

        /// Returns *true* if a given action is available
        ///
        func isActionEnabled(action: Action) -> Bool {
        //    NSString *key = [self keyForAction:action];
        //    return [self actionForKey:key] != nil;
            return false
        }

        /// Returns *true* if a given action is toggled on. (I.e.: Approval = On, means that the comment
        /// is currently approved).
        ///
        func isActionOn(action: Action) -> Bool {
        //    NSString *key = [self keyForAction:action];
        //    return [[self actionForKey:key] boolValue];
            return false
        }

        //- (NSString *)keyForAction:(NoteAction)action
        //{
        //    // TODO: Nuke This once the data model has been swifted!
        //    NSDictionary *keyMap = @{
        //        @(NoteActionFollow)     : NoteActionFollowKey,
        //        @(NoteActionLike)       : NoteActionLikeKey,
        //        @(NoteActionSpam)       : NoteActionSpamKey,
        //        @(NoteActionTrash)      : NoteActionTrashKey,
        //        @(NoteActionReply)      : NoteActionReplyKey,
        //        @(NoteActionApprove)    : NoteActionApproveKey,
        //        @(NoteActionEdit)       : NoteActionEditKey
        //    };
        //
        //    return keyMap[@(action)] ?: [NSString string];
        //}
        //
        func cacheValueForKey(key: String) -> AnyObject? {
        //    return self.dynamicAttributesCache[key];
            return nil
        }

        func setCacheValue(value: AnyObject, forKey: String) {
        //    if (!value) {
        //        return;
        //    }
        //
        //    self.dynamicAttributesCache[key] = value;
        }

        class func blocksFromArray(rawBlocks: [AnyObject], notification: Notification) -> [Block]? {
        //    if (![rawBlocks isKindOfClass:[NSArray class]]) {
        //        return nil;
        //    }
        //
        //    NSMutableArray *parsed = [NSMutableArray array];
        //
        //    for (NSDictionary *rawDict in rawBlocks) {
        //        if (![rawDict isKindOfClass:[NSDictionary class]]) {
        //            continue;
        //        }
        //
        //        NotificationBlock *block    = [[[self class] alloc] initWithDictionary:rawDict];
        //        block.parent                = notification;
        //
        //        //  Duck Typing code below:
        //        //  Infer block type based on... stuff. (Sorry)
        //        //
        //        NotificationMedia *media    = [block.media firstObject];
        //
        //        //  User
        //        if ([rawDict[NoteTypeKey] isEqual:NoteTypeUser]) {
        //            block.type = NoteBlockTypeUser;
        //
        //        //  Comments
        //        } else if ([block.metaCommentID isEqual:notification.metaCommentID] && block.metaSiteID != nil) {
        //            block.type = NoteBlockTypeComment;
        //
        //        //  Images
        //        } else if (media.isImage || media.isBadge) {
        //            block.type = NoteBlockTypeImage;
        //
        //        //  Text
        //        } else {
        //            block.type = NoteBlockTypeText;
        //        }
        //
        //        [parsed addObject:block];
        //    }
        //
        //    return parsed;
return nil
        }
    }
}
