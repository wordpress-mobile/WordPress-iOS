#import "Notification.h"
#import "NSDictionary+SafeExpectations.h"



#pragma mark ====================================================================================
#pragma mark Constants
#pragma mark ====================================================================================

NSString const *NoteActionFollowKey     = @"follow";
NSString const *NoteActionReplyKey      = @"replyto-comment";
NSString const *NoteActionApproveKey    = @"approve-comment";
NSString const *NoteActionSpamKey       = @"spam-comment";
NSString const *NoteActionTrashKey      = @"trash-comment";

NSString const *NoteMetaKey             = @"meta";
NSString const *NoteMediaKey            = @"media";
NSString const *NoteActionsKey          = @"actions";
NSString const *NoteIdsKey              = @"ids";
NSString const *NoteSiteKey             = @"site";
NSString const *NoteCommentKey          = @"comment";
NSString const *NotePostKey             = @"post";
NSString const *NoteTextKey             = @"text";
NSString const *NoteTypeKey             = @"type";
NSString const *NoteUrlKey              = @"url";
NSString const *NoteIndicesKey          = @"indices";
NSString const *NoteWidthKey            = @"width";
NSString const *NoteHeightKey           = @"height";


#pragma mark ====================================================================================
#pragma mark NotificationURL
#pragma mark ====================================================================================

@implementation NotificationURL

- (instancetype)initWithDictionary:(NSDictionary *)rawURL
{
	if ((self = [super init]))
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

@end


#pragma mark ====================================================================================
#pragma mark NotificationMedia
#pragma mark ====================================================================================

@implementation NotificationMedia

- (instancetype)initWithDictionary:(NSDictionary *)rawMedia
{
	if ((self = [super init]))
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
    return [self.type isEqualToString:@"image"];
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
	if ((self = [super init]))
	{
        NSArray *rawUrls            = [rawBlock arrayForKey:NoteIdsKey];
        NSArray *rawMedia           = [rawBlock arrayForKey:NoteMediaKey];
        
		_text                       = [rawBlock stringForKey:NoteTextKey];
		_urls                       = [[self class] parseObjectsOfKind:[NotificationURL class] fromArray:rawUrls];
		_media                      = [[self class] parseObjectsOfKind:[NotificationMedia class] fromArray:rawMedia];
        _meta                       = [rawBlock dictionaryForKey:NoteMetaKey];
        _actions                    = [rawBlock dictionaryForKey:NoteActionsKey];
        
        // Parse the Type!
        NotificationMedia *media    = [_media firstObject];
        BOOL isImage                = media.isImage;
        
        if ([[rawBlock stringForKey:NoteTypeKey] isEqualToString:@"user"]) {
            _type = NoteBlockTypesUser;
        } else if (isImage) {
            _type = NoteBlockTypesImage;
        } else {
            _type = NoteBlockTypesText;
        }
	}
	
	return self;
}

- (NSNumber *)metaSiteID
{
    return [[self.meta dictionaryForKey:NoteIdsKey] numberForKey:NoteSiteKey];
}

- (void)setActionOverrideValue:(id)obj forKey:(NSString *)key
{
    if (!_actionsOverride) {
        _actionsOverride = [NSMutableDictionary dictionary];
    }
    
    _actionsOverride[key] = obj;
}

- (void)removeActionOverrideForKey:(NSString *)key
{
    [_actionsOverride removeObjectForKey:key];
}

- (BOOL)hasActions
{
    return self.actions.count;
}

- (id)actionForKey:(NSString *)key
{
    return self.actionsOverride[key] ?: self.actions[key];
}

+ (NSArray *)parseBlocksFromArray:(NSArray *)rawBlocks
{
    return [self parseObjectsOfKind:[self class] fromArray:rawBlocks];
}

+ (NSArray *)parseObjectsOfKind:(Class)kind fromArray:(NSArray *)rawArray
{
    if (![rawArray isKindOfClass:[NSArray class]]) {
        return nil;
    }
    
	NSMutableArray *parsed = [NSMutableArray array];
	for (NSDictionary *rawDict in rawArray) {
        if ([rawDict isKindOfClass:[NSDictionary class]]) {
            [parsed addObject:[[kind alloc] initWithDictionary:rawDict]];
        }
	}
	
	return parsed;
}

@end


#pragma mark ====================================================================================
#pragma mark Notification
#pragma mark ====================================================================================

@interface Notification ()
@property (nonatomic, strong) NSDate            *date;
@property (nonatomic, strong) NSURL             *iconURL;
@property (nonatomic, strong) NotificationBlock *subjectBlock;
@property (nonatomic, strong) NSArray           *bodyBlocks;
@end


@implementation Notification

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

@synthesize date            = _date;
@synthesize iconURL         = _iconURL;
@synthesize subjectBlock    = _subjectBlock;
@synthesize bodyBlocks      = _bodyBlocks;


- (BOOL)isComment
{
    return [self.type isEqualToString:@"comment"];
}

- (BOOL)isMatcher
{
    return [self.type isEqualToString:@"automattcher"];
}

- (BOOL)isStatsEvent
{
    NSArray *events = @[ @"_milestone_", @"traffic_", @"best_", @"most_"];
    
    for (NSString *event in events) {
        if ([self.type rangeOfString:event].length) {
            return YES;
        }
    }
    
    return NO;
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
        NSTimeInterval timeInterval = [self.timestamp doubleValue];
        _date = [NSDate dateWithTimeIntervalSince1970:timeInterval];
    }
    
    return self.date;
}

- (NotificationBlock *)subjectBlock
{
    if (!_subjectBlock) {
        _subjectBlock = [[NotificationBlock alloc] initWithDictionary:self.subject];
    }

    return _subjectBlock;
}

- (NSArray *)bodyBlocks
{
    if (!_bodyBlocks) {
        _bodyBlocks = [NotificationBlock parseBlocksFromArray:self.body];
    }
    
    return _bodyBlocks;
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


#pragma mark - Helpers

- (void)didTurnIntoFault
{
    _date           = nil;
    _iconURL        = nil;
    _subjectBlock   = nil;
    _bodyBlocks     = nil;
}

@end
