#import "ReaderSiteService.h"

#import "AccountService.h"
#import "ContextManager.h"
#import "ReaderPostService.h"
#import "ReaderPost.h"
#import "ReaderTopicService.h"
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
            if (success) {
                success();
            }
            [WPAppAnalytics track:WPAnalyticsStatReaderSiteFollowed withBlogID:[NSNumber numberWithUnsignedInteger:siteID]];

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
        [self unfollowSiteTopicWithSiteID:@(siteID)];
        if (success) {
            success();
        }
        [WPAppAnalytics track:WPAnalyticsStatReaderSiteUnfollowed withBlogID:[NSNumber numberWithUnsignedInteger:siteID]];
        
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
            [WPAppAnalytics track:WPAnalyticsStatReaderSiteFollowed withProperties:@{ @"url":sanitizedURL }];

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
        [self unfollowSiteTopicWithURL:siteURL];
        if (success) {
            success();
        }
        [WPAppAnalytics track:WPAnalyticsStatReaderSiteUnfollowed withProperties:@{@"url":siteURL}];
    } failure:failure];
}

- (void)unfollowSiteTopicWithSiteID:(NSNumber *)siteID
{
    ReaderTopicService *topicService = [[ReaderTopicService alloc] initWithManagedObjectContext:self.managedObjectContext];
    [topicService markUnfollowedSiteTopicWithSiteID:siteID];
}

- (void)unfollowSiteTopicWithURL:(NSString *)siteURL
{
    ReaderTopicService *topicService = [[ReaderTopicService alloc] initWithManagedObjectContext:self.managedObjectContext];
    [topicService markUnfollowedSiteTopicWithFeedURL:siteURL];
}

- (void)syncPostsForFollowedSites
{
    ReaderTopicService *topicService = [[ReaderTopicService alloc] initWithManagedObjectContext:self.managedObjectContext];
    ReaderAbstractTopic *followedSites = [topicService topicForFollowedSites];
    if (!followedSites) {
        return;
    }

    NSManagedObjectContext *context = [[ContextManager sharedInstance] newDerivedContext];
    ReaderPostService *postService = [[ReaderPostService alloc] initWithManagedObjectContext:context];
    [postService fetchPostsForTopic:followedSites earlierThan:[NSDate date] success:nil failure:nil];
}

- (void)flagSiteWithID:(NSNumber *)siteID asBlocked:(BOOL)blocked success:(void(^)(void))success failure:(void(^)(NSError *error))failure
{
    WordPressComRestApi *api = [self apiForRequest];
    if (!api) {
        if (failure) {
            failure([self errorForNotLoggedIn]);
        }
        return;
    }

    // Optimistically flag the posts from the site being blocked.
    [self flagPostsFromSite:siteID asBlocked:blocked];

    ReaderSiteServiceRemote *service = [[ReaderSiteServiceRemote alloc] initWithWordPressComRestApi:api];
    [service flagSiteWithID:[siteID integerValue] asBlocked:blocked success:^{
        NSDictionary *properties = @{WPAppAnalyticsKeyBlogID:siteID};
        [WPAppAnalytics track:WPAnalyticsStatReaderSiteBlocked withProperties:properties];
        
        if (success) {
            success();
        }
    } failure:^(NSError *error) {
        // Undo the changes
        [self flagPostsFromSite:siteID asBlocked:!blocked];

        if (failure) {
            failure(error);
        }
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
    } failure:^(NSError *error) {
        DDLogInfo(@"Could not find site at URL: %@", siteURL);
        [self followSiteAtURL:[siteURL absoluteString] success:success failure:failure];
    }];
}

- (void)flagPostsFromSite:(NSNumber *)siteID asBlocked:(BOOL)blocked
{
    ReaderPostService *service = [[ReaderPostService alloc] initWithManagedObjectContext:self.managedObjectContext];
    [service flagPostsFromSite:siteID asBlocked:blocked];
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
    NSString *description = NSLocalizedString(@"You are already following that site.", @"Error message informing the user that they are already following a site in their reader.");
    NSDictionary *userInfo = @{NSLocalizedDescriptionKey:description};
    NSError *error = [[NSError alloc] initWithDomain:ReaderSiteServiceErrorDomain code:ReaderSiteServiceErrorAlreadyFollowingSite userInfo:userInfo];
    return error;
}

@end
