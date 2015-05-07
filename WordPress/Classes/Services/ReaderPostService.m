#import "ReaderPostService.h"
#import "ReaderPostServiceRemote.h"
#import "ReaderSiteService.h"
#import "WordPressComApi.h"
#import "ReaderPost.h"
#import "ReaderTopic.h"
#import "RemoteReaderPost.h"
#import "WPAccount.h"
#import "AccountService.h"
#import "DateUtils.h"
#import "ContextManager.h"
#import "NSString+Helpers.h"
#import "NSString+XMLExtensions.h"

NSUInteger const ReaderPostServiceNumberToSync = 20;
NSUInteger const ReaderPostServiceTitleLength = 30;
NSUInteger const ReaderPostServiceMaxPosts = 200;
NSUInteger const ReaderPostServiceMaxBatchesToBackfill = 3;
NSString * const ReaderPostServiceErrorDomain = @"ReaderPostServiceErrorDomain";

/**
 ReaderPostServiceBackfillState A simple state object used to keep track of backfilling posts.
 */
@interface ReaderPostServiceBackfillState : NSObject

@property (nonatomic) NSUInteger backfillBatchNumber;
@property (nonatomic, strong) NSMutableArray *backfilledRemotePosts;
@property (nonatomic, strong) NSDate *backfillDate;
@property (nonatomic) BOOL skippingSave;

@end

@implementation ReaderPostServiceBackfillState
@end

@interface ReaderPostService()

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@end

@implementation ReaderPostService

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)context
{
    self = [super init];
    if (self) {
        _managedObjectContext = context;
    }

    return self;
}

#pragma mark - Fetch Methods

- (void)fetchPostsForTopic:(ReaderTopic *)topic success:(void (^)(NSInteger count, BOOL hasMore))success failure:(void (^)(NSError *error))failure
{
    [self fetchPostsForTopic:topic earlierThan:[NSDate date] success:success failure:failure];
}

- (void)fetchPostsForTopic:(ReaderTopic *)topic earlierThan:(NSDate *)date success:(void (^)(NSInteger count, BOOL hasMore))success failure:(void (^)(NSError *error))failure
{
    [self fetchPostsForTopic:topic earlierThan:date skippingSave:NO success:success failure:failure];
}

- (void)fetchPostsForTopic:(ReaderTopic *)topic earlierThan:(NSDate *)date skippingSave:(BOOL)skippingSave success:(void (^)(NSInteger count, BOOL hasMore))success failure:(void (^)(NSError *error))failure
{
    NSManagedObjectID *topicObjectID = topic.objectID;
    ReaderPostServiceRemote *remoteService = [[ReaderPostServiceRemote alloc] initWithRemoteApi:[self apiForRequest]];
    [remoteService fetchPostsFromEndpoint:[NSURL URLWithString:topic.path]
                                    count:ReaderPostServiceNumberToSync
                                   before:date
                                  success:^(NSArray *posts) {
                                      [self mergePosts:posts earlierThan:date forTopic:topicObjectID skippingSave:skippingSave callingSuccess:success];
                                  } failure:^(NSError *error) {
                                      if (failure) {
                                          failure(error);
                                      }
                                  }];
}

