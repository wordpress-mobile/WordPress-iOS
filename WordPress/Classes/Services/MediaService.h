#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <Photos/Photos.h>
#import "LocalCoreDataService.h"


@class Media;
@class RemoteVideoPressVideo;
@class Blog;
@class AbstractPost;
@protocol ExportableAsset;

extern NSErrorDomain _Nonnull const MediaServiceErrorDomain;
typedef NS_ERROR_ENUM(MediaServiceErrorDomain, MediaServiceError) {
    MediaServiceErrorFileDoesNotExist = 0,
    MediaServiceErrorFileLargerThanDiskQuotaAvailable = 1,
    MediaServiceErrorFileLargerThanMaxFileSize = 2,
    MediaServiceErrorUnableToCreateMedia = 3,
    MediaServiceErrorUnknownUploadError = 4
};

@interface MediaService : LocalCoreDataService

/**
 Uploads the Media object to the server.
 
 @param media object to upload to the server.
 @param automatedRetry Whether we're uploading media due to an automated upload retry.
 @param progress a NSProgress that tracks the upload progress to the server.
 @param success a block that will be invoked when the media upload finished with success
 @param failure a block that will be invoked when there is upload error.
 */
- (void)uploadMedia:(nonnull Media *)media
     automatedRetry:(BOOL)automatedRetry
           progress:(NSProgress * __nullable __autoreleasing * __nullable) progress
            success:(nullable void (^)(void))success
            failure:(nullable void (^)(NSError * _Nullable error))failure;

/**
 Updates the media object details. All fields defined in the media object will be updated.
 
 NOTE: This method doesn't allow you to update media file, because that always stays static after the initial
 upload, it only allows to change details like, caption, alternative text, etc...

 @param media object to update.
 @success a block that will be invoked when the media upload finished with success
 @failure a block that will be invoked when there is upload error.
 */
- (void)updateMedia:(nonnull Media *)media
            success:(nullable void (^)(void))success
            failure:(nullable void (^)(NSError * _Nullable error))failure;

/**
 Updates the specified defails of media object.

 @param media object to update.
 @param fieldsToUpdate Fields to be updated of media object.
 @success a block that will be invoked when the media upload finished with success
 @failure a block that will be invoked when there is upload error.
 */
- (void)updateMedia:(nonnull Media *)media
     fieldsToUpdate:(NSArray<NSString *> *)fieldsToUpdate
            success:(nullable void (^)(void))success
            failure:(nullable void (^)(NSError * _Nullable error))failure;

/**
 Updates multiple media objects similar to `-updateMedia:success:failure:` but batches them
 together. All fields defined in the media objects will be updated.
 
 The success handler is only called when all updates succeed. Failure is called
 if the entire process fails in some catostrophic way.
 
 @param mediaObjects An array of media objects to update
 @param success
 */
- (void)updateMedia:(nonnull NSArray<Media *> *)mediaObjects
     overallSuccess:(nullable void (^)(void))overallSuccess
            failure:(nullable void (^)(NSError * _Nullable error))failure;

/**
 Updates specified details of multiple media objects.
 
 The success handler is only called when all updates succeed. Failure is called
 if the entire process fails in some catostrophic way.
 
 @param mediaObjects An array of media objects to update
 @param fieldsToUpdate Fields to be updated of media objects.
 @param success
 */
- (void)updateMedia:(nonnull NSArray<Media *> *)mediaObjects
     fieldsToUpdate:(NSArray<NSString *> *)fieldsToUpdate
     overallSuccess:(nullable void (^)(void))overallSuccess
            failure:(nullable void (^)(NSError * _Nullable error))failure;

/**
 Deletes the Media object from the server. Note the Media is deleted, not trashed.

 @param media object to delete.
 @param success a block that will be invoked when the media deletion finished with success
 @param failure a block that will be invoked when there is an error.
 */
- (void)deleteMedia:(nonnull Media *)media
            success:(nullable void (^)(void))success
            failure:(nullable void (^)(NSError * _Nonnull error))failure;

/**
 Deletes multiple Media objects from the server. Note the Media objects are deleted, not trashed.

 @param mediaObjects An array of media objects to delete.
 @param progress a block that will be invoked after each media item is deleted successfully
 @param success a block that will be invoked when the media deletion finished with success
 @param failure a block that will be invoked when there is an error.
 */
- (void)deleteMedia:(nonnull NSArray<Media *> *)mediaObjects
           progress:(nullable void (^)(NSProgress *_Nonnull progress))progress
            success:(nullable void (^)(void))success
            failure:(nullable void (^)(void))failure;

/**
 *  Retrieves the metadata of a VideoPress video.
 *
 *  The metadata parameters can be found in the API reference:
 *  https://developer.wordpress.com/docs/api/1.1/get/videos/%24guid/
 *
 *  @param videoPressID ID of the video in VideoPress.
 *  @param success a block to be executed when the metadata is fetched successfully.
 *  @param failure a block to be executed when the metadata can't be fetched.
 */
- (void)getMetadataFromVideoPressID:(nonnull NSString *)videoPressID
                             inBlog:(nonnull Blog *)blog
                            success:(nullable void (^)(RemoteVideoPressVideo * _Nonnull metadata))success
                            failure:(nullable void (^)(NSError * _Nonnull error))failure;

/**
 * Sync all Media objects from the server to local database
 
 * @param blog
 * @param success a block that will be invoked when the sync succeeds
 * @param failure a block that will be invoked when the sync fails
 */
- (void)syncMediaLibraryForBlog:(nonnull Blog *)blog
                        success:(nullable void (^)(void))success
                        failure:(nullable void (^)(NSError * _Nonnull error))failure;


- (void)getMediaLibraryServerCountForBlog:(nonnull Blog *)blog
                            forMediaTypes:(nonnull NSSet *)mediaTypes
                                  success:(nullable void (^)(NSInteger count))success
                                  failure:(nullable void (^)(NSError * _Nonnull error))failure;

@end
