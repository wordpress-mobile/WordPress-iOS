@import WordPressComStatsiOS;
@import WordPressShared;
@import Reachability;

#import "StatsViewController.h"
#import "Blog.h"
#import "WordPressAppDelegate.h"
#import "WPAccount.h"
#import "ContextManager.h"
#import "BlogService.h"
#import "SFHFKeychainUtils.h"
#import "TodayExtensionService.h"
#import "WordPress-Swift.h"
#import "WPAppAnalytics.h"

@import WordPressComStatsiOS;

static NSString *const StatsBlogObjectURLRestorationKey = @"StatsBlogObjectURL";

@interface StatsViewController () <WPStatsViewControllerDelegate, UIViewControllerRestoration>

@property (nonatomic, assign) BOOL showingJetpackLogin;
// Stores if we tried to initStats and failed because we are offline.
// If true, initStats will be retried as soon as we are online again.
@property (nonatomic, assign) BOOL offline;
@property (nonatomic, strong) UINavigationController *statsNavVC;
@property (nonatomic, strong) WPStatsViewController *statsVC;
@property (nonatomic, weak) NoResultsViewController *noResultsViewController;
@property (nonatomic, strong) UIActivityIndicatorView *loadingIndicator;

@end

@implementation StatsViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.restorationClass = [self class];
        self.restorationIdentifier = NSStringFromClass([self class]);
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
 
    self.view.backgroundColor = [WPStyleGuide itsEverywhereGrey];

    NSBundle *statsBundle = [NSBundle bundleForClass:[WPStatsViewController class]];
    self.statsNavVC = [[UIStoryboard storyboardWithName:@"SiteStats" bundle:statsBundle] instantiateInitialViewController];
    self.statsVC = self.statsNavVC.viewControllers.firstObject;
    self.statsVC.statsDelegate = self;
    self.loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.loadingIndicator.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.loadingIndicator];
    [NSLayoutConstraint activateConstraints:@[
                                              [self.loadingIndicator.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
                                              [self.loadingIndicator.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor]
                                              ]];

    self.navigationItem.title = NSLocalizedString(@"Stats", @"Stats window title");

    // Being shown in a modal window
    if (self.presentingViewController != nil) {
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonTapped:)];
        self.navigationItem.rightBarButtonItem = doneButton;
        self.title = self.blog.settings.name;
    }

    WordPressAppDelegate *appDelegate = [WordPressAppDelegate sharedInstance];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:appDelegate.internetReachability];
    [self initStats];
}

- (void)setBlog:(Blog *)blog
{
    _blog = blog;
    DDLogInfo(@"Loading Stats for the following blog: %@", [blog url]);
}

- (void)addStatsViewControllerToView
{
    if (self.presentingViewController == nil) {
        UIBarButtonItem *settingsButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Today", @"") style:UIBarButtonItemStylePlain target:self action:@selector(makeSiteTodayWidgetSite:)];
        self.navigationItem.rightBarButtonItem = settingsButton;
    }
    
    [self addChildViewController:self.statsVC];
    [self.view addSubview:self.statsVC.view];
    self.statsVC.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view pinSubviewToAllEdges:self.statsVC.view];
    [self.statsVC didMoveToParentViewController:self];
}


- (void)initStats
{
    WordPressAppDelegate *appDelegate = [WordPressAppDelegate sharedInstance];
    if (!appDelegate.connectionAvailable) {
        [self showNoResults];
        self.offline = YES;
        return;
    }
    self.offline = NO;

    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:context];
    
    self.statsVC.siteTimeZone = [blogService timeZoneForBlog:self.blog];

    // WordPress.com + Jetpack REST
    if (self.blog.account) {
        self.statsVC.oauth2Token = self.blog.account.authToken;
        self.statsVC.siteID = self.blog.dotComID;
        [self addStatsViewControllerToView];

        return;
    }

    [self refreshStatus];
}

