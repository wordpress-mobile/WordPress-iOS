@import WordPressShared;
@import Reachability;

#import "StatsViewController.h"
#import "Blog.h"
#import "WPAccount.h"
#import "ContextManager.h"
#import "BlogService.h"
#import "SFHFKeychainUtils.h"
#import "TodayExtensionService.h"
#import "WordPress-Swift.h"
#import "WPAppAnalytics.h"

static NSString *const StatsBlogObjectURLRestorationKey = @"StatsBlogObjectURL";

@interface StatsViewController () <UIViewControllerRestoration, NoResultsViewControllerDelegate>

@property (nonatomic, assign) BOOL showingJetpackLogin;
@property (nonatomic, assign) BOOL isActivatingStatsModule;
@property (nonatomic, strong) SiteStatsDashboardViewController *siteStatsDashboardVC;
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

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];
    self.navigationItem.title = NSLocalizedString(@"Stats", @"Stats window title");
    
    UINavigationController *statsNavVC = [[UIStoryboard storyboardWithName:@"SiteStatsDashboard" bundle:nil] instantiateInitialViewController];
    self.siteStatsDashboardVC = statsNavVC.viewControllers.firstObject;
    
    self.noResultsViewController = [NoResultsViewController controller];
    self.noResultsViewController.delegate = self;

    self.loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    self.loadingIndicator.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.loadingIndicator];
    [NSLayoutConstraint activateConstraints:@[
                                              [self.loadingIndicator.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
                                              [self.loadingIndicator.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor]
                                              ]];

    // Being shown in a modal window
    if (self.presentingViewController != nil) {
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonTapped:)];
        self.navigationItem.rightBarButtonItem = doneButton;
        self.title = self.blog.settings.name;
    }

    WordPressAppDelegate *appDelegate = [WordPressAppDelegate shared];
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
    if (@available (iOS 14, *)) {
        // do not install the widgets button on iOS 14 or later, if today widget feature flag is enabled
        if (![Feature enabled:FeatureFlagTodayWidget]) {
            [self installWidgetsButton];
        }
    } else if (self.presentingViewController == nil) {
        [self installWidgetsButton];
    }

    [self addChildViewController:self.siteStatsDashboardVC];
    [self.view addSubview:self.siteStatsDashboardVC.view];
    [self.siteStatsDashboardVC didMoveToParentViewController:self];
}

- (void) installWidgetsButton
{
    UIBarButtonItem *settingsButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Widgets", @"Nav bar button title to set the site used for Stats widgets.") style:UIBarButtonItemStylePlain target:self action:@selector(makeSiteTodayWidgetSite:)];
    self.navigationItem.rightBarButtonItem = settingsButton;
}

- (void)initStats
{
    SiteStatsInformation.sharedInstance.siteTimeZone = [self.blog timeZone];

    // WordPress.com + Jetpack REST
    if (self.blog.account) {
        
        // Prompt user to enable site stats if stats module is disabled
        if (!self.isActivatingStatsModule && ![self.blog isStatsActive]) {
            [self showStatsModuleDisabled];
            return;
        }
        
        SiteStatsInformation.sharedInstance.oauth2Token = self.blog.account.authToken;
        SiteStatsInformation.sharedInstance.siteID = self.blog.dotComID;
        
        [self addStatsViewControllerToView];
        [self initializeStatsWidgetsIfNeeded];
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

    [service configureTodayWidgetWithSiteID:SiteStatsInformation.sharedInstance.siteID
                                   blogName:self.blog.settings.name
                                    blogUrl:self.blog.displayURL
                               siteTimeZone:SiteStatsInformation.sharedInstance.siteTimeZone
                             andOAuth2Token:SiteStatsInformation.sharedInstance.oauth2Token];
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

- (void)showStatsModuleDisabled
{
    [self instantiateNoResultsViewControllerIfNeeded];
    [self.noResultsViewController configureForStatsModuleDisabled];
    [self displayNoResults];
}

- (void)showEnablingSiteStats
{
    [self instantiateNoResultsViewControllerIfNeeded];
    [self.noResultsViewController configureForActivatingStatsModule];
    [self displayNoResults];
}

- (void)instantiateNoResultsViewControllerIfNeeded
{
    if (!self.noResultsViewController) {
        self.noResultsViewController = [NoResultsViewController controller];
        self.noResultsViewController.delegate = self;
    }
}

- (void)displayNoResults
{
    [self addChildViewController:self.noResultsViewController];
    [self.view addSubviewWithFadeAnimation:self.noResultsViewController.view];
    self.noResultsViewController.view.frame = self.view.bounds;
    [self.noResultsViewController didMoveToParentViewController:self];
}

- (void)reachabilityChanged:(NSNotification *)notification
{
    Reachability *reachability = notification.object;
    if (reachability.isReachable) {
        [self initStats];
    }
}

#pragma mark - NoResultsViewControllerDelegate

-(void)actionButtonPressed
{
    [self showEnablingSiteStats];
        
    self.isActivatingStatsModule = YES;
    
    __weak __typeof(self) weakSelf = self;

    [self activateStatsModuleWithSuccess:^{
        [weakSelf.noResultsViewController removeFromView];
        [weakSelf initStats];
        weakSelf.isActivatingStatsModule = NO;
    } failure:^(NSError *error) {
        DDLogError(@"Error activating stats module: %@", error);
        [weakSelf showStatsModuleDisabled];
        weakSelf.isActivatingStatsModule = NO;
    }];
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
