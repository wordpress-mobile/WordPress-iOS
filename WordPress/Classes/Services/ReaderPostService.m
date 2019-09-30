#import "ReaderPostService.h"

#import "AccountService.h"
#import "ContextManager.h"
#import "ReaderGapMarker.h"
#import "ReaderPost.h"
#import "ReaderSiteService.h"
#import "SourcePostAttribution.h"
#import "WPAccount.h"
#import "WPAppAnalytics.h"
#import <WordPressShared/NSString+XMLExtensions.h>
#import "WordPress-Swift.h"
@import WordPressKit;
@import WordPressShared;

NSUInteger const ReaderPostServiceNumberToSync = 40;
// NOTE: The search endpoint is currently capped to max results of 20 and returns
// a 500 error if more are requested.
// For performance reasons, request fewer results. EJ 2016-05-13
NSUInteger const ReaderPostServiceNumberToSyncForSearch = 10;
NSUInteger const ReaderPostServiceMaxSearchPosts = 200;
NSUInteger const ReaderPostServiceMaxPosts = 300;
NSString * const ReaderPostServiceErrorDomain = @"ReaderPostServiceErrorDomain";
NSString * const ReaderPostServiceToggleSiteFollowingState = @"ReaderPostServiceToggleSiteFollowingState";

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
                  atOffset:(NSUInteger)offset
           deletingEarlier:(BOOL)deleteEarlier
                   success:(void (^)(NSInteger count, BOOL hasMore))success
                   failure:(void (^)(NSError *error))failure
{
    NSNumber *rank = @([[NSDate date] timeIntervalSinceReferenceDate]);
    if (offset > 0) {
        rank = [self rankForPostAtOffset:offset - 1 forTopic:topic];
    }

    if (offset >= ReaderPostServiceMaxSearchPosts && [topic isKindOfClass:[ReaderSearchTopic class]]) {
        // A search supports a max offset of 199. If more are requested we want to bail early.
        success(0, NO);
        return;
    }

    // Don't pass the algorithm if at the start of the results
    NSString *reqAlgorithm = offset == 0 ? nil : topic.algorithm;

    NSManagedObjectID *topicObjectID = topic.objectID;
    ReaderPostServiceRemote *remoteService = [[ReaderPostServiceRemote alloc] initWithWordPressComRestApi:[self apiForRequest]];
    [remoteService fetchPostsFromEndpoint:[NSURL URLWithString:topic.path]
                                algorithm:reqAlgorithm
                                    count:[self numberToSyncForTopic:topic]
                                   offset:offset
                                  success:^(NSArray<RemoteReaderPost *> *posts, NSString *algorithm) {
                                      [self updateTopic:topicObjectID withAlgorithm:algorithm];

                                      [self mergePosts:posts
                                        rankedLessThan:rank
                                              forTopic:topicObjectID
                                       deletingEarlier:deleteEarlier
                                        callingSuccess:success];

                                  }
                                  failure:^(NSError *error) {
                                      if (failure) {
                                          failure(error);
                                      }
                                  }];
}


