#import <CoreData/CoreData.h>
#import "Blog.h"
#import "AbstractPost.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, MediaRemoteStatus) {
    MediaRemoteStatusSync,          /* Post synced. */
    MediaRemoteStatusFailed,        /* Upload failed. */
    MediaRemoteStatusLocal,         /* Only local version. */
    MediaRemoteStatusPushing,       /* Uploading post. */
    MediaRemoteStatusProcessing,    /* Intermediate status before uploading. */
};

typedef NS_ENUM(NSUInteger, MediaType) {
    MediaTypeImage,
    MediaTypeVideo,
    MediaTypeDocument,
    MediaTypePowerpoint
};

@interface Media :  NSManagedObject

// Managed properties

@property (nonatomic, strong, nullable) NSString *caption;
@property (nonatomic, strong) NSDate *creationDate;
@property (nonatomic, strong, nullable) NSString *desc;
@property (nonatomic, strong, nullable) NSString *filename;
@property (nonatomic, strong, nullable) NSNumber *filesize;
@property (nonatomic, strong, nullable) NSNumber *height;
@property (nonatomic, strong, nullable) NSNumber *length;
@property (nonatomic, strong, nullable) NSString *localThumbnailURL;
@property (nonatomic, strong, nullable) NSString *localURL;
@property (nonatomic, strong, nullable) NSNumber *mediaID;
@property (nonatomic, strong, nullable) NSString *mediaTypeString;
@property (nonatomic, strong, nullable) NSNumber *postID;
@property (nonatomic, strong, nullable) NSNumber *remoteStatusNumber;
@property (nonatomic, strong, nullable) NSString *remoteThumbnailURL;
@property (nonatomic, strong, nullable) NSString *remoteURL;
@property (nonatomic, strong, nullable) NSString *shortcode;
@property (nonatomic, strong, nullable) NSString *title;
@property (nonatomic, strong, nullable) NSString *videopressGUID;
@property (nonatomic, strong, nullable) NSNumber *width;

// Relationships

@property (nonatomic, strong) Blog *blog;
@property (nonatomic, strong, nullable) NSSet *posts;

// Helper properties

@property (nonatomic, assign) MediaType mediaType;
@property (nonatomic, assign) MediaRemoteStatus remoteStatus;
@property (nonatomic, strong, nullable) NSString *absoluteLocalURL;
@property (nonatomic, strong, nullable) NSString *absoluteThumbnailLocalURL;

// Helper methods

+ (NSString *)stringFromMediaType:(MediaType)mediaType;

- (nullable NSString *)fileExtension;
- (nullable NSString *)mimeType;
- (void)setMediaTypeForExtension:(NSString *)extension;

// CoreData helpers

- (void)remove;
- (void)save;

@end

@class AbstractPost;

@interface Media (CoreDataGeneratedAccessors)

- (void)addPostsObject:(AbstractPost *)value;
- (void)removePostsObject:(AbstractPost *)value;
- (void)addPosts:(NSSet *)values;
- (void)removePosts:(NSSet *)values;

@end

NS_ASSUME_NONNULL_END