- (void)fetchPost:(NSUInteger)postID forSite:(NSUInteger)siteID success:(void (^)(ReaderPost *post))success failure:(void (^)(NSError *error))failure
{
    ReaderPostServiceRemote *remoteService = [[ReaderPostServiceRemote alloc] initWithRemoteApi:[self apiForRequest]];
    [remoteService fetchPost:postID fromSite:siteID success:^(RemoteReaderPost *remotePost) {
        if (!success) {
            return;
        }

        ReaderPost *post = [self createOrReplaceFromRemotePost:remotePost forTopic:nil];

        NSError *error;
        BOOL obtainedID = [self.managedObjectContext obtainPermanentIDsForObjects:@[post] error:&error];
        if (!obtainedID) {
            DDLogError(@"Error obtaining a permanent ID for post. %@, %@", post, error);
        }

        [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
        success(post);

    } failure:^(NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}

- (void)backfillPostsForTopic:(ReaderTopic *)topic success:(void (^)(NSInteger count, BOOL hasMore))success failure:(void (^)(NSError *error))failure
{
    [self backfillPostsForTopic:topic skippingSave:NO success:success failure:failure];
}

- (void)backfillPostsForTopic:(ReaderTopic *)topic skippingSave:(BOOL)skippingSave success:(void (^)(NSInteger count, BOOL hasMore))success failure:(void (^)(NSError *error))failure
{
    NSManagedObjectID *topicObjectID = topic.objectID;
    ReaderPost *post = [self newestPostForTopic:topicObjectID];
    ReaderPostServiceBackfillState *state = [[ReaderPostServiceBackfillState alloc] init];
    if (post) {
        state.backfillDate = post.sortDate;
    } else {
        state.backfillDate = [NSDate date];
    }
    state.backfillBatchNumber = 0;
    state.backfilledRemotePosts = [NSMutableArray array];
    state.skippingSave = skippingSave;

    [self fetchPostsToBackfillTopic:topicObjectID
                        earlierThan:[NSDate date]
                      backfillState:(ReaderPostServiceBackfillState *)state
                            success:success
                            failure:failure];
}

#pragma mark - Update Methods

- (void)toggleLikedForPost:(ReaderPost *)post success:(void (^)())success failure:(void (^)(NSError *error))failure
{
    // Get a the post in our own context
    NSError *error;
    ReaderPost *readerPost = (ReaderPost *)[self.managedObjectContext existingObjectWithID:post.objectID error:&error];
    if (error) {
        if (failure) {
            failure(error);
        }
        return;
    }

    // Keep previous values in case of failure
    BOOL oldValue = readerPost.isLiked;
    BOOL like = !oldValue;
    NSNumber *oldCount = [readerPost.likeCount copy];

    // Optimistically update
    readerPost.isLiked = like;
    if (like) {
        readerPost.likeCount = @([readerPost.likeCount integerValue] + 1);
    } else {
        readerPost.likeCount = @([readerPost.likeCount integerValue] - 1);
    }
    [self.managedObjectContext performBlockAndWait:^{
        [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
    }];

    // Define success block
    void (^successBlock)() = ^void() {
        if (success) {
            success();
        }
    };

    // Define failure block
    void (^failureBlock)(NSError *error) = ^void(NSError *error) {
        // Revert changes on failure
        readerPost.isLiked = oldValue;
        readerPost.likeCount = oldCount;
        [self.managedObjectContext performBlockAndWait:^{
            [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
        }];
        if (failure) {
            failure(error);
        }
    };

    // Call the remote service
    ReaderPostServiceRemote *remoteService = [[ReaderPostServiceRemote alloc] initWithRemoteApi:[self apiForRequest]];
    if (like) {
        [remoteService likePost:[readerPost.postID integerValue] forSite:[readerPost.siteID integerValue] success:successBlock failure:failureBlock];
    } else {
        [remoteService unlikePost:[readerPost.postID integerValue] forSite:[readerPost.siteID integerValue] success:successBlock failure:failureBlock];
    }
}

- (void)toggleFollowingForPost:(ReaderPost *)post success:(void (^)())success failure:(void (^)(NSError *error))failure
{
    // Get a the post in our own context
    NSError *error;
    ReaderPost *readerPost = (ReaderPost *)[self.managedObjectContext existingObjectWithID:post.objectID error:&error];
    if (error) {
        if (failure) {
            failure(error);
        }
        return;
    }

    // Keep previous values in case of failure
    BOOL oldValue = readerPost.isFollowing;
    BOOL follow = !oldValue;

    // Optimistically update
    readerPost.isFollowing = follow;
    [self setFollowing:follow forPostsFromSiteWithID:post.siteID andURL:post.blogURL];

    // Define success block
    void (^successBlock)() = ^void() {
        if (success) {
            success();
        }
    };

    // Define failure block
    void (^failureBlock)(NSError *error) = ^void(NSError *error) {
        // Revert changes on failure
        readerPost.isFollowing = oldValue;
        [self setFollowing:oldValue forPostsFromSiteWithID:post.siteID andURL:post.blogURL];

        if (failure) {
            failure(error);
        }
    };

    ReaderSiteService *siteService = [[ReaderSiteService alloc] initWithManagedObjectContext:self.managedObjectContext];
    if (post.isWPCom) {
        if (follow) {
            [siteService followSiteWithID:[post.siteID integerValue] success:successBlock failure:failureBlock];
        } else {
            [siteService unfollowSiteWithID:[post.siteID integerValue] success:successBlock failure:failureBlock];
        }
    } else if (post.blogURL) {
        if (follow) {
            [siteService followSiteAtURL:post.blogURL success:successBlock failure:failureBlock];
        } else {
            [siteService unfollowSiteAtURL:post.blogURL success:successBlock failure:failureBlock];
        }
    } else {
        NSString *description = NSLocalizedString(@"Could not toggle Follow: missing blogURL attribute", @"An error description explaining that Follow could not be toggled due to a missing blogURL attribute.");
        NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : description };
        NSError *error = [NSError errorWithDomain:ReaderPostServiceErrorDomain code:0 userInfo:userInfo];
        failureBlock(error);
    }
}

- (void)reblogPost:(ReaderPost *)post toSite:(NSUInteger)siteID note:(NSString *)note success:(void (^)())success failure:(void (^)(NSError *error))failure
{
    // Get a the post in our own context
    NSError *error;
    ReaderPost *readerPost = (ReaderPost *)[self.managedObjectContext existingObjectWithID:post.objectID error:&error];
    if (error) {
        if (failure) {
            failure(error);
        }
        return;
    }

    // Do not reblog a post on a private blog
    if (readerPost.isBlogPrivate) {
        if (failure) {
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey:NSLocalizedString(@"Posts belonging to private blogs may not be reblogged.", @"An error description explaining that posts from private blogs may not be reblogged.")};
            failure([NSError errorWithDomain:ReaderPostServiceErrorDomain code:0 userInfo:userInfo]);
        }
        return;
    }

    // Optimisitically save
    readerPost.isReblogged = YES;
    [self.managedObjectContext performBlockAndWait:^{
        [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
    }];

    // Define failure block
    void (^failureBlock)(NSError *error) = ^void(NSError *error) {
        readerPost.isReblogged = NO;
        [self.managedObjectContext performBlockAndWait:^{
            [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
        }];
        if (failure) {
            failure(error);
        }
    };

    // Define success block
    void (^successBlock)(BOOL isReblogged) = ^void(BOOL isReblogged) {
        if (!isReblogged) {
            // This is a failsafe. If we receive a success from the REST api, and
            // isReblogged is false then either the user has disabled rebloging,
            // or its not a wpcom blog. We shouldn't reach this point but just in case...
            NSString *description = NSLocalizedString(@"Reblogging might not be permitted for this post.", @"An error description explaining that a post could not be reblogged.");
            NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : description };
            NSError *error = [NSError errorWithDomain:ReaderPostServiceErrorDomain code:0 userInfo:userInfo];
            failureBlock(error);
        } else if (success) {
            success();
        }
    };

    ReaderPostServiceRemote *remoteService = [[ReaderPostServiceRemote alloc] initWithRemoteApi:[self apiForRequest]];
    [remoteService reblogPost:[readerPost.postID integerValue]
                     fromSite:[readerPost.siteID integerValue]
                       toSite:siteID
                         note:note
                      success:successBlock
                      failure:failureBlock];
}

- (void)deletePostsWithNoTopic
{
    NSError *error;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"ReaderPost"];

    NSPredicate *pred = [NSPredicate predicateWithFormat:@"topic = NULL"];
    [fetchRequest setPredicate:pred];

    NSArray *arr = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (error) {
        DDLogError(@"%@, error fetching posts belonging to no topic: %@", NSStringFromSelector(_cmd), error);
        return;
    }

    for (ReaderPost *post in arr) {
        DDLogInfo(@"%@, deleting topicless post: %@", NSStringFromSelector(_cmd), post);
        [self.managedObjectContext deleteObject:post];
    }

    [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
}

- (void)setFollowing:(BOOL)following forPostsFromSiteWithID:(NSNumber *)siteID andURL:(NSString *)siteURL
{
    // Fetch all the posts for the specified site ID and update its following status
    NSError *error;
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"ReaderPost"];
    request.predicate = [NSPredicate predicateWithFormat:@"siteID = %@ AND blogURL = %@", siteID, siteURL];
    NSArray *results = [self.managedObjectContext executeFetchRequest:request error:&error];
    if (error) {
        DDLogError(@"%@, error (un)following posts with siteID %@ and URL @%: %@", NSStringFromSelector(_cmd), siteID, siteURL, error);
        return;
    }
    if ([results count] == 0) {
        return;
    }

    for (ReaderPost *post in results) {
        post.isFollowing = following;
    }
    [self.managedObjectContext performBlock:^{
        [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
    }];
}

- (void)deletePostsWithSiteID:(NSNumber *)siteID andSiteURL:(NSString *)siteURL fromTopic:(ReaderTopic *)topic
{
    NSError *error;
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"ReaderPost"];
    NSString *likeSiteURL = [NSString stringWithFormat:@"%@*", siteURL];
    request.predicate = [NSPredicate predicateWithFormat:@"siteID = %@ AND permaLink LIKE %@ AND topic = %@", siteID, likeSiteURL, topic];
    NSArray *results = [self.managedObjectContext executeFetchRequest:request error:&error];
    if (error) {
        DDLogError(@"%@, error (un)following posts with siteID %@ and URL @%: %@", NSStringFromSelector(_cmd), siteID, siteURL, error);
        return;
    }

    if ([results count] == 0) {
        return;
    }

    for (ReaderPost *post in results) {
        [self.managedObjectContext deleteObject:post];
    }

    [self.managedObjectContext performBlockAndWait:^{
        [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
    }];
}

- (void)deletePostsFromSiteWithID:(NSNumber *)siteID
{
    NSError *error;
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"ReaderPost"];
    request.predicate = [NSPredicate predicateWithFormat:@"siteID = %@ AND isWPCom = YES", siteID];
    NSArray *results = [self.managedObjectContext executeFetchRequest:request error:&error];
    if (error) {
        DDLogError(@"%@, error deleting posts belonging to siteID %@: %@", NSStringFromSelector(_cmd), siteID, error);
        return;
    }

    if ([results count] == 0) {
        return;
    }

    for (ReaderPost *post in results) {
        DDLogInfo(@"Deleting post: %@", post);
        [self.managedObjectContext deleteObject:post];
    }

    [self.managedObjectContext performBlockAndWait:^{
        [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
    }];
}

- (void)flagPostsFromSite:(NSNumber *)siteID asBlocked:(BOOL)blocked
{
    NSError *error;
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"ReaderPost"];
    request.predicate = [NSPredicate predicateWithFormat:@"siteID = %@ AND isWPCom = YES", siteID];
    NSArray *results = [self.managedObjectContext executeFetchRequest:request error:&error];
    if (error) {
        DDLogError(@"%@, error deleting posts belonging to siteID %@: %@", NSStringFromSelector(_cmd), siteID, error);
        return;
    }

    if ([results count] == 0) {
        return;
    }

    for (ReaderPost *post in results) {
        post.isSiteBlocked = blocked;
    }

    [self.managedObjectContext performBlockAndWait:^{
        [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
    }];
}


#pragma mark - Private Methods

/**
 Get the api to use for the request.
 */
- (WordPressComApi *)apiForRequest
{
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:self.managedObjectContext];
    WPAccount *defaultAccount = [accountService defaultWordPressComAccount];
    WordPressComApi *api = [defaultAccount restApi];
    if (![api hasCredentials]) {
        api = [WordPressComApi anonymousApi];
    }
    return api;
}

- (NSUInteger)numberOfPostsForTopic:(ReaderTopic *)topic
{
    NSError *error;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"ReaderPost"];

    NSPredicate *pred = [NSPredicate predicateWithFormat:@"topic = %@", topic];
    [fetchRequest setPredicate:pred];

    NSUInteger count = [self.managedObjectContext countForFetchRequest:fetchRequest error:&error];
    return count;
}

#pragma mark - Backfill Processing Methods

/**
 Retrieve the newest post for the specified topic

 @param topicObjectID The `NSManagedObjectID` of the ReaderTopic for the post
 @return The newest post in Core Data for the topic, or nil.
 */
- (ReaderPost *)newestPostForTopic:(NSManagedObjectID *)topicObjectID
{
    NSError *error;
    ReaderTopic *topic = (ReaderTopic *)[self.managedObjectContext existingObjectWithID:topicObjectID error:&error];
    if (error) {
        DDLogError(@"%@, error fetching topic from NSManagedObjectID : %@", NSStringFromSelector(_cmd), error);
        return nil;
    }
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"ReaderPost"];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"topic == %@", topic];
    [fetchRequest setPredicate:pred];
    fetchRequest.fetchLimit = 1;

    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"sortDate" ascending:NO];
    [fetchRequest setSortDescriptors:@[sortDescriptor]];

    ReaderPost *post = (ReaderPost *)[self.managedObjectContext executeFetchRequest:fetchRequest error:&error].firstObject;
    if (error) {
        DDLogError(@"%@, error fetching newest post for topic: %@", NSStringFromSelector(_cmd), error);
        return nil;
    }
    return post;
}

