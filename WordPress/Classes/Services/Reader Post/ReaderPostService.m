#import "ReaderPostService.h"

#import "AccountService.h"
#import "CoreDataStack.h"
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

NSUInteger const ReaderPostServiceNumberToSync = 7;
// NOTE: The search endpoint is currently capped to max results of 20 and returns
// a 500 error if more are requested.
// For performance reasons, request fewer results. EJ 2016-05-13
NSUInteger const ReaderPostServiceNumberToSyncForSearch = 10;
NSUInteger const ReaderPostServiceMaxSearchPosts = 200;
NSUInteger const ReaderPostServiceMaxPosts = 300;
NSString * const ReaderPostServiceErrorDomain = @"ReaderPostServiceErrorDomain";
NSString * const ReaderPostServiceToggleSiteFollowingState = @"ReaderPostServiceToggleSiteFollowingState";

static NSString * const ReaderPostGlobalIDKey = @"globalID";

@implementation ReaderPostService

#pragma mark - Fetch Methods

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
    NSNumber * __block rank = @([[NSDate date] timeIntervalSinceReferenceDate]);
    if (offset > 0) {
        [self.coreDataStack.mainContext performBlockAndWait:^{
            rank = [self rankForPostAtOffset:offset - 1 forTopic:topic inContext:self.coreDataStack.mainContext];
        }];
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
    [self.coreDataStack performAndSaveUsingBlock:^(NSManagedObjectContext *context) {
        ReaderAbstractTopic *topic = (ReaderAbstractTopic *)[context existingObjectWithID:topicObjectID error:nil];
        topic.algorithm = algorithm;
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

        NSManagedObjectID * __block postObjectID = nil;
        [self.coreDataStack performAndSaveUsingBlock:^(NSManagedObjectContext *context) {
            ReaderPost *post = [self createOrReplaceFromRemotePost:remotePost forTopic:nil inContext:context];

            NSError *error;
            BOOL obtainedID = [context obtainPermanentIDsForObjects:@[post] error:&error];
            if (!obtainedID) {
                DDLogError(@"Error obtaining a permanent ID for post. %@, %@", post, error);
            }
            postObjectID = post.objectID;
        } completion:^{
            success([self.coreDataStack.mainContext existingObjectWithID:postObjectID error:nil]);
        } onQueue:dispatch_get_main_queue()];
    } failure:failure];
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

        NSManagedObjectID * __block postObjectID = nil;
        [self.coreDataStack performAndSaveUsingBlock:^(NSManagedObjectContext *context) {
            ReaderPost *post = [self createOrReplaceFromRemotePost:remotePost forTopic:nil inContext:context];

            NSError *error;
            BOOL obtainedID = [context obtainPermanentIDsForObjects:@[post] error:&error];
            if (!obtainedID) {
                DDLogError(@"Error obtaining a permanent ID for post. %@, %@", post, error);
            }
            postObjectID = post.objectID;
        } completion:^{
            success([self.coreDataStack.mainContext existingObjectWithID:postObjectID error:nil]);
        } onQueue:dispatch_get_main_queue()];
    } failure:failure];
}

- (void)refreshPostsForFollowedTopic
{
    [self.coreDataStack performAndSaveUsingBlock:^(NSManagedObjectContext *context) {
        ReaderAbstractTopic *topic = [ReaderAbstractTopic lookupFollowedSitesTopicInContext:context];
        if (topic) {
            ReaderPostService *service = [[ReaderPostService alloc] initWithCoreDataStack:self.coreDataStack];
            [service fetchPostsForTopic:topic earlierThan:[NSDate date] deletingEarlier:YES success:nil failure:nil];
        }
    }];
}

#pragma mark - Update Methods

- (void)toggleLikedForPost:(ReaderPost *)post success:(void (^)(void))success failure:(void (^)(NSError *error))failure
{
    [self.coreDataStack performAndSaveUsingBlock:^(NSManagedObjectContext *context) {
        // Get a the post in our own context
        NSError *error;
        ReaderPost *readerPost = (ReaderPost *)[context existingObjectWithID:post.objectID error:&error];
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (failure) {
                    failure(error);
                }
            });
            return;
        }

        [self toggleLikedForPost:readerPost inContext:context success:success failure:failure];
    }];
}

