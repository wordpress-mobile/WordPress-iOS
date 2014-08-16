#import <Simperium/SPManagedObject.h>



@class NotificationBlock;
@class NotificationURL;

#pragma mark ====================================================================================
#pragma mark Constants
#pragma mark ====================================================================================

extern NSString * NoteActionFollowKey;
extern NSString * NoteActionLikeKey;
extern NSString * NoteActionSpamKey;
extern NSString * NoteActionTrashKey;
extern NSString * NoteActionReplyKey;
extern NSString * NoteActionApproveKey;

typedef NS_ENUM(NSInteger, NoteBlockTypes)
{
    NoteBlockTypesText,
    NoteBlockTypesComment,
    NoteBlockTypesQuote,
    NoteBlockTypesImage,
    NoteBlockTypesUser
};


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
@property (nonatomic, assign,  readonly) BOOL               isMatcher;
@property (nonatomic, assign,  readonly) BOOL               isStatsEvent;
@property (nonatomic, assign,  readonly) BOOL               isComment;

// Helpers
- (NotificationBlock *)findUserBlock;
- (NotificationBlock *)findCommentBlock;
- (NotificationURL *)findNotificationUrlWithUrl:(NSURL *)url;

@end


#pragma mark ====================================================================================
#pragma mark NotificationBlock
#pragma mark ====================================================================================

@interface NotificationBlock : NSObject

@property (nonatomic, strong, readonly) NSString            *text;
@property (nonatomic, strong, readonly) NSArray             *urls;				// Array of NotificationURL objects
@property (nonatomic, strong, readonly) NSArray             *media;				// Array of NotificationMedia objects
@property (nonatomic, strong, readonly) NSDictionary        *meta;
@property (nonatomic, strong, readonly) NSDictionary        *actions;

// Derived Properties
@property (nonatomic, assign, readonly) NoteBlockTypes      type;
@property (nonatomic, strong, readonly) NSNumber            *metaSiteID;
@property (nonatomic, strong, readonly) NSNumber            *metaCommentID;
@property (nonatomic, strong, readonly) NSString            *metaLinksHome;

- (BOOL)hasActions;
- (void)setActionOverrideValue:(NSNumber *)obj forKey:(NSString *)key;
- (void)removeActionOverrideForKey:(NSString *)key;
- (NSNumber *)actionForKey:(NSString *)key;

@end


#pragma mark ====================================================================================
#pragma mark NotificationURL
#pragma mark ====================================================================================

@interface NotificationURL : NSObject

@property (nonatomic, strong, readonly) NSString            *type;
@property (nonatomic, strong, readonly) NSURL               *url;
@property (nonatomic, assign, readonly) NSRange             range;

// Derived Properties
@property (nonatomic, assign, readonly) BOOL                isUser;
@property (nonatomic, assign, readonly) BOOL                isPost;
@property (nonatomic, assign, readonly) BOOL                isComment;

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


