#import <Foundation/Foundation.h>

@class WordPressComApi;
@class RemoteReaderPost;

@interface ReaderPostServiceRemote : NSObject

- (id)initWithRemoteApi:(WordPressComApi *)api;


/**
 Fetches the posts from the specified remote endpoint

 @param count number of posts to fetch.
 @param success block called on a successful fetch.
 @param failure block called if there is any error. `error` can be any underlying network error.
 */
- (void)fetchPostsFromEndpoint:(NSURL *)endpoint
                         count:(NSUInteger)count
                       success:(void (^)(NSArray *posts))success
                       failure:(void (^)(NSError *error))failure;

/**
 Fetches the posts from the specified remote endpoint
 
 @param count number of posts to fetch.
 @param after the date to fetch posts after.
 @param success block called on a successful fetch.
 @param failure block called if there is any error. `error` can be any underlying network error.
 */
- (void)fetchPostsFromEndpoint:(NSURL *)endpoint
                         count:(NSUInteger)count
                         after:(NSDate *)date
                       success:(void (^)(NSArray *posts))success
                       failure:(void (^)(NSError *error))failure;

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

/**
 Reblog a post from one site to another
 
 @param postID The ID of the post to reblog.
 @param siteID The ID of the origin site.
 @param targetSiteID The ID of the destination site.
 @param note A short note about the reblog.
 @param success block called on a successful fetch.
 @param failure block called if there is any error. `error` can be any underlying network error.
 */
- (void)reblogPost:(NSUInteger)postID
          fromSite:(NSUInteger)siteID
            toSite:(NSUInteger)targetSiteID
              note:(NSString *)note
           success:(void (^)(BOOL isReblogged))success
           failure:(void (^)(NSError *error))failure;


@end
