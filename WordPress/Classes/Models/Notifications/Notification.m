#import "Notification.h"
#import "NSDictionary+SafeExpectations.h"
#import "NSString+Helpers.h"



#pragma mark ====================================================================================
#pragma mark Constants
#pragma mark ====================================================================================

NSString const *NoteActionFollowKey     = @"follow";
NSString const *NoteActionReplyKey      = @"replyto-comment";
NSString const *NoteActionApproveKey    = @"approve-comment";
NSString const *NoteActionSpamKey       = @"spam-comment";
NSString const *NoteActionTrashKey      = @"trash-comment";
NSString const *NoteActionLikeKey       = @"like-comment";
NSString const *NoteActionEditKey       = @"approve-comment";

NSString const *NoteRangeTypeUserKey    = @"user";
NSString const *NoteRangeTypePostKey    = @"post";
NSString const *NoteRangeTypeCommentKey = @"comment";
NSString const *NoteRangeTypeStatsKey   = @"stat";
NSString const *NoteRangeTypeFollowKey  = @"follow";
NSString const *NoteRangeTypeBlockquoteKey = @"blockquote";
NSString const *NoteRangeTypeNoticonKey = @"noticon";
NSString const *NoteRangeTypeSiteKey    = @"site";
NSString const *NoteRangeTypeMatchKey   = @"match";

NSString const *NoteMediaTypeImage      = @"image";
NSString const *NoteMediaTypeBadge      = @"badge";

NSString const *NoteTypeUser            = @"user";
NSString const *NoteTypeComment         = @"comment";
NSString const *NoteTypeMatcher         = @"automattcher";
NSString const *NoteTypePost            = @"post";
NSString const *NoteTypeFollow          = @"follow";
NSString const *NoteTypeLike            = @"like";
NSString const *NoteTypeCommentLike     = @"comment_like";

NSString const *NoteMetaKey             = @"meta";
NSString const *NoteMediaKey            = @"media";
NSString const *NoteActionsKey          = @"actions";
NSString const *NoteLinksKey            = @"links";
NSString const *NoteIdsKey              = @"ids";
NSString const *NoteRangesKey           = @"ranges";
NSString const *NoteSiteKey             = @"site";
NSString const *NoteHomeKey             = @"home";
NSString const *NoteCommentKey          = @"comment";
NSString const *NotePostKey             = @"post";
NSString const *NoteTextKey             = @"text";
NSString const *NoteTypeKey             = @"type";
NSString const *NoteUrlKey              = @"url";
NSString const *NoteTitlesKey           = @"titles";
NSString const *NoteIndicesKey          = @"indices";
NSString const *NoteWidthKey            = @"width";
NSString const *NoteHeightKey           = @"height";

NSString const *NoteRangeIdKey          = @"id";
NSString const *NoteRangeValueKey       = @"value";
NSString const *NoteSiteIdKey           = @"site_id";
NSString const *NotePostIdKey           = @"post_id";
NSString const *NoteReplyIdKey          = @"reply_comment";



#pragma mark ====================================================================================
#pragma mark NotificationRange
#pragma mark ====================================================================================

@implementation NotificationRange

- (instancetype)initWithDictionary:(NSDictionary *)rawRange
{
    self = [super init];
	if (self)
	{
		NSArray *indices	= [rawRange arrayForKey:NoteIndicesKey];
		NSInteger location	= [indices.firstObject intValue];
		NSInteger length	= [indices.lastObject intValue] - location;

        NSString *rawType   = [rawRange stringForKey:NoteTypeKey];
        rawType             = (rawType == nil && _url != nil) ? (NSString *)NoteRangeTypeSiteKey : rawType;
        rawType             = rawType ?: [NSString string];

        _type               = [self rangeTypeForKey:rawType];
		_url                = [NSURL URLWithString:[rawRange stringForKey:NoteUrlKey]];
		_range              = NSMakeRange(location, length);
        _siteID             = [rawRange numberForKey:NoteSiteIdKey];

        //  SORRY: << Let me stress this. Sorry, i'm 1000% against Duck Typing.
        //  ======
        //  `id` is coupled with the `type`. Which, in turn, is also duck typed.
        //
        //      type = post     => id = post_id
        //      type = comment  => id = comment_id
        //      type = user     => id = user_id
        //      type = site     => id = site_id
        //
        if (_type == NoteRangeTypeUser) {
            _userID         = [rawRange numberForKey:NoteRangeIdKey];

        } else if (_type == NoteRangeTypePost) {
            _postID         = [rawRange numberForKey:NoteRangeIdKey];
            
        } else if (_type == NoteRangeTypeComment) {
            _commentID      = [rawRange numberForKey:NoteRangeIdKey];
            _postID         = [rawRange numberForKey:NotePostIdKey];

        } else if (_type == NoteRangeTypeNoticon) {
            _value          = [rawRange stringForKey:NoteRangeValueKey];
            
        } else if (_type == NoteRangeTypeSite) {
            _siteID         = [rawRange numberForKey:NoteRangeIdKey];
        }
	}
	
	return self;
}

