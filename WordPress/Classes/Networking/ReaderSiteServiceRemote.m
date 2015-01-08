#import "ReaderSiteServiceRemote.h"
#import "WordPressComApi.h"
#import "RemoteReaderSite.h"

NSString * const ReaderSiteServiceRemoteErrorDomain = @"ReaderSiteServiceRemoteErrorDomain";

@interface ReaderSiteServiceRemote ()
@property (nonatomic, strong) WordPressComApi *api;
@end

@implementation ReaderSiteServiceRemote

- (id)initWithRemoteApi:(WordPressComApi *)api {
    self = [super init];
    if (self) {
        _api = api;
    }
    return self;
}

- (void)fetchFollowedSitesWithSuccess:(void(^)(NSArray *sites))success failure:(void(^)(NSError *error))failure
{
    NSString *path = @"read/following/mine?meta=site,feed";

    [self.api GET:path parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (!success) {
            return;
        }
        NSDictionary *response = (NSDictionary *)responseObject;
        NSArray *subscriptions = [response arrayForKey:@"subscriptions"];
        NSMutableArray *sites = [NSMutableArray array];
        for (NSDictionary *dict in subscriptions) {
            RemoteReaderSite *site = [self normalizeSiteDictionary:dict];
            site.isSubscribed = YES;
            [sites addObject:site];
        }
        success(sites);

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}

- (void)followSiteWithID:(NSUInteger)siteID success:(void (^)())success failure:(void(^)(NSError *error))failure
{
    NSString *path = [NSString stringWithFormat:@"sites/%d/follows/new", siteID];
    [self.api POST:path parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            success();
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}

- (void)unfollowSiteWithID:(NSUInteger)siteID success:(void (^)())success failure:(void(^)(NSError *error))failure
{
    NSString *path = [NSString stringWithFormat:@"sites/%d/follows/mine/delete", siteID];
    [self.api POST:path parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            success();
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}

- (void)followSiteAtURL:(NSString *)siteURL success:(void (^)())success failure:(void(^)(NSError *error))failure
{
    NSString *path = [NSString stringWithFormat:@"read/following/mine/new?url=%@", siteURL];
    NSDictionary *params = @{@"url": siteURL};
    [self.api POST:path parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *dict = (NSDictionary *)responseObject;
        BOOL subscribed = [[dict numberForKey:@"subscribed"] boolValue];
        if (!subscribed) {
            if (failure) {
                DDLogError(@"Error following site at url: %@", siteURL);
                NSError *error = [self errorForUnsuccessfulFollowSite];
                failure(error);
            }
            return;
        }
        if (success) {
            success();
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}

- (void)unfollowSiteAtURL:(NSString *)siteURL success:(void (^)())success failure:(void(^)(NSError *error))failure
{
    NSString *path = [NSString stringWithFormat:@"read/following/mine/delete?url=%@", siteURL];
    NSDictionary *params = @{@"url": siteURL};
    [self.api POST:path parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *dict = (NSDictionary *)responseObject;
        BOOL subscribed = [[dict numberForKey:@"subscribed"] boolValue];
        if (subscribed) {
            if (failure) {
                DDLogError(@"Error unfollowing site at url: %@", siteURL);
                NSError *error = [self errorForUnsuccessfulFollowSite];
                failure(error);
            }
            return;
        }
        if (success) {
            success();
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}

- (void)findSiteIDForURL:(NSURL *)siteURL success:(void (^)(NSUInteger siteID))success failure:(void(^)(NSError *error))failure
{
    NSString *host = [siteURL host];
    if (!host) {
        // error;
        if (failure) {
            NSError *error = [self errorForInvalidHost];
            failure(error);
        }
        return;
    }

    // Define success block
    void (^successBlock)(AFHTTPRequestOperation *operation, id responseObject) = ^void(AFHTTPRequestOperation *operation, id responseObject) {
        if (!success) {
            return;
        }
        NSDictionary *dict = (NSDictionary *)responseObject;
        NSUInteger siteID = [[dict numberForKey:@"ID"] integerValue];
        success(siteID);
    };

    // Define failure block
    void (^failureBlock)(AFHTTPRequestOperation *operation, NSError *error) = ^void(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    };

    NSString *path = [NSString stringWithFormat:@"sites/%@", host];
    [self.api GET:path parameters:nil success:successBlock failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSString *newHost;
        if ([host hasPrefix:@"www."]) {
            // If the provided host includes a www. prefix, try again without it.
            newHost = [host substringFromIndex:4];

        } else {
            // If the provided host includes a www. prefix, try again without it.
            newHost = [NSString stringWithFormat:@"www.%@", host];

        }
        NSString *newPath = [NSString stringWithFormat:@"sites/%@", newHost];
        [self.api GET:newPath parameters:nil success:successBlock failure:failureBlock];
    }];
}

- (void)checkSiteExistsAtURL:(NSURL *)siteURL success:(void (^)())success failure:(void(^)(NSError *error))failure
{
    // Just ping the URL and make sure we don't get back a 40x error.
    [self.api HEAD:[siteURL absoluteString] parameters:nil success:^(AFHTTPRequestOperation *operation) {
        if (success) {
            success();
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}

- (void)checkSubscribedToSiteByID:(NSUInteger)siteID success:(void (^)(BOOL follows))success failure:(void(^)(NSError *error))failure
{
    NSString *path = [NSString stringWithFormat:@"sites/%d/follows/mine", siteID];
    [self.api GET:path parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (!success) {
            return;
        }
        NSDictionary *dict = (NSDictionary *)responseObject;
        BOOL follows = [[dict numberForKey:@"is_following"] boolValue];
        success(follows);

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}

- (void)checkSubscribedToFeedByURL:(NSURL *)siteURL success:(void (^)(BOOL follows))success failure:(void(^)(NSError *error))failure
{
    NSString *path = @"read/following/mine";
    [self.api GET:path parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (!success) {
            return;
        }

        BOOL follows = NO;
        NSString *responseString = [[operation responseString] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        if ([responseString rangeOfString:[siteURL absoluteString]].location != NSNotFound) {
            follows = YES;
        }
        success(follows);

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}

- (void)flagSiteWithID:(NSUInteger)siteID asBlocked:(BOOL)blocked success:(void(^)())success failure:(void(^)(NSError *error))failure
{
    NSString *path;
    if (blocked) {
        path = [NSString stringWithFormat:@"me/block/sites/%d/new", siteID];
    } else {
        path = [NSString stringWithFormat:@"me/block/sites/%d/delete", siteID];
    }

    [self.api POST:path parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *dict = (NSDictionary *)responseObject;
        if (![[dict numberForKey:@"success"] boolValue]) {
            if (blocked) {
                failure([self errorForUnsuccessfulBlockSite]);
            } else {
                failure([self errorForUnsuccessfulUnblockSite]);
            }
            return;
        }

        if (success) {
            success();
        }

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}


#pragma mark - Private Methods

- (RemoteReaderSite *)normalizeSiteDictionary:(NSDictionary *)dict
{
    NSDictionary *meta = [dict dictionaryForKeyPath:@"meta.data.site"];
    if (!meta) {
        meta = [dict dictionaryForKeyPath:@"meta.data.feed"];
    }

    RemoteReaderSite *site = [[RemoteReaderSite alloc] init];
    site.recordID = [dict numberForKey:@"ID"];
    site.path = [dict stringForKey:@"URL"]; // Retrieve from the parent dictionary due to a bug in the REST API that returns NULL in the feed dictionary in some cases.
    site.siteID = [meta numberForKey:@"ID"];
    site.feedID = [meta numberForKey:@"feed_ID"];
    site.name = [meta stringForKey:@"name"];
    if ([site.name length] == 0) {
        site.name = site.path;
    }
    site.icon = [meta stringForKeyPath:@"icon.img"];

    return site;
}

- (NSError *)errorForInvalidHost
{
    NSString *description = NSLocalizedString(@"The URL is missing a valid host.", @"Error message describing a problem with a URL.");
    NSDictionary *userInfo = @{NSLocalizedDescriptionKey:description};
    NSError *error = [[NSError alloc] initWithDomain:ReaderSiteServiceRemoteErrorDomain code:ReaderSiteServiceRemoteInvalidHost userInfo:userInfo];
    return error;
}

- (NSError *)errorForUnsuccessfulFollowSite
{
    NSString *description = NSLocalizedString(@"Could not follow the site at the address specified.", @"Error message informing the user that there was a problem subscribing to a site or feed.");
    NSDictionary *userInfo = @{NSLocalizedDescriptionKey:description};
    NSError *error = [[NSError alloc] initWithDomain:ReaderSiteServiceRemoteErrorDomain code:ReaderSiteServiceRemoteUnsuccessfulFollowSite userInfo:userInfo];
    return error;
}

- (NSError *)errorForUnsuccessfulUnfollowSite
{
    NSString *description = NSLocalizedString(@"Could not unfollow the site at the address specified.", @"Error message informing the user that there was a problem unsubscribing to a site or feed.");
    NSDictionary *userInfo = @{NSLocalizedDescriptionKey:description};
    NSError *error = [[NSError alloc] initWithDomain:ReaderSiteServiceRemoteErrorDomain code:ReaderSiteServiceRemoteUnsuccessfulUnfollowSite userInfo:userInfo];
    return error;
}

- (NSError *)errorForUnsuccessfulBlockSite
{
    NSString *description = NSLocalizedString(@"There was a problem blocking posts from the specified site.", @"Error message informing the user that there was a problem blocking posts from a site from their reader.");
    NSDictionary *userInfo = @{NSLocalizedDescriptionKey:description};
    NSError *error = [[NSError alloc] initWithDomain:ReaderSiteServiceRemoteErrorDomain code:ReaderSiteSErviceRemoteUnsuccessfulBlockSite userInfo:userInfo];
    return error;
}

- (NSError *)errorForUnsuccessfulUnblockSite
{
    NSString *description = NSLocalizedString(@"There was a problem removing the block for specified site.", @"Error message informing the user that there was a problem clearing the block on site preventing its posts from displaying in the reader.");
    NSDictionary *userInfo = @{NSLocalizedDescriptionKey:description};
    NSError *error = [[NSError alloc] initWithDomain:ReaderSiteServiceRemoteErrorDomain code:ReaderSiteSErviceRemoteUnsuccessfulBlockSite userInfo:userInfo];
    return error;
}

@end