- (void)updateTopic:(NSManagedObjectID *)topicObjectID withAlgorithm:(NSString *)algorithm
{
    [self.managedObjectContext performBlock:^{
        NSError *error;
        ReaderAbstractTopic *topic = (ReaderAbstractTopic *)[self.managedObjectContext existingObjectWithID:topicObjectID error:&error];
        topic.algorithm = algorithm;

        [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
    }];
}


- (void)fetchPostsForTopic:(ReaderAbstractTopic *)topic
               earlierThan:(NSDate *)date
           deletingEarlier:(BOOL)deleteEarlier
                   success:(void (^)(NSInteger count, BOOL hasMore))success
                   failure:(void (^)(NSError *error))failure
{
    // Don't pass the algorithm if fetching a brand new list.
    // When fetching the beginning of a date ordered list the date passed is "now".
    // If the passed date is equal to the current date we know we're starting from scratch.
    NSString *reqAlgorithm = [date isEqualToDate:[NSDate date]] ? nil : topic.algorithm;

    NSManagedObjectID *topicObjectID = topic.objectID;
    ReaderPostServiceRemote *remoteService = [[ReaderPostServiceRemote alloc] initWithWordPressComRestApi:[self apiForRequest]];
    [remoteService fetchPostsFromEndpoint:[NSURL URLWithString:topic.path]
                                algorithm:reqAlgorithm
                                    count:[self numberToSyncForTopic:topic]
                                   before:date
                                  success:^(NSArray *posts, NSString *algorithm) {
                                      [self updateTopic:topicObjectID withAlgorithm:algorithm];

                                      // Construct a rank from the date provided
                                      NSNumber *rank = @([date timeIntervalSinceReferenceDate]);
                                      [self mergePosts:posts
                                        rankedLessThan:rank
                                              forTopic:topicObjectID
                                       deletingEarlier:deleteEarlier
                                        callingSuccess:success];

                                  }
                                  failure:^(NSError *error) {
                                      if (failure) {
                                          failure(error);
                                      }
                                  }];
}

- (void)fetchPost:(NSUInteger)postID forSite:(NSUInteger)siteID isFeed:(BOOL)isFeed success:(void (^)(ReaderPost *post))success failure:(void (^)(NSError *error))failure
{
    ReaderPostServiceRemote *remoteService = [[ReaderPostServiceRemote alloc] initWithWordPressComRestApi:[self apiForRequest]];
    [remoteService fetchPost:postID fromSite:siteID isFeed:isFeed success:^(RemoteReaderPost *remotePost) {
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

- (void)fetchPostAtURL:(NSURL *)postURL
               success:(void (^)(ReaderPost *post))success
               failure:(void (^)(NSError *error))failure
{
    ReaderPostServiceRemote *remoteService = [[ReaderPostServiceRemote alloc] initWithWordPressComRestApi:[self apiForRequest]];
    [remoteService fetchPostAtURL:postURL
                          success:^(RemoteReaderPost *remotePost) {
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

- (void)refreshPostsForFollowedTopic
{
    // Do all of this work on a background thread.
    NSManagedObjectContext *context = [[ContextManager sharedInstance] newDerivedContext];
    ReaderTopicService *topicService = [[ReaderTopicService alloc] initWithManagedObjectContext:context];
    [context performBlock:^{
        ReaderAbstractTopic *topic = [topicService topicForFollowedSites];
        if (topic) {
            ReaderPostService *service = [[ReaderPostService alloc] initWithManagedObjectContext:context];
            [service fetchPostsForTopic:topic earlierThan:[NSDate date] deletingEarlier:YES success:nil failure:nil];
        }
    }];
}


#pragma mark - Update Methods

- (void)toggleLikedForPost:(ReaderPost *)post success:(void (^)(void))success failure:(void (^)(NSError *error))failure
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

        NSDictionary *railcar = [readerPost railcarDictionary];
        // Define success block.
        NSNumber *postID = readerPost.postID;
        NSNumber *siteID = readerPost.siteID;
        void (^successBlock)(void) = ^void() {
            if (postID && siteID) {
                NSDictionary *properties = @{
                                              WPAppAnalyticsKeyPostID: postID,
                                              WPAppAnalyticsKeyBlogID: siteID
                                              };
                if (like) {
                    [WPAppAnalytics track:WPAnalyticsStatReaderArticleLiked withProperties:properties];
                    if (railcar) {
                        [WPAppAnalytics trackTrainTracksInteraction:WPAnalyticsStatReaderArticleLiked withProperties:railcar];
                    }
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
        ReaderPostServiceRemote *remoteService = [[ReaderPostServiceRemote alloc] initWithWordPressComRestApi:[self apiForRequest]];
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
             success:(void (^)(void))success
             failure:(void (^)(NSError *error))failure
{
    // Optimistically Update
    [self setFollowing:following forPostsFromSiteWithID:siteID andURL:siteURL];

    // Define success block
    void (^successBlock)(void) = ^void() {
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

- (void)toggleFollowingForPost:(ReaderPost *)post success:(void (^)(void))success failure:(void (^)(NSError *error))failure
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

    ReaderTopicService *topicService = [[ReaderTopicService alloc] initWithManagedObjectContext:self.managedObjectContext];
    // If this post belongs to a site topic, let the topic service do the work.
    if ([readerPost.topic isKindOfClass:[ReaderSiteTopic class]]) {
        ReaderSiteTopic *siteTopic = (ReaderSiteTopic *)readerPost.topic;
        [topicService toggleFollowingForSite:siteTopic success:success failure:failure];
        return;
    }

    // Keep previous values in case of failure
    BOOL oldValue = readerPost.isFollowing;
    BOOL follow = !oldValue;

    // Optimistically update
    readerPost.isFollowing = follow;
    [self setFollowing:follow forPostsFromSiteWithID:post.siteID andURL:post.blogURL];


    // If the post in question belongs to the default followed sites topic, skip refreshing.
    // We don't want to jar the user.
    BOOL shouldRefreshFollowedPosts = post.topic != [topicService topicForFollowedSites];

    // Define success block
    void (^successBlock)(void) = ^void() {
        if (shouldRefreshFollowedPosts) {
            [self refreshPostsForFollowedTopic];
        }
        if (success) {
            success();
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            //Notifiy Settings view controller a site's following state has changed
            [[NSNotificationCenter defaultCenter] postNotificationName:ReaderPostServiceToggleSiteFollowingState object:nil];
        });
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
    if (!post.isExternal) {
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

- (void)toggleSavedForLaterForPost:(ReaderPost *)post
                           success:(void (^)(void))success
                           failure:(void (^)(NSError *error))failure
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

        readerPost.isSavedForLater = !readerPost.isSavedForLater;

        [[ContextManager sharedInstance] saveContext:self.managedObjectContext];

        success();
    }];
}

- (void)deletePostsWithNoTopic
{
    NSError *error;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"ReaderPost"];

    NSPredicate *pred = [NSPredicate predicateWithFormat:@"topic = NULL AND inUse = false"];
    pred = [self predicateIgnoringSavedForLaterPosts:pred];
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

- (void)clearSavedPostFlags
{
    NSError *error;
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"ReaderPost"];
    request.predicate = [NSPredicate predicateWithFormat:@"isSavedForLater = true"];
    NSArray *results = [self.managedObjectContext executeFetchRequest:request error:&error];
    if (error) {
        DDLogError(@"%@, unsaving saved posts: %@", NSStringFromSelector(_cmd), error);
        return;
    }

    for (ReaderPost *post in results) {
        post.isSavedForLater = NO;
    }

    [[ContextManager sharedInstance] saveContextAndWait:self.managedObjectContext];
}

- (void)clearInUseFlags
{
    NSError *error;
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"ReaderPost"];
    request.predicate = [NSPredicate predicateWithFormat:@"inUse = true"];
    NSArray *results = [self.managedObjectContext executeFetchRequest:request error:&error];
    if (error) {
        DDLogError(@"%@, marking posts not in use.: %@", NSStringFromSelector(_cmd), error);
        return;
    }

    for (ReaderPost *post in results) {
        post.inUse = NO;
    }

    [[ContextManager sharedInstance] saveContextAndWait:self.managedObjectContext];
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
    NSPredicate *postsMatching = [NSPredicate predicateWithFormat:@"siteID = %@ AND permaLink LIKE %@ AND topic = %@", siteID, likeSiteURL, topic];
    request.predicate = [self predicateIgnoringSavedForLaterPosts:postsMatching];
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
    NSPredicate *postsMatching = [NSPredicate predicateWithFormat:@"siteID = %@ AND isWPCom = YES", siteID];
    request.predicate = [self predicateIgnoringSavedForLaterPosts:postsMatching];
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
- (WordPressComRestApi *)apiForRequest
{
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:self.managedObjectContext];
    WPAccount *defaultAccount = [accountService defaultWordPressComAccount];
    WordPressComRestApi *api = [defaultAccount wordPressComRestApi];
    if (![api hasCredentials]) {
        api = [WordPressComRestApi defaultApiWithOAuthToken:nil
                                                  userAgent:[WPUserAgent wordPressUserAgent]
                                                  localeKey:[WordPressComRestApi LocaleKeyDefault]];
    }
    return api;
}

- (NSUInteger)numberToSyncForTopic:(ReaderAbstractTopic *)topic
{
    return [topic isKindOfClass:[ReaderSearchTopic class]] ? ReaderPostServiceNumberToSyncForSearch : ReaderPostServiceNumberToSync;
}

- (NSUInteger)maxPostsToSaveForTopic:(ReaderAbstractTopic *)topic
{
    return [topic isKindOfClass:[ReaderSearchTopic class]] ? ReaderPostServiceMaxSearchPosts : ReaderPostServiceMaxPosts;
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

- (NSNumber *)rankForPostAtOffset:(NSUInteger)offset forTopic:(ReaderAbstractTopic *)topic
{
    NSError *error;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"ReaderPost"];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"topic = %@", topic];
    [fetchRequest setPredicate:predicate];

    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"sortRank" ascending:NO];
    [fetchRequest setSortDescriptors:@[sortDescriptor]];

    fetchRequest.fetchOffset = offset;
    fetchRequest.fetchLimit = 1;

    ReaderPost *post = [[self.managedObjectContext executeFetchRequest:fetchRequest error:&error] firstObject];
    if (error || !post) {
        DDLogError(@"Error fetching post at a specific offset.", error);
        return nil;
    }

    return post.sortRank;
}

- (NSPredicate *)predicateIgnoringSavedForLaterPosts:(NSPredicate*)fromPredicate
{
    return [NSCompoundPredicate andPredicateWithSubpredicates:@[fromPredicate, [self notSavedForLaterPredicate]]];
}

- (NSPredicate *)notSavedForLaterPredicate
{
    return [NSPredicate predicateWithFormat:@"isSavedForLater == NO"];
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
    rankedLessThan:(NSNumber *)rank
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
            [self deletePostsRankedLessThan:rank forTopic:readerTopic];

        } else {
            NSArray *posts = remotePosts;
            BOOL overlap = NO;

            if (!deleteEarlier) {
                // Before processing the new posts, check if there is an overlap between
                // what is currently cached, and what is being synced.
                overlap = [self checkIfRemotePosts:posts overlapExistingPostsinTopic:readerTopic];

                // A strategy to avoid false positives in gap detection is to sync
                // one extra post. Only remove the extra post if we received a
                // full set of results. A partial set means we've reached
                // the end of syncable content.
                if ([posts count] == [self numberToSyncForTopic:readerTopic] && ![ReaderHelpers isTopicSearchTopic:readerTopic]) {
                    posts = [posts subarrayWithRange:NSMakeRange(0, [posts count] - 1)];
                    postsCount = [posts count];
                }

            }

            // Create or update the synced posts.
            NSMutableArray *newPosts = [self makeNewPostsFromRemotePosts:posts forTopic:readerTopic];

            // When refreshing, some content previously synced may have been deleted remotely.
            // Remove anything we've synced that is missing.
            // NOTE that this approach leaves the possibility for older posts to not be cleaned up.
            [self deletePostsForTopic:readerTopic missingFromBatch:newPosts withStartingRank:rank];

            // If deleting earlier, delete every post older than the last post in this batch.
            if (deleteEarlier) {
                ReaderPost *lastPost = [newPosts lastObject];
                [self deletePostsRankedLessThan:lastPost.sortRank forTopic:readerTopic];
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
                    if ([self topic:readerTopic hasPostsRankedLessThan:lastPost.sortRank]) {
                        [self insertGapMarkerBeforePost:lastPost forTopic:readerTopic];
                    }
                }
            }
        }

        // Clean up
        [self deletePostsInExcessOfMaxAllowedForTopic:readerTopic];
        [self deletePostsFromBlockedSites];

        BOOL hasMore = NO;
        BOOL spaceAvailable = ([self numberOfPostsForTopic:readerTopic] < [self maxPostsToSaveForTopic:readerTopic]);
        if ([ReaderHelpers isTopicTag:readerTopic]) {
            // For tags, assume there is more content as long as more than zero results are returned.
            hasMore = (postsCount > 0 ) && spaceAvailable;
        } else {
            // For other topics, assume there is more content as long as the number of results requested is returned.
            hasMore = ([remotePosts count] == [self numberToSyncForTopic:readerTopic]) && spaceAvailable;
        }

        [[ContextManager sharedInstance] saveContext:self.managedObjectContext withCompletionBlock:^{
            // Is called on main queue
            if (success) {
                success(postsCount, hasMore);
            }
        }];
    }];
}

- (BOOL)checkIfRemotePosts:(NSArray *)remotePosts overlapExistingPostsinTopic:(ReaderAbstractTopic *)readerTopic
{
    // Get global IDs of new posts to use as part of the predicate.
    NSSet *remoteGlobalIDs = [self globalIDsOfRemotePosts:remotePosts];

    // Fetch matching existing posts.
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([ReaderPost class])];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"topic = %@ AND globalID in %@", readerTopic, remoteGlobalIDs];

    NSError *error;
    NSArray *results = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (error) {
        DDLogError(error.localizedDescription);
        return NO;
    }

    // For each match, check that the dates are the same.  If at least one date is the same then there is an overlap so return true.
    // If the dates are different then the existing cached post will be updated. Don't treat this as overlap.
    for (ReaderPost *post in results) {
        for (RemoteReaderPost *remotePost in remotePosts) {
            if (![remotePost.globalID isEqualToString:post.globalID]) {
                continue;
            }
            if ([post.sortDate isEqualToDate:remotePost.sortDate]) {
                return YES;
            }
        }
    }

    return NO;
}

