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
    MediaRemoteStatusStub,          /* We only have the mediaID information from the server */
};

typedef NS_ENUM(NSUInteger, MediaType) {
    MediaTypeImage,
    MediaTypeVideo,
    MediaTypeDocument,
    MediaTypePowerpoint,
    MediaTypeAudio
};

@interface Media :  NSManagedObject

// Managed properties

@property (nonatomic, strong, nullable) NSString *alt;
@property (nonatomic, strong, nullable) NSString *caption;
@property (nonatomic, strong, nullable) NSDate *creationDate;
@property (nonatomic, strong, nullable) NSString *desc;
@property (nonatomic, strong, nullable) NSString *filename;
@property (nonatomic, strong, nullable) NSNumber *filesize;
@property (nonatomic, strong, nullable) NSNumber *height;
@property (nonatomic, strong, nullable) NSNumber *length;
@property (nonatomic, strong, nullable) NSString *localThumbnailIdentifier;
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
@property (nonatomic, strong, nullable) NSError *error;
@property (nonatomic, strong, nonnull) NSNumber *autoUploadFailureCount;

// Relationships

@property (nonatomic, strong) Blog *blog;
@property (nonatomic, strong, nullable) NSSet *posts;
@property (nonatomic, strong, nullable) NSSet *featuredOnPosts;

// Helper properties

@property (nonatomic, assign) MediaType mediaType;
@property (nonatomic, assign) MediaRemoteStatus remoteStatus;

/**
 Local file URL for the Media's asset. e.g. an image, video, gif or other file.
 */
@property (nonatomic, strong, nullable) NSURL *absoluteLocalURL;

/**
 Local file URL for a preprocessed thumbnail of the Media's asset. This may be nil if the
 thumbnail has been deleted from the cache directory.

 Note: it is recommended to instead use MediaService to generate thumbnails with a preferred size.
 */
@property (nonatomic, strong, nullable) NSURL *absoluteThumbnailLocalURL;

/// Returns true if the media object already exists on the server
@property (nonatomic, readonly) BOOL hasRemote;

// Helper methods

+ (NSString *)stringFromMediaType:(MediaType)mediaType;

- (nullable NSString *)fileExtension;
- (nullable NSString *)mimeType;

- (void)setMediaTypeForExtension:(NSString *)extension;

- (void)setMediaTypeForMimeType:(NSString *)mimeType;

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

- (void)addFeaturedOnPostsObject:(AbstractPost *)value;
- (void)removeFeaturedOnPostsObject:(AbstractPost *)value;
- (void)addFeaturedOnPosts:(NSSet *)values;
- (void)removeFeaturedOnPosts:(NSSet *)values;

@end

NS_ASSUME_NONNULL_END
