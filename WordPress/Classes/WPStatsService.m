#import "WPStatsService.h"
#import "AccountService.h"
#import "BlogService.h"
#import "ContextManager.h"
#import "WPAccount.h"
#import "Blog.h"
#import "WPStatsServiceRemote.h"

@interface WPStatsService ()

@property (nonatomic, strong) NSNumber *siteId;
@property (nonatomic, strong) WPAccount *account;

@end

@implementation WPStatsService
{

}

- (instancetype)initWithSiteId:(NSNumber *)siteId andAccount:(WPAccount *)account {
    self = [super init];
    if (self) {
        _siteId = siteId;
        _account = account;
    }

    return self;
}

- (void)retrieveStatsWithCompletionHandler:(StatsCompletion)completion failureHandler:(void (^)(NSError *error))failureHandler
{
    void (^failure)(NSError *error) = ^void (NSError *error) {
        DDLogError(@"Error while retrieving stats: %@", error);

        if (failureHandler) {
            failureHandler(error);
        }
    };

    [self.remote fetchStatsForSiteId:self.siteId
               withCompletionHandler:completion
                      failureHandler:failure];
}

- (WPStatsServiceRemote *)remote
{
    if (!_remote) {
        _remote = [[WPStatsServiceRemote alloc] initWithRemoteApi:self.account.restApi andSiteId:self.siteId];
    }

    return _remote;
}

@end