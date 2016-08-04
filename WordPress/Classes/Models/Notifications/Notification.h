#import <Simperium/Simperium.h>


#pragma mark ====================================================================================
#pragma mark Constants
#pragma mark ====================================================================================

extern NSString * __nonnull NoteMediaTypeImage;

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

+ (nonnull NSArray<NotificationRange *> *)rangesFromArray:(nullable NSArray *)rawURL;

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

+ (nonnull NSArray<NotificationMedia *> *)mediaFromArray:(nullable NSArray *)rawMedia;

@end