- (NoteRangeType)rangeTypeForKey:(NSString *)rangeTypeKey
{
    NSDictionary *typeMap = @{
        NoteRangeTypeUserKey        : @(NoteRangeTypeUser),
        NoteRangeTypePostKey        : @(NoteRangeTypePost),
        NoteRangeTypeCommentKey     : @(NoteRangeTypeComment),
        NoteRangeTypeStatsKey       : @(NoteRangeTypeStats),
        NoteRangeTypeFollowKey      : @(NoteRangeTypeFollow),
        NoteRangeTypeBlockquoteKey  : @(NoteRangeTypeBlockquote),
        NoteRangeTypeNoticonKey     : @(NoteRangeTypeNoticon),
        NoteRangeTypeSiteKey        : @(NoteRangeTypeSite),
        NoteRangeTypeMatchKey       : @(NoteRangeTypeMatch)
    };

    // Note: Fallback to Site Range Type, in the *unknown* scenario.
    NSNumber *type = typeMap[rangeTypeKey];
    return type ? [type integerValue] : NoteRangeTypeSite;
}


+ (NSArray *)rangesFromArray:(NSArray *)rawURL
{
	NSMutableArray *parsed = [NSMutableArray array];
	for (NSDictionary *rawDict in rawURL) {
        if ([rawDict isKindOfClass:[NSDictionary class]]) {
            [parsed addObject:[[[self class] alloc] initWithDictionary:rawDict]];
        }
	}
	
	return parsed;
}

@end


#pragma mark ====================================================================================
#pragma mark NotificationMedia
#pragma mark ====================================================================================

@implementation NotificationMedia

- (instancetype)initWithDictionary:(NSDictionary *)rawMedia
{
    self = [super init];
	if (self)
	{
		// Parse Indices
		NSArray *indices	= [rawMedia arrayForKey:NoteIndicesKey];
		NSInteger location	= [indices.firstObject intValue];
		NSInteger length	= [indices.lastObject intValue] - location;
		NSNumber *width     = [rawMedia numberForKey:NoteWidthKey];
		NSNumber *height    = [rawMedia numberForKey:NoteHeightKey];
        
		// Parse NoteMedia
		_type               = [rawMedia stringForKey:NoteTypeKey];
		_mediaURL           = [NSURL URLWithString:[rawMedia stringForKey:NoteUrlKey]];
		_size               = CGSizeMake(width.intValue, height.intValue);
		_range              = NSMakeRange(location, length);
	}
	
	return self;
}

- (BOOL)isImage
{
    return [self.type isEqual:NoteMediaTypeImage];
}

- (BOOL)isBadge
{
    return [self.type isEqual:NoteMediaTypeBadge];
}

+ (NSArray *)mediaFromArray:(NSArray *)rawMedia
{
	NSMutableArray *parsed = [NSMutableArray array];
	for (NSDictionary *rawDict in rawMedia) {
        if ([rawDict isKindOfClass:[NSDictionary class]]) {
            [parsed addObject:[[[self class] alloc] initWithDictionary:rawDict]];
        }
	}
	
	return parsed;
}

@end
#pragma mark ====================================================================================
#pragma mark NotificationBlock
#pragma mark ====================================================================================

@interface NotificationBlockGroup ()
@property (nonatomic, strong) NSArray               *blocks;
@property (nonatomic, assign) NoteBlockGroupType    type;
@end

@implementation NotificationBlockGroup

- (NotificationBlock *)blockOfType:(NoteBlockType)type
{
    return [NotificationBlock firstBlockOfType:type fromBlocksArray:self.blocks];
}

- (NSSet *)imageUrlsForBlocksOfTypes:(NSSet *)types
{
    NSMutableSet *urls = [NSMutableSet set];
    
    for (NotificationBlock *block in self.blocks) {
        if ([types containsObject:@(block.type)] == false) {
            continue;
        }
        
        NSArray *imageUrls = [block imageUrls];
        if (imageUrls) {
            [urls addObjectsFromArray:imageUrls];
        }
    }
    
    return urls;
}

