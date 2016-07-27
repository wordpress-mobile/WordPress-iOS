#import <Simperium/Simperium.h>

@class NotificationBlock;
@class NotificationBlockGroup;
@class NotificationRange;
@class NotificationMedia;

#pragma mark ====================================================================================
#pragma mark Constants
#pragma mark ====================================================================================

extern NSString * __nonnull NoteActionFollowKey;
extern NSString * __nonnull NoteActionLikeKey;
extern NSString * __nonnull NoteActionSpamKey;
extern NSString * __nonnull NoteActionTrashKey;
extern NSString * __nonnull NoteActionReplyKey;
extern NSString * __nonnull NoteActionApproveKey;
extern NSString * __nonnull NoteActionEditKey;

extern NSString * __nonnull NoteRangeTypeUser;
extern NSString * __nonnull NoteRangeTypePost;
extern NSString * __nonnull NoteRangeTypeComment;
extern NSString * __nonnull NoteRangeTypeStats;
extern NSString * __nonnull NoteRangeTypeBlockquote;
extern NSString * __nonnull NoteRangeTypeNoticon;
extern NSString * __nonnull NoteRangeTypeSite;
extern NSString * __nonnull NoteRangeTypeMatch;

extern NSString * __nonnull NoteMediaTypeImage;

extern NSString * __nonnull NoteTypeUser;
extern NSString * __nonnull NoteTypeComment;
extern NSString * __nonnull NoteTypeMatcher;
extern NSString * __nonnull NoteTypePost;
extern NSString * __nonnull NoteTypeFollow;
extern NSString * __nonnull NoteTypeLike;
extern NSString * __nonnull NoteTypeCommentLike;


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

@property (nonatomic, strong, nullable, readonly) NSString                          *icon;
@property (nonatomic, strong, nullable, readonly) NSString                          *noticon;

@property (nonatomic, strong, nullable, readwrite) NSNumber                         *read;
@property (nonatomic, strong, nullable, readonly) NSString                          *timestamp;
@property (nonatomic, strong, nullable, readonly) NSString                          *type;
@property (nonatomic, strong, nullable, readonly) NSString                          *url;
@property (nonatomic, strong, nullable, readonly) NSString                          *title;

// Raw Properties
@property (nonatomic, strong, nullable, readonly) NSArray                           *subject;
@property (nonatomic, strong, nullable, readonly) NSArray                           *header;
@property (nonatomic, strong, nullable, readonly) NSArray                           *body;
@property (nonatomic, strong, nullable, readonly) NSDictionary                      *meta;

// Derived Properties
@property (nonatomic, strong, nullable, readonly) NotificationBlockGroup            *subjectBlockGroup;
@property (nonatomic, strong, nullable, readonly) NotificationBlockGroup            *headerBlockGroup;
@property (nonatomic, strong,  nonnull, readonly) NSArray<NotificationBlockGroup *> *bodyBlockGroups;
@property (nonatomic, assign, nullable, readonly) NSNumber                          *metaSiteID;
@property (nonatomic, assign, nullable, readonly) NSNumber                          *metaPostID;
@property (nonatomic, strong, nullable, readonly) NSNumber                          *metaCommentID;
@property (nonatomic, strong, nullable, readonly) NSNumber                          *metaReplyID;
@property (nonatomic, strong, nullable, readonly) NSURL                             *iconURL;
@property (nonatomic, strong,  nonnull, readonly) NSDate                            *timestampAsDate;

@property (nonatomic, assign, readonly) BOOL                                        isMatcher;
@property (nonatomic, assign, readonly) BOOL                                        isComment;
@property (nonatomic, assign, readonly) BOOL                                        isPost;
@property (nonatomic, assign, readonly) BOOL                                        isFollow;
@property (nonatomic, assign, readonly) BOOL                                        isLike;
@property (nonatomic, assign, readonly) BOOL                                        isCommentLike;
@property (nonatomic, assign, readonly) BOOL                                        isBadge;
@property (nonatomic, assign, readonly) BOOL                                        hasReply;

// Helpers
- (nullable NotificationBlockGroup *)blockGroupOfType:(NoteBlockGroupType)type;
- (nullable NotificationRange *)notificationRangeWithUrl:(nonnull NSURL *)url;

- (nullable NotificationBlock *)subjectBlock;
- (nullable NotificationBlock *)snippetBlock;

- (BOOL)isUnapprovedComment;

@end


#pragma mark ====================================================================================
#pragma mark NotificationBlock
#pragma mark ====================================================================================

// Adapter Class: Multiple Blocks can be mapped to a single view
@interface NotificationBlockGroup : NSObject

@property (nonatomic, strong, nonnull, readonly) NSArray<NotificationBlock *>   *blocks;
@property (nonatomic, assign, readonly) NoteBlockGroupType  type;