#pragma mark Gap Detection Methods

- (void)removeGapMarkerForTopic:(ReaderAbstractTopic *)topic ifNewPostsOverlapMarker:(NSArray *)newPosts
{
    ReaderGapMarker *gapMarker = [self gapMarkerForTopic:topic];
    if (gapMarker) {
        double highestRank = [((ReaderPost *)newPosts.firstObject).sortRank doubleValue];
        double lowestRank = [((ReaderPost *)newPosts.lastObject).sortRank doubleValue];
        double gapRank = [gapMarker.sortRank doubleValue];
        // Confirm the overlap includes the gap marker.
        if (lowestRank < gapRank && gapRank < highestRank) {
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

    // For compatability with posts that are sorted by score
    marker.sortRank = @([post.sortRank doubleValue] - CGFLOAT_MIN);
    marker.score = post.score;

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
        DDLogInfo(@"Deleting Gap Marker: %@", marker);
        [self.managedObjectContext deleteObject:marker];
    }
}

- (BOOL)topic:(ReaderAbstractTopic *)topic hasPostsRankedLessThan:(NSNumber *)rank
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([ReaderPost class])];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"topic = %@ AND sortRank < %@", topic, rank];

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


#pragma mark Deletion and Clean up

/**
 Deletes any existing post whose sortRank is less than the passed rank. This
 is to handle situations where posts have been synced but were subsequently removed
 from the result set (deleted, unliked, etc.) rendering the result set empty.

 @param rank The sortRank to delete posts less than.
 @param topic The `ReaderAbstractTopic` to delete posts from.
 */