- (void)toggleLikedForPost:(ReaderPost *)readerPost inContext:(NSManagedObjectContext *)context success:(void (^)(void))success failure:(void (^)(NSError *error))failure
{
    NSParameterAssert(readerPost.managedObjectContext == context);

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
                [WPAnalytics trackReaderStat:WPAnalyticsStatReaderArticleLiked properties:properties];
                if (railcar) {
                    [WPAnalytics trackReaderStat:WPAnalyticsStatReaderArticleLiked properties:railcar];
                }
            } else {
                [WPAnalytics trackReaderStat:WPAnalyticsStatReaderArticleUnliked properties:properties];
            }
        }
        if (success) {
            success();
        }
    };

    // Define failure block. Make sure rollback happens in the moc's queue,
    void (^failureBlock)(NSError *error) = ^void(NSError *error) {
        [context performBlockAndWait:^{
            // Revert changes on failure
            readerPost.isLiked = oldValue;
            readerPost.likeCount = oldCount;

            [[ContextManager sharedInstance] saveContext:context withCompletionBlock:^{
                if (failure) {
                    failure(error);
                }
            } onQueue:dispatch_get_main_queue()];
        }];
    };

    // Call the remote service.
    ReaderPostServiceRemote *remoteService = [[ReaderPostServiceRemote alloc] initWithWordPressComRestApi:[self apiForRequestInContext:context]];
    if (like) {
        [remoteService likePost:[readerPost.postID integerValue] forSite:[readerPost.siteID integerValue] success:successBlock failure:failureBlock];
    } else {
        [remoteService unlikePost:[readerPost.postID integerValue] forSite:[readerPost.siteID integerValue] success:successBlock failure:failureBlock];
    }
}

- (void)toggleFollowingForPost:(ReaderPost *)post
                       success:(void (^)(BOOL follow))success
                       failure:(void (^)(BOOL follow, NSError *error))failure
{
    [self.coreDataStack performAndSaveUsingBlock:^(NSManagedObjectContext *context) {
        NSError *error;
        ReaderPost *readerPost = (ReaderPost *)[context existingObjectWithID:post.objectID error:&error];
        if (error) {
            if (failure) {
                failure(true, error);
            }
            return;
        }

        [self toggleFollowingForPost:readerPost inContext:context success:success failure:failure];
    }];
}

- (void)toggleFollowingForPost:(ReaderPost *)readerPost
                     inContext:(NSManagedObjectContext *)context
                       success:(void (^)(BOOL follow))success
                       failure:(void (^)(BOOL follow, NSError *error))failure
{
    NSParameterAssert(readerPost.managedObjectContext == context);

    // If this post belongs to a site topic, let the topic service do the work.
    ReaderTopicService *topicService = [[ReaderTopicService alloc] initWithCoreDataStack:self.coreDataStack];

    if ([readerPost.topic isKindOfClass:[ReaderSiteTopic class]]) {
        ReaderSiteTopic *siteTopic = (ReaderSiteTopic *)readerPost.topic;
        [topicService toggleFollowingForSite:siteTopic success:success failure:failure];
        return;
    }

    if (readerPost.feedID) {
        ReaderSiteTopic *feedSiteTopic = [ReaderSiteTopic lookupWithFeedID:readerPost.feedID inContext:context];
        if (feedSiteTopic) {
            [topicService toggleFollowingForSite:feedSiteTopic success:success failure:failure];
            return;
        }
    }


    // Keep previous values in case of failure
    BOOL oldValue = readerPost.isFollowing;
    BOOL follow = !oldValue;

    // Optimistically update
    readerPost.isFollowing = follow;
    [self setFollowing:follow forPostsFromSiteWithID:readerPost.siteID andURL:readerPost.blogURL];


    // If the post in question belongs to the default followed sites topic, skip refreshing.
    // We don't want to jar the user.
    BOOL shouldRefreshFollowedPosts = readerPost.topic != [ReaderAbstractTopic lookupFollowedSitesTopicInContext:context];

    // Define success block
    void (^successBlock)(void) = ^void() {
        
        // Update subscription count
        NSInteger oldSubscriptionCount = [WPAnalytics subscriptionCount];
        NSInteger newSubscriptionCount = follow ? oldSubscriptionCount + 1 : oldSubscriptionCount - 1;
        [WPAnalytics setSubscriptionCount:newSubscriptionCount];
        
        if (shouldRefreshFollowedPosts) {
            [self refreshPostsForFollowedTopic];
        }
        if (success) {
            success(follow);
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            //Notifiy Settings view controller a site's following state has changed
            [[NSNotificationCenter defaultCenter] postNotificationName:ReaderPostServiceToggleSiteFollowingState object:nil];
        });
    };

    // Define failure block
    void (^failureBlock)(NSError *error) = ^void(NSError *error) {
        // Revert changes on failure
        [self setFollowing:oldValue forPostsFromSiteWithID:readerPost.siteID andURL:readerPost.blogURL completion:^{
            if (failure) {
                failure(follow, error);
            }
        }];
    };

    ReaderSiteService *siteService = [[ReaderSiteService alloc] initWithCoreDataStack:self.coreDataStack];
    if (!readerPost.isExternal) {
        if (follow) {
            [siteService followSiteWithID:[readerPost.siteID integerValue] success:successBlock failure:failureBlock];
        } else {
            [siteService unfollowSiteWithID:[readerPost.siteID integerValue] success:successBlock failure:failureBlock];
        }
    } else if (readerPost.blogURL) {
        if (follow) {
            [siteService followSiteAtURL:readerPost.blogURL success:successBlock failure:failureBlock];
        } else {
            [siteService unfollowSiteAtURL:readerPost.blogURL success:successBlock failure:failureBlock];
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
    [self.coreDataStack performAndSaveUsingBlock:^(NSManagedObjectContext *context) {
        // Get a the post in our own context
        NSError *error;
        ReaderPost *readerPost = (ReaderPost *)[context existingObjectWithID:post.objectID error:&error];
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (failure) {
                    failure(error);
                }
            });
            return;
        }

        readerPost.isSavedForLater = !readerPost.isSavedForLater;
    } completion:success onQueue:dispatch_get_main_queue()];
}

- (void)toggleSeenForPost:(ReaderPost *)post
                  success:(void (^)(void))success
                  failure:(void (^)(NSError *error))failure
{
    NSError *error = [self validatePostForSeenToggle: post];
    if (error != nil) {
        if (failure) {
            failure(error);
        }

        return;
    }

    [self.coreDataStack performAndSaveUsingBlock:^(NSManagedObjectContext *context) {
        // Get a the post in our own context
        NSError *error;
        ReaderPost *readerPost = (ReaderPost *)[context existingObjectWithID:post.objectID error:&error];
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (failure) {
                    failure(error);
                }
            });
            return;
        }

        [self toggleSeenForPost:readerPost inContext:context success:success failure:failure];
    }];
}

- (void)toggleSeenForPost:(ReaderPost *)readerPost
                inContext:(NSManagedObjectContext *)context
                  success:(void (^)(void))success
                  failure:(void (^)(NSError *error))failure
{
    NSParameterAssert(readerPost.managedObjectContext == context);

    // Keep previous values in case of failure
    BOOL oldValue = readerPost.isSeen;
    BOOL seen = !oldValue;

    // Optimistically update
    readerPost.isSeen = seen;

    // Define success block.
    void (^successBlock)(void) = ^void() {
        if (success) {
            success();
        }
    };

    // Define failure block. Make sure rollback happens in the managedObjectContext's queue.
    void (^failureBlock)(NSError *error) = ^void(NSError *error) {
        [context performBlockAndWait:^{

            DDLogError(@"Error while toggling post Seen status: %@", error);
            readerPost.isSeen = oldValue;

            [[ContextManager sharedInstance] saveContext:context withCompletionBlock:^{
                if (failure) {
                    failure(error);
                }
            } onQueue:dispatch_get_main_queue()];
        }];
    };

    // Call the remote service.
    ReaderPostServiceRemote *remoteService = [[ReaderPostServiceRemote alloc] initWithWordPressComRestApi:[self apiForRequestInContext:context]];

    if (readerPost.isWPCom) {
        [remoteService markBlogPostSeenWithSeen:seen
                                         blogID:readerPost.siteID
                                         postID:readerPost.postID
                                        success:successBlock failure:failureBlock];
    } else {
        [remoteService markFeedPostSeenWithSeen:seen
                                         feedID:readerPost.feedID
                                     feedItemID:readerPost.feedItemID
                                        success:successBlock failure:failureBlock];
    }
}

- (void)deletePostsWithNoTopic
{
    [self.coreDataStack performAndSaveUsingBlock:^(NSManagedObjectContext *context) {
        NSError *error;
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"ReaderPost"];

        NSPredicate *pred = [NSPredicate predicateWithFormat:@"topic = NULL AND inUse = false"];
        pred = [self predicateIgnoringSavedForLaterPosts:pred];
        [fetchRequest setPredicate:pred];

        NSArray *arr = [context executeFetchRequest:fetchRequest error:&error];
        if (error) {
            DDLogError(@"%@, error fetching posts belonging to no topic: %@", NSStringFromSelector(_cmd), error);
            return;
        }

        for (ReaderPost *post in arr) {
            DDLogInfo(@"%@, deleting topicless post: %@", NSStringFromSelector(_cmd), post);
            [context deleteObject:post];
        }
    }];
}

- (void)clearSavedPostFlags
{
    [self.coreDataStack performAndSaveUsingBlock:^(NSManagedObjectContext *context) {
        NSError *error;
        NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"ReaderPost"];
        request.predicate = [NSPredicate predicateWithFormat:@"isSavedForLater = true"];
        NSArray *results = [context executeFetchRequest:request error:&error];
        if (error) {
            DDLogError(@"%@, unsaving saved posts: %@", NSStringFromSelector(_cmd), error);
            return;
        }

        for (ReaderPost *post in results) {
            post.isSavedForLater = NO;
        }
    }];
}

- (void)clearInUseFlags
{
    [self.coreDataStack performAndSaveUsingBlock:^(NSManagedObjectContext *context) {
        NSError *error;
        NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"ReaderPost"];
        request.predicate = [NSPredicate predicateWithFormat:@"inUse = true"];
        NSArray *results = [context executeFetchRequest:request error:&error];
        if (error) {
            DDLogError(@"%@, marking posts not in use.: %@", NSStringFromSelector(_cmd), error);
            return;
        }

        for (ReaderPost *post in results) {
            post.inUse = NO;
        }
    }];
}

- (void)setFollowing:(BOOL)following forPostsFromSiteWithID:(NSNumber *)siteID andURL:(NSString *)siteURL
{
    [self setFollowing:following forPostsFromSiteWithID:siteID andURL:siteURL completion:nil];
}

- (void)setFollowing:(BOOL)following forPostsFromSiteWithID:(NSNumber *)siteID andURL:(NSString *)siteURL completion:(void (^)(void))completion
{
    [self.coreDataStack performAndSaveUsingBlock:^(NSManagedObjectContext *context) {
        // Fetch all the posts for the specified site ID and update its following status
        NSError *error;
        NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"ReaderPost"];
        request.predicate = [NSPredicate predicateWithFormat:@"siteID = %@ AND blogURL = %@", siteID, siteURL];
        NSArray *results = [context executeFetchRequest:request error:&error];
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
    } completion:completion onQueue:dispatch_get_main_queue()];
}


#pragma mark - Private Methods

/**
 Get the api to use for the request.
 */
- (WordPressComRestApi *)apiForRequest
{
    WordPressComRestApi * __block api = nil;
    [self.coreDataStack.mainContext performBlockAndWait:^{
        api = [self apiForRequestInContext:self.coreDataStack.mainContext];
    }];
    return api;
}