+ (NotificationBlockGroup *)groupWithBlocks:(NSArray *)blocks type:(NoteBlockGroupType)type
{
    NotificationBlockGroup *group   = [self new];
    group.blocks                    = blocks;
    group.type                      = type;
    return group;
}

+ (NotificationBlockGroup *)subjectGroupFromArray:(NSArray *)rawBlocks notification:(Notification *)notification
{
    // Subject: Contains a User + Text Block
    NSArray *blocks = [NotificationBlock blocksFromArray:rawBlocks notification:notification];
    if (blocks.count == 0) {
        return nil;
    }

    return [NotificationBlockGroup groupWithBlocks:blocks type:NoteBlockGroupTypeSubject];
}

+ (NotificationBlockGroup *)headerGroupFromArray:(NSArray *)rawBlocks notification:(Notification *)notification
{
    // Header: Contains a User + Text Block
    NSArray *blocks = [NotificationBlock blocksFromArray:rawBlocks notification:notification];
    if (blocks.count == 0) {
        return nil;
    }

    return [NotificationBlockGroup groupWithBlocks:blocks type:NoteBlockGroupTypeHeader];
}

+ (NSArray *)bodyGroupsFromArray:(NSArray *)rawBlocks notification:(Notification *)notification
{
    NSArray *blocks         = [NotificationBlock blocksFromArray:rawBlocks notification:notification];
    NSMutableArray *groups  = [NSMutableArray array];
    
    if (blocks.count == 0) {
        return groups;
    }

    // Comment: Contains a User + Comment Block
    if (notification.isComment) {
        
        //  Note:
        //  I find myself, again, surrounded by the forces of Duck Typing. Comment Notifications are now
        //  required to always render the Actions at the very bottom. This snippet is meant to adapt the backend
        //  data structure, so that a single NotificationBlockGroup can be easily mapped against a single UI entity.
        //
        //  -   NoteBlockGroupTypeComment: NoteBlockTypeComment + NoteBlockTypeUser
        //  -   Anything
        //  -   NoteBlockGroupTypeActions: A copy of the NoteBlockTypeComment block
        
        NotificationBlock *commentBlock = [NotificationBlock firstBlockOfType:NoteBlockTypeComment fromBlocksArray:blocks];
        NotificationBlock *userBlock    = [NotificationBlock firstBlockOfType:NoteBlockTypeUser fromBlocksArray:blocks];
        NSArray *commentGroupBlocks     = @[commentBlock, userBlock];
        NSArray *actionsGroupBlocks     = @[commentBlock];
        
        NSMutableArray *middleBlocks    = [blocks mutableCopy];
        [middleBlocks removeObjectsInArray:commentGroupBlocks];
        
        // Finally, arrange the Block Groups
        [groups addObject:[NotificationBlockGroup groupWithBlocks:commentGroupBlocks type:NoteBlockGroupTypeComment]];

        for (NotificationBlock *block in middleBlocks) {
            
            // Duck Typing Again:
            // If the block contains a range that matches with the metaReplyID field, we'll need to render this
            // with a custom style
            //
            BOOL isReply                = [block notificationRangeWithCommentId:notification.metaReplyID] != nil;
            NoteBlockGroupType type     = isReply ? NoteBlockGroupTypeFooter : block.type;
            
            [groups addObject:[NotificationBlockGroup groupWithBlocks:@[block] type:type]];
        }
        
        [groups addObject:[NotificationBlockGroup groupWithBlocks:actionsGroupBlocks type:NoteBlockGroupTypeActions]];
        
        
    // Rest: 1-1 relationship
    } else {
        
        //  More Duck Typing:
        //
        //  -   Notifications of the kind [Follow, Like, CommentLike] may contain a Footer block.
        //  -   We can assume that whenever the last block is of the type NoteBlockTypeText, we're dealing with a footer.
        //  -   Whenever we detect such a block, we'll map the NotificationBlock into a NoteBlockGroupTypeFooter group.
        //
        BOOL canContainFooter = notification.isFollow || notification.isLike || notification.isCommentLike;
        
        for (NotificationBlock *block in blocks) {
            BOOL isFooter               = canContainFooter && block.type == NoteBlockTypeText && blocks.lastObject == block;
            NoteBlockGroupType type     = isFooter ? NoteBlockGroupTypeFooter : block.type;
            
            [groups addObject:[NotificationBlockGroup groupWithBlocks:@[block] type:type]];
        }
    }
    
    return groups;
}

@end
