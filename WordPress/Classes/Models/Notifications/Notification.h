#import <Simperium/Simperium.h>


#pragma mark ====================================================================================
#pragma mark Constants
#pragma mark ====================================================================================

typedef NS_ENUM(NSInteger, NotificationMediaKind)
{
    NotificationMediaKindImage,
    NotificationMediaKindBadge
};

typedef NS_ENUM(NSInteger, NotificationRangeKind)
{
    NotificationRangeKindUser,
    NotificationRangeKindPost,
    NotificationRangeKindComment,
    NotificationRangeKindStats,
    NotificationRangeKindFollow,
    NotificationRangeKindBlockquote,
    NotificationRangeKindNoticon,
    NotificationRangeKindSite,
    NotificationRangeKindMatch
};


#pragma mark ====================================================================================
#pragma mark NotificationRange
#pragma mark ====================================================================================

@interface NotificationRange : NSObject

@property (nonatomic, assign, readonly) NSRange             range;
@property (nonatomic, assign, readonly) NotificationRangeKind kind;
@property (nonatomic, strong, nullable, readonly) NSString  *value;
@property (nonatomic, strong, nullable, readonly) NSURL     *url;
@property (nonatomic, strong, nullable, readonly) NSNumber  *postID;
@property (nonatomic, strong, nullable, readonly) NSNumber  *commentID;
@property (nonatomic, strong, nullable, readonly) NSNumber  *userID;
@property (nonatomic, strong, nullable, readonly) NSNumber  *siteID;

+ (nonnull NSArray<NotificationRange *> *)rangesFromArray:(nullable NSArray *)rawURL;

@end


#pragma mark ====================================================================================
#pragma mark NotificationMedia
#pragma mark ====================================================================================

@interface NotificationMedia : NSObject

@property (nonatomic, assign, readonly) NotificationRangeKind kind;
@property (nonatomic, strong, nullable, readonly) NSString  *type;
@property (nonatomic, strong, nullable, readonly) NSURL     *mediaURL;
@property (nonatomic, assign, readonly) CGSize              size;
@property (nonatomic, assign, readonly) NSRange             range;

// Derived Properties
@property (nonatomic, assign, readonly) BOOL                isImage;
@property (nonatomic, assign, readonly) BOOL                isBadge;

+ (nonnull NSArray<NotificationMedia *> *)mediaFromArray:(nullable NSArray *)rawMedia;

@end