/**
 Private fetch method that is part of the backfill process. This is basically a
 passthrough call to `fetchPostsFromEndpoint:count:before:success:failure:` that
 passes the results to `processBackfillPostsForTopic:posts:success:failure:`.
 This should only be called once the backfill date, array and batch count have
 been initialized as in `fetchPostsToBackfillTopic:success:failure:`.

 @param topicObjectID The NSManagedObjectID of the Topic for which to request posts.
 @param date The date to get posts earlier than.
 @param state The current `ReaderPostServiceBackfillState`
 @param success block called on a successful fetch.
 @param failure block called if there is any error. `error` can be any underlying network error.
 */
- (void)fetchPostsToBackfillTopic:(NSManagedObjectID *)topicObjectID
                      earlierThan:(NSDate *)date
                    backfillState:(ReaderPostServiceBackfillState *)state
                          success:(void (^)(NSInteger count, BOOL hasMore))success
                          failure:(void (^)(NSError *error))failure
{
    NSError *error;
    ReaderTopic *topic = (ReaderTopic *)[self.managedObjectContext existingObjectWithID:topicObjectID error:&error];
    if (error) {
        DDLogError(@"%@, error fetching topic from NSManagedObjectID : %@", NSStringFromSelector(_cmd), error);
        if (failure) {
            failure(error);
            return;
        }
    }

    ReaderPostServiceRemote *remoteService = [[ReaderPostServiceRemote alloc] initWithRemoteApi:[self apiForRequest]];
    [remoteService fetchPostsFromEndpoint:[NSURL URLWithString:topic.path]
                                    count:ReaderPostServiceNumberToSync
                                   before:date
                                  success:^(NSArray *posts) {
                                      [self processBackfillPostsForTopic:topicObjectID posts:posts backfillState:state success:success failure:failure];
                                  } failure:^(NSError *error) {
                                      if (failure) {
                                          failure(error);
                                      }
                                  }];
}

