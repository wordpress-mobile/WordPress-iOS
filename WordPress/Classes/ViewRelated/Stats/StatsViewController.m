#import "StatsViewController.h"
#import "Blog+Jetpack.h"
#import "WordPressAppDelegate.h"
#import "JetpackSettingsViewController.h"
#import "StatsWebViewController.h"
#import "WPAccount.h"
#import "ContextManager.h"
#import "WPStatsViewController_Private.h"


@implementation StatsViewController

- (id)init {
    self = [super init];
    if (self) {
        self.statsDelegate = self;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
}

- (void)setBlog:(Blog *)blog {
    _blog = blog;
    DDLogInfo(@"Loading Stats for the following blog: %@", [blog url]);
    
    WordPressAppDelegate *appDelegate = [WordPressAppDelegate sharedWordPressApplicationDelegate];
    if (!appDelegate.connectionAvailable) {
        [self showNoResultsWithTitle:NSLocalizedString(@"No Connection", @"") message:NSLocalizedString(@"An active internet connection is required to view stats", @"")];
    } else {
        [self initStats];
    }
}

- (void)initStats {
    if (self.blog.isWPcom) {
        
        self.oauth2Token = self.blog.restApi.authToken;
        self.siteID = self.blog.blogID;
        
        [super initStats];
        return;
    }
    
    // Jetpack
    BOOL needsJetpackLogin = ![self.blog.jetpackAccount.restApi hasCredentials];
    if (!needsJetpackLogin && self.blog.jetpackBlogID && self.blog.jetpackAccount) {
        self.siteID = self.blog.jetpackBlogID;
        self.oauth2Token = self.blog.jetpackAccount.restApi.authToken;
        
        [super initStats];
    } else {
        [self promptForJetpackCredentials];
    }
}

- (void)promptForJetpackCredentials {
    JetpackSettingsViewController *controller = [[JetpackSettingsViewController alloc] initWithBlog:self.blog];
    controller.showFullScreen = NO;
    __weak JetpackSettingsViewController *safeController = controller;
    [controller setCompletionBlock:^(BOOL didAuthenticate) {
        if (didAuthenticate) {
            [WPAnalytics track:WPAnalyticsStatSignedInToJetpack];
            [WPAnalytics track:WPAnalyticsStatPerformedJetpackSignInFromStatsScreen];
            [safeController.view removeFromSuperview];
            [safeController removeFromParentViewController];
            self.tableView.scrollEnabled = YES;
            [self initStats];
        }
    }];
    
    self.tableView.scrollEnabled = NO;
    [self addChildViewController:controller];
    [self.tableView addSubview:controller.view];
}

- (void)statsViewController:(WPStatsViewController *)statsViewController didSelectViewWebStatsForSiteID:(NSNumber *)siteID
{
    StatsWebViewController *vc = [[StatsWebViewController alloc] init];
    vc.blog = self.blog;
    [self.navigationController pushViewController:vc animated:YES];
}


@end
