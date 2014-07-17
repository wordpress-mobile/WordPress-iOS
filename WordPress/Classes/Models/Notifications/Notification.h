#import <Simperium/SPManagedObject.h>



@class NotificationBlock;

extern NSString * NoteActionFollowKey;
extern NSString * NoteActionReplyKey;
extern NSString * NoteActionApproveKey;
extern NSString * NoteActionSpamKey;
extern NSString * NoteActionTrashKey;

extern NSString * NoteLinkTypeUser;
extern NSString * NoteLinkTypePost;


#pragma mark ====================================================================================
#pragma mark Notification
#pragma mark ====================================================================================

@interface Notification : SPManagedObject

@property (nonatomic, strong,  readonly) NSString           *icon;
@property (nonatomic, strong,  readonly) NSString           *noticon;

@property (nonatomic, strong, readwrite) NSNumber           *read;
@property (nonatomic, strong,  readonly) NSString           *timestamp;
@property (nonatomic, strong,  readonly) NSString           *type;
@property (nonatomic, strong,  readonly) NSString           *url;

// Raw Properties
@property (nonatomic, strong,  readonly) NSDictionary       *subject;
@property (nonatomic, strong,  readonly) NSArray            *body;
@property (nonatomic, strong,  readonly) NSDictionary       *meta;

// Derived Properties
@property (nonatomic, strong,  readonly) NotificationBlock  *subjectBlock;
@property (nonatomic, strong,  readonly) NSArray            *bodyBlocks;		// Array of NotificationBlock objects
@property (nonatomic, assign,  readonly) NSNumber           *metaSiteID;
@property (nonatomic, assign,  readonly) NSNumber           *metaPostID;
@property (nonatomic, strong,  readonly) NSNumber           *metaCommentID;
@property (nonatomic, strong,  readonly) NSURL              *iconURL;
@property (nonatomic, strong,  readonly) NSDate             *timestampAsDate;

// Helpers
@property (nonatomic, assign, readonly) BOOL                isMatcher;
@property (nonatomic, assign, readonly) BOOL                isStatsEvent;
@property (nonatomic, assign, readonly) BOOL                isComment;

@end


#pragma mark ====================================================================================
#pragma mark NotificationBlock
#pragma mark ====================================================================================

typedef NS_ENUM(NSInteger, NoteBlockTypes)
{
    NoteBlockTypesText,
    NoteBlockTypesImage,
    NoteBlockTypesUser
};

@interface NotificationBlock : NSObject

@property (nonatomic, strong, readonly) NSString            *text;
@property (nonatomic, strong, readonly) NSArray             *urls;				// Array of NotificationURL objects
@property (nonatomic, strong, readonly) NSArray             *media;				// Array of NotificationMedia objects
@property (nonatomic, strong, readonly) NSDictionary        *meta;
@property (nonatomic, strong, readonly) NSDictionary        *actions;

// Derived Properties
@property (nonatomic, assign, readonly) NoteBlockTypes      type;
@property (nonatomic, strong, readonly) NSNumber            *metaSiteID;

- (BOOL)hasActions;
- (void)setActionOverrideValue:(id)obj forKey:(NSString *)key;
- (void)removeActionOverrideForKey:(NSString *)key;
- (id)actionForKey:(NSString *)key;

@end


#pragma mark ====================================================================================
#pragma mark NotificationURL
#pragma mark ====================================================================================

@interface NotificationURL : NSObject

@property (nonatomic, strong, readonly) NSString            *type;
@property (nonatomic, strong, readonly) NSURL               *url;
@property (nonatomic, assign, readonly) NSRange             range;

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

@end