/**
 Processes a batch of backfilled posts.
 When backfilling, the goal is to request up to three batches of post, or until
 a fetched batch includes the newest posts currently in Core Data.

 @param topicObjectID The NSManagedObjectID of the Topic for which to request posts.
 @param posts An array of fetched posts.
 @param state The current `ReaderPostServiceBackfillState`
 @param success block called on a successful fetch.
 @param failure block called if there is any error. `error` can be any underlying network error.
 */
- (void)processBackfillPostsForTopic:(NSManagedObjectID *)topicObjectID
                               posts:(NSArray *)posts
                       backfillState:(ReaderPostServiceBackfillState *)state
                             success:(void (^)(NSInteger count, BOOL hasMore))success
                             failure:(void (^)(NSError *error))failure
{
    state.backfillBatchNumber++;
    [state.backfilledRemotePosts addObjectsFromArray:posts];

    NSDate *oldestDate = [NSDate date];
    if ([state.backfilledRemotePosts count] > 0) {
        RemoteReaderPost *remotePost = [state.backfilledRemotePosts lastObject];
        oldestDate = [DateUtils dateFromISOString:remotePost.sortDate];
    }

    if (state.backfillBatchNumber > ReaderPostServiceMaxBatchesToBackfill || oldestDate == [state.backfillDate earlierDate:oldestDate]) {
        // our work is done
        [self mergePosts:state.backfilledRemotePosts earlierThan:[NSDate date] forTopic:topicObjectID skippingSave:state.skippingSave callingSuccess:success];
    } else {
        [self fetchPostsToBackfillTopic:topicObjectID earlierThan:oldestDate backfillState:state success:success failure:failure];
    }
}

