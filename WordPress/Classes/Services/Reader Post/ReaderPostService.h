#import <Foundation/Foundation.h>
#import "CoreDataService.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnullability-completeness"

@import WordPressKit;
@import WordPressShared;

@class ReaderPost;
@class ReaderAbstractTopic;

extern NSString * const ReaderPostServiceErrorDomain;
extern NSString * const ReaderPostServiceToggleSiteFollowingState;

@interface ReaderPostService : CoreDataService

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
 Fetches and saves the posts for the specified topic

 @param topic The Topic for which to request posts.
 @param offset The offset of the posts to fetch.
 @param deletingEarlier Deletes any cached posts earlier than the earliers post returned.
 @param success block called on a successful fetch.
 @param failure block called if there is any error. `error` can be any underlying network error.
 */
- (void)fetchPostsForTopic:(ReaderAbstractTopic *)topic
                  atOffset:(NSUInteger)offset
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
           isFeed:(BOOL)isFeed 
          success:(void (^)(ReaderPost *post))success
          failure:(void (^)(NSError *error))failure;

/**
 Fetches a specific post from the specified URL

 @param postURL The URL of the post to fetch
 @param success block called on a successful fetch.
 @param failure block called if there is any error. `error` can be any underlying network error.
 */
- (void)fetchPostAtURL:(NSURL *)postURL
          success:(void (^)(ReaderPost *post))success
          failure:(void (^)(NSError *error))failure;

/**
 Silently refresh posts for the followed sites topic.
 Note that calling this method creates a new service instance that performs
 all its work on a derived managed object context, and background queue.
 */
- (void)refreshPostsForFollowedTopic;

/**
 Toggle the liked status of the specified post.

 @param post The reader post to like/unlike.
 @param success block called on a successful fetch.
 @param failure block called if there is any error. `error` can be any underlying network error.
 */
- (void)toggleLikedForPost:(ReaderPost *)post
                   success:(void (^)(void))success
                   failure:(void (^)(NSError *error))failure;

/**
 Toggle the following status of the specified post's blog.

 @param post The ReaderPost whose blog should be followed.
 @param success block called on a successful fetch.
 @param failure block called if there is any error. `error` can be any underlying network error.
 */
- (void)toggleFollowingForPost:(ReaderPost *)post
                       success:(void (^)(BOOL follow))success
                       failure:(void (^)(BOOL follow, NSError *error))failure;

/**
 Toggle the saved for later status of the specified post.

 @param post The reader post to like/unlike.
 @param success block called on a successful fetch.
 @param failure block called if there is any error. `error` can be any underlying network error.
 */
- (void)toggleSavedForLaterForPost:(ReaderPost *)post
                           success:(void (^)(void))success
                           failure:(void (^)(NSError *error))failure;

/**
 Toggle the seen status of the specified post.
 
 @param post The reader post to mark seen/unseen.
 @param success block called on a successful fetch.
 @param failure block called if there is any error. `error` can be any underlying network error.
 */
- (void)toggleSeenForPost:(ReaderPost *)post
                  success:(void (^)(void))success
                  failure:(void (^)(NSError *error))failure;

/**
 Deletes all posts that do not belong to a `ReaderAbstractTopic`
 Saves the NSManagedObjectContext.
 */
- (void)deletePostsWithNoTopic;

/**
 Sets the `isSavedForLater` flag to false for all posts.
 */
- (void)clearSavedPostFlags;

/**
 Globally sets the `inUse` flag to false for all posts.
 */
- (void)clearInUseFlags;

/**
 Updates in core data the following status of posts belonging to the specified site & url

 @param following Whether the user is following the site.
 @param siteID The ID of the site
 @siteURL the URL of the site.
 */
- (void)setFollowing:(BOOL)following forPostsFromSiteWithID:(NSNumber *)siteID andURL:(NSString *)siteURL;

/**
 Delete all `ReaderPosts` beyond the max number to be retained.

 The managed object context is not saved.

 @param topic the `ReaderAbstractTopic` to delete posts from.
 */
- (void)deletePostsInExcessOfMaxAllowedForTopic:(ReaderAbstractTopic *)topic;

/**
 Delete posts that are flagged as belonging to a blocked site.

 The managed object context is not saved.
 */
- (void)deletePostsFromBlockedSites;

#pragma mark - Merging and Deletion

/**
 Merge a freshly fetched batch of posts into the existing set of posts for the specified topic.
 Saves the managed object context.

 @param remotePosts An array of RemoteReaderPost objects
 @param date The `before` date posts were requested.
 @param topicObjectID The ObjectID of the ReaderAbstractTopic to assign to the newly created posts.
 @param success block called on a successful fetch which should be performed after merging
 */
- (void)mergePosts:(NSArray *)remotePosts
    rankedLessThan:(NSNumber *)rank
          forTopic:(NSManagedObjectID *)topicObjectID
   deletingEarlier:(BOOL)deleteEarlier
    callingSuccess:(void (^)(NSInteger count, BOOL hasMore))success;

#pragma mark Internal

@property (readwrite, assign) BOOL isSilentlyFetchingPosts;

- (WordPressComRestApi *)apiForRequest;
- (NSUInteger)numberToSyncForTopic:(ReaderAbstractTopic *)topic;
- (void)updateTopic:(NSManagedObjectID *)topicObjectID withAlgorithm:(NSString *)algorithm;
- (BOOL)canLoadMorePostsForTopic:(ReaderAbstractTopic * _Nonnull)readerTopic remotePosts:(NSArray * _Nonnull)remotePosts inContext: (NSManagedObjectContext * _Nonnull)context;

@end

#pragma clang diagnostic pop // -Wnullability-completeness
