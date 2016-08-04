#import <Simperium/Simperium.h>

@class Notification;
@class NotificationBlock;
@class NotificationBlockGroup;
@class NotificationRange;
@class NotificationMedia;

#pragma mark ====================================================================================
#pragma mark Constants
#pragma mark ====================================================================================

extern NSString * __nonnull NoteMediaTypeImage;

typedef NS_ENUM(NSInteger, NoteBlockType)
{
    NoteBlockTypeText,
    NoteBlockTypeImage,                                     // BlockTypesImage: Includes Badges and Images
    NoteBlockTypeUser,
    NoteBlockTypeComment
};

typedef NS_ENUM(NSInteger, NoteAction)
{
    NoteActionFollow,
    NoteActionLike,
    NoteActionSpam,
    NoteActionTrash,
    NoteActionReply,
    NoteActionApprove,
    NoteActionEdit
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

typedef NS_ENUM(NSInteger, NoteRangeType)
{
    NoteRangeTypeUser,
    NoteRangeTypePost,
    NoteRangeTypeComment,
    NoteRangeTypeStats,
    NoteRangeTypeFollow,
    NoteRangeTypeBlockquote,
    NoteRangeTypeNoticon,
    NoteRangeTypeSite,
    NoteRangeTypeMatch
};


#pragma mark ====================================================================================
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
@property (nonatomic, strong, nullable, readonly) NSURL                         *metaLinksHome;
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
 *	@param		action      The action that should get a temporary 'Override' value
 */
- (void)setOverrideValue:(nonnull NSNumber *)value forAction:(NoteAction)action;

/**
 *	@brief      Removes any local (temporary) value that might have been set by means of *setActionOverrideValue*.
 *
 *	@param		action      The action that should get its overrides removed.
 */
- (void)removeOverrideValueForAction:(NoteAction)action;

/**
 *	@brief      Returns the Notification Block status for a given action. If there's any local override,
 *              the (override) value will be returned.
 *
 *	@param		action      The action to check.
 *  @returns                The value for any given action
 */
- (nullable NSNumber *)actionForKey:(nonnull NSString *)key;

/**
 *	@brief      Returns *true* if a given action is available
 *
 *	@param		action      The action to check.
 *  @returns                True if the action can be performed. False otherwise.
 */
- (BOOL)isActionEnabled:(NoteAction)action;

/**
 *	@brief      Returns *true* if a given action is toggled on. (I.e.: Approval = On, means that the comment
 *              is currently approved).
 *
 *	@param		action      The action to check.
 *  @returns                True if the action is currently "toggled on".
 */
- (BOOL)isActionOn:(NoteAction)action;

@end


#pragma mark ====================================================================================
#pragma mark NotificationRange
#pragma mark ====================================================================================

@interface NotificationRange : NSObject

@property (nonatomic, assign, readonly) NSRange             range;
@property (nonatomic, assign, readonly) NoteRangeType       type;
@property (nonatomic, strong, nullable, readonly) NSString  *value;
@property (nonatomic, strong, nullable, readonly) NSURL     *url;
@property (nonatomic, strong, nullable, readonly) NSNumber  *postID;
@property (nonatomic, strong, nullable, readonly) NSNumber  *commentID;
@property (nonatomic, strong, nullable, readonly) NSNumber  *userID;
@property (nonatomic, strong, nullable, readonly) NSNumber  *siteID;

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