#pragma mark - Merging and Deletion

/**
 Merge a freshly fetched batch of posts into the existing set of posts for the specified topic.
 Saves the managed object context.

 @param posts An array of RemoteReaderPost objects
 @param date The `before` date posts were requested.
 @param topicObjectID The ObjectID of the ReaderTopic to assign to the newly created posts.
 @param success block called on a successful fetch which should be performed after merging
 */
- (void)mergePosts:(NSArray *)posts
       earlierThan:(NSDate *)date
          forTopic:(NSManagedObjectID *)topicObjectID
      skippingSave:(BOOL)skippingSave
    callingSuccess:(void (^)(NSInteger count, BOOL hasMore))success
{
    // Use a performBlock here so the work to merge does not block the main thread.
    [self.managedObjectContext performBlock:^{

        NSError *error;
        ReaderTopic *readerTopic = (ReaderTopic *)[self.managedObjectContext existingObjectWithID:topicObjectID error:&error];
        if (error || !readerTopic) {
            // if there was an error or the topic was deleted just bail.
            if (success) {
                success(0, NO);
            }
            return;
        }

        NSUInteger postsCount = [posts count];
        if (postsCount == 0) {
            [self deletePostsEarlierThan:date forTopic:readerTopic];
        } else {
            NSMutableArray *newPosts = [self makeNewPostsFromRemotePosts:posts forTopic:readerTopic];
            [self deletePostsForTopic:readerTopic missingFromBatch:newPosts withStartingDate:date];
        }
        [self deletePostsInExcessOfMaxAllowedForTopic:readerTopic];
        [self deletePostsFromBlockedSites];
        readerTopic.lastSynced = [NSDate date];

        if (!skippingSave) {
            // performBlockAndWait here so we know our objects are saved before we call success.
            [self.managedObjectContext performBlockAndWait:^{
                [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
            }];
        }
        if (success) {
            BOOL hasMore = ((postsCount > 0 ) && ([self numberOfPostsForTopic:readerTopic] < ReaderPostServiceMaxPosts));
            success(postsCount, hasMore);
        }
    }];
}

/**
 Deletes any existing post whose sortDate is earlier than the passed date. This
 is to handle situations where posts have been synced but were subsequently removed
 from the result set (deleted, unliked, etc.) rendering the result set empty.

 @param date The date to delete posts earlier than.
 @param topic The ReaderTopic to delete posts from.
 */
- (void)deletePostsEarlierThan:(NSDate *)date forTopic:(ReaderTopic *)topic
{
    // Don't trust the relationships on the topic to be current or correct.
    NSError *error;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"ReaderPost"];

    NSPredicate *pred = [NSPredicate predicateWithFormat:@"topic == %@ AND sortDate < %@", topic, date];

    [fetchRequest setPredicate:pred];

    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"sortDate" ascending:NO];
    [fetchRequest setSortDescriptors:@[sortDescriptor]];

    NSArray *currentPosts = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (error) {
        DDLogError(@"%@ error fetching posts: %@", NSStringFromSelector(_cmd), error);
        return;
    }

    for (ReaderPost *post in currentPosts) {
        DDLogInfo(@"Deleting ReaderPost: %@", post);
        [self.managedObjectContext deleteObject:post];
    }
}

/**
 Using an array of post as a filter, deletes any existing post whose sortDate falls
 within the range of the filter posts, but is not included in the filter posts.

 This let's us remove unliked posts from /read/liked, posts from blogs that are
 unfollowed from /read/following, or posts that were otherwise removed.

 The managed object context is not saved.

 @param topic The ReaderTopic to delete posts from.
 @param posts The batch of posts to use as a filter.
 @param startingDate The starting date of the batch of posts. May be earlier than the earliest post in the batch.
 */
- (void)deletePostsForTopic:(ReaderTopic *)topic missingFromBatch:(NSArray *)posts withStartingDate:(NSDate *)startingDate
{
    // Don't trust the relationships on the topic to be current or correct.
    NSError *error;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"ReaderPost"];

    NSDate *newestDate = startingDate;
    NSDate *oldestDate = ((ReaderPost *)[posts lastObject]).sortDate;
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"topic == %@ AND sortDate > %@ AND sortDate < %@", topic, oldestDate, newestDate];

    [fetchRequest setPredicate:pred];

    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"sortDate" ascending:NO];
    [fetchRequest setSortDescriptors:@[sortDescriptor]];

    NSArray *currentPosts = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (error) {
        DDLogError(@"%@ error fetching posts: %@", NSStringFromSelector(_cmd), error);
        return;
    }

    for (ReaderPost *post in currentPosts) {
        if (![posts containsObject:post]) {
            DDLogInfo(@"Deleting ReaderPost: %@", post);
            [self.managedObjectContext deleteObject:post];
        }
    }
}

/**
 Delete all `ReaderPosts` beyond the max number to be retained.

 The managed object context is not saved.

 @param topic the `ReaderTopic` to delete posts from.
 */
