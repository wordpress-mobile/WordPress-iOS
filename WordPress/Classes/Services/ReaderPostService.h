#import <Foundation/Foundation.h>
#import "LocalCoreDataService.h"

@class ReaderPost;
@class ReaderAbstractTopic;

extern NSString * const ReaderPostServiceErrorDomain;

@interface ReaderPostService : LocalCoreDataService

/**
 Fetches the posts for the specified topic

 @param topic The Topic for which to request posts.
 @param success block called on a successful fetch.
 @param failure block called if there is any error. `error` can be any underlying network error.
 */
- (void)fetchPostsForTopic:(ReaderAbstractTopic *)topic
                   success:(void (^)(NSInteger count, BOOL hasMore))success
                   failure:(void (^)(NSError *error))failure;

/**
 Fetches and saves the posts for the specified topic

 @param topic The Topic for which to request posts.
 @param date The date to get posts earlier than.
 @param success block called on a successful fetch.
 @param failure block called if there is any error. `error` can be any underlying network error.
 */
- (void)fetchPostsForTopic:(ReaderAbstractTopic *)topic
               earlierThan:(NSDate *)date
                   success:(void (^)(NSInteger count, BOOL hasMore))success
                   failure:(void (^)(NSError *error))failure;

/**
 Fetches and saves the posts for the specified topic

 @param topic The Topic for which to request posts.
 @param date The date to get posts earlier than.
 @param deletingEarlier Deletes any cached posts earlier than the earliers post returned.
 @param success block called on a successful fetch.
 @param failure block called if there is any error. `error` can be any underlying network error.
 */
- (void)fetchPostsForTopic:(ReaderAbstractTopic *)topic
               earlierThan:(NSDate *)date
           deletingEarlier:(BOOL)deleteEarlier
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
 Deletes all posts that do not belong to a `ReaderAbstractTopic`
 Saves the NSManagedObjectContext.
 */
- (void)deletePostsWithNoTopic;

/**
 Delete posts from the specified site/feed from the specified topic
 
 @param siteID The id of the site or feed.
 @param siteURL The URL of the site or feed.
 @param topic The `ReaderAbstractTopic` owning the posts.
 */
- (void)deletePostsWithSiteID:(NSNumber *)siteID
                   andSiteURL:(NSString *)siteURL
                    fromTopic:(ReaderAbstractTopic *)topic;

/**
 Delete posts from the specified site (not feed)

 @param siteID The id of the site or feed.
 */

- (void)deletePostsFromSiteWithID:(NSNumber *)siteID;

- (void)flagPostsFromSite:(NSNumber *)siteID asBlocked:(BOOL)blocked;

/**
 Follows or unfollows the specified site. Posts belonging to that site and URL
 have their following status updated in core data. 

 @param following Whether the user is following the site.
 @param siteID The ID of the site
 @siteURL the URL of the site. 
 @param success block called on a successful call.
 @param failure block called if there is any error. `error` can be any underlying network error.
 */
- (void)setFollowing:(BOOL)following
  forWPComSiteWithID:(NSNumber *)siteID
              andURL:(NSString *)siteURL
             success:(void (^)())success
             failure:(void (^)(NSError *error))failure;

/**
 Updates in core data the following status of posts belonging to the specified site & url

 @param following Whether the user is following the site.
 @param siteID The ID of the site
 @siteURL the URL of the site.
 */
- (void)setFollowing:(BOOL)following forPostsFromSiteWithID:(NSNumber *)siteID andURL:(NSString *)siteURL;

@end
