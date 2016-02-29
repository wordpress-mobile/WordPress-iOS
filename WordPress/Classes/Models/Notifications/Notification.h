#import <Simperium/Simperium.h>

@class NotificationBlock;
@class NotificationBlockGroup;
@class NotificationRange;
@class NotificationMedia;

#pragma mark ====================================================================================
#pragma mark Constants
#pragma mark ====================================================================================

extern NSString * NoteActionFollowKey;
extern NSString * NoteActionLikeKey;
extern NSString * NoteActionSpamKey;
extern NSString * NoteActionTrashKey;
extern NSString * NoteActionReplyKey;
extern NSString * NoteActionApproveKey;
extern NSString * NoteActionEditKey;

extern NSString * NoteRangeTypeUser;
extern NSString * NoteRangeTypePost;
extern NSString * NoteRangeTypeComment;
extern NSString * NoteRangeTypeStats;
extern NSString * NoteRangeTypeBlockquote;
extern NSString * NoteRangeTypeNoticon;
extern NSString * NoteRangeTypeSite;
extern NSString * NoteRangeTypeMatch;

extern NSString * NoteMediaTypeImage;

extern NSString * NoteTypeUser;
extern NSString * NoteTypeComment;
extern NSString * NoteTypeMatcher;
extern NSString * NoteTypePost;
extern NSString * NoteTypeFollow;
extern NSString * NoteTypeLike;
extern NSString * NoteTypeCommentLike;


typedef NS_ENUM(NSInteger, NoteBlockType)
{
    NoteBlockTypeText,
    NoteBlockTypeImage,                                     // BlockTypesImage: Includes Badges and Images
    NoteBlockTypeUser,
    NoteBlockTypeComment
};

typedef NS_ENUM(NSInteger, NoteBlockGroupType)
{
    NoteBlockGroupTypeText     = NoteBlockTypeText,
    NoteBlockGroupTypeImage    = NoteBlockTypeImage,
    NoteBlockGroupTypeUser     = NoteBlockTypeUser,
    NoteBlockGroupTypeComment  = NoteBlockTypeComment,      // Blocks: User  + Comment
    NoteBlockGroupTypeActions  = 100,                       // Blocks: Comment
    NoteBlockGroupTypeSubject  = 200,                       // Blocks: Text  + Text
    NoteBlockGroupTypeHeader   = 300,                       // Blocks: Image + Text
    NoteBlockGroupTypeFooter   = 400                        // Blocks: Text
};


#pragma mark ====================================================================================
#pragma mark Notification
#pragma mark ====================================================================================

@interface Notification : SPManagedObject

@property (nonatomic, strong,  readonly) NSString               *icon;
@property (nonatomic, strong,  readonly) NSString               *noticon;

@property (nonatomic, strong, readwrite) NSNumber               *read;
@property (nonatomic, strong,  readonly) NSString               *timestamp;
@property (nonatomic, strong,  readonly) NSString               *type;
@property (nonatomic, strong,  readonly) NSString               *url;
@property (nonatomic, strong,  readonly) NSString               *title;

// Raw Properties
@property (nonatomic, strong,  readonly) NSArray                *subject;
@property (nonatomic, strong,  readonly) NSArray                *header;
@property (nonatomic, strong,  readonly) NSArray                *body;
@property (nonatomic, strong,  readonly) NSDictionary           *meta;

// Derived Properties
@property (nonatomic, strong,  readonly) NotificationBlockGroup *subjectBlockGroup;
@property (nonatomic, strong,  readonly) NotificationBlockGroup *headerBlockGroup;
@property (nonatomic, strong,  readonly) NSArray                *bodyBlockGroups;   // Array of NotificationBlockGroup objects
@property (nonatomic, assign,  readonly) NSNumber               *metaSiteID;
@property (nonatomic, assign,  readonly) NSNumber               *metaPostID;
@property (nonatomic, strong,  readonly) NSNumber               *metaCommentID;
@property (nonatomic, strong,  readonly) NSNumber               *metaReplyID;
@property (nonatomic, strong,  readonly) NSURL                  *iconURL;
@property (nonatomic, strong,  readonly) NSDate                 *timestampAsDate;

@property (nonatomic, assign,  readonly) BOOL                   isMatcher;
@property (nonatomic, assign,  readonly) BOOL                   isComment;
@property (nonatomic, assign,  readonly) BOOL                   isPost;
@property (nonatomic, assign,  readonly) BOOL                   isFollow;
@property (nonatomic, assign,  readonly) BOOL                   isLike;
@property (nonatomic, assign,  readonly) BOOL                   isCommentLike;
@property (nonatomic, assign,  readonly) BOOL                   isBadge;
@property (nonatomic, assign,  readonly) BOOL                   hasReply;

// Helpers
- (NotificationBlockGroup *)blockGroupOfType:(NoteBlockGroupType)type;
- (NotificationRange *)notificationRangeWithUrl:(NSURL *)url;

- (NotificationBlock *)subjectBlock;
- (NotificationBlock *)snippetBlock;

- (BOOL)isUnapprovedComment;

@end


#pragma mark ====================================================================================
#pragma mark NotificationBlock
#pragma mark ====================================================================================

// Adapter Class: Multiple Blocks can be mapped to a single view
@interface NotificationBlockGroup : NSObject

@property (nonatomic, strong, readonly) NSArray             *blocks;
@property (nonatomic, assign, readonly) NoteBlockGroupType type;