- (void)deletePostsRankedLessThan:(NSNumber *)rank forTopic:(ReaderAbstractTopic *)topic
{
    // Don't trust the relationships on the topic to be current or correct.
    NSError *error;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"ReaderPost"];

    NSPredicate *pred = [NSPredicate predicateWithFormat:@"topic = %@ AND sortRank < %@", topic, rank];
    [fetchRequest setPredicate:pred];

    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"sortRank" ascending:NO];
    [fetchRequest setSortDescriptors:@[sortDescriptor]];

    NSArray *currentPosts = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (error) {
        DDLogError(@"%@ error fetching posts: %@", NSStringFromSelector(_cmd), error);
        return;
    }

    for (ReaderPost *post in currentPosts) {
        if (post.isSavedForLater) {
            // If the missing post is currently being used or has been saved, just remove its topic.
            post.topic = nil;
        } else {
            DDLogInfo(@"Deleting ReaderPost: %@", post);
            [self.managedObjectContext deleteObject:post];
        }
    }
}

/**
 Using an array of post as a filter, deletes any existing post whose sortRank falls
 within the range of the filter posts, but is not included in the filter posts.

 This let's us remove unliked posts from /read/liked, posts from blogs that are
 unfollowed from /read/following, or posts that were otherwise removed.

 The managed object context is not saved.

 @param topic The ReaderAbstractTopic to delete posts from.
 @param posts The batch of posts to use as a filter.
 @param startingRank The starting rank of the batch of posts. May be less than the highest ranked post in the batch.
 */
