#import "ReaderSiteService.h"

#import "AccountService.h"
#import "CoreDataStack.h"
#import "ReaderPostService.h"
#import "ReaderPost.h"
#import "WPAccount.h"
#import "WordPress-Swift.h"
#import "WPAppAnalytics.h"
@import WordPressKit;

NSString * const ReaderSiteServiceErrorDomain = @"ReaderSiteServiceErrorDomain";

@implementation ReaderSiteService

- (void)followSiteByURL:(NSURL *)siteURL success:(void (^)(void))success failure:(void(^)(NSError *error))failure
{
    WordPressComRestApi *api = [self apiForRequest];
    if (!api) {
        if (failure) {
            failure([self errorForNotLoggedIn]);
        }
        return;
    }

    ReaderSiteServiceRemote *service = [[ReaderSiteServiceRemote alloc] initWithWordPressComRestApi:api];

    // Make sure the URL provided leads to a visible site / does not 404.
    [service checkSiteExistsAtURL:siteURL success:^{
        [self followExistingSiteByURL:siteURL success:success failure:failure];
    } failure:^(NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}

- (void)followSiteWithID:(NSUInteger)siteID success:(void(^)(void))success failure:(void(^)(NSError *error))failure
{
    WordPressComRestApi *api = [self apiForRequest];
    if (!api) {
        if (failure) {
            failure([self errorForNotLoggedIn]);
        }
        return;
    }

    ReaderSiteServiceRemote *service = [[ReaderSiteServiceRemote alloc] initWithWordPressComRestApi:api];
    [service checkSubscribedToSiteByID:siteID success:^(BOOL follows) {
        if (follows) {
            if (failure) {
                failure([self errorForAlreadyFollowingSiteOrFeed]);
            }
            return;
        }
        [service followSiteWithID:siteID success:^(){
            [self fetchTopicServiceWithID:siteID success:success failure:failure];
            NSNumber *blogID = [NSNumber numberWithUnsignedInteger:siteID];
            [WPAnalytics trackReaderStat:WPAnalyticsStatReaderSiteFollowed properties:@{ @"blog_id": blogID }];
        } failure:failure];

    } failure:^(NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}

- (void)unfollowSiteWithID:(NSUInteger)siteID success:(void(^)(void))success failure:(void(^)(NSError *error))failure
{
    WordPressComRestApi *api = [self apiForRequest];
    if (!api) {
        if (failure) {
            failure([self errorForNotLoggedIn]);
        }
        return;
    }

    ReaderSiteServiceRemote *service = [[ReaderSiteServiceRemote alloc] initWithWordPressComRestApi:[self apiForRequest]];
    [service unfollowSiteWithID:siteID success:^(){
        [self markUnfollowedSiteTopicWithSiteID:@(siteID)];
        if (success) {
            success();
        }
        NSNumber *blogID = [NSNumber numberWithUnsignedInteger:siteID];
        [WPAnalytics trackReaderStat:WPAnalyticsStatReaderSiteUnfollowed properties:@{ @"blog_id": blogID }];
        
    } failure:failure];
}

- (void)followSiteAtURL:(NSString *)siteURL success:(void(^)(void))success failure:(void(^)(NSError *error))failure
{
    WordPressComRestApi *api = [self apiForRequest];
    if (!api) {
        if (failure) {
            failure([self errorForNotLoggedIn]);
        }
        return;
    }

    // Include protocol if absent.
    NSString *sanitizedURL = siteURL;
    NSRange rng = [sanitizedURL rangeOfString:@"://"];
    if (rng.location == NSNotFound) {
        sanitizedURL = [NSString stringWithFormat:@"http://%@", sanitizedURL];
    }

    ReaderSiteServiceRemote *service = [[ReaderSiteServiceRemote alloc] initWithWordPressComRestApi:[self apiForRequest]];
    [service checkSubscribedToFeedByURL:[NSURL URLWithString:sanitizedURL] success:^(BOOL follows) {
        if (follows) {
            if (failure) {
                failure([self errorForAlreadyFollowingSiteOrFeed]);
            }
            return;
        }
        [service followSiteAtURL:sanitizedURL success:^(){
            if (success) {
                success();
            }
            [WPAnalytics trackReaderStat:WPAnalyticsStatReaderSiteFollowed properties:@{ @"url":sanitizedURL }];

        } failure:failure];
    } failure:^(NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}

- (void)unfollowSiteAtURL:(NSString *)siteURL success:(void(^)(void))success failure:(void(^)(NSError *error))failure
{
    WordPressComRestApi *api = [self apiForRequest];
    if (!api) {
        if (failure) {
            failure([self errorForNotLoggedIn]);
        }
        return;
    }

    ReaderSiteServiceRemote *service = [[ReaderSiteServiceRemote alloc] initWithWordPressComRestApi:[self apiForRequest]];
    [service unfollowSiteAtURL:siteURL success:^(){
        [self markUnfollowedSiteTopicWithFeedURL:siteURL];
        if (success) {
            success();
        }
        [WPAnalytics trackReaderStat:WPAnalyticsStatReaderSiteUnfollowed properties:@{@"url":siteURL}];
    } failure:failure];
}

- (void)syncPostsForFollowedSites
{
    [self.coreDataStack performAndSaveUsingBlock:^(NSManagedObjectContext *context) {
        ReaderAbstractTopic *followedSites = [ReaderAbstractTopic lookupFollowedSitesTopicInContext:context];
        if (!followedSites) {
            return;
        }

        ReaderPostService *postService = [[ReaderPostService alloc] initWithCoreDataStack:self.coreDataStack];
        [postService fetchPostsForTopic:followedSites earlierThan:[NSDate date] success:nil failure:nil];
    }];
}

- (void)topicWithSiteURL:(NSURL *)siteURL success:(void (^)(ReaderSiteTopic *topic))success failure:(void(^)(NSError *error))failure
{
    WordPressComRestApi *api = [self apiForRequest];
    ReaderSiteServiceRemote *service = [[ReaderSiteServiceRemote alloc] initWithWordPressComRestApi:api];
    
    [service findSiteIDForURL:siteURL success:^(NSUInteger siteID) {
        NSNumber *site = [NSNumber numberWithUnsignedLong:siteID];
        ReaderSiteTopic *topic = [ReaderSiteTopic lookupWithSiteID:site inContext:self.coreDataStack.mainContext];
        success(topic);
    } failure:^(NSError *error) {
        failure(error);
    }];
}

#pragma mark - Private Methods


/**
 Fetch the topic after a site is followed
 */
- (void)fetchTopicServiceWithID:(NSUInteger)siteID success:(void(^)(void))success failure:(void(^)(NSError *error))failure
{
    DDLogInfo(@"Fetch and store followed topic");
    ReaderTopicService *service  = [[ReaderTopicService alloc] initWithCoreDataStack:self.coreDataStack];
    [service siteTopicForSiteWithID:@(siteID)
                             isFeed:false
                            success:^(NSManagedObjectID * __unused objectID, BOOL __unused isFollowing) {
                                if (success) {
                                    success();
                                }
    } failure:failure];
}

/**
 Get the api to use for the request.
 */
- (WordPressComRestApi *)apiForRequest
{
    WordPressComRestApi * __block api = nil;
    [self.coreDataStack.mainContext performBlockAndWait:^{
        WPAccount *defaultAccount = [WPAccount lookupDefaultWordPressComAccountInContext:self.coreDataStack.mainContext];
        api = [defaultAccount wordPressComRestApi];
    }];

    if (![api hasCredentials]) {
        return nil;
    }

    return api;
}

/**
 Called once a URL is confirmed to point at a valid site. Continues the following process.
 */
- (void)followExistingSiteByURL:(NSURL *)siteURL success:(void (^)(void))success failure:(void(^)(NSError *error))failure
{
    WordPressComRestApi *api = [self apiForRequest];
    ReaderSiteServiceRemote *service = [[ReaderSiteServiceRemote alloc] initWithWordPressComRestApi:api];
    [service findSiteIDForURL:siteURL success:^(NSUInteger siteID) {
        if (siteID) {
            [self followSiteWithID:siteID success:success failure:failure];
        } else {
            [self followSiteAtURL:[siteURL absoluteString] success:success failure:failure];
        }
    } failure:^(NSError * __unused error) {
        DDLogInfo(@"Could not find site at URL: %@", siteURL);
        [self followSiteAtURL:[siteURL absoluteString] success:success failure:failure];
    }];
}

- (void)flagPostsFromSite:(NSNumber *)siteID asBlocked:(BOOL)blocked
{
    [self.coreDataStack performAndSaveUsingBlock:^(NSManagedObjectContext *context) {
        [self flagPostsFromSite:siteID asBlocked:blocked inContext:context];
    }];
}

- (void)flagPostsFromSite:(NSNumber *)siteID asBlocked:(BOOL)blocked inContext:(NSManagedObjectContext *)context
{
    NSError *error;
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"ReaderPost"];
    request.predicate = [NSPredicate predicateWithFormat:@"siteID = %@", siteID];
    NSArray *results = [context executeFetchRequest:request error:&error];
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
}

// Updates the site topic's following status in core data only.
- (void)markUnfollowedSiteTopicWithFeedURL:(NSString *)feedURL
{
    [self.coreDataStack performAndSaveUsingBlock:^(NSManagedObjectContext *context) {
        ReaderSiteTopic *topic = [ReaderSiteTopic lookupWithFeedURL:feedURL inContext:context];
        topic.following = NO;
    }];
}

// Updates the site topic's following status in core data only.
- (void)markUnfollowedSiteTopicWithSiteID:(NSNumber *)siteID
{
    [self.coreDataStack performAndSaveUsingBlock:^(NSManagedObjectContext *context) {
        ReaderSiteTopic *topic = [ReaderSiteTopic lookupWithSiteID:siteID inContext:context];
        topic.following = NO;
    }];
}

#pragma mark - Error messages

- (NSError *)errorForNotLoggedIn
{
    NSString *description = NSLocalizedString(@"You must be signed in to a WordPress.com account to perform this action.", @"Error message informing the user that being logged into a WordPress.com account is required.");
    NSDictionary *userInfo = @{NSLocalizedDescriptionKey:description};
    NSError *error = [[NSError alloc] initWithDomain:ReaderSiteServiceErrorDomain code:ReaderSiteServiceErrorNotLoggedIn userInfo:userInfo];
    return error;
}

- (NSError *)errorForAlreadyFollowingSiteOrFeed
{

    NSString *description = NSLocalizedStringWithDefaultValue(@"reader.error.already.subscribed.message",
                                                              nil,
                                                              [NSBundle mainBundle],
                                                              @"You are already subscribed to this blog.",
                                                              @"Error message informing the user that they are already following a blog in their reader.");
    NSDictionary *userInfo = @{NSLocalizedDescriptionKey:description};
    NSError *error = [[NSError alloc] initWithDomain:ReaderSiteServiceErrorDomain code:ReaderSiteServiceErrorAlreadyFollowingSite userInfo:userInfo];
    return error;
}

@end
