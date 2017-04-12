#import <Foundation/Foundation.h>

@class RemoteMedia;

@protocol MediaServiceRemote <NSObject>


- (void)getMediaWithID:(NSNumber *)mediaID
               success:(void (^)(RemoteMedia *remoteMedia))success
               failure:(void (^)(NSError *error))failure;

- (void)uploadMedia:(RemoteMedia *)media
           progress:(NSProgress **)progress
            success:(void (^)(RemoteMedia *remoteMedia))success
            failure:(void (^)(NSError *error))failure;

/**
 *  Update media details on the server
 *
 *  @param media   the media object to update
 *  @param success a block to be executed when the request finishes with success.
 *  @param failure a block to be executed when the request fails.
 */
- (void)updateMedia:(RemoteMedia *)media
            success:(void (^)(RemoteMedia *remoteMedia))success
            failure:(void (^)(NSError *error))failure;

/**
 *  Delete media from the server. Note the media is deleted, not trashed.
 *
 *  @param media   the media object to delete
 *  @param success a block to be executed when the request finishes with success.
 *  @param failure a block to be executed when the request fails.
 */
- (void)deleteMedia:(RemoteMedia *)media
            success:(void (^)())success
            failure:(void (^)(NSError *error))failure;

/**
 *  Get Media items from blog using the options parameter.
 *
 *  @param success a block to be executed when the request finishes with success.
 *  @param failure a block to be execute when the request fails.
 */
- (void)getMediaLibraryWithSuccess:(void (^)(NSArray *))success
                           failure:(void (^)(NSError *))failure;

/**
 *  Get the number of media items available in the blog
 *
 *  @param success a block to be executed when the request finishes with success.
 *  @param failure a block to be execute when the request fails.
 */
- (void)getMediaLibraryCountWithSuccess:(void (^)(NSInteger))success
                                failure:(void (^)(NSError *))failure;

/**
 Retrieves the VideoPress URL for the request videoPressID

 @param videoPressID the videoPressID to search for
 @param success a block to be executed if the the video is found on VideoPress and the URL is valid
 @param failure a block to be executed if the video is not found on VideoPress.
 */
-(void)getVideoURLFromVideoPressID:(NSString *)videoPressID
                           success:(void (^)(NSURL *))success
                           failure:(void (^)(NSError *))failure;


@end
