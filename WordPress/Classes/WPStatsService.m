#import "WPStatsService.h"
#import "WPStatsServiceRemote.h"
#import "AccountService.h"
#import "BlogService.h"
#import "ContextManager.h"
#import "WPAccount.h"
#import "Blog.h"

@interface WPStatsService ()

@property (nonatomic, strong) NSNumber *siteId;

@end

@implementation WPStatsService
{

}

- (instancetype)initWithSiteId:(NSNumber *)siteId {
    self = [super init];
    if (self) {
        _siteId = siteId;
    }

    return self;
}

- (void)retrieveStatsWithCompletionHandler:(StatsCompletion)completion
{
    void (^failure)(NSError *error) = ^void (NSError *error) {
        DDLogError(@"Error while retrieving stats: %@", error);

        if (completion) {
            completion(nil, nil, nil, nil, nil, nil, nil);
        }
    };

    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:context];
    WPAccount *account = nil;

    // Find blog by ID if it's set up on this device
    Blog *blog = [blogService blogByBlogId:self.siteId];
    if (blog) {
        account = blog.account;
    } else {
        // Otherwise use default WP.com account for authentication of remote stats data
        AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
        account = [accountService defaultWordPressComAccount];
    }

    WPStatsServiceRemote *remote = [[WPStatsServiceRemote alloc] initWithRemoteApi:account.restApi andSiteId:self.siteId];
    [remote fetchStatsForSiteId:self.siteId
          withCompletionHandler:completion
                 failureHandler:failure];
}

@end