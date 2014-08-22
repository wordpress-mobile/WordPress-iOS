#import "StatsViewController.h"
#import "Blog+Jetpack.h"
#import "WordPressAppDelegate.h"
#import "JetpackSettingsViewController.h"
#import "StatsWebViewController.h"
#import "WPAccount.h"
#import "ContextManager.h"
#import "WPStatsViewController_Private.h"
#import "BlogService.h"
#import <NotificationCenter/NotificationCenter.h>
#import "SettingsViewController.h"

static NSString *const StatsBlogObjectURLRestorationKey = @"StatsBlogObjectURL";

@interface StatsViewController () <UIActionSheetDelegate>
@property (nonatomic, assign) BOOL showingJetpackLogin;
@end

@implementation StatsViewController

- (id)init
{
    self = [super init];
    if (self) {
        self.statsDelegate = self;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIBarButtonItem *settingsButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Today", @"") style:UIBarButtonItemStylePlain target:self action:@selector(makeSiteTodayWidgetSite:)];
    self.navigationItem.rightBarButtonItem = settingsButton;
}

- (void)setBlog:(Blog *)blog
{
    _blog = blog;
    DDLogInfo(@"Loading Stats for the following blog: %@", [blog url]);

    WordPressAppDelegate *appDelegate = [WordPressAppDelegate sharedWordPressApplicationDelegate];
    if (!appDelegate.connectionAvailable) {
        [self showNoResultsWithTitle:NSLocalizedString(@"No Connection", @"") message:NSLocalizedString(@"An active internet connection is required to view stats", @"")];
    }
}

- (void)initStats
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:context];
    
    self.siteTimeZone = [blogService timeZoneForBlog:self.blog];

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

- (void)saveSiteDetailsForTodayWidget
{
    // Save the token and site ID to shared user defaults for use in the today widget
    NSUserDefaults *sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.org.wordpress"];
    [sharedDefaults setObject:self.siteTimeZone.name forKey:@"WordPressTodayWidgetTimeZone"];
    [sharedDefaults setObject:self.siteID forKey:@"WordPressTodayWidgetSiteId"];
    [sharedDefaults setObject:self.blog.blogName forKey:@"WordPressTodayWidgetSiteName"];
    [sharedDefaults setObject:self.oauth2Token forKey:@"WordPressTodayWidgetOAuth2Token"];
    
    // Turns the widget on for this site
    [[NCWidgetController widgetController] setHasContent:YES forWidgetWithBundleIdentifier:@"org.wordpress.WordPressTodayWidget"];
}

- (void)promptForJetpackCredentials
{
    if (self.showingJetpackLogin) {
        return;
    }
    self.showingJetpackLogin = YES;
    JetpackSettingsViewController *controller = [[JetpackSettingsViewController alloc] initWithBlog:self.blog];
    controller.showFullScreen = NO;
    __weak JetpackSettingsViewController *safeController = controller;
    [controller setCompletionBlock:^(BOOL didAuthenticate) {
        if (didAuthenticate) {
            [WPAnalytics track:WPAnalyticsStatSignedInToJetpack];
            [WPAnalytics track:WPAnalyticsStatPerformedJetpackSignInFromStatsScreen];
            [safeController.view removeFromSuperview];
            [safeController removeFromParentViewController];
            self.showingJetpackLogin = NO;
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

- (IBAction)makeSiteTodayWidgetSite:(id)sender
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"You can display a single site's stats in the iOS Today/Notification Center view.", @"Action sheet title for setting Today Widget site to the current one")
                                                             delegate:self
                                                    cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:NSLocalizedString(@"Use this site", @""), nil];
    [actionSheet showFromTabBar:self.tabBarController.tabBar];
}

#pragma mark - UIActionSheetDelegate methods

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        [self saveSiteDetailsForTodayWidget];
    }
}

#pragma mark - Restoration

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    NSURL *blogObjectURL = [[self.blog objectID] URIRepresentation];
    [coder encodeObject:blogObjectURL forKey:StatsBlogObjectURLRestorationKey];
    [super encodeRestorableStateWithCoder:coder];
}

+ (UIViewController *)viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder
{
    NSURL *blogObjectURL = [coder decodeObjectForKey:StatsBlogObjectURLRestorationKey];
    if (!blogObjectURL) {
        return nil;
    }

    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    NSManagedObjectID *blogObjectID = [context.persistentStoreCoordinator managedObjectIDForURIRepresentation:blogObjectURL];
    Blog *blog = (Blog *)[context existingObjectWithID:blogObjectID error:nil];
    if (!blog) {
        return nil;
    }
    StatsViewController *viewController = [[self alloc] init];
    viewController.blog = blog;

    return viewController;
}

@end
