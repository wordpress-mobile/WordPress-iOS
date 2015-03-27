#import <Foundation/Foundation.h>

@class Blog;
@class RemoteMedia;

@protocol MediaServiceRemote <NSObject>


/**
 Loads specs for all of the media associated with a blog
 */
- (void)getMediaLibraryForBlog:(Blog *)blog
                       success:(void (^)(NSArray *remoteMedia))success
                       failure:(void (^)(NSError *error))failure;

/**
 Loads a particular media
 */
- (void) getMediaWithID:(NSNumber *)mediaID
                forBlog:(Blog *)blog
                success:(void (^)(RemoteMedia *remoteMedia))success
                failure:(void (^)(NSError *error))failure;

/**
 Uploads a new media
 */
- (void) createMedia:(RemoteMedia *)media
             forBlog:(Blog *)blog
            progress:(NSProgress **)progress
             success:(void (^)(RemoteMedia *remoteMedia))success
             failure:(void (^)(NSError *error))failure;

@end
