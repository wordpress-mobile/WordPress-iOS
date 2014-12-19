#import <Foundation/Foundation.h>
#import "LocalCoreDataService.h"

@class ReaderPost;
@class ReaderTopic;

extern NSString * const ReaderPostServiceErrorDomain;

@interface ReaderPostService : NSObject<LocalCoreDataService>

/**
 Fetches the posts for the specified topic

 @param topic The Topic for which to request posts.
 @param success block called on a successful fetch.
 @param failure block called if there is any error. `error` can be any underlying network error.
 */
- (void)fetchPostsForTopic:(ReaderTopic *)topic
                   success:(void (^)(NSInteger count, BOOL hasMore))success
                   failure:(void (^)(NSError *error))failure;

/**
 Fetches and saves the posts for the specified topic

 @param topic The Topic for which to request posts.
 @param date The date to get posts earlier than.
 @param success block called on a successful fetch.
 @param failure block called if there is any error. `error` can be any underlying network error.
 */
- (void)fetchPostsForTopic:(ReaderTopic *)topic
               earlierThan:(NSDate *)date
                   success:(void (^)(NSInteger count, BOOL hasMore))success
                   failure:(void (^)(NSError *error))failure;


/**
 Fetches and optionally saves the posts for the specified topic

 @param topic The Topic for which to request posts.
 @param date The date to get posts earlier than.
 @param skippingSave BOOL whether the save operation should be skipped.
 @param success block called on a successful fetch.
 @param failure block called if there is any error. `error` can be any underlying network error.
 */
- (void)fetchPostsForTopic:(ReaderTopic *)topic
               earlierThan:(NSDate *)date
              skippingSave:(BOOL)skippingSave
                   success:(void (^)(NSInteger count, BOOL hasMore))success
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
 Backfills and saves posts for the specified topic.

 @param topic The Topic for which to request posts.
 @param success block called on a successful fetch.
 @param failure block called if there is any error. `error` can be any underlying network error.
 */
- (void)backfillPostsForTopic:(ReaderTopic *)topic
                      success:(void (^)(NSInteger count, BOOL hasMore))success
                      failure:(void (^)(NSError *error))failure;

/**
 Backfills and optionally saves posts for the specified topic.

 @param topic The Topic for which to request posts.
 @param skippingSave BOOL whether the save operation should be skipped.
 @param success block called on a successful fetch.
 @param failure block called if there is any error. `error` can be any underlying network error.
 */
- (void)backfillPostsForTopic:(ReaderTopic *)topic
                 skippingSave:(BOOL)skippingSave
                      success:(void (^)(NSInteger count, BOOL hasMore))success
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

/**
 Deletes all posts that do not belong to a ReaderTopic
 Saves the NSManagedObjectContext.
 */
- (void)deletePostsWithNoTopic;

/**
 Delete posts from the specified site/feed from the specified topic
 
 @param siteID The id of the site or feed.
 @param siteURL The URL of the site or feed.
 @param topic The `ReaderTopic` owning the posts.
 */
- (void)deletePostsWithSiteID:(NSNumber *)siteID
                   andSiteURL:(NSString *)siteURL
                    fromTopic:(ReaderTopic *)topic;

/**
 Delete posts from the specified site (not feed)

 @param siteID The id of the site or feed.
 */

- (void)deletePostsFromSiteWithID:(NSNumber *)siteID;

- (void)flagPostsFromSite:(NSNumber *)siteID asBlocked:(BOOL)blocked;

@end
