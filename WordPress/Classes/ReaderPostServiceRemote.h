#import <Foundation/Foundation.h>

@class WordPressComApi;

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

@end
