#import "Notification.h"
#import "NSDictionary+SafeExpectations.h"
#import "NSString+Helpers.h"
#import "WordPress-Swift.h"



#pragma mark ====================================================================================
#pragma mark Constants
#pragma mark ====================================================================================

NSString *NoteActionFollowKey           = @"follow";
NSString *NoteActionReplyKey            = @"replyto-comment";
NSString *NoteActionApproveKey          = @"approve-comment";
NSString *NoteActionSpamKey             = @"spam-comment";
NSString *NoteActionTrashKey            = @"trash-comment";
NSString *NoteActionLikeKey             = @"like-comment";
NSString *NoteActionEditKey             = @"approve-comment";

NSString const *NoteRangeTypeUser       = @"user";
NSString const *NoteRangeTypePost       = @"post";
NSString const *NoteRangeTypeComment    = @"comment";
NSString const *NoteRangeTypeStats      = @"stat";
NSString const *NoteRangeTypeFollow     = @"follow";
NSString const *NoteRangeTypeBlockquote = @"blockquote";
NSString const *NoteRangeTypeNoticon    = @"noticon";
NSString const *NoteRangeTypeSite       = @"site";
NSString const *NoteRangeTypeMatch      = @"match";

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
#pragma mark Notification: Private Methods
#pragma mark ====================================================================================

@interface Notification (Internals)
- (void)didChangeOverrides;
@end


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
		
		_url                = [NSURL URLWithString:[rawRange stringForKey:NoteUrlKey]];
		_range              = NSMakeRange(location, length);
        _type               = [rawRange stringForKey:NoteTypeKey];
        _siteID             = [rawRange numberForKey:NoteSiteIdKey];

        //  SORRY: << Let me stress this. Sorry, i'm 1000% against Duck Typing.
        //  =====
        //  `id` is coupled with the `type`. Which, in turn, is also duck typed.
        //
        //      type = post     => id = post_id
        //      type = comment  => id = comment_id
        //      type = user     => id = user_id
        //      type = site     => id = site_id
        
        _type               = (_type == nil && _url != nil) ? (NSString *)NoteRangeTypeSite : _type;
        _type               = _type ?: [NSString string];
        
        if ([_type isEqual:NoteRangeTypePost]) {
            _postID         = [rawRange numberForKey:NoteRangeIdKey];
            
        } else if ([_type isEqual:NoteRangeTypeComment]) {
            _commentID      = [rawRange numberForKey:NoteRangeIdKey];
            _postID         = [rawRange numberForKey:NotePostIdKey];
            
        } else if ([_type isEqual:NoteRangeTypeUser]) {
            _userID         = [rawRange numberForKey:NoteRangeIdKey];
            
        } else if ([_type isEqual:NoteRangeTypeNoticon]) {
            _value          = [rawRange stringForKey:NoteRangeValueKey];
            
        } else if ([_type isEqual:NoteRangeTypeSite]) {
            _siteID         = [rawRange numberForKey:NoteRangeIdKey];
        }
	}
	
	return self;
}

- (BOOL)isUser
{
    return [self.type isEqual:NoteRangeTypeUser];
}

- (BOOL)isPost
{
    return [self.type isEqual:NoteRangeTypePost];
}

- (BOOL)isComment
{
    return [self.type isEqual:NoteRangeTypeComment];
}

- (BOOL)isFollow
{
    return [self.type isEqual:NoteRangeTypeFollow];
}

- (BOOL)isStats
{
    return [self.type isEqual:NoteRangeTypeStats];
}

- (BOOL)isBlockquote
{
    return [self.type isEqual:NoteRangeTypeBlockquote];
}