- (WordPressComRestApi *)apiForRequestInContext:(NSManagedObjectContext *)context
{
    WPAccount *defaultAccount = [WPAccount lookupDefaultWordPressComAccountInContext:context];
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

- (NSUInteger)numberOfPostsForTopic:(ReaderAbstractTopic *)topic inContext:(NSManagedObjectContext *)context
{
    NSError *error;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"ReaderPost"];
    fetchRequest.includesSubentities = NO; // Exclude gap markers when counting.
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"topic = %@", topic];
    [fetchRequest setPredicate:pred];

    NSUInteger count = [context countForFetchRequest:fetchRequest error:&error];
    return count;
}

- (NSNumber *)rankForPostAtOffset:(NSUInteger)offset forTopic:(ReaderAbstractTopic *)topic inContext:(NSManagedObjectContext *)context
{
    NSError *error;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"ReaderPost"];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"topic = %@", topic];
    [fetchRequest setPredicate:predicate];

    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"sortRank" ascending:NO];
    [fetchRequest setSortDescriptors:@[sortDescriptor]];

    fetchRequest.fetchOffset = offset;
    fetchRequest.fetchLimit = 1;

    ReaderPost *post = [[context executeFetchRequest:fetchRequest error:&error] firstObject];
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

- (NSError *)validatePostForSeenToggle:(ReaderPost *)post
{
    NSString *description = nil;
    
    if (post.isWPCom && post.postID == nil) {
        DDLogError(@"Could not toggle Seen: missing postID.");
        description = NSLocalizedString(@"Could not toggle Seen: missing postID.", @"An error description explaining that Seen could not be toggled due to a missing postID.");
        
    } else if (!post.isWPCom && post.feedItemID == nil) {
        DDLogError(@"Could not toggle Seen: missing feedItemID.");
        description = NSLocalizedString(@"Could not toggle Seen: missing feedItemID.", @"An error description explaining that Seen could not be toggled due to a missing feedItemID.");
    }
    
    if (description == nil) {
        return nil;
    }
    
    NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : description };
    NSError *error = [NSError errorWithDomain:ReaderPostServiceErrorDomain code:0 userInfo:userInfo];
    return error;
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
    NSUInteger __block postsCount = 0;
    BOOL __block hasMore = NO;

    [self.coreDataStack performAndSaveUsingBlock:^(NSManagedObjectContext *context) {
        NSError *error;
        ReaderAbstractTopic *readerTopic = (ReaderAbstractTopic *)[context existingObjectWithID:topicObjectID error:&error];
        if (error || !readerTopic) {
            // if there was an error or the topic was deleted just bail.
            if (success) {
                success(0, NO);
            }
            return;
        }

        postsCount = [remotePosts count];
        if (postsCount == 0) {
            [self deletePostsRankedLessThan:rank forTopic:readerTopic inContext:context];
        } else {
            NSArray *posts = remotePosts;
            BOOL overlap = NO;

            if (!deleteEarlier) {
                // Before processing the new posts, check if there is an overlap between
                // what is currently cached, and what is being synced.
                overlap = [self checkIfRemotePosts:posts overlapExistingPostsinTopic:readerTopic inContext:context];

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
            NSMutableArray *newPosts = [self makeNewPostsFromRemotePosts:posts forTopic:readerTopic inContext:context];

            // When refreshing, some content previously synced may have been deleted remotely.
            // Remove anything we've synced that is missing.
            // NOTE that this approach leaves the possibility for older posts to not be cleaned up.
            [self deletePostsForTopic:readerTopic missingFromBatch:newPosts withStartingRank:rank inContext:context];

            // If deleting earlier, delete every post older than the last post in this batch.
            if (deleteEarlier) {
                ReaderPost *lastPost = [newPosts lastObject];
                [self deletePostsRankedLessThan:lastPost.sortRank forTopic:readerTopic inContext:context];
                [self removeGapMarkerForTopic:readerTopic inContext:context]; // Paranoia

            } else {

                // Handle an overlap in posts that were synced
                if (overlap) {
                    [self removeGapMarkerForTopic:readerTopic ifNewPostsOverlapMarker:newPosts inContext:context];

                } else {
                    // If there are existing posts older than the oldest of the
                    // new posts then append a gap placeholder to the end of the
                    // new posts
                    ReaderPost *lastPost = [newPosts lastObject];
                    if ([self topic:readerTopic hasPostsRankedLessThan:lastPost.sortRank inContext:context]) {
                        [self insertGapMarkerBeforePost:lastPost forTopic:readerTopic inContext:context];
                    }
                }
            }
        }

        // Clean up
        [self deletePostsInExcessOfMaxAllowedForTopic:readerTopic inContext:context];
        [self deletePostsFromBlockedSitesInContext:context];

        BOOL spaceAvailable = ([self numberOfPostsForTopic:readerTopic inContext:context] < [self maxPostsToSaveForTopic:readerTopic]);
        hasMore = postsCount > 0 && spaceAvailable;
    } completion:^{
        if (success) {
            success(postsCount, hasMore);
        }
    } onQueue:dispatch_get_main_queue()];
}

