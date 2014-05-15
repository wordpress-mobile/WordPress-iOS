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

    NSDate *today = [NSDate date];
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    [dateComponents setDay:-1];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *yesterday = [calendar dateByAddingComponents:dateComponents toDate:today options:0];

    [self.remote fetchStatsForTodayDate:today
                       andYesterdayDate:yesterday
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