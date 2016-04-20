#import "ReaderPostService.h"

#import "AccountService.h"
#import "ContextManager.h"
#import "DateUtils.h"
#import "NSString+Helpers.h"
#import "NSString+XMLExtensions.h"
#import "ReaderGapMarker.h"
#import "ReaderPost.h"
#import "ReaderPostServiceRemote.h"
#import "ReaderSiteService.h"
#import "RemoteReaderPost.h"
#import "RemoteSourcePostAttribution.h"
#import "SourcePostAttribution.h"
#import "WordPressComApi.h"
#import "WPAccount.h"
#import "WordPress-Swift.h"
#import "WPAppAnalytics.h"

NSUInteger const ReaderPostServiceNumberToSync = 40;
NSUInteger const ReaderPostServiceTitleLength = 30;
NSUInteger const ReaderPostServiceMaxPosts = 300;
NSString * const ReaderPostServiceErrorDomain = @"ReaderPostServiceErrorDomain";

static NSString * const ReaderPostGlobalIDKey = @"globalID";
static NSString * const SourceAttributionSiteTaxonomy = @"site-pick";
static NSString * const SourceAttributionImageTaxonomy = @"image-pick";
static NSString * const SourceAttributionQuoteTaxonomy = @"quote-pick";
static NSString * const SourceAttributionStandardTaxonomy = @"standard-pick";

@implementation ReaderPostService

#pragma mark - Fetch Methods

- (void)fetchPostsForTopic:(ReaderAbstractTopic *)topic
                   success:(void (^)(NSInteger count, BOOL hasMore))success
                   failure:(void (^)(NSError *error))failure
{
    [self fetchPostsForTopic:topic earlierThan:[NSDate date] success:success failure:failure];
}

- (void)fetchPostsForTopic:(ReaderAbstractTopic *)topic
               earlierThan:(NSDate *)date
                   success:(void (^)(NSInteger count, BOOL hasMore))success
                   failure:(void (^)(NSError *error))failure
{

    [self fetchPostsForTopic:topic earlierThan:date deletingEarlier:NO success:success failure:failure];
}

- (void)fetchPostsForTopic:(ReaderAbstractTopic *)topic
               earlierThan:(NSDate *)date
           deletingEarlier:(BOOL)deleteEarlier
                   success:(void (^)(NSInteger count, BOOL hasMore))success
                   failure:(void (^)(NSError *error))failure
{
    NSManagedObjectID *topicObjectID = topic.objectID;
    ReaderPostServiceRemote *remoteService = [[ReaderPostServiceRemote alloc] initWithApi:[self apiForRequest]];
    [remoteService fetchPostsFromEndpoint:[NSURL URLWithString:topic.path]
                                    count:ReaderPostServiceNumberToSync
                                   before:date
                                  success:^(NSArray *posts) {

                                      [self mergePosts:posts
                                           earlierThan:date
                                              forTopic:topicObjectID
                                       deletingEarlier:deleteEarlier
                                        callingSuccess:success];

                                  } failure:^(NSError *error) {
                                      if (failure) {
                                          failure(error);
                                      }
                                  }];
}

- (void)fetchPost:(NSUInteger)postID forSite:(NSUInteger)siteID success:(void (^)(ReaderPost *post))success failure:(void (^)(NSError *error))failure
{
    ReaderPostServiceRemote *remoteService = [[ReaderPostServiceRemote alloc] initWithApi:[self apiForRequest]];
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


#pragma mark - Update Methods

- (void)toggleLikedForPost:(ReaderPost *)post success:(void (^)())success failure:(void (^)(NSError *error))failure
{
    [self.managedObjectContext performBlock:^{

        // Get a the post in our own context
        NSError *error;
        ReaderPost *readerPost = (ReaderPost *)[self.managedObjectContext existingObjectWithID:post.objectID error:&error];
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (failure) {
                    failure(error);
                }
            });
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
        [[ContextManager sharedInstance] saveContext:self.managedObjectContext];


        // Define success block.
        NSNumber *postID = readerPost.postID;
        NSNumber *siteID = readerPost.siteID;
        void (^successBlock)() = ^void() {
            if (postID && siteID) {
                NSDictionary *properties = @{
                                              WPAppAnalyticsKeyPostID: postID,
                                              WPAppAnalyticsKeyBlogID: siteID
                                              };
                if (like) {
                    [WPAppAnalytics track:WPAnalyticsStatReaderArticleLiked withProperties:properties];
                } else {
                    [WPAppAnalytics track:WPAnalyticsStatReaderArticleUnliked withProperties:properties];
                }
            }
            if (success) {
                success();
            }
        };

        // Define failure block. Make sure rollback happens in the moc's queue,
        void (^failureBlock)(NSError *error) = ^void(NSError *error) {
            [self.managedObjectContext performBlockAndWait:^{
                // Revert changes on failure
                readerPost.isLiked = oldValue;
                readerPost.likeCount = oldCount;

                [[ContextManager sharedInstance] saveContext:self.managedObjectContext withCompletionBlock:^{
                    if (failure) {
                        failure(error);
                    }
                }];
            }];
        };

        // Call the remote service.
        ReaderPostServiceRemote *remoteService = [[ReaderPostServiceRemote alloc] initWithApi:[self apiForRequest]];
        if (like) {
            [remoteService likePost:[readerPost.postID integerValue] forSite:[readerPost.siteID integerValue] success:successBlock failure:failureBlock];
        } else {
            [remoteService unlikePost:[readerPost.postID integerValue] forSite:[readerPost.siteID integerValue] success:successBlock failure:failureBlock];
        }

    }];
}

- (void)setFollowing:(BOOL)following
  forWPComSiteWithID:(NSNumber *)siteID
              andURL:(NSString *)siteURL
             success:(void (^)())success
             failure:(void (^)(NSError *error))failure
{
    // Optimistically Update
    [self setFollowing:following forPostsFromSiteWithID:siteID andURL:siteURL];

    // Define success block
    void (^successBlock)() = ^void() {
        if (success) {
            success();
        }
    };

    // Define failure block
    void (^failureBlock)(NSError *error) = ^void(NSError *error) {
        // Revert changes on failure
        [self setFollowing:!following forPostsFromSiteWithID:siteID andURL:siteURL];

        if (failure) {
            failure(error);
        }
    };

    ReaderSiteService *siteService = [[ReaderSiteService alloc] initWithManagedObjectContext:self.managedObjectContext];
    if (following) {
        [siteService followSiteWithID:[siteID integerValue] success:successBlock failure:failureBlock];
    } else {
        [siteService unfollowSiteWithID:[siteID integerValue] success:successBlock failure:failureBlock];
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

- (void)deletePostsWithSiteID:(NSNumber *)siteID andSiteURL:(NSString *)siteURL fromTopic:(ReaderAbstractTopic *)topic
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

- (NSUInteger)numberOfPostsForTopic:(ReaderAbstractTopic *)topic
{
    NSError *error;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"ReaderPost"];
    fetchRequest.includesSubentities = NO; // Exclude gap markers when counting.
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"topic = %@", topic];
    [fetchRequest setPredicate:pred];

    NSUInteger count = [self.managedObjectContext countForFetchRequest:fetchRequest error:&error];
    return count;
}

#pragma mark - Backfill Processing Methods

/**
 Retrieve the newest post for the specified topic

 @param topicObjectID The `NSManagedObjectID` of the ReaderAbstractTopic for the post
 @return The newest post in Core Data for the topic, or nil.
 */
