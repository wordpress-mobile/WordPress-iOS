#import "ReaderSiteService.h"
#import "ReaderSiteServiceRemote.h"
#import "WordPressComApi.h"
#import "WPAccount.h"
#import "AccountService.h"
#import "ContextManager.h"
#import "ReaderSite.h"
#import "RemoteReaderSite.h"
#import "ReaderTopicService.h"
#import "ReaderPostService.h"
#import "ReaderPost.h"

NSString * const ReaderSiteServiceErrorDomain = @"ReaderSiteServiceErrorDomain";

@interface ReaderSiteService()

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@end

@implementation ReaderSiteService

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)context
{
    self = [super init];
    if (self) {
        _managedObjectContext = context;
    }

    return self;
}

- (void)fetchFollowedSitesWithSuccess:(void(^)())success failure:(void(^)(NSError *error))failure
{
    WordPressComApi *api = [self apiForRequest];
    if (!api) {
        if (failure) {
            failure([self errorForNotLoggedIn]);
        }
        return;
    }

    ReaderSiteServiceRemote *service = [[ReaderSiteServiceRemote alloc] initWithRemoteApi:api];
    [service fetchFollowedSitesWithSuccess:^(NSArray *sites) {
        AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:self.managedObjectContext];
        WPAccount *defaultAccount = [accountService defaultWordPressComAccount];
        [self mergeSites:sites forAccount:defaultAccount];

        if (success) {
            success();
        }
    } failure:^(NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}

- (void)followSiteByURL:(NSURL *)siteURL success:(void (^)())success failure:(void(^)(NSError *error))failure
{
    WordPressComApi *api = [self apiForRequest];
    if (!api) {
        if (failure) {
            failure([self errorForNotLoggedIn]);
        }
        return;
    }

    ReaderSiteServiceRemote *service = [[ReaderSiteServiceRemote alloc] initWithRemoteApi:api];

    // Make sure the URL provided leads to a visible site / does not 404.
    [service checkSiteExistsAtURL:siteURL success:^{
        [self followExistingSiteByURL:siteURL success:success failure:failure];
    } failure:^(NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}

- (void)followSiteWithID:(NSUInteger)siteID success:(void(^)())success failure:(void(^)(NSError *error))failure
{
    WordPressComApi *api = [self apiForRequest];
    if (!api) {
        if (failure) {
            failure([self errorForNotLoggedIn]);
        }
        return;
    }

    ReaderSiteServiceRemote *service = [[ReaderSiteServiceRemote alloc] initWithRemoteApi:api];
    [service checkSubscribedToSiteByID:siteID success:^(BOOL follows) {
        if (follows) {
            if (failure) {
                failure([self errorForAlreadyFollowingSiteOrFeed]);
            }
            return;
        }
        [service followSiteWithID:siteID success:success failure:failure];

    } failure:^(NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}

- (void)unfollowSiteWithID:(NSUInteger)siteID success:(void(^)())success failure:(void(^)(NSError *error))failure
{
    WordPressComApi *api = [self apiForRequest];
    if (!api) {
        if (failure) {
            failure([self errorForNotLoggedIn]);
        }
        return;
    }

    ReaderSiteServiceRemote *service = [[ReaderSiteServiceRemote alloc] initWithRemoteApi:[self apiForRequest]];
    [service unfollowSiteWithID:siteID success:success failure:failure];
}

- (void)followSiteAtURL:(NSString *)siteURL success:(void(^)())success failure:(void(^)(NSError *error))failure
{
    WordPressComApi *api = [self apiForRequest];
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

    ReaderSiteServiceRemote *service = [[ReaderSiteServiceRemote alloc] initWithRemoteApi:[self apiForRequest]];
    [service checkSubscribedToFeedByURL:[NSURL URLWithString:sanitizedURL] success:^(BOOL follows) {
        if (follows) {
            if (failure) {
                failure([self errorForAlreadyFollowingSiteOrFeed]);
            }
            return;
        }
        [service followSiteAtURL:sanitizedURL success:success failure:failure];
    } failure:^(NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}

- (void)unfollowSiteAtURL:(NSString *)siteURL success:(void(^)())success failure:(void(^)(NSError *error))failure
{
    WordPressComApi *api = [self apiForRequest];
    if (!api) {
        if (failure) {
            failure([self errorForNotLoggedIn]);
        }
        return;
    }

    ReaderSiteServiceRemote *service = [[ReaderSiteServiceRemote alloc] initWithRemoteApi:[self apiForRequest]];
    [service unfollowSiteAtURL:siteURL success:success failure:failure];
}

- (void)unfollowSite:(ReaderSite *)site success:(void(^)())success failure:(void(^)(NSError *error))failure
{
    NSString *path = site.path;
    NSUInteger siteID = [site.siteID integerValue];

    // Optimistically delete
    [self deletePostsFromFollowedTopicForSite:site];
    [self.managedObjectContext deleteObject:site];
    [self.managedObjectContext performBlockAndWait:^{
        [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
    }];

    if ([site isFeed]) {
        [self unfollowSiteAtURL:path success:success failure:failure];
    } else {
        [self unfollowSiteWithID:siteID success:success failure:failure];
    }
}

- (void)deletePostsFromFollowedTopicForSite:(ReaderSite *)site
{
    ReaderTopicService *topicService = [[ReaderTopicService alloc] initWithManagedObjectContext:self.managedObjectContext];
    ReaderTopic *followedSites = [topicService topicForFollowedSites];
    if (!followedSites) {
        return;
    }
    NSNumber *siteID = site.siteID;
    if (!siteID) {
        siteID = site.feedID;
    }
    NSManagedObjectContext *context = [[ContextManager sharedInstance] newDerivedContext];
    ReaderPostService *postService = [[ReaderPostService alloc] initWithManagedObjectContext:context];
    [postService deletePostsWithSiteID:siteID andSiteURL:site.path fromTopic:followedSites];
}

- (void)syncPostsForFollowedSites
{
    ReaderTopicService *topicService = [[ReaderTopicService alloc] initWithManagedObjectContext:self.managedObjectContext];
    ReaderTopic *followedSites = [topicService topicForFollowedSites];
    if (!followedSites) {
        return;
    }

    NSManagedObjectContext *context = [[ContextManager sharedInstance] newDerivedContext];
    ReaderPostService *postService = [[ReaderPostService alloc] initWithManagedObjectContext:context];
    [postService fetchPostsForTopic:followedSites earlierThan:[NSDate date] success:nil failure:nil];
}


- (void)flagSiteWithID:(NSNumber *)siteID asBlocked:(BOOL)blocked success:(void(^)())success failure:(void(^)(NSError *error))failure
{
    WordPressComApi *api = [self apiForRequest];
    if (!api) {
        if (failure) {
            failure([self errorForNotLoggedIn]);
        }
        return;
    }

    // Optimistically flag the posts from the site being blocked.
    [self flagPostsFromSite:siteID asBlocked:blocked];

    ReaderSiteServiceRemote *service = [[ReaderSiteServiceRemote alloc] initWithRemoteApi:api];
    [service flagSiteWithID:[siteID integerValue] asBlocked:blocked success:^{
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
- (WordPressComApi *)apiForRequest
{
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:self.managedObjectContext];
    WPAccount *defaultAccount = [accountService defaultWordPressComAccount];
    WordPressComApi *api = [defaultAccount restApi];
    if (![api hasCredentials]) {
        return nil;
    }
    return api;
}

/**
 Called once a URL is confirmed to point at a valid site. Continues the following process.
 */
- (void)followExistingSiteByURL:(NSURL *)siteURL success:(void (^)())success failure:(void(^)(NSError *error))failure
{
    WordPressComApi *api = [self apiForRequest];
    ReaderSiteServiceRemote *service = [[ReaderSiteServiceRemote alloc] initWithRemoteApi:api];
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


/**
 Saves the specified `ReaderSites`. Any `ReaderSites` not included in the passed
 array are removed from Core Data.

 @param sites An array of `ReaderSites` to save.
 @param account The account the sites should belong to.
 */
- (void)mergeSites:(NSArray *)sites forAccount:(WPAccount *)account {
    NSArray *currentSites = [self allSites];
    NSMutableArray *sitesToKeep = [NSMutableArray array];

    for (RemoteReaderSite *remoteSite in sites) {
        ReaderSite *newSite = [self createOrReplaceFromRemoteSite:remoteSite];
        newSite.account = account;
        if (newSite != nil) {
            [sitesToKeep addObject:newSite];
        } else {
            DDLogInfo(@"%@ returned a nil site: %@", NSStringFromSelector(_cmd), remoteSite);
        }
    }

    if ([currentSites count] > 0) {
        for (ReaderSite *site in currentSites) {
            if (![sitesToKeep containsObject:site]) {
                DDLogInfo(@"Deleting ReaderSite: %@", site);
                [self.managedObjectContext deleteObject:site];
            }
        }
    }

    [self.managedObjectContext performBlockAndWait:^{
        [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
    }];
}

/**
 Create a new `ReaderSite` or update an existing `ReaderSite`.

 @param dict A `RemoteReaderSite` object.
 @return A new or updated, but unsaved, `ReaderSite`.
 */
- (ReaderSite *)createOrReplaceFromRemoteSite:(RemoteReaderSite *)remoteSite
{
    NSString *name = remoteSite.name;
    if (name.length == 0) {
        return nil;
    }

    NSString *path = remoteSite.path;
    if (path.length == 0) {
        return nil;
    }

    ReaderSite *site = [self findSiteByRecordID:remoteSite.recordID];
    if (site == nil) {
        site = (ReaderSite *)[NSEntityDescription insertNewObjectForEntityForName:@"ReaderSite"
                                              inManagedObjectContext:self.managedObjectContext];
    }

    site.recordID = remoteSite.recordID;
    site.siteID = remoteSite.siteID;
    site.feedID = remoteSite.feedID;
    site.name = remoteSite.name;
    site.path = remoteSite.path;
    site.icon = remoteSite.icon;
    site.isSubscribed = remoteSite.isSubscribed;

    return site;
}

/**
 Find a specific ReaderSite by its `recordID` property.

 @param recordID The unique, cannonical ID of the site.
 @return A matching `ReaderSite` or nil if there is no match.
 */
- (ReaderSite *)findSiteByRecordID:(NSNumber *)recordID
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"ReaderSite"];
    request.predicate = [NSPredicate predicateWithFormat:@"recordID = %@", recordID];

    NSError *error;
    NSArray *results = [self.managedObjectContext executeFetchRequest:request error:&error];
    if (error) {
        DDLogError(@"%@ error executing fetch request: %@", NSStringFromSelector(_cmd), error);
        return nil;
    }

    ReaderSite *site = (ReaderSite *)[results firstObject];
    return site;
}

/**
 Fetch all `ReaderSites` currently in Core Data.

 @return An array of all `ReaderSites` currently persisted in Core Data.
 */
- (NSArray *)allSites
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"ReaderSite"];

    NSError *error;
    NSArray *results = [self.managedObjectContext executeFetchRequest:request error:&error];
    if (error) {
        DDLogError(@"%@ error executing fetch request: %@", NSStringFromSelector(_cmd), error);
        return @[];
    }

    return results;
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
