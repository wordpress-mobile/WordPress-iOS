#import <Foundation/Foundation.h>

@class RemoteMedia;
@class RemoteVideoPressVideo;

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
            success:(void (^)(void))success
            failure:(void (^)(NSError *error))failure;

/**
 *  Get all WordPress Media Library items in batches.
 *
 *  The `pageLoad` block is called with media items in each page, except the last page. If there is only one page of media
 *  items, the `pageLoad` block will not be called.
 *
 *  The `success` block is called with all media items in the Media Library. Calling this block marks the end of the loading.
 *
 *  The `failure` block is called when any API call fails. Calling this block marks the end of the loading.
 *
 *  @param pageLoad a block to be executed when each page of media is loaded.
 *  @param success a block to be executed when the request finishes with success.
 *  @param failure a block to be execute when the request fails.
 */
- (void)getMediaLibraryWithPageLoad:(void (^)(NSArray *))pageLoad
                            success:(void (^)(NSArray *))success
                            failure:(void (^)(NSError *))failure;

/**
 *  Get the number of media items available in the blog
 *
 *  @param mediaType the type of media to count for (image, video, audio, application)
 *  @param success a block to be executed when the request finishes with success.
 *  @param failure a block to be execute when the request fails.
 */
- (void)getMediaLibraryCountForType:(NSString *)mediaType
                        withSuccess:(void (^)(NSInteger))success
                            failure:(void (^)(NSError *))failure;

/**
 *  Retrieves the metadata of a VideoPress video.
 *
 *  The metadata parameters can be found in the API reference:
 *  https://developer.wordpress.com/docs/api/1.1/get/videos/%24guid/
 *
 *  @param videoPressID ID of the video in VideoPress.
 *  @param isSitePrivate true if the site is private, this will be used to determine the fetch of the VideoPress token.
 *  @param success a block to be executed when the metadata is fetched successfully.
 *  @param failure a block to be executed when the metadata can't be fetched.
 */
-(void)getMetadataFromVideoPressID:(NSString *)videoPressID
                     isSitePrivate:(BOOL)isSitePrivate
                           success:(void (^)(RemoteVideoPressVideo *metadata))success
                           failure:(void (^)(NSError *))failure;

/**
 Retrieves the VideoPress token for the request videoPressID.
 The token is required to play private VideoPress videos.

 @param videoPressID the videoPressID to search for.
 @param success a block to be executed if the the token is fetched successfully for the VideoPress video.
 @param failure a block to be executed if the token can't be fetched for the VideoPress video.
 */
-(void)getVideoPressToken:(NSString *)videoPressID
                           success:(void (^)(NSString *token))success
                           failure:(void (^)(NSError *))failure;

@end
