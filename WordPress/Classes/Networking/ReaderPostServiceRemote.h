#import <Foundation/Foundation.h>
#import "ServiceRemoteREST.h"

@class RemoteReaderPost;

@interface ReaderPostServiceRemote : ServiceRemoteREST

/**
 Fetches the posts from the specified remote endpoint

 @param count number of posts to fetch.
 @param before the date to fetch posts before.
 @param success block called on a successful fetch.
 @param failure block called if there is any error. `error` can be any underlying network error.
 */
- (void)fetchPostsFromEndpoint:(NSURL *)endpoint
                         count:(NSUInteger)count
                        before:(NSDate *)date
                       success:(void (^)(NSArray *posts))success
                       failure:(void (^)(NSError *error))failure;

/**
 Fetches a specific post from the specified remote site

 @param postID the ID of the post to fetch
 @param siteID the ID of the site the post belongs to
 @param success block called on a successful fetch.
 @param failure block called if there is any error. `error` can be any underlying network error.
 */
- (void)fetchPost:(NSUInteger)postID
         fromSite:(NSUInteger)siteID
          success:(void (^)(RemoteReaderPost *post))success
          failure:(void (^)(NSError *error))failure;

/**
 Mark a post as liked by the user.

 @param postID The ID of the post.
 @param siteID The ID of the site.
 @param success block called on a successful fetch.
 @param failure block called if there is any error. `error` can be any underlying network error.
 */
- (void)likePost:(NSUInteger)postID
         forSite:(NSUInteger)siteID
         success:(void (^)())success
         failure:(void (^)(NSError *error))failure;

/**
 Mark a post as unliked by the user.

 @param postID The ID of the post.
 @param siteID The ID of the site.
 @param success block called on a successful fetch.
 @param failure block called if there is any error. `error` can be any underlying network error.
 */
- (void)unlikePost:(NSUInteger)postID
           forSite:(NSUInteger)siteID
           success:(void (^)())success
           failure:(void (^)(NSError *error))failure;

@end
