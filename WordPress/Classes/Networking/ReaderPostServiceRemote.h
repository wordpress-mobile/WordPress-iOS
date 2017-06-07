#import <Foundation/Foundation.h>
@import WordPressKit;

@class RemoteReaderPost;

@interface ReaderPostServiceRemote : ServiceRemoteWordPressComREST

/**
 Fetches the posts from the specified remote endpoint

 @param algorithm meta data used in paging
 @param count number of posts to fetch.
 @param before the date to fetch posts before.
 @param success block called on a successful fetch.
 @param failure block called if there is any error. `error` can be any underlying network error.
 */
- (void)fetchPostsFromEndpoint:(NSURL *)endpoint
                     algorithm:(NSString *)algorithm
                         count:(NSUInteger)count
                        before:(NSDate *)date
                       success:(void (^)(NSArray<RemoteReaderPost *> *posts, NSString *algorithm))success
                       failure:(void (^)(NSError *error))failure;

/**
 Fetches the posts from the specified remote endpoint

 @param algorithm meta data used in paging
 @param count number of posts to fetch.
 @param offset The offset of the fetch.
 @param success block called on a successful fetch.
 @param failure block called if there is any error. `error` can be any underlying network error.
 */
- (void)fetchPostsFromEndpoint:(NSURL *)endpoint
                     algorithm:(NSString *)algorithm
                         count:(NSUInteger)count
                        offset:(NSUInteger)offset
                       success:(void (^)(NSArray<RemoteReaderPost *> *posts, NSString *algorithm))success
                       failure:(void (^)(NSError *))failure;

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
 A helper method for constructing the endpoint URL for a reader search request.
 
 @param phrase The search phrase
 
 @return The endpoint URL as a string.
 */
- (NSString *)endpointUrlForSearchPhrase:(NSString *)phrase;

@end