- (void)deletePostsInExcessOfMaxAllowedForTopic:(ReaderTopic *)topic
{
    // Don't trust the relationships on the topic to be current or correct.
    NSError *error;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"ReaderPost"];

    NSPredicate *pred = [NSPredicate predicateWithFormat:@"topic == %@", topic];
    [fetchRequest setPredicate:pred];

    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"sortDate" ascending:NO];
    [fetchRequest setSortDescriptors:@[sortDescriptor]];

    // Specifying a fetchOffset to just get the posts in range doesn't seem to work very well.
    // Just perform the fetch and remove the excess.
    NSUInteger count = [self.managedObjectContext countForFetchRequest:fetchRequest error:&error];
    if (count <= ReaderPostServiceMaxPosts) {
        return;
    }

    NSArray *posts = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (error) {
        DDLogError(@"%@ error fetching posts: %@", NSStringFromSelector(_cmd), error);
        return;
    }

    NSRange range = NSMakeRange(ReaderPostServiceMaxPosts, [posts count] - ReaderPostServiceMaxPosts);
    NSArray *postsToDelete = [posts subarrayWithRange:range];
    for (ReaderPost *post in postsToDelete) {
        DDLogInfo(@"Deleting ReaderPost: %@", post.postTitle);
        [self.managedObjectContext deleteObject:post];
    }
}

/**
 Delete posts that are flagged as belonging to a blocked site.
 
 The managed object context is not saved.
 */
- (void)deletePostsFromBlockedSites
{
    NSError *error;
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"ReaderPost"];
    request.predicate = [NSPredicate predicateWithFormat:@"isSiteBlocked = YES"];
    NSArray *results = [self.managedObjectContext executeFetchRequest:request error:&error];
    if (error) {
        DDLogError(@"%@, error deleting deleting posts from blocked sites: %@", NSStringFromSelector(_cmd), error);
        return;
    }

    if ([results count] == 0) {
        return;
    }

    for (ReaderPost *post in results) {
        DDLogInfo(@"Deleting post: %@", post);
        [self.managedObjectContext deleteObject:post];
    }
}

/**
 Accepts an array of `RemoteReaderPost` objects and creates model objects
 for each one.

 @param posts An array of `RemoteReaderPost` objects.
 @param topic The `ReaderTopic` to assign to the created posts.
 @return An array of `ReaderPost` objects
 */
- (NSMutableArray *)makeNewPostsFromRemotePosts:(NSArray *)posts forTopic:(ReaderTopic *)topic
{
    NSMutableArray *newPosts = [NSMutableArray array];
    for (RemoteReaderPost *post in posts) {
        ReaderPost *newPost = [self createOrReplaceFromRemotePost:post forTopic:topic];
        if (newPost != nil) {
            [newPosts addObject:newPost];
        } else {
            DDLogInfo(@"%@ returned a nil post: %@", NSStringFromSelector(_cmd), post);
        }
    }
    return newPosts;
}

/**
 Create a `ReaderPost` model object from the specified dictionary.

 @param dict A `RemoteReaderPost` object.
 @param topic The `ReaderTopic` to assign to the created post.
 @return A `ReaderPost` model object whose properties are populated with the values from the passed dictionary.
 */
- (ReaderPost *)createOrReplaceFromRemotePost:(RemoteReaderPost *)remotePost forTopic:(ReaderTopic *)topic
{
    NSError *error;
    ReaderPost *post;
    NSString *globalID = remotePost.globalID;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"ReaderPost"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"globalID = %@ AND topic = %@", globalID, topic];
    NSArray *arr = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];

    if (error) {
        DDLogError(@"Error fetching an existing reader post. - %@", error);
    } else if ([arr count] > 0) {
        post = (ReaderPost *)[arr objectAtIndex:0];
    } else {
        post = [NSEntityDescription insertNewObjectForEntityForName:@"ReaderPost"
                                             inManagedObjectContext:self.managedObjectContext];
    }

    post.author = remotePost.author;
    post.authorAvatarURL = remotePost.authorAvatarURL;
    post.authorDisplayName = remotePost.authorDisplayName;
    post.authorEmail = remotePost.authorEmail;
    post.authorURL = remotePost.authorURL;
    post.blogName = [self makePlainText:remotePost.blogName];
    post.blogDescription = [self makePlainText:remotePost.blogDescription];
    post.blogURL = remotePost.blogURL;
    post.commentCount = remotePost.commentCount;
    post.commentsOpen = remotePost.commentsOpen;
    post.content = [self formatContent:remotePost.content];
    post.date_created_gmt = [DateUtils dateFromISOString:remotePost.date_created_gmt];
    post.featuredImage = remotePost.featuredImage;
    post.globalID = remotePost.globalID;
    post.isBlogPrivate = remotePost.isBlogPrivate;
    post.isFollowing = remotePost.isFollowing;
    post.isLiked = remotePost.isLiked;
    post.isReblogged = remotePost.isReblogged;
    post.isWPCom = remotePost.isWPCom;
    post.likeCount = remotePost.likeCount;
    post.permaLink = remotePost.permalink;
    post.postID = remotePost.postID;
    post.postTitle = [self makePlainText:remotePost.postTitle];
    post.siteID = remotePost.siteID;
    post.sortDate = [DateUtils dateFromISOString:remotePost.sortDate];
    post.status = remotePost.status;
    post.tags = remotePost.tags;
    post.isSharingEnabled = remotePost.isSharingEnabled;
    post.isLikesEnabled = remotePost.isLikesEnabled;
    post.isSiteBlocked = NO;

    // Construct a summary if necessary.
    NSString *summary = [self formatSummary:remotePost.summary];
    if (!summary) {
        summary = [self createSummaryFromContent:post.content];
    }
    post.summary = summary;

    // Construct a title if necessary.
    if ([post.postTitle length] == 0 && [post.summary length] > 0) {
        post.postTitle = [self titleFromSummary:post.summary];
    }

    // assign the topic last.
    post.topic = topic;

    return post;
}

