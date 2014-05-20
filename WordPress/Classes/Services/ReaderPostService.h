#import <Foundation/Foundation.h>
#import "LocalCoreDataService.h"

@class ReaderPost;
@class ReaderTopic;

@interface ReaderPostService : NSObject<LocalCoreDataService>

/**
 Fetches the posts for the specified topic

 @param topic The Topic for which to request posts.
 @param success block called on a successful fetch.
 @param failure block called if there is any error. `error` can be any underlying network error.
 */
- (void)fetchPostsForTopic:(ReaderTopic *)topic
                   success:(void (^)(BOOL hasMore))success
                   failure:(void (^)(NSError *error))failure;

/**
 Fetches the posts for the specified topic

 @param topic The Topic for which to request posts.
 @param date The date to get posts earlier than.
 @param success block called on a successful fetch.
 @param failure block called if there is any error. `error` can be any underlying network error.
 */
- (void)fetchPostsForTopic:(ReaderTopic *)topic
               earlierThan:(NSDate *)date
                   success:(void (^)(BOOL hasMore))success
                   failure:(void (^)(NSError *error))failure;

/**
 Fetches a specific post from the specified remote site

 @param postID The ID of the post to fetch.
 @param siteID The ID of the post's site.
 @param success block called on a successful fetch.
 @param failure block called if there is any error. `error` can be any underlying network error.
 */
- (void)fetchPost:(NSUInteger)postID
          forSite:(NSUInteger)siteID
          success:(void (^)(ReaderPost *post))success
          failure:(void (^)(NSError *error))failure;

/**
 Backfills posts for the specified topic.

 @param topic The Topic for which to request posts.
 @param success block called on a successful fetch.
 @param failure block called if there is any error. `error` can be any underlying network error.
 */
- (void)backfillPostsForTopic:(ReaderTopic *)topic
                      success:(void (^)(BOOL hasMore))success
                      failure:(void (^)(NSError *error))failure;

/**
 Toggle the liked status of the specified post.

 @param post The reader post to like/unlike.
 @param success block called on a successful fetch.
 @param failure block called if there is any error. `error` can be any underlying network error.
 */
- (void)toggleLikedForPost:(ReaderPost *)post
                   success:(void (^)())success
                   failure:(void (^)(NSError *error))failure;

/**
 Toggle the following status of the specified post's blog.

 @param post The ReaderPost whose blog should be followed.
 @param success block called on a successful fetch.
 @param failure block called if there is any error. `error` can be any underlying network error.
 */
- (void)toggleFollowingForPost:(ReaderPost *)post
                       success:(void (^)())success
                       failure:(void (^)(NSError *error))failure;

/**
 Reblog the specified post to a target blog. Optionally including a note.

 @param post The ReaderPost to reblog.
 @param siteID The ID of the destination site.
 @param note (Optional.) A short note about the reblog.
 @param success block called on a successful fetch.
 @param failure block called if there is any error. `error` can be any underlying network error.
 */
- (void)reblogPost:(ReaderPost *)post
            toSite:(NSUInteger)siteID
              note:(NSString *)note
           success:(void (^)())success
           failure:(void (^)(NSError *error))failure;

@end
