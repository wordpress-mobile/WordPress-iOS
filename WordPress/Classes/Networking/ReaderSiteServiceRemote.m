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
        NSDictionary *dict = (NSDictionary *)responseObject;
        NSArray *arr = [dict arrayForKey:@"subscriptions"];
        NSMutableArray *sites = [NSMutableArray array];
        for (NSDictionary *dict in arr) {
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
            NSString *description = NSLocalizedString(@"The URL is missing a valid host.", @"Error message describing a problem with a URL.");
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey:description};
            NSError *error = [[NSError alloc] initWithDomain:ReaderSiteServiceRemoteErrorDomain code:ReaderSiteServiceRemoteInvalidHost userInfo:userInfo];
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
        if (![host hasPrefix:@"www."]) {
            failureBlock(operation, error);
            return;
        }
        // If the provided host includes a www. prefix, try again without it.
        NSString *newHost = [host substringFromIndex:4];
        NSString *newPath = [NSString stringWithFormat:@"sites/%@", newHost];
        [self.api GET:newPath parameters:nil success:successBlock failure:failureBlock];
    }];
}


- (RemoteReaderSite *)normalizeSiteDictionary:(NSDictionary *)dict
{
    NSDictionary *meta = [dict dictionaryForKeyPath:@"meta.data.site"];
    if (!meta) {
        meta = [dict dictionaryForKeyPath:@"meta.data.feed"];
    }

    RemoteReaderSite *site = [[RemoteReaderSite alloc] init];
    site.recordID = [dict numberForKey:@"ID"];
    site.path = [dict stringForKey:@"URL"]; // Retrive from the parent dictionary due to a bug in the REST API that returns NULL in the feed dictionary in some cases.
    site.siteID = [meta numberForKey:@"ID"];
    site.feedID = [meta numberForKey:@"feed_ID"];
    site.name = [meta stringForKey:@"name"];
    if ([site.name length] == 0) {
        site.name = site.path;
    }
    site.icon = [meta stringForKeyPath:@"icon.img"];

    return site;
}


@end
