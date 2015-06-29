#import <Foundation/Foundation.h>

@class Blog;
@class RemoteMedia;

@protocol MediaServiceRemote <NSObject>


- (void)getMediaWithID:(NSNumber *)mediaID
                 forBlog:(Blog *)blog
                 success:(void (^)(RemoteMedia *remoteMedia))success
                 failure:(void (^)(NSError *error))failure;

- (void)createMedia:(RemoteMedia *)media
                forBlog:(Blog *)blog
               progress:(NSProgress **)progress
                success:(void (^)(RemoteMedia *remoteMedia))success
                failure:(void (^)(NSError *error))failure;

/**
 *  Get Media items from blog using the options parameter.
 *
 *  @param blog    from to where fetch the media library.
 *  @param success a block to be executed when the request finishes with success.
 *  @param failure a block to be execute when the request fails.
 */
- (void)getMediaLibraryForBlog:(Blog *)blog
                       success:(void (^)(NSArray *))success
                       failure:(void (^)(NSError *))failure;

/**
 *  Get the number of media items available in the blog
 *
 *  @param blog    from to where fetch the media library.
 *  @param success a block to be executed when the request finishes with success.
 *  @param failure a block to be execute when the request fails.
 */
- (void)getMediaLibraryCountForBlog:(Blog *)blog
                            success:(void (^)(NSInteger))success
                            failure:(void (^)(NSError *))failure;



@end