- (BOOL)isNoticon
{
    return [self.type isEqual:NoteRangeTypeNoticon];
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

@interface NotificationBlock ()
@property (nonatomic, strong, readwrite) NSMutableDictionary    *actionsOverride;
@property (nonatomic, assign, readwrite) NoteBlockType          type;
@property (nonatomic, strong, readwrite) NSMutableDictionary    *dynamicAttributesCache;
@property (nonatomic,   weak, readwrite) Notification           *parent;
@end


@implementation NotificationBlock

- (instancetype)initWithDictionary:(NSDictionary *)rawBlock
{
    self = [super init];
	if (self)
	{
        NSArray *rawRanges          = [rawBlock arrayForKey:NoteRangesKey];
        NSArray *rawMedia           = [rawBlock arrayForKey:NoteMediaKey];
        
		_text                       = [rawBlock stringForKey:NoteTextKey];
		_ranges                     = [NotificationRange rangesFromArray:rawRanges];
		_media                      = [NotificationMedia mediaFromArray:rawMedia];
        _meta                       = [rawBlock dictionaryForKey:NoteMetaKey];
        _actions                    = [rawBlock dictionaryForKey:NoteActionsKey];
        _dynamicAttributesCache     = [NSMutableDictionary dictionary];
	}
	
	return self;
}

- (NSNumber *)metaSiteID
{
    return [[self.meta dictionaryForKey:NoteIdsKey] numberForKey:NoteSiteKey];
}

- (NSNumber *)metaCommentID
{
    return [[self.meta dictionaryForKey:NoteIdsKey] numberForKey:NoteCommentKey];
}

- (NSString *)metaLinksHome
{
    return [[self.meta dictionaryForKey:NoteLinksKey] stringForKey:NoteHomeKey];
}

- (NSString *)metaTitlesHome
{
    return [[self.meta dictionaryForKey:NoteTitlesKey] stringForKey:NoteHomeKey];
}

- (NotificationRange *)notificationRangeWithUrl:(NSURL *)url
{
    for (NotificationRange *range in self.ranges) {
        if ([range.url isEqual:url]) {
            return range;
        }
    }

    return nil;
}

- (NotificationRange *)notificationRangeWithCommentId:(NSNumber *)commentId
{
    for (NotificationRange *range in self.ranges) {
        if ([range.commentID isEqual:commentId]) {
            return range;
        }
    }
    
    return nil;
}

- (NSArray *)imageUrls
{
    NSMutableArray *urls = [NSMutableArray array];
    
    for (NotificationMedia *media in self.media) {
        if (media.isImage && media.mediaURL != nil) {
            [urls addObject:media.mediaURL];
        }
    }
    
    return urls;
}

- (BOOL)isCommentApproved
{
    return [self isActionOn:NoteActionApproveKey] || ![self isActionEnabled:NoteActionApproveKey];
}

- (void)setActionOverrideValue:(NSNumber *)value forKey:(NSString *)key
{
    if (!_actionsOverride) {
        _actionsOverride = [NSMutableDictionary dictionary];
    }
    
    _actionsOverride[key] = value;
    
    [self.parent didChangeOverrides];
}

- (void)removeActionOverrideForKey:(NSString *)key
{
    [_actionsOverride removeObjectForKey:key];
}

- (NSNumber *)actionForKey:(NSString *)key
{
    return [self.actionsOverride numberForKey:key] ?: [self.actions numberForKey:key];
}

- (BOOL)isActionEnabled:(NSString *)key
{
    return [self actionForKey:key] != nil;
}

- (BOOL)isActionOn:(NSString *)key
{
    return [[self actionForKey:key] boolValue];
}

- (id)cacheValueForKey:(NSString *)key
{
    return self.dynamicAttributesCache[key];
}

- (void)setCacheValue:(id)value forKey:(NSString *)key
{
    if (!value) {
        return;
    }
    
    self.dynamicAttributesCache[key] = value;
}

+ (NotificationBlock *)firstBlockOfType:(NoteBlockType)type fromBlocksArray:(NSArray *)blocks
{
    for (NotificationBlock *block in blocks) {
        if (block.type == type) {
            return block;
        }
    }
    return nil;
}

+ (NSArray *)blocksFromArray:(NSArray *)rawBlocks notification:(Notification *)notification
{
    if (![rawBlocks isKindOfClass:[NSArray class]]) {
        return nil;
    }
    
    NSMutableArray *parsed = [NSMutableArray array];
    
    for (NSDictionary *rawDict in rawBlocks) {
        if (![rawDict isKindOfClass:[NSDictionary class]]) {
            continue;
        }
        
        NotificationBlock *block    = [[[self class] alloc] initWithDictionary:rawDict];
        block.parent                = notification;
        
        //  Duck Typing code below:
        //  Infer block type based on... stuff. (Sorry)
        //
        NotificationMedia *media    = [block.media firstObject];
        
        //  User
        if ([rawDict[NoteTypeKey] isEqual:NoteTypeUser]) {
            block.type = NoteBlockTypeUser;
            
        //  Comments
        } else if ([block.metaCommentID isEqual:notification.metaCommentID] && block.metaSiteID != nil) {
            block.type = NoteBlockTypeComment;

        //  Images
        } else if (media.isImage || media.isBadge) {
            block.type = NoteBlockTypeImage;
         
        //  Text
        } else {
            block.type = NoteBlockTypeText;
        }

        [parsed addObject:block];
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

+ (NSArray *)blockGroupsFromArray:(NSArray *)rawBlocks notification:(Notification *)notification
{
    NSArray *blocks         = [NotificationBlock blocksFromArray:rawBlocks notification:notification];
    NSMutableArray *groups  = [NSMutableArray array];
    
    // Don't proceed if there are no parsed blocks
    if (blocks.count == 0) {
        return nil;
    }
    
    // Subject: Contains a User + Text Block
    if (rawBlocks == notification.subject) {
        [groups addObject:[NotificationBlockGroup groupWithBlocks:blocks type:NoteBlockGroupTypeSubject]];

    // Header: Contains a User + Text Block
    } else if (rawBlocks == notification.header) {
        [groups addObject:[NotificationBlockGroup groupWithBlocks:blocks type:NoteBlockGroupTypeHeader]];
        
    // Comment: Contains a User + Comment Block
    } else if (notification.isComment) {
        
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
        BOOL canContainFooter           = notification.isFollow || notification.isLike || notification.isCommentLike;
        
        for (NotificationBlock *block in blocks) {
            BOOL isFooter               = canContainFooter && block.type == NoteBlockTypeText && blocks.lastObject == block;
            NoteBlockGroupType type     = isFooter ? NoteBlockGroupTypeFooter : block.type;
            
            [groups addObject:[NotificationBlockGroup groupWithBlocks:@[block] type:type]];
        }
    }
    
    return groups;
}

@end



#pragma mark ====================================================================================
#pragma mark Notification
#pragma mark ====================================================================================

@interface Notification ()
@property (nonatomic, strong) NSDate                    *date;
@property (nonatomic, strong) NSURL                     *iconURL;
@property (nonatomic, strong) NotificationBlockGroup    *subjectBlockGroup;
@property (nonatomic, strong) NotificationBlockGroup    *headerBlockGroup;
@property (nonatomic, strong) NSArray                   *bodyBlockGroups;
@end


@implementation Notification

@dynamic header;
@dynamic body;
@dynamic ghostData;
@dynamic simperiumKey;
@dynamic icon;
@dynamic noticon;
@dynamic meta;
@dynamic read;
@dynamic subject;
@dynamic timestamp;
@dynamic type;
@dynamic url;
@dynamic title;

@synthesize date                = _date;
@synthesize iconURL             = _iconURL;
@synthesize subjectBlockGroup   = _subjectBlockGroup;
@synthesize headerBlockGroup    = _headerBlockGroup;
@synthesize bodyBlockGroups     = _bodyBlockGroups;


#pragma mark - NSManagedObject Overriden Methods

- (void)didTurnIntoFault
{
    _date               = nil;
    _iconURL            = nil;
    _subjectBlockGroup  = nil;
    _headerBlockGroup   = nil;
    _bodyBlockGroups    = nil;
}


#pragma mark - Derived Properties

- (NSURL *)iconURL
{
    if (!_iconURL) {
        _iconURL = [NSURL URLWithString:self.icon];
    }
    return _iconURL;
}

- (NSDate *)timestampAsDate
{
    if (!_date) {
        NSAssert(self.timestamp, @"Notification Timestamp should not be nil [%@]", self.simperiumKey);
        if (self.timestamp) {
            _date = [NSDate dateWithISO8601String:self.timestamp];
        }
        
        //  Failsafe:
        //  If, for whatever reason, the date cannot be parsed, make sure we always return a date.
        //  Otherwise notification-grouping might fail
        //
        if (_date == nil) {
            DDLogError(@"Error: couldn't parse date [%@] for notification with id [%@]", self.timestamp, self.simperiumKey);
            _date = [NSDate date];
        }
    }
    
    return self.date;
}

- (NotificationBlockGroup *)subjectBlockGroup
{
    if (!_subjectBlockGroup) {
        _subjectBlockGroup = [[NotificationBlockGroup blockGroupsFromArray:self.subject notification:self] firstObject];
    }

    return _subjectBlockGroup;
}

- (NotificationBlockGroup *)headerBlockGroup
{
    if (!_headerBlockGroup) {
        _headerBlockGroup = [[NotificationBlockGroup blockGroupsFromArray:self.header notification:self] firstObject];
    }
    
    return _headerBlockGroup;
}

- (NSArray *)bodyBlockGroups
{
    if (!_bodyBlockGroups) {
        _bodyBlockGroups = [NotificationBlockGroup blockGroupsFromArray:self.body notification:self];
    }
    
    return _bodyBlockGroups;
}

- (NSNumber *)metaSiteID
{
    return [[self.meta dictionaryForKey:NoteIdsKey] numberForKey:NoteSiteKey];
}

- (NSNumber *)metaPostID
{
    return [[self.meta dictionaryForKey:NoteIdsKey] numberForKey:NotePostKey];
}

- (NSNumber *)metaCommentID
{
    return [[self.meta dictionaryForKey:NoteIdsKey] numberForKey:NoteCommentKey];
}

- (NSNumber *)metaReplyID
{
    return [[self.meta dictionaryForKey:NoteIdsKey] numberForKey:NoteReplyIdKey];
}

- (BOOL)isMatcher
{
    return [self.type isEqual:NoteTypeMatcher];
}

- (BOOL)isComment
{
    return [self.type isEqual:NoteTypeComment];
}

- (BOOL)isPost
{
    return [self.type isEqual:NoteTypePost];
}

- (BOOL)isFollow
{
    return [self.type isEqual:NoteTypeFollow];
}

- (BOOL)isLike
{
    return [self.type isEqual:NoteTypeLike];
}

- (BOOL)isCommentLike
{
    return [self.type isEqual:NoteTypeCommentLike];
}

- (BOOL)isBadge
{
    //  Note:
    //  This developer does not like duck typing. Sorry about the following snippet.
    //
    for (NotificationBlockGroup *group in self.bodyBlockGroups) {
        for (NotificationBlock *block in group.blocks) {
            for (NotificationMedia *media in block.media) {
                if (media.isBadge) {
                    return true;
                }
            }
        }
    }
    
    return false;
}

- (BOOL)hasReply
{
    return self.isComment && self.metaReplyID != nil;
}


#pragma mark - Comment Helpers

- (NotificationBlockGroup *)blockGroupOfType:(NoteBlockGroupType)type
{
    for (NotificationBlockGroup *blockGroup in self.bodyBlockGroups) {
        if (blockGroup.type == type) {
            return blockGroup;
        }
    }
    return nil;
}

- (NotificationRange *)notificationRangeWithUrl:(NSURL *)url
{
    // Find in Header + Body please!
    NSMutableArray *groups = [NSMutableArray array];
    [groups addObjectsFromArray:self.bodyBlockGroups];
    if (self.headerBlockGroup) {
        [groups addObject:self.headerBlockGroup];
    }
    
    for (NotificationBlockGroup *group in groups) {
        for (NotificationBlock *block in group.blocks) {
            NotificationRange *range = [block notificationRangeWithUrl:url];
            if (range) {
                return range;
            }
        }
    }
    return nil;
}

- (NotificationBlock *)subjectBlock
{
    return self.subjectBlockGroup.blocks.firstObject;
}

- (NotificationBlock *)snippetBlock
{
    NSArray *subjectBlocks = self.subjectBlockGroup.blocks;
    return (subjectBlocks.count > 1) ? subjectBlocks.lastObject : nil;
}

// Check if this note is a comment and in 'unapproved' status
- (BOOL)isUnapprovedComment
{
    NotificationBlockGroup *group = [self blockGroupOfType:NoteBlockGroupTypeComment];
    if (group && [group blockOfType:NoteBlockTypeComment]) {
        NotificationBlock *block = [group blockOfType:NoteBlockTypeComment];
        return [block isActionEnabled:NoteActionApproveKey] && ![block isActionOn:NoteActionApproveKey];
    }

    return NO;
}

- (void)didChangeOverrides
{
    // HACK:
    // This is a NO-OP that will force NSFetchedResultsController to reload the row for this object.
    // Helpful when dealing with non-CoreData backed attributes.
    //
    self.read = self.read;
}

@end