- (BOOL)checkIfRemotePosts:(NSArray *)remotePosts overlapExistingPostsinTopic:(ReaderAbstractTopic *)readerTopic inContext:(NSManagedObjectContext *)context
{
    // Get global IDs of new posts to use as part of the predicate.
    NSSet *remoteGlobalIDs = [self globalIDsOfRemotePosts:remotePosts];

    // Fetch matching existing posts.
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([ReaderPost class])];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"topic = %@ AND globalID in %@", readerTopic, remoteGlobalIDs];

    NSError *error;
    NSArray *results = [context executeFetchRequest:fetchRequest error:&error];
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

- (void)removeGapMarkerForTopic:(ReaderAbstractTopic *)topic ifNewPostsOverlapMarker:(NSArray *)newPosts inContext:(NSManagedObjectContext *)context
{
    ReaderGapMarker *gapMarker = [self gapMarkerForTopic:topic inContext:context];
    if (gapMarker) {
        double highestRank = [((ReaderPost *)newPosts.firstObject).sortRank doubleValue];
        double lowestRank = [((ReaderPost *)newPosts.lastObject).sortRank doubleValue];
        double gapRank = [gapMarker.sortRank doubleValue];
        // Confirm the overlap includes the gap marker.
        if (lowestRank < gapRank && gapRank < highestRank) {
            // No need for a gap placeholder. Remove any that existed
            [self removeGapMarkerForTopic:topic inContext:context];
        }
    }
}

- (ReaderGapMarker *)gapMarkerForTopic:(ReaderAbstractTopic *)topic inContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([ReaderGapMarker class])];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"topic = %@", topic];

    NSError *error;
    NSArray *results = [context executeFetchRequest:fetchRequest error:&error];
    if (error) {
        DDLogError(error.localizedDescription);
        return nil;
    }

    // Assume there will ever only be one and return the first result.
    return results.firstObject;
}

- (void)insertGapMarkerBeforePost:(ReaderPost *)post forTopic:(ReaderAbstractTopic *)topic inContext:(NSManagedObjectContext *)context
{
    [self removeGapMarkerForTopic:topic inContext:context];

    ReaderGapMarker *marker = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([ReaderGapMarker class])
                                                            inManagedObjectContext:context];

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


- (void)removeGapMarkerForTopic:(ReaderAbstractTopic *)topic inContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([ReaderGapMarker class])];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"topic = %@", topic];

    NSError *error;
    NSArray *results = [context executeFetchRequest:fetchRequest error:&error];
    if (error) {
        DDLogError(error.localizedDescription);
        return;
    }

    // There should only ever be one, but loop over all results just in case.
    for (ReaderGapMarker *marker in results) {
        DDLogInfo(@"Deleting Gap Marker: %@", marker);
        [context deleteObject:marker];
    }
}

