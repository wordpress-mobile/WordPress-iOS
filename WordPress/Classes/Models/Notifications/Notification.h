#import <Simperium/SPManagedObject.h>



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

extern NSString * NoteMediaTypeImage;

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
    NoteBlockGroupTypeComment  = NoteBlockTypeComment,      // Contains a User + Comment Block
    NoteBlockGroupTypeSubject  = 20,                        // Contains a User + Text Block
    NoteBlockGroupTypeHeader   = 30                         // Contains a User + Text Block
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
@property (nonatomic, strong,  readonly) NSURL                  *iconURL;
@property (nonatomic, strong,  readonly) NSDate                 *timestampAsDate;

@property (nonatomic, assign,  readonly) BOOL                   isMatcher;
@property (nonatomic, assign,  readonly) BOOL                   isComment;
@property (nonatomic, assign,  readonly) BOOL                   isPost;
@property (nonatomic, assign,  readonly) BOOL                   isFollow;
@property (nonatomic, assign,  readonly) BOOL                   isBadge;

// Helpers
- (NotificationBlockGroup *)blockGroupOfType:(NoteBlockGroupType)type;
- (NotificationRange *)notificationRangeWithUrl:(NSURL *)url;

- (NotificationBlock *)subjectBlock;
- (NotificationBlock *)snippetBlock;

- (BOOL)isUnapprovedComment;
- (void)didChangeOverrides;

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
@property (nonatomic, assign, readonly) BOOL                isBadge;
@property (nonatomic, strong, readonly) NSNumber            *metaSiteID;
@property (nonatomic, strong, readonly) NSNumber            *metaCommentID;
@property (nonatomic, strong, readonly) NSString            *metaLinksHome;
@property (nonatomic, strong, readonly) NSString            *metaTitlesHome;

// Overrides
@property (nonatomic, strong, readwrite) NSString           *textOverride;

- (NotificationRange *)notificationRangeWithUrl:(NSURL *)url;
- (NSArray *)imageUrls;

- (void)setActionOverrideValue:(NSNumber *)obj forKey:(NSString *)key;
- (void)removeActionOverrideForKey:(NSString *)key;
- (NSNumber *)actionForKey:(NSString *)key;

- (BOOL)isActionEnabled:(NSString *)key;
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