- (void)deletePostsForTopic:(ReaderAbstractTopic *)topic missingFromBatch:(NSArray *)posts withStartingRank:(NSNumber *)startingRank
{
    // Don't trust the relationships on the topic to be current or correct.
    NSError *error;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"ReaderPost"];

    NSNumber *highestRank = startingRank;

    NSNumber *lowestRank = ((ReaderPost *)[posts lastObject]).sortRank;
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"topic == %@ AND sortRank > %@ AND sortRank < %@", topic, lowestRank, highestRank];

    [fetchRequest setPredicate:pred];

    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"sortRank" ascending:NO];
    [fetchRequest setSortDescriptors:@[sortDescriptor]];

    NSArray *currentPosts = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (error) {
        DDLogError(@"%@ error fetching posts: %@", NSStringFromSelector(_cmd), error);
        return;
    }

    for (ReaderPost *post in currentPosts) {
        if ([posts containsObject:post]) {
            continue;
        }
        // The post was missing from the batch and needs to be cleaned up.
        if ([self topicShouldBeClearedFor:post]) {
            // If the missing post is currently being used or has been saved, just remove its topic.
            post.topic = nil;
        } else {
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

    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"sortRank" ascending:NO];
    [fetchRequest setSortDescriptors:@[sortDescriptor]];

    NSUInteger maxPosts = [self maxPostsToSaveForTopic:topic];

    // Specifying a fetchOffset to just get the posts in range doesn't seem to work very well.
    // Just perform the fetch and remove the excess.
    NSUInteger count = [self.managedObjectContext countForFetchRequest:fetchRequest error:&error];
    if (count <= maxPosts) {
        return;
    }

    NSArray *posts = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (error) {
        DDLogError(@"%@ error fetching posts: %@", NSStringFromSelector(_cmd), error);
        return;
    }

    NSRange range = NSMakeRange(maxPosts, [posts count] - maxPosts);
    NSArray *postsToDelete = [posts subarrayWithRange:range];
    for (ReaderPost *post in postsToDelete) {
        if ([self topicShouldBeClearedFor:post]) {
            post.topic = nil;
        } else {
            DDLogInfo(@"Deleting ReaderPost: %@", post.postTitle);
            [self.managedObjectContext deleteObject:post];
        }
    }

    // If the last remaining post is a gap marker, remove it.
    ReaderPost *lastPost = [posts objectAtIndex:maxPosts - 1];
    if ([lastPost isKindOfClass:[ReaderGapMarker class]]) {
        DDLogInfo(@"Deleting Last GapMarker: %@", lastPost);
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
        if ([self topicShouldBeClearedFor:post]) {
            // If the missing post is currenty being used just remove its topic.
            post.topic = nil;
        } else {
            DDLogInfo(@"Deleting ReaderPost: %@", post.postTitle);
            [self.managedObjectContext deleteObject:post];
        }
    }
}