- (BOOL)topic:(ReaderAbstractTopic *)topic hasPostsRankedLessThan:(NSNumber *)rank inContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([ReaderPost class])];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"topic = %@ AND sortRank < %@", topic, rank];

    NSError *error;
    NSInteger count = [context countForFetchRequest:fetchRequest error:&error];
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
- (void)deletePostsRankedLessThan:(NSNumber *)rank forTopic:(ReaderAbstractTopic *)topic inContext:(NSManagedObjectContext *)context
{
    // Don't trust the relationships on the topic to be current or correct.
    NSError *error;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"ReaderPost"];

    NSPredicate *pred = [NSPredicate predicateWithFormat:@"topic = %@ AND sortRank < %@", topic, rank];
    [fetchRequest setPredicate:pred];

    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"sortRank" ascending:NO];
    [fetchRequest setSortDescriptors:@[sortDescriptor]];

    NSArray *currentPosts = [context executeFetchRequest:fetchRequest error:&error];
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
            [context deleteObject:post];
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
- (void)deletePostsForTopic:(ReaderAbstractTopic *)topic
           missingFromBatch:(NSArray *)posts
           withStartingRank:(NSNumber *)startingRank
                  inContext:(NSManagedObjectContext *)context
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

    NSArray *currentPosts = [context executeFetchRequest:fetchRequest error:&error];
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
            [context deleteObject:post];
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
    [self.coreDataStack performAndSaveUsingBlock:^(NSManagedObjectContext *context) {
        [self deletePostsInExcessOfMaxAllowedForTopic:topic inContext:context];
    }];
}

- (void)deletePostsInExcessOfMaxAllowedForTopic:(ReaderAbstractTopic *)topic inContext:(NSManagedObjectContext *)context
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
    NSUInteger count = [context countForFetchRequest:fetchRequest error:&error];
    if (count <= maxPosts) {
        return;
    }

    NSArray *posts = [context executeFetchRequest:fetchRequest error:&error];
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
            [context deleteObject:post];
        }
    }

    // If the last remaining post is a gap marker, remove it.
    ReaderPost *lastPost = [posts objectAtIndex:maxPosts - 1];
    if ([lastPost isKindOfClass:[ReaderGapMarker class]]) {
        DDLogInfo(@"Deleting Last GapMarker: %@", lastPost);
        [context deleteObject:lastPost];
    }
}

/**
 Delete posts that are flagged as belonging to a blocked site.
 
 The managed object context is not saved.
 */
- (void)deletePostsFromBlockedSites
{
    [self.coreDataStack performAndSaveUsingBlock:^(NSManagedObjectContext *context) {
        [self deletePostsFromBlockedSitesInContext:context];
    }];
}

- (void)deletePostsFromBlockedSitesInContext:(NSManagedObjectContext *)context
{
    NSError *error;
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"ReaderPost"];
    request.predicate = [NSPredicate predicateWithFormat:@"isSiteBlocked = YES"];
    NSArray *results = [context executeFetchRequest:request error:&error];
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
            [context deleteObject:post];
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
- (NSMutableArray *)makeNewPostsFromRemotePosts:(NSArray *)posts forTopic:(ReaderAbstractTopic *)topic inContext:(NSManagedObjectContext *)context
{
    NSMutableArray *newPosts = [NSMutableArray array];
    for (RemoteReaderPost *post in posts) {
        ReaderPost *newPost = [self createOrReplaceFromRemotePost:post forTopic:topic inContext:context];
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
- (ReaderPost *)createOrReplaceFromRemotePost:(RemoteReaderPost *)remotePost forTopic:(ReaderAbstractTopic *)topic inContext:(NSManagedObjectContext *)context
{
    NSParameterAssert(context != nil);
    NSParameterAssert(topic == nil || topic.managedObjectContext == context);
    return [ReaderPost createOrReplaceFromRemotePost:remotePost forTopic:topic context:context];
}

#pragma mark Internal

- (BOOL)canLoadMorePostsForTopic:(ReaderAbstractTopic * _Nonnull)readerTopic remotePosts:(NSArray * _Nonnull)remotePosts inContext: (NSManagedObjectContext * _Nonnull)context {
    BOOL spaceAvailable = ([self numberOfPostsForTopic:readerTopic inContext:context] < [self maxPostsToSaveForTopic:readerTopic]);
    return [remotePosts count] > 0 && spaceAvailable;
}

@end