- (ReaderPost *)newestPostForTopic:(NSManagedObjectID *)topicObjectID
{
    NSError *error;
    ReaderAbstractTopic *topic = (ReaderAbstractTopic *)[self.managedObjectContext existingObjectWithID:topicObjectID error:&error];
    if (error) {
        DDLogError(@"%@, error fetching topic from NSManagedObjectID : %@", NSStringFromSelector(_cmd), error);
        return nil;
    }
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"ReaderPost"];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"topic = %@", topic];
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
       earlierThan:(NSDate *)date
          forTopic:(NSManagedObjectID *)topicObjectID
   deletingEarlier:(BOOL)deleteEarlier
    callingSuccess:(void (^)(NSInteger count, BOOL hasMore))success
{
    // Use a performBlock here so the work to merge does not block the main thread.
    [self.managedObjectContext performBlock:^{

        if (self.managedObjectContext.parentContext == [[ContextManager sharedInstance] mainContext]) {
            // Its possible the ReaderAbstractTopic was deleted the parent main context.
            // If so, and we merge and save, it will cause a crash.
            // Reset the context so it will be current with its parent context.
            [self.managedObjectContext reset];
        }

        NSError *error;
        ReaderAbstractTopic *readerTopic = (ReaderAbstractTopic *)[self.managedObjectContext existingObjectWithID:topicObjectID error:&error];
        if (error || !readerTopic) {
            // if there was an error or the topic was deleted just bail.
            if (success) {
                success(0, NO);
            }
            return;
        }

        NSUInteger postsCount = [remotePosts count];
        if (postsCount == 0) {
            [self deletePostsEarlierThan:date forTopic:readerTopic];

        } else {
            NSArray *posts = remotePosts;
            BOOL overlap = NO;

            if (!deleteEarlier) {
                // Before processing the new posts, check if there is an overlap between
                // what is currently cached, and what is being synced.
                NSSet *existingGlobalIDs = [self globalIDsOfExistingPostsForTopic:readerTopic];
                NSSet *newGlobalIDs = [self globalIDsOfRemotePosts:posts];
                overlap = [existingGlobalIDs intersectsSet:newGlobalIDs];

                // A strategy to avoid false positives in gap detection is to sync
                // one extra post. Only remove the extra post if we received a
                // full set of results. A partial set means we've reached
                // the end of syncable content.
                if ([posts count] == ReaderPostServiceNumberToSync) {
                    posts = [posts subarrayWithRange:NSMakeRange(0, [posts count] - 2)];
                    postsCount = [posts count];
                }
            }

            // Create or update the synced posts.
            NSMutableArray *newPosts = [self makeNewPostsFromRemotePosts:posts forTopic:readerTopic];

            // When refreshing, some content previously synced may have been deleted remotely.
            // Remove anything we've synced that is missing.
            // NOTE that this approach leaves the possibility for older posts to not be cleaned up.
            [self deletePostsForTopic:readerTopic missingFromBatch:newPosts withStartingDate:date];

            // If deleting earlier, delete every post older than the last post in this batch.
            if (deleteEarlier) {
                ReaderPost *lastPost = [newPosts lastObject];
                [self deletePostsEarlierThan:lastPost.sortDate forTopic:readerTopic];
                [self removeGapMarkerForTopic:readerTopic]; // Paranoia

            } else {

                // Handle an overlap in posts that were synced
                if (overlap) {
                    [self removeGapMarkerForTopic:readerTopic ifNewPostsOverlapMarker:newPosts];

                } else {
                    // If there are existing posts older than the oldest of the
                    // new posts then append a gap placeholder to the end of the
                    // new posts
                    ReaderPost *lastPost = [newPosts lastObject];
                    if ([self topic:readerTopic hasPostsOlderThan:lastPost.sortDate]) {
                        [self insertGapMarkerBeforePost:lastPost forTopic:readerTopic];
                    }
                }
            }
        }

        // Clean up
        [self deletePostsInExcessOfMaxAllowedForTopic:readerTopic];
        [self deletePostsFromBlockedSites];

        BOOL hasMore = ((postsCount > 0 ) && ([self numberOfPostsForTopic:readerTopic] < ReaderPostServiceMaxPosts));
        [[ContextManager sharedInstance] saveContext:self.managedObjectContext withCompletionBlock:^{
            // Is called on main queue
            if (success) {
                success(postsCount, hasMore);
            }
        }];
    }];
}


#pragma mark Gap Detection Methods

- (void)removeGapMarkerForTopic:(ReaderAbstractTopic *)topic ifNewPostsOverlapMarker:(NSArray *)newPosts
{
    ReaderGapMarker *gapMarker = [self gapMarkerForTopic:topic];
    if (gapMarker) {
        NSDate *newestPostDate = ((ReaderPost *)newPosts.firstObject).sortDate;
        NSDate *oldestPostDate = ((ReaderPost *)newPosts.lastObject).sortDate;
        NSDate *gapDate = gapMarker.sortDate;
        // Confirm the overlap includes the gap marker.
        if (gapDate == [newestPostDate earlierDate:gapDate] && gapDate == [oldestPostDate laterDate:gapDate]) {
            // No need for a gap placeholder. Remove any that existed
            [self removeGapMarkerForTopic:topic];
        }
    }
}

- (ReaderGapMarker *)gapMarkerForTopic:(ReaderAbstractTopic *)topic
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([ReaderGapMarker class])];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"topic = %@", topic];

    NSError *error;
    NSArray *results = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (error) {
        DDLogError(error.localizedDescription);
        return nil;
    }

    // Assume there will ever only be one and return the first result.
    return results.firstObject;
}

- (void)insertGapMarkerBeforePost:(ReaderPost *)post forTopic:(ReaderAbstractTopic *)topic
{
    [self removeGapMarkerForTopic:topic];

    ReaderGapMarker *marker = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([ReaderGapMarker class])
                                                            inManagedObjectContext:self.managedObjectContext];

    // Synced posts do not use millisecond precision for their dates. We can take
    // advantage of this and make our marker post a fraction of a second earlier
    // than the last post.
    // We'll store the unmodifed sort date as date_create_gmt so we have a convenient
    // and accurate date reference should we need it.
    marker.sortDate = [post.sortDate dateByAddingTimeInterval:-0.1];
    marker.date_created_gmt = post.sortDate;
    marker.topic = topic;
}


- (void)removeGapMarkerForTopic:(ReaderAbstractTopic *)topic
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([ReaderGapMarker class])];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"topic = %@", topic];

    NSError *error;
    NSArray *results = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (error) {
        DDLogError(error.localizedDescription);
        return;
    }

    // There should only ever be one, but loop over all results just in case.
    for (ReaderGapMarker *marker in results) {
        [self.managedObjectContext deleteObject:marker];
    }
}

- (BOOL)topic:(ReaderAbstractTopic *)topic hasPostsOlderThan:(NSDate *)date
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([ReaderPost class])];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"topic = %@ AND sortDate < %@", topic, date];

    NSError *error;
    NSInteger count = [self.managedObjectContext countForFetchRequest:fetchRequest error:&error];
    if (error) {
        DDLogError(error.localizedDescription);
        return NO;
    }
    return (count > 0);
}

- (NSSet *)globalIDsOfRemotePosts:(NSArray *)remotePosts
{
    NSMutableArray *arr = [NSMutableArray array];
    for (RemoteReaderPost *post in remotePosts) {
        [arr addObject:post.globalID];
    }
    // return non-mutable array
    return [NSSet setWithArray:arr];
}

- (NSSet *)globalIDsOfExistingPostsForTopic:(ReaderAbstractTopic *)topic
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([ReaderPost class])];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"topic = %@", topic];
    fetchRequest.includesSubentities = NO;

    NSError *error;
    NSArray *results = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (error) {
        DDLogError(error.localizedDescription);
        return [NSSet set];
    }

    NSMutableArray *arr = [NSMutableArray array];
    for (ReaderPost *post in results) {
        NSString *globalID = post.globalID ?: @"";
        [arr addObject:globalID];
    }
    // return non-mutable array
    return [NSSet setWithArray:arr];
}


#pragma mark Deletion and Clean up

/**
 Deletes any existing post whose sortDate is earlier than the passed date. This
 is to handle situations where posts have been synced but were subsequently removed
 from the result set (deleted, unliked, etc.) rendering the result set empty.

 @param date The date to delete posts earlier than.
 @param topic The `ReaderAbstractTopic` to delete posts from.
 */
- (void)deletePostsEarlierThan:(NSDate *)date forTopic:(ReaderAbstractTopic *)topic
{
    // Don't trust the relationships on the topic to be current or correct.
    NSError *error;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"ReaderPost"];

    NSPredicate *pred = [NSPredicate predicateWithFormat:@"topic = %@ AND sortDate < %@", topic, date];

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

 @param topic The ReaderAbstractTopic to delete posts from.
 @param posts The batch of posts to use as a filter.
 @param startingDate The starting date of the batch of posts. May be earlier than the earliest post in the batch.
 */
- (void)deletePostsForTopic:(ReaderAbstractTopic *)topic missingFromBatch:(NSArray *)posts withStartingDate:(NSDate *)startingDate
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

 @param topic the `ReaderAbstractTopic` to delete posts from.
 */
- (void)deletePostsInExcessOfMaxAllowedForTopic:(ReaderAbstractTopic *)topic
{
    // Don't trust the relationships on the topic to be current or correct.
    NSError *error;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"ReaderPost"];

    NSPredicate *pred = [NSPredicate predicateWithFormat:@"topic = %@", topic];
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

    // If the last remaining post is a gap marker, remove it.
    ReaderPost *lastPost = [posts objectAtIndex:ReaderPostServiceMaxPosts - 1];
    if ([lastPost isKindOfClass:[ReaderGapMarker class]]) {
        [self.managedObjectContext deleteObject:lastPost];
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


#pragma mark Entity Creation

/**
 Accepts an array of `RemoteReaderPost` objects and creates model objects
 for each one.

 @param posts An array of `RemoteReaderPost` objects.
 @param topic The `ReaderAbsractTopic` to assign to the created posts.
 @return An array of `ReaderPost` objects
 */
- (NSMutableArray *)makeNewPostsFromRemotePosts:(NSArray *)posts forTopic:(ReaderAbstractTopic *)topic
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
 @param topic The `ReaderAbstractTopic` to assign to the created post.
 @return A `ReaderPost` model object whose properties are populated with the values from the passed dictionary.
 */
- (ReaderPost *)createOrReplaceFromRemotePost:(RemoteReaderPost *)remotePost forTopic:(ReaderAbstractTopic *)topic
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
    post.siteIconURL = remotePost.siteIconURL;
    post.blogName = [self makePlainText:remotePost.blogName];
    post.blogDescription = [self makePlainText:remotePost.blogDescription];
    post.blogURL = remotePost.blogURL;
    post.commentCount = remotePost.commentCount;
    post.commentsOpen = remotePost.commentsOpen;
    post.content = [self formatContent:remotePost.content];
    post.date_created_gmt = [DateUtils dateFromISOString:remotePost.date_created_gmt];
    post.featuredImage = remotePost.featuredImage;
    post.feedID = remotePost.feedID;
    post.feedItemID = remotePost.feedItemID;
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

    if (remotePost.crossPostMeta) {
        if (!post.crossPostMeta) {
            ReaderCrossPostMeta *meta = (ReaderCrossPostMeta *)[NSEntityDescription insertNewObjectForEntityForName:[ReaderCrossPostMeta classNameWithoutNamespaces]
                                                                                     inManagedObjectContext:self.managedObjectContext];
            post.crossPostMeta = meta;
        }
        post.crossPostMeta.siteURL = remotePost.crossPostMeta.siteURL;
        post.crossPostMeta.postURL = remotePost.crossPostMeta.postURL;
        post.crossPostMeta.commentURL = remotePost.crossPostMeta.commentURL;
        post.crossPostMeta.siteID = remotePost.crossPostMeta.siteID;
        post.crossPostMeta.postID = remotePost.crossPostMeta.postID;
    } else {
        post.crossPostMeta = nil;
    }

    NSString *tag = remotePost.primaryTag;
    NSString *slug = remotePost.primaryTagSlug;
    if ([topic isKindOfClass:[ReaderTagTopic class]]) {
        ReaderTagTopic *tagTopic = (ReaderTagTopic *)topic;
        if ([tagTopic.slug isEqualToString:remotePost.primaryTagSlug]) {
            tag = remotePost.secondaryTag;
            slug = remotePost.secondaryTagSlug;
        }
    }
    post.primaryTag = tag;
    post.primaryTagSlug = slug;

    post.isExternal = remotePost.isExternal;
    post.isJetpack = remotePost.isJetpack;
    post.wordCount = remotePost.wordCount;
    post.readingTime = remotePost.readingTime;

    if (remotePost.sourceAttribution) {
        post.sourceAttribution = [self createOrReplaceFromRemoteDiscoverAttribution:remotePost.sourceAttribution forPost:post];
    } else {
        post.sourceAttribution = nil;
    }

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

- (SourcePostAttribution *)createOrReplaceFromRemoteDiscoverAttribution:(RemoteSourcePostAttribution *)remoteAttribution
                                                                forPost:(ReaderPost *)post
{
    SourcePostAttribution *attribution = post.sourceAttribution;

    if (!attribution) {
        attribution = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([SourcePostAttribution class])
                                             inManagedObjectContext:self.managedObjectContext];
    }
    attribution.authorName = remoteAttribution.authorName;
    attribution.authorURL = remoteAttribution.authorURL;
    attribution.avatarURL = remoteAttribution.avatarURL;
    attribution.blogName = remoteAttribution.blogName;
    attribution.blogURL = remoteAttribution.blogURL;
    attribution.permalink = remoteAttribution.permalink;
    attribution.blogID = remoteAttribution.blogID;
    attribution.postID = remoteAttribution.postID;
    attribution.commentCount = remoteAttribution.commentCount;
    attribution.likeCount = remoteAttribution.likeCount;
    attribution.attributionType = [self attributionTypeFromTaxonomies:remoteAttribution.taxonomies];
    return attribution;
}

- (NSString *)attributionTypeFromTaxonomies:(NSArray *)taxonomies
{
    if ([taxonomies containsObject:SourceAttributionSiteTaxonomy]) {
        return SourcePostAttributionTypeSite;
    }

    if ([taxonomies containsObject:SourceAttributionImageTaxonomy] ||
        [taxonomies containsObject:SourceAttributionQuoteTaxonomy] ||
        [taxonomies containsObject:SourceAttributionStandardTaxonomy] ) {
        return SourcePostAttributionTypePost;
    }

    return nil;
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