#pragma mark - Content Formatting and Sanitization

/**
 Formats the post content.
 Removes transforms videopress markup into video tags, strips inline styles and tidys up paragraphs.

 @param content The post content as a string.
 @return The formatted content.
 */
- (NSString *)formatContent:(NSString *)content
{
    if ([self containsVideoPress:content]) {
        content = [self formatVideoPress:content];
    }
    content = [self normalizeParagraphs:content];
    content = [self removeInlineStyles:content];
    content = [content stringByReplacingHTMLEmoticonsWithEmoji];

    return content;
}

/**
 Formats a post's summary.  The excerpts provided by the REST API contain HTML and have some extra content appened to the end.
 HTML is stripped and the extra bit is removed.

 @param string The summary to format.
 @return The formatted summary.
 */
- (NSString *)formatSummary:(NSString *)summary
{
    summary = [self makePlainText:summary];

    NSString *continueReading = NSLocalizedString(@"Continue reading", @"Part of a prompt suggesting that there is more content for the user to read.");
    continueReading = [NSString stringWithFormat:@"%@ →", continueReading];

    NSRange rng = [summary rangeOfString:continueReading options:NSCaseInsensitiveSearch];
    if (rng.location != NSNotFound) {
        summary = [summary substringToIndex:rng.location];
    }

    return summary;
}

/**
 Create a summary for the post based on the post's content.

 @param string The post's content string. This should be the formatted content string.
 @return A summary for the post.
 */
- (NSString *)createSummaryFromContent:(NSString *)string
{
    return [BasePost summaryFromContent:string];
}

/**
 Transforms the specified string to plain text.  HTML markup is removed and HTML entities are decoded.

 @param string The string to transform.
 @return The transformed string.
 */
- (NSString *)makePlainText:(NSString *)string
{
    return [NSString makePlainText:string];
}

/**
 Clean up paragraphs and in an HTML string. Removes duplicate paragraph tags and unnecessary DIVs.

 @param string The string to normalize.
 @return A string with normalized paragraphs.
 */
- (NSString *)normalizeParagraphs:(NSString *)string
{
    if (!string) {
        return @"";
    }

    static NSRegularExpression *regexDivStart;
    static NSRegularExpression *regexDivEnd;
    static NSRegularExpression *regexPStart;
    static NSRegularExpression *regexPEnd;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSError *error;
        regexDivStart = [NSRegularExpression regularExpressionWithPattern:@"<div[^>]*>" options:NSRegularExpressionCaseInsensitive error:&error];
        regexDivEnd = [NSRegularExpression regularExpressionWithPattern:@"</div>" options:NSRegularExpressionCaseInsensitive error:&error];
        regexPStart = [NSRegularExpression regularExpressionWithPattern:@"<p[^>]*>\\s*<p[^>]*>" options:NSRegularExpressionCaseInsensitive error:&error];
        regexPEnd = [NSRegularExpression regularExpressionWithPattern:@"</p>\\s*</p>" options:NSRegularExpressionCaseInsensitive error:&error];
    });

    // Convert div tags to p tags
    string = [regexDivStart stringByReplacingMatchesInString:string options:NSMatchingReportCompletion range:NSMakeRange(0, [string length]) withTemplate:@"<p>"];
    string = [regexDivEnd stringByReplacingMatchesInString:string options:NSMatchingReportCompletion range:NSMakeRange(0, [string length]) withTemplate:@"</p>"];

    // Remove duplicate p tags.
    string = [regexPStart stringByReplacingMatchesInString:string options:NSMatchingReportCompletion range:NSMakeRange(0, [string length]) withTemplate:@"<p>"];
    string = [regexPEnd stringByReplacingMatchesInString:string options:NSMatchingReportCompletion range:NSMakeRange(0, [string length]) withTemplate:@"</p>"];

    return string;
}

/**
 Strip inline styles from the passed HTML sting.

 @param string An HTML string to sanitize.
 @return A string with inline styles removed.
 */
- (NSString *)removeInlineStyles:(NSString *)string
{
    if (!string) {
        return @"";
    }

    static NSRegularExpression *regex;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSError *error;
        regex = [NSRegularExpression regularExpressionWithPattern:@"style=\"[^\"]*\"" options:NSRegularExpressionCaseInsensitive error:&error];
    });

    // Remove inline styles.
    return [regex stringByReplacingMatchesInString:string options:NSMatchingReportCompletion range:NSMakeRange(0, [string length]) withTemplate:@""];
}