- (BOOL)topicShouldBeClearedFor:(ReaderPost *)post
{
    return (post.inUse || post.isSavedForLater);
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
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"globalID = %@ AND (topic = %@ OR topic = NULL)", globalID, topic];
    NSArray *arr = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];

    BOOL existing = false;
    if (error) {
        DDLogError(@"Error fetching an existing reader post. - %@", error);
    } else if ([arr count] > 0) {
        post = (ReaderPost *)[arr objectAtIndex:0];
        existing = YES;
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
    post.blogName = remotePost.blogName;
    post.blogDescription = remotePost.blogDescription;
    post.blogURL = remotePost.blogURL;
    post.commentCount = remotePost.commentCount;
    post.commentsOpen = remotePost.commentsOpen;
    post.content = remotePost.content;
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
    post.postTitle = remotePost.postTitle;
    post.railcar = remotePost.railcar;
    post.score = remotePost.score;
    post.siteID = remotePost.siteID;
    post.sortDate = remotePost.sortDate;

    if (existing && [topic isKindOfClass:[ReaderSearchTopic class]]) {
        // Failsafe.  The `read/search` endpoint might return the same post on
        // more than one page. If this happens preserve the *original* sortRank
        // to avoid content jumping around in the UI.
    } else {
        post.sortRank = remotePost.sortRank;
    }

    post.status = remotePost.status;
    post.summary = remotePost.summary;
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

@end
