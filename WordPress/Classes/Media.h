//
//  Media.h
//  WordPress
//
//  Created by Chris Boyd on 6/23/10.
//  
//

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

@interface Media :  NSManagedObject  
{
}

@property (nonatomic, strong) NSNumber * mediaID;
@property (nonatomic, strong) NSString * mediaType;
@property (weak, nonatomic, readonly) NSString * mediaTypeName;
@property (nonatomic, strong) NSString * remoteURL;
@property (nonatomic, strong) NSString * localURL;
@property (nonatomic, strong) NSString * shortcode;
@property (nonatomic, strong) NSNumber * length;
@property (nonatomic, strong) NSString * title;
@property (nonatomic, strong) NSData * thumbnail;
@property (nonatomic, strong) NSString * filename;
@property (nonatomic, strong) NSNumber * filesize;
@property (nonatomic, strong) NSNumber * width;
@property (nonatomic, strong) NSNumber * height;
@property (nonatomic, strong) NSString * orientation;
@property (nonatomic, strong) NSDate * creationDate;
@property (weak, nonatomic, readonly) NSString * html;
@property (nonatomic, strong) NSNumber * remoteStatusNumber;
@property (nonatomic) MediaRemoteStatus remoteStatus;
@property (nonatomic) float progress;
@property (nonatomic, strong) NSString * caption;
@property (nonatomic, strong) NSString * desc;

@property (nonatomic, strong) Blog * blog;
@property (nonatomic, strong) NSMutableSet * posts;
@property (nonatomic, assign) BOOL isUnattached;

+ (Media *)newMediaForPost:(AbstractPost *)post;
+ (Media *)newMediaForBlog:(Blog *)blog withContext:(NSManagedObjectContext *)context;
+ (Media *)createOrReplaceMediaFromJSON:(NSDictionary*)json forBlog:(Blog *)blog withContext:(NSManagedObjectContext *)context;
+ (void)bulkDeleteMedia:(NSArray *)media withSuccess:(void(^)())success failure:(void (^)(NSError *error, NSArray *failures))failure;

- (void)cancelUpload;
- (void)uploadWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure;
- (void)remove;
- (void)save;
- (void)remoteUpdateWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure;
- (void)setImage:(UIImage *)image withSize:(MediaResize)size;

@end



