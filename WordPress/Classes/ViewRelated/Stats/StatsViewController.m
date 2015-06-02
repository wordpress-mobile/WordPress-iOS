#import "StatsViewController.h"
#import "Blog.h"
#import "WordPressAppDelegate.h"
#import "JetpackSettingsViewController.h"
#import "StatsWebViewController.h"
#import "WPChromelessWebViewController.h"
#import "WPAccount.h"
#import "ContextManager.h"
#import "BlogService.h"
#import "SettingsViewController.h"
#import "SFHFKeychainUtils.h"
#import "TodayExtensionService.h"
#import <WPStatsViewController.h>
#import <WPNoResultsView.h>

static NSString *const StatsBlogObjectURLRestorationKey = @"StatsBlogObjectURL";

@interface StatsViewController () <UIActionSheetDelegate, WPStatsViewControllerDelegate>

@property (nonatomic, assign) BOOL showingJetpackLogin;
@property (nonatomic, strong) WPStatsViewController *statsVC;
@property (nonatomic, weak) WPNoResultsView *noResultsView;

@end

@implementation StatsViewController

- (id)init
{
    self = [super init];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
 
    self.view.backgroundColor = [WPStyleGuide itsEverywhereGrey];
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"WordPressCom-Stats-iOS" ofType:@"bundle"];
    NSBundle *bundle = [NSBundle bundleWithPath:path];
    self.statsVC = [[UIStoryboard storyboardWithName:@"SiteStats" bundle:bundle] instantiateInitialViewController];
    self.statsVC.statsDelegate = self;
    
    self.navigationItem.title = NSLocalizedString(@"Stats", @"Stats window title");

    // Being shown in a modal window
    if (self.presentingViewController != nil) {
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonTapped:)];
        self.navigationItem.rightBarButtonItem = doneButton;
        self.title = self.blog.blogName;
    }

    [self initStats];
}

- (void)setBlog:(Blog *)blog
{
    _blog = blog;
    DDLogInfo(@"Loading Stats for the following blog: %@", [blog url]);
}

- (void)addStatsViewControllerToView
{
    if (self.presentingViewController == nil && WIDGETS_EXIST) {
        UIBarButtonItem *settingsButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Today", @"") style:UIBarButtonItemStylePlain target:self action:@selector(makeSiteTodayWidgetSite:)];
        self.navigationItem.rightBarButtonItem = settingsButton;
    }
    
    [self addChildViewController:self.statsVC];
    [self.view addSubview:self.statsVC.view];
    [self.statsVC didMoveToParentViewController:self];
}


- (void)initStats
{
    WordPressAppDelegate *appDelegate = [WordPressAppDelegate sharedInstance];
    if (!appDelegate.connectionAvailable) {
        [self showNoResultsWithTitle:NSLocalizedString(@"No Connection", @"") message:NSLocalizedString(@"An active internet connection is required to view stats", @"")];
        return;
    }

    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:context];
    
    self.statsVC.siteTimeZone = [blogService timeZoneForBlog:self.blog];

    // WordPress.com + Jetpack REST
    if (self.blog.account.isWpcom) {
        self.statsVC.oauth2Token = self.blog.restApi.authToken;
        self.statsVC.siteID = self.blog.dotComID;
        [self addStatsViewControllerToView];

        return;
    }

    // Jetpack Legacy (WPJetpackRESTEnabled == NO)
    BOOL needsJetpackLogin = ![self.blog.jetpackAccount.restApi hasCredentials];
    if (!needsJetpackLogin && self.blog.jetpack.siteID && self.blog.jetpackAccount) {
        self.statsVC.siteID = self.blog.jetpack.siteID;
        self.statsVC.oauth2Token = self.blog.jetpackAccount.restApi.authToken;
        [self addStatsViewControllerToView];

    } else {
        [self promptForJetpackCredentials];
    }
}


- (void)saveSiteDetailsForTodayWidget
{
    TodayExtensionService *service = [TodayExtensionService new];
    [service configureTodayWidgetWithSiteID:self.statsVC.siteID
                                   blogName:self.blog.blogName
                               siteTimeZone:self.statsVC.siteTimeZone
                             andOAuth2Token:self.statsVC.oauth2Token];
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
            
            [self initStats];
        }
    }];

    [self addChildViewController:controller];
    [self.view addSubview:controller.view];
}


- (void)statsViewController:(WPStatsViewController *)statsViewController didSelectViewWebStatsForSiteID:(NSNumber *)siteID
{
    StatsWebViewController *vc = [[StatsWebViewController alloc] init];
    vc.blog = self.blog;
    [self.navigationController pushViewController:vc animated:YES];
}


- (void)statsViewController:(WPStatsViewController *)controller openURL:(NSURL *)url
{
    WPChromelessWebViewController *vc = [[WPChromelessWebViewController alloc] init];
    [vc loadPath:url.absoluteString];
    [self.navigationController pushViewController:vc animated:YES];
}


- (IBAction)makeSiteTodayWidgetSite:(id)sender
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"You can display a single site's stats in the iOS Today/Notification Center view.", @"Action sheet title for setting Today Widget site to the current one")
                                                             delegate:self
                                                    cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:NSLocalizedString(@"Use this site", @""), nil];
    if (IS_IPAD) {
        [actionSheet showFromBarButtonItem:sender animated:YES];
    } else {
        [actionSheet showFromTabBar:self.tabBarController.tabBar];
    }
}


- (IBAction)doneButtonTapped:(id)sender
{
    if (self.dismissBlock) {
        self.dismissBlock();
    }
}


- (void)showNoResultsWithTitle:(NSString *)title message:(NSString *)message
{
    [self.noResultsView removeFromSuperview];
    WPNoResultsView *noResultsView = [WPNoResultsView noResultsViewWithTitle:title message:message accessoryView:nil buttonTitle:nil];
    self.noResultsView = noResultsView;
    [self.view addSubview:self.noResultsView];
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
