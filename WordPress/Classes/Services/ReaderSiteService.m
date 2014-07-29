#import "ReaderSiteService.h"
#import "ReaderSiteServiceRemote.h"
#import "WordPressComApi.h"
#import "WPAccount.h"
#import "AccountService.h"
#import "ContextManager.h"

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

- (void)fetchFollowedSitesWithSuccess:(void(^)(NSArray *sites))success failure:(void(^)(NSError *error))failure
{
    WordPressComApi *api = [self apiForRequest];
    if (!api) {
        if (failure) {
            failure([self errorForNotLoggedIn]);
        }
        return;
    }

    ReaderSiteServiceRemote *service = [[ReaderSiteServiceRemote alloc] initWithRemoteApi:api];
    [service fetchFollowedSitesWithSuccess:success failure:failure];
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
    [service followSiteWithID:siteID success:success failure:failure];
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

    ReaderSiteServiceRemote *service = [[ReaderSiteServiceRemote alloc] initWithRemoteApi:[self apiForRequest]];
    [service followSiteAtURL:siteURL success:success failure:failure];
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

- (NSError *)errorForNotLoggedIn
{
    NSString *description = NSLocalizedString(@"You must be signed in to a WordPress.com account to perform this action.", @"Error message informing the user that being logged into a WordPress.com account is required.");
    NSDictionary *userInfo = @{NSLocalizedDescriptionKey:description};
    NSError *error = [[NSError alloc] initWithDomain:ReaderSiteServiceErrorDomain code:ReaderSiteServiceNotLoggedInError userInfo:userInfo];
    return error;
}


@end
