#import "Notification.h"
#import "NSDictionary+SafeExpectations.h"
#import "WordPress-Swift.h"



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

NSString const *NoteLinkTypeUser        = @"user";
NSString const *NoteLinkTypePost        = @"post";
NSString const *NoteLinkTypeComment     = @"comment";
NSString const *NoteLinkTypeStats       = @"stat";

NSString const *NoteMediaTypeImage      = @"image";

NSString const *NoteBlockTypeUser       = @"user";
NSString const *NoteBlockTypeComment    = @"comment";

NSString const *NoteTypeMatcher         = @"automattcher";
NSString const *NoteTypeComment         = @"comment";

NSString const *NoteMetaKey             = @"meta";
NSString const *NoteMediaKey            = @"media";
NSString const *NoteActionsKey          = @"actions";
NSString const *NoteLinksKey            = @"links";
NSString const *NoteIdsKey              = @"ids";
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


#pragma mark ====================================================================================
#pragma mark NotificationURL
#pragma mark ====================================================================================

@implementation NotificationURL

- (instancetype)initWithDictionary:(NSDictionary *)rawURL
{
    self = [super init];
	if (self)
	{
		NSArray *indices	= [rawURL arrayForKey:NoteIndicesKey];
		NSInteger location	= [indices.firstObject intValue];
		NSInteger length	= [indices.lastObject intValue] - location;
		
		_url                = [NSURL URLWithString:[rawURL stringForKey:NoteUrlKey]];
		_range              = NSMakeRange(location, length);
        _type               = [rawURL stringForKey:NoteTypeKey];
	}
	
	return self;
}

- (BOOL)isUser
{
    return [self.type isEqual:NoteLinkTypeUser];
}

- (BOOL)isPost
{
    return [self.type isEqual:NoteLinkTypePost];
}

- (BOOL)isComment
{
    return [self.type isEqual:NoteLinkTypeComment];
}

- (BOOL)isStats
{
    return [self.type isEqual:NoteLinkTypeStats];
}

+ (NSArray *)urlsFromArray:(NSArray *)rawURL
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
@property (nonatomic, assign, readwrite) NoteBlockTypes         type;
@end


@implementation NotificationBlock

- (instancetype)initWithDictionary:(NSDictionary *)rawBlock
{
    self = [super init];
	if (self)
	{
        NSArray *rawUrls            = [rawBlock arrayForKey:NoteIdsKey];
        NSArray *rawMedia           = [rawBlock arrayForKey:NoteMediaKey];
        
		_text                       = [rawBlock stringForKey:NoteTextKey];
		_urls                       = [NotificationURL urlsFromArray:rawUrls];
		_media                      = [NotificationMedia mediaFromArray:rawMedia];
        _meta                       = [rawBlock dictionaryForKey:NoteMetaKey];
        _actions                    = [rawBlock dictionaryForKey:NoteActionsKey];
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

- (NotificationURL *)notificationUrlWithUrl:(NSURL *)url
{
    for (NotificationURL *noteURL in self.urls) {
        if ([noteURL.url isEqual:url]) {
            return noteURL;
        }
    }

    return nil;
}

- (void)setActionOverrideValue:(NSNumber *)value forKey:(NSString *)key
{
    if (!_actionsOverride) {
        _actionsOverride = [NSMutableDictionary dictionary];
    }
    
    _actionsOverride[key] = value;
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

+ (NSArray *)blocksFromArray:(NSArray *)rawBlocks notification:(Notification *)notification
{
    if (![rawBlocks isKindOfClass:[NSArray class]]) {
        return nil;
    }
    
    NSMutableArray *parsed  = [NSMutableArray array];
    
    for (NSDictionary *rawDict in rawBlocks) {
        if (![rawDict isKindOfClass:[NSDictionary class]]) {
            continue;
        }
        
        NotificationBlock *block    = [[[self class] alloc] initWithDictionary:rawDict];
        
        //  Duck Typing code below:
        //  Infer block type based on... stuff. (Sorry)
        //
        NotificationMedia *media    = [block.media firstObject];
        
        //  User
        if ([rawDict[NoteTypeKey] isEqual:NoteBlockTypeUser]) {
            block.type = NoteBlockTypesUser;
            
        //  Comments
        } else if ([block.metaCommentID isEqual:notification.metaCommentID] && block.metaSiteID != nil) {
            block.type = NoteBlockTypesComment;
            
        //  Images
        } else if (media.isImage) {
            block.type = NoteBlockTypesImage;
            
        //  Text
        } else {
            block.type = NoteBlockTypesText;
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
@property (nonatomic, strong) NSArray             *blocks;
@property (nonatomic, assign) NoteBlockGroupTypes type;
@end

@implementation NotificationBlockGroup

- (NotificationBlock *)blockOfType:(NoteBlockTypes)type
{
    for (NotificationBlock *block in self.blocks) {
        if (block.type == type) {
            return block;
        }
    }
    return nil;
}

+ (NotificationBlockGroup *)groupWithBlocks:(NSArray *)blocks type:(NoteBlockGroupTypes)type
{
    NSAssert([blocks isKindOfClass:[NSArray class]], nil);
    NotificationBlockGroup *group   = [self new];
    group.blocks                    = blocks;
    group.type                      = type;
    return group;
}

+ (NSArray *)blockGroupsFromArray:(NSArray *)rawBlocks notification:(Notification *)notification
{
    NSArray *blocks         = [NotificationBlock blocksFromArray:rawBlocks notification:notification];
    NSMutableArray *groups  = [NSMutableArray array];
    
    // Subject: Contains a User + Text Block
    if (rawBlocks == notification.subject) {
        [groups addObject:[NotificationBlockGroup groupWithBlocks:blocks type:NoteBlockGroupTypesSubject]];
    
    // Snippet: Contains a User + Text Block
    } else if (rawBlocks == notification.header) {
        [groups addObject:[NotificationBlockGroup groupWithBlocks:blocks type:NoteBlockGroupTypesSnippet]];
        
    // Comment: Contains a User + Comment Block
    } else if (notification.isComment) {
        [groups addObject:[NotificationBlockGroup groupWithBlocks:blocks type:NoteBlockGroupTypesComment]];
       
    // Rest: 1-1 relationship
    } else {
        for (NotificationBlock *block in blocks) {
            [groups addObject:[NotificationBlockGroup groupWithBlocks:@[block] type:block.type]];
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
        _date = [NSDate dateWithISO8601String:self.timestamp];
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

- (BOOL)isMatcher
{
    return [self.type isEqual:NoteTypeMatcher];
}

- (BOOL)isComment
{
    return [self.type isEqual:NoteTypeComment];
}


#pragma mark - Comment Helpers

- (NotificationBlockGroup *)blockGroupOfType:(NoteBlockGroupTypes)type
{
    for (NotificationBlockGroup *blockGroup in self.bodyBlockGroups) {
        if (blockGroup.type == type) {
            return blockGroup;
        }
    }
    return nil;
}

- (NotificationURL *)notificationUrlWithUrl:(NSURL *)url
{
#warning NOT COOL
    
    // Find in Header + Body please!
    NSMutableArray *groups = [NSMutableArray array];
    [groups addObjectsFromArray:self.bodyBlockGroups];
    if (self.headerBlockGroup) {
        [groups addObject:self.headerBlockGroup];
    }
    
    for (NotificationBlockGroup *group in groups) {
        for (NotificationBlock *block in group.blocks) {
            NotificationURL *notificationURL = [block notificationUrlWithUrl:url];
            if (notificationURL) {
                return notificationURL;
            }
        }
    }
    return nil;
}

@end