- (void)refreshStatus
{
    [self.loadingIndicator startAnimating];
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:context];
    __weak __typeof(self) weakSelf = self;
    [blogService syncBlog:self.blog success:^{
        [self.loadingIndicator stopAnimating];
        [weakSelf promptForJetpackCredentials];
    } failure:^(NSError * _Nonnull error) {
        DDLogError(@"Error refreshing blog status when loading stats: %@", error);
        [self.loadingIndicator stopAnimating];
        [weakSelf promptForJetpackCredentials];
    }];
}


- (void)saveSiteDetailsForTodayWidget
{
    TodayExtensionService *service = [TodayExtensionService new];
    [service configureTodayWidgetWithSiteID:self.statsVC.siteID
                                   blogName:self.blog.settings.name
                               siteTimeZone:self.statsVC.siteTimeZone
                             andOAuth2Token:self.statsVC.oauth2Token];
}


- (void)promptForJetpackCredentials
{
    if (self.showingJetpackLogin) {
        return;
    }
    self.showingJetpackLogin = YES;
    JetpackLoginViewController *controller = [[JetpackLoginViewController alloc] initWithBlog:self.blog];
    __weak JetpackLoginViewController *safeController = controller;
    [controller setCompletionBlock:^(){
            [WPAppAnalytics track:WPAnalyticsStatSignedInToJetpack withProperties: @{@"source": @"stats"} withBlog:self.blog];
            [safeController.view removeFromSuperview];
            [safeController removeFromParentViewController];
            self.showingJetpackLogin = NO;
            [self initStats];
    }];

    [self addChildViewController:controller];
    [self.view addSubview:controller.view];
    controller.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view pinSubviewToAllEdges:controller.view];
}


- (void)statsViewController:(WPStatsViewController *)controller openURL:(NSURL *)url
{
    NSParameterAssert(url != nil);
    NSParameterAssert([url isKindOfClass:[NSURL class]]);
    // Make sure the passed url is a real NSURL, or Swift will crash on it
    if (![url isKindOfClass:[NSURL class]]) {
        DDLogError(@"Stats tried to open an invalid URL: %@", url);
        return;
    }
    UIViewController *webViewController = [WebViewControllerFactory controllerAuthenticatedWithDefaultAccountWithUrl:url];
    [self.navigationController pushViewController:webViewController animated:YES];
}


- (IBAction)makeSiteTodayWidgetSite:(id)sender
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"You can display a single site's stats in the iOS Today/Notification Center view.", @"Action sheet title for setting Today Widget site to the current one")
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleActionSheet];
    [alertController addActionWithTitle:NSLocalizedString(@"Cancel", @"")
                                  style:UIAlertActionStyleCancel
                                handler:nil];
    [alertController addActionWithTitle:NSLocalizedString(@"Use this site", @"")
                                  style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction *alertAction) {
                                   [self saveSiteDetailsForTodayWidget];
                                  }];
    alertController.popoverPresentationController.barButtonItem = sender;
    [self presentViewController:alertController animated:YES completion:nil];
}


- (IBAction)doneButtonTapped:(id)sender
{
    if (self.dismissBlock) {
        self.dismissBlock();
    }
}


- (void)showNoResults
{
    [self.noResultsViewController removeFromView];

    NSString *title = NSLocalizedString(@"No Connection", @"Title for the error view when there's no connection");
    NSString *subtitle = NSLocalizedString(@"An active internet connection is required to view stats",
                                           @"Error message shown when trying to view Stats and there is no internet connection.");

    self.noResultsViewController = [NoResultsViewController controllerWithTitle:title
                                                                    buttonTitle:nil
                                                                       subtitle:subtitle
                                                             attributedSubtitle:nil
                                                                          image:nil
                                                                  accessoryView:nil];

    [self addChildViewController:self.noResultsViewController];
    [self.view addSubviewWithFadeAnimation:self.noResultsViewController.view];
    [self.noResultsViewController didMoveToParentViewController:self];
}

- (void)reachabilityChanged:(NSNotification *)notification
{
    Reachability *reachability = notification.object;
    if (reachability.isReachable) {
        [self initStats];
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
