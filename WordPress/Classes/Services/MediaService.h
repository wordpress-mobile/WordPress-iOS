#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "LocalCoreDataService.h"

extern CGSize const MediaMaxImageSize;
extern NSInteger const MediaMinImageSizeDimension;
extern NSInteger const MediaMaxImageSizeDimension;

@class Media;
@class Blog;

@interface MediaService : NSObject <LocalCoreDataService>

+ (CGSize)maxImageSizeSetting;

+ (void)setMaxImageSizeSetting:(CGSize)imageSize;

/**
 Sync all Media objects from the server to local database
 
 @param blog
 @success a block that will be invoked when the sync succeeds
 @failure a block that will be invoked when the sync fails
 */
- (void)syncMediaLibraryForBlog:(Blog *)blog
                        success:(void (^)())success
                        failure:(void (^)(NSError *error))failure;

/**
 Create a Media object using the asset as the source and making it a child of the post with postObjectId.
 
 @param asset
 @param postObjectID
 @completion a block that will be invoked when the media is created, on success it will return a valid Media object, on failure it will return a nil Media and an error object with the details.
 */
- (void)createMediaWithAsset:(ALAsset *)asset
             forPostObjectID:(NSManagedObjectID *)postObjectID
                  completion:(void (^)(Media *media, NSError *error))completion;


/**
 Get the Media object from the server using the blog and the mediaID as the identifier of the resource
 
 @param mediaID
 @param blog
 @success a block that will be invoked when the media is retrieved
 @failure a block that will be invoked if an error happens returnin the associated error object with the details.
 */
- (void)getMediaWithID:(NSNumber *)mediaID
                inBlog:(Blog *)blog
           withSuccess:(void (^)(Media *media))success
               failure:(void (^)(NSError *error))failure;

/**
 Uploads the Media object to the server.
 
 @param media object to upload to the server.
 @param progress a NSProgress that tracks the upload progress to the server.
 @sucess a block that will be invoked when the media upload finished with success
 @failure a block that will be invoked when there is upload error.
 */
- (void)uploadMedia:(Media *)media
           progress:(NSProgress **) progress
            success:(void (^)())success
            failure:(void (^)(NSError *error))failure;

/**
 Find the media object in the local database.
 
 @param mediaID
 @param blog
 
 @return the Media object with the mediaID that belongs to the blog. Nil if not found.
 */
- (Media *)findMediaWithID:(NSNumber *)mediaID inBlog:(Blog *)blog;

@end