- (NotificationBlock *)blockOfType:(NoteBlockType)type;
- (NSSet *)imageUrlsForBlocksOfTypes:(NSSet *)types;

@end


#pragma mark ====================================================================================
#pragma mark NotificationBlock
#pragma mark ====================================================================================

@interface NotificationBlock : NSObject

@property (nonatomic, strong, readonly) NSString            *text;
@property (nonatomic, strong, readonly) NSArray             *ranges;			// Array of NotificationRange objects
@property (nonatomic, strong, readonly) NSArray             *media;				// Array of NotificationMedia objects
@property (nonatomic, strong, readonly) NSDictionary        *meta;
@property (nonatomic, strong, readonly) NSDictionary        *actions;

// Derived Properties
@property (nonatomic, assign, readonly) NoteBlockType       type;
@property (nonatomic, strong, readonly) NSNumber            *metaSiteID;
@property (nonatomic, strong, readonly) NSNumber            *metaCommentID;
@property (nonatomic, strong, readonly) NSString            *metaLinksHome;
@property (nonatomic, strong, readonly) NSString            *metaTitlesHome;

// Overrides
@property (nonatomic, strong, readwrite) NSString           *textOverride;


/**
 *	@brief      Finds the first NotificationRange instance that maps to a given URL.
 *
 *	@param		url         The URL mapped by the NotificationRange instance we need to find.
 *  @returns                A NotificationRange instance mapping to a given URL.
 */
- (NotificationRange *)notificationRangeWithUrl:(NSURL *)url;


/**
 *	@brief      Finds the first NotificationRange instance that maps to a given CommentID.
 *
 *	@param		commentID   The CommentID mapped by the NotificationRange instance we need to find.
 *  @returns                A NotificationRange instance referencing to a given commentID.
 */
- (NotificationRange *)notificationRangeWithCommentId:(NSNumber *)commentId;


/**
 *	@brief      Collects all of the Image URL's referenced by the NotificationMedia instances
 *
 *  @returns                An array of NSURL instances, mapping to images required by this block.
 */
- (NSArray *)imageUrls;

/**
 *	@brief      Returns YES if the associated comment (if any) is approved. NO otherwise.
 *
 *  @returns                A boolean value indicating whether the comment is approved, or not.
 */
- (BOOL)isCommentApproved;

/**
 *	@brief      Allows us to set a local override for a remote value. This is used to fake the UI, while
 *              there's a BG call going on.
 *
 *	@param		value       The local "Temporary" value.
 *	@param		key         The key that should get a temporary 'Override' value
 */
- (void)setActionOverrideValue:(NSNumber *)value forKey:(NSString *)key;

/**
 *	@brief      Removes any local (temporary) value that might have been set by means of *setActionOverrideValue*.
 *
 *	@param		key         The key that should get its overrides removed.
 */
- (void)removeActionOverrideForKey:(NSString *)key;

/**
 *	@brief      Returns the Notification Block status for a given action. If there's any local override,
 *              the (override) value will be returned.
 *
 *	@param		key         The key of the action to check.
 *  @returns                The value for any given action
 */
- (NSNumber *)actionForKey:(NSString *)key;

/**
 *	@brief      Returns *true* if a given action is available
 *
 *	@param		key         The key of the action to check.
 *  @returns                True if the action can be performed. False otherwise.
 */
- (BOOL)isActionEnabled:(NSString *)key;

/**
 *	@brief      Returns *true* if a given action is toggled on. (I.e.: Approval = On, means that the comment
 *              is currently approved).
 *
 *	@param		key         The key of the action to check.
 *  @returns                True if the action is currently "toggled on".
 */
- (BOOL)isActionOn:(NSString *)key;

@end


#pragma mark ====================================================================================
#pragma mark NotificationRange
#pragma mark ====================================================================================

@interface NotificationRange : NSObject

@property (nonatomic, strong, readonly) NSString            *value;
@property (nonatomic, strong, readonly) NSString            *type;
@property (nonatomic, strong, readonly) NSURL               *url;
@property (nonatomic, assign, readonly) NSRange             range;
@property (nonatomic, strong, readonly) NSNumber            *postID;
@property (nonatomic, strong, readonly) NSNumber            *commentID;
@property (nonatomic, strong, readonly) NSNumber            *userID;
@property (nonatomic, strong, readonly) NSNumber            *siteID;

// Derived Properties
@property (nonatomic, assign, readonly) BOOL                isUser;
@property (nonatomic, assign, readonly) BOOL                isPost;
@property (nonatomic, assign, readonly) BOOL                isComment;
@property (nonatomic, assign, readonly) BOOL                isFollow;
@property (nonatomic, assign, readonly) BOOL                isStats;
@property (nonatomic, assign, readonly) BOOL                isBlockquote;
@property (nonatomic, assign, readonly) BOOL                isNoticon;

@end


#pragma mark ====================================================================================
#pragma mark NotificationMedia
#pragma mark ====================================================================================

@interface NotificationMedia : NSObject

@property (nonatomic, strong, readonly) NSString            *type;
@property (nonatomic, strong, readonly) NSURL               *mediaURL;
@property (nonatomic, assign, readonly) CGSize              size;
@property (nonatomic, assign, readonly) NSRange             range;

// Derived Properties
@property (nonatomic, assign, readonly) BOOL                isImage;
@property (nonatomic, assign, readonly) BOOL                isBadge;

@end