- (nullable NotificationBlock *)blockOfType:(NoteBlockType)type;
- (nonnull NSSet<NSURL *> *)imageUrlsForBlocksOfTypes:(nonnull NSSet *)types;

@end


#pragma mark ====================================================================================
#pragma mark NotificationBlock
#pragma mark ====================================================================================

@interface NotificationBlock : NSObject

@property (nonatomic, strong, nullable, readonly) NSString                      *text;
@property (nonatomic, strong, nonnull,  readonly) NSArray<NotificationRange *>  *ranges;
@property (nonatomic, strong, nonnull,  readonly) NSArray<NotificationMedia *>  *media;
@property (nonatomic, strong, nullable, readonly) NSDictionary                  *meta;
@property (nonatomic, strong, nullable, readonly) NSDictionary                  *actions;

// Derived Properties
@property (nonatomic, assign, readonly) NoteBlockType                           type;
@property (nonatomic, strong, nullable, readonly) NSNumber                      *metaSiteID;
@property (nonatomic, strong, nullable, readonly) NSNumber                      *metaCommentID;
@property (nonatomic, strong, nullable, readonly) NSString                      *metaLinksHome;
@property (nonatomic, strong, nullable, readonly) NSString                      *metaTitlesHome;

// Overrides
@property (nonatomic, strong, nullable, readwrite) NSString                     *textOverride;


/**
 *	@brief      Finds the first NotificationRange instance that maps to a given URL.
 *
 *	@param		url         The URL mapped by the NotificationRange instance we need to find.
 *  @returns                A NotificationRange instance mapping to a given URL.
 */
- (nullable NotificationRange *)notificationRangeWithUrl:(nonnull NSURL *)url;


/**
 *	@brief      Finds the first NotificationRange instance that maps to a given CommentID.
 *
 *	@param		commentID   The CommentID mapped by the NotificationRange instance we need to find.
 *  @returns                A NotificationRange instance referencing to a given commentID.
 */
- (nullable NotificationRange *)notificationRangeWithCommentId:(nonnull NSNumber *)commentId;


/**
 *	@brief      Collects all of the Image URL's referenced by the NotificationMedia instances
 *
 *  @returns                An array of NSURL instances, mapping to images required by this block.
 */
- (nonnull NSArray<NSURL *> *)imageUrls;

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
- (void)setActionOverrideValue:(nonnull NSNumber *)value forKey:(nonnull NSString *)key;

/**
 *	@brief      Removes any local (temporary) value that might have been set by means of *setActionOverrideValue*.
 *
 *	@param		key         The key that should get its overrides removed.
 */
- (void)removeActionOverrideForKey:(nonnull NSString *)key;

/**
 *	@brief      Returns the Notification Block status for a given action. If there's any local override,
 *              the (override) value will be returned.
 *
 *	@param		key         The key of the action to check.
 *  @returns                The value for any given action
 */
- (nullable NSNumber *)actionForKey:(nonnull NSString *)key;

/**
 *	@brief      Returns *true* if a given action is available
 *
 *	@param		key         The key of the action to check.
 *  @returns                True if the action can be performed. False otherwise.
 */
- (BOOL)isActionEnabled:(nonnull NSString *)key;

/**
 *	@brief      Returns *true* if a given action is toggled on. (I.e.: Approval = On, means that the comment
 *              is currently approved).
 *
 *	@param		key         The key of the action to check.
 *  @returns                True if the action is currently "toggled on".
 */
- (BOOL)isActionOn:(nonnull NSString *)key;

@end


#pragma mark ====================================================================================
#pragma mark NotificationRange
#pragma mark ====================================================================================

@interface NotificationRange : NSObject

@property (nonatomic, assign, readonly) NSRange             range;
@property (nonatomic, strong,  nonnull, readonly) NSString  *type;
@property (nonatomic, strong, nullable, readonly) NSString  *value;
@property (nonatomic, strong, nullable, readonly) NSURL     *url;
@property (nonatomic, strong, nullable, readonly) NSNumber  *postID;
@property (nonatomic, strong, nullable, readonly) NSNumber  *commentID;
@property (nonatomic, strong, nullable, readonly) NSNumber  *userID;
@property (nonatomic, strong, nullable, readonly) NSNumber  *siteID;

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

@property (nonatomic, strong, nullable, readonly) NSString  *type;
@property (nonatomic, strong, nullable, readonly) NSURL     *mediaURL;
@property (nonatomic, assign, readonly) CGSize              size;
@property (nonatomic, assign, readonly) NSRange             range;

// Derived Properties
@property (nonatomic, assign, readonly) BOOL                isImage;
@property (nonatomic, assign, readonly) BOOL                isBadge;

@end


