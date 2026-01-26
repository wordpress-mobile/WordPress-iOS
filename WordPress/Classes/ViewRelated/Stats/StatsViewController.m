#import "StatsViewController.h"
#import "BlogService.h"
#import "WordPress-Swift.h"
#import "WPAppAnalytics.h"

@import WordPressData;
@import WordPressShared;
@import Reachability;

@interface StatsViewController () <NoResultsViewControllerDelegate>

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
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];
    [self updateNavigationTitle];

    self.siteStatsDashboardVC = [[SiteStatsDashboardViewController alloc] init];

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
        self.navigationItem.leftBarButtonItem = doneButton;
        self.title = self.blog.settings.name;
    }

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kTMReachabilityChangedNotification object:ReachabilityUtils.internetReachability];

    [self registerForTraitChanges:@[UITraitHorizontalSizeClass.class] withAction:@selector(updateNavigationTitle)];

    [self initStats];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [ObjCBridge incrementSignificantEvent];
}

- (void)updateNavigationTitle
{
    if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact) {
        self.navigationItem.title = NSLocalizedString(@"Stats", @"Stats window title");
    } else {
        self.navigationItem.title = nil;
    }
}

- (void)setBlog:(Blog *)blog
{
    _blog = blog;
    DDLogInfo(@"Loading Stats for the following blog: %@", [blog url]);
}

- (void)addStatsViewControllerToView
{
    [self addChildViewController:self.siteStatsDashboardVC];
    [self.view addSubview:self.siteStatsDashboardVC.view];
    [self.siteStatsDashboardVC didMoveToParentViewController:self];
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
        SiteStatsInformation.sharedInstance.supportsFileDownloads = [self.blog supports:BlogFeatureFileDownloadsStats];
        
        [self addStatsViewControllerToView];
        [self initializeStatsWidgetsIfNeeded];
        return;
    }

    [self refreshStatus];
}

- (void)refreshStatus
{
    [self.loadingIndicator startAnimating];
    BlogService *blogService = [[BlogService alloc] initWithCoreDataStack:[ContextManager sharedInstance]];
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

- (void)promptForJetpackCredentials
{
    if (self.showingJetpackLogin) {
        return;
    }
    self.showingJetpackLogin = YES;

    __weak __typeof(self) weakSelf = self;
    [self showJetpackConnectionViewWithCompletion:^{
        weakSelf.showingJetpackLogin = NO;
        [weakSelf initStats];
    }];
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

@end
