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

typedef NS_ENUM(NSUInteger, MediaResize) {
    MediaResizeSmall,
    MediaResizeMedium,
    MediaResizeLarge,
    MediaResizeOriginal
};

typedef NS_ENUM(NSUInteger, MediaOrientation) {
    MediaOrientationPortrait,
    MediaOrientationLandscape
};

@interface Media :  NSManagedObject

@property (nonatomic, strong) NSNumber * mediaID;
@property (nonatomic, strong) NSString * mediaTypeString;
@property (nonatomic, assign) MediaType mediaType;
@property (nonatomic, strong) NSString * remoteURL;
@property (nonatomic, strong) NSString * localURL;
@property (nonatomic, strong) NSString * shortcode;
@property (nonatomic, strong) NSNumber * length;
@property (nonatomic, strong) NSString * title;
@property (nonatomic, strong) NSString * filename;
@property (nonatomic, strong) NSNumber * filesize;
@property (nonatomic, strong) NSNumber * width;
@property (nonatomic, strong) NSNumber * height;
@property (nonatomic, strong) NSString * orientation DEPRECATED_ATTRIBUTE;
@property (nonatomic, strong) NSDate * creationDate;
@property (nonatomic, strong) NSString *videopressGUID;
@property (nonatomic, weak, readonly) NSString * html;
@property (nonatomic, strong) NSNumber * remoteStatusNumber;
@property (nonatomic, assign) MediaRemoteStatus remoteStatus;
@property (nonatomic, strong) NSString * caption;
@property (nonatomic, strong) NSString * desc;
@property (nonatomic, strong) Blog * blog;
@property (nonatomic, strong) NSSet *posts;
@property (nonatomic, assign, readonly) BOOL unattached;
@property (nonatomic, assign, readonly) BOOL featured;
@property (nonatomic, strong) NSString *absoluteLocalURL;
@property (nonatomic, strong) NSString *remoteThumbnailURL;
@property (nonatomic, strong) NSString *localThumbnailURL;
@property (nonatomic, strong) NSString *absoluteThumbnailLocalURL;
@property (nonatomic, strong, readonly) NSString *posterImageURL;


- (void)mediaTypeFromUrl:(NSString *)ext;

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