/**
 Check the specified string for occurances of videopress videos.

 @param string The string to search.
 @return YES if a match was found, else returns NO.
 */

- (BOOL)containsVideoPress:(NSString *)string
{
    return [string rangeOfString:@"class=\"videopress-placeholder"].location != NSNotFound;
}

/**
 Replace occurances of videopress markup with video tags int he passed HTML string.

 @param string An HTML string.
 @return The HTML string with videopress markup replaced with in image tag.
 */
- (NSString *)formatVideoPress:(NSString *)string
{
    NSMutableString *mstr = [string mutableCopy];

    static NSRegularExpression *regexVideoPress;
    static NSRegularExpression *regexMp4;
    static NSRegularExpression *regexSrc;
    static NSRegularExpression *regexPoster;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSError *error;
        regexVideoPress = [NSRegularExpression regularExpressionWithPattern:@"<div.*class=\"video-player[\\S\\s]+?<div.*class=\"videopress-placeholder[\\s\\S]*?</noscript>" options:NSRegularExpressionCaseInsensitive error:&error];
        regexMp4 = [NSRegularExpression regularExpressionWithPattern:@"mp4[\\s\\S]+?mp4" options:NSRegularExpressionCaseInsensitive error:&error];
        regexSrc = [NSRegularExpression regularExpressionWithPattern:@"http\\S+mp4" options:NSRegularExpressionCaseInsensitive error:&error];
        regexPoster = [NSRegularExpression regularExpressionWithPattern:@"<img.*class=\"videopress-poster[\\s\\S]*?>" options:NSRegularExpressionCaseInsensitive error:&error];
    });

    // Find instances of VideoPress markup.

    NSArray *matches = [regexVideoPress matchesInString:mstr options:NSRegularExpressionCaseInsensitive range:NSMakeRange(0, [mstr length])];
    for (NSTextCheckingResult *match in [matches reverseObjectEnumerator]) {
        // compose videopress string

        // Find the mp4 in the markup.
        NSRange mp4Match = [regexMp4 rangeOfFirstMatchInString:mstr options:NSRegularExpressionCaseInsensitive range:match.range];
        if (mp4Match.location == NSNotFound) {
            DDLogError(@"%@ failed to match mp4 JSON string while formatting video press markup: %@", NSStringFromSelector(_cmd), [mstr substringWithRange:match.range]);
            [mstr replaceCharactersInRange:match.range withString:@""];
            continue;
        }
        NSString *mp4 = [mstr substringWithRange:mp4Match];

        // Get the mp4 url.
        NSRange srcMatch = [regexSrc rangeOfFirstMatchInString:mp4 options:NSRegularExpressionCaseInsensitive range:NSMakeRange(0, [mp4 length])];
        if (srcMatch.location == NSNotFound) {
            DDLogError(@"%@ failed to match mp4 src when formatting video press markup: %@", NSStringFromSelector(_cmd), mp4);
            [mstr replaceCharactersInRange:match.range withString:@""];
            continue;
        }
        NSString *src = [mp4 substringWithRange:srcMatch];
        src = [src stringByReplacingOccurrencesOfString:@"\\/" withString:@"/"];

        NSString *height = @"200"; // default
        NSString *placeholder = @"";
        NSRange posterMatch = [regexPoster rangeOfFirstMatchInString:string options:NSRegularExpressionCaseInsensitive range:NSMakeRange(0, [string length])];
        if (posterMatch.location != NSNotFound) {
            NSString *poster = [string substringWithRange:posterMatch];
            NSString *value = [self parseValueForAttributeNamed:@"height" inElement:poster];
            if (value) {
                height = value;
            }

            value = [self parseValueForAttributeNamed:@"src" inElement:poster];
            if (value) {
                placeholder = value;
            }
        }

        // Compose a video tag to replace the default markup.
        NSString *fmt = @"<video src=\"%@\" controls width=\"100%%\" height=\"%@\" poster=\"%@\"><source src=\"%@\" type=\"video/mp4\"></video>";
        NSString *vid = [NSString stringWithFormat:fmt, src, height, placeholder, src];

        [mstr replaceCharactersInRange:match.range withString:vid];
    }

    return mstr;
}

- (NSString *)parseValueForAttributeNamed:(NSString *)attribute inElement:(NSString *)element
{
    NSString *value = @"";
    NSString *attrStr = [NSString stringWithFormat:@"%@=\"", attribute];
    NSRange attrRange = [element rangeOfString:attrStr];
    if (attrRange.location != NSNotFound) {
        NSInteger location = attrRange.location + attrRange.length;
        NSInteger length = [element length] - location;
        NSRange ending = [element rangeOfString:@"\"" options:NSCaseInsensitiveSearch range:NSMakeRange(location, length)];
        value = [element substringWithRange:NSMakeRange(location, ending.location - location)];
    }
    return value;
}

/**
 Creates a title for the post from the post's summary.

 @param summary The already formatted post summary.
 @return A title for the post that is a snippet of the summary.
 */
- (NSString *)titleFromSummary:(NSString *)summary
{
    return [summary stringByEllipsizingWithMaxLength:ReaderPostServiceTitleLength preserveWords:YES];
}

@end
