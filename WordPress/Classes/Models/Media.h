#import <CoreData/CoreData.h>
#import "Blog.h"
#import "AbstractPost.h"

typedef NS_ENUM(NSUInteger, MediaRemoteStatus) {
    MediaRemoteStatusSync,    // Post synced
    MediaRemoteStatusFailed,      // Upload failed
    MediaRemoteStatusLocal,       // Only local version
    MediaRemoteStatusPushing,       // Uploading post
    MediaRemoteStatusProcessing, // Intermediate status before uploading
};

typedef NS_ENUM(NSUInteger, MediaType) {
    MediaTypeImage,
    MediaTypeVideo,
    MediaTypeDocument,
    MediaTypePowerpoint
};

@interface Media :  NSManagedObject

// Managed properties

@property (nonatomic, strong) NSString *caption;
@property (nonatomic, strong) NSDate *creationDate;
@property (nonatomic, strong) NSString *desc;
@property (nonatomic, strong) NSString *filename;
@property (nonatomic, strong) NSNumber *filesize;
@property (nonatomic, strong) NSNumber *height;
@property (nonatomic, strong) NSNumber *length;
@property (nonatomic, strong) NSString *localThumbnailURL;
@property (nonatomic, strong) NSString *localURL;
@property (nonatomic, strong) NSNumber *mediaID;
@property (nonatomic, strong) NSString *mediaTypeString;
@property (nonatomic, strong) NSNumber *postID;
@property (nonatomic, strong) NSNumber *remoteStatusNumber;
@property (nonatomic, strong) NSString *remoteThumbnailURL;
@property (nonatomic, strong) NSString *remoteURL;
@property (nonatomic, strong) NSString *shortcode;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *videopressGUID;
@property (nonatomic, strong) NSNumber *width;

// Relationships

@property (nonatomic, strong) Blog *blog;
@property (nonatomic, strong) NSSet *posts;

// Helper properties

@property (nonatomic, assign) MediaType mediaType;
@property (nonatomic, weak, readonly) NSString *html;
@property (nonatomic, assign) MediaRemoteStatus remoteStatus;
@property (nonatomic, assign, readonly) BOOL unattached;
@property (nonatomic, assign, readonly) BOOL featured;
@property (nonatomic, strong) NSString *absoluteLocalURL;
@property (nonatomic, strong) NSString *absoluteThumbnailLocalURL;
@property (nonatomic, strong, readonly) NSString *posterImageURL;

// Helper methods

+ (NSString *)stringFromMediaType:(MediaType)mediaType;

- (void)mediaTypeFromUrl:(NSString *)ext;
- (NSString *)fileExtension;
- (NSString *)mimeType;

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
