#import "BlogDetailsViewController.h"

#import "AccountService.h"
#import "BlogService.h"
#import "CommentsViewController.h"
#import "CoreDataStack.h"
#import "ReachabilityUtils.h"
#import "SiteSettingsViewController.h"
#import "SharingViewController.h"
#import "StatsViewController.h"
#import "WPAccount.h"
#import "WPAppAnalytics.h"
#import "WPGUIConstants.h"
#import "WordPress-Swift.h"
#import "MenusViewController.h"
#import "UIViewController+RemoveQuickStart.h"
#import <Reachability/Reachability.h>
#import <WordPressShared/WPTableViewCell.h>

@import Gridicons;

static NSString *const BlogDetailsCellIdentifier = @"BlogDetailsCell";
static NSString *const BlogDetailsPlanCellIdentifier = @"BlogDetailsPlanCell";
static NSString *const BlogDetailsSettingsCellIdentifier = @"BlogDetailsSettingsCell";
static NSString *const BlogDetailsRemoveSiteCellIdentifier = @"BlogDetailsRemoveSiteCell";
static NSString *const BlogDetailsQuickActionsCellIdentifier = @"BlogDetailsQuickActionsCell";
static NSString *const BlogDetailsSectionHeaderViewIdentifier = @"BlogDetailsSectionHeaderView";
static NSString *const QuickStartHeaderViewNibName = @"BlogDetailsSectionHeaderView";
static NSString *const BlogDetailsQuickStartCellIdentifier = @"BlogDetailsQuickStartCell";
static NSString *const BlogDetailsSectionFooterIdentifier = @"BlogDetailsSectionFooterView";
static NSString *const BlogDetailsMigrationSuccessCellIdentifier = @"BlogDetailsMigrationSuccessCell";
static NSString *const BlogDetailsJetpackBrandingCardCellIdentifier = @"BlogDetailsJetpackBrandingCardCellIdentifier";
static NSString *const BlogDetailsJetpackInstallCardCellIdentifier = @"BlogDetailsJetpackInstallCardCellIdentifier";

NSString * const WPBlogDetailsRestorationID = @"WPBlogDetailsID";
NSString * const WPBlogDetailsBlogKey = @"WPBlogDetailsBlogKey";
NSString * const WPBlogDetailsSelectedIndexPathKey = @"WPBlogDetailsSelectedIndexPathKey";

CGFloat const BlogDetailGridiconSize = 24.0;
CGFloat const BlogDetailGridiconAccessorySize = 17.0;
CGFloat const BlogDetailQuickStartSectionHeaderHeight = 48.0;
CGFloat const BlogDetailSectionTitleHeaderHeight = 40.0;
CGFloat const BlogDetailSectionsSpacing = 20.0;
CGFloat const BlogDetailSectionFooterHeight = 40.0;
NSTimeInterval const PreloadingCacheTimeout = 60.0 * 5; // 5 minutes
NSString * const HideWPAdminDate = @"2015-09-07T00:00:00Z";

CGFloat const BlogDetailReminderSectionHeaderHeight = 8.0;
CGFloat const BlogDetailReminderSectionFooterHeight = 1.0;

// NOTE: Currently "stats" acts as the calypso dashboard with a redirect to
// stats/insights. Per @mtias, if the dashboard should change at some point the
// redirect will be updated to point to new content, eventhough the path is still
// "stats/".
// aerych, 2016-06-14
NSString * const WPCalypsoDashboardPath = @"https://wordpress.com/stats/";

#pragma mark - Helper Classes for Blog Details view model.

@implementation BlogDetailsRow

- (instancetype)initWithTitle:(NSString * __nonnull)title
                        image:(UIImage * __nonnull)image
                     callback:(void(^)(void))callback
{
    return [self initWithTitle:title
                    identifier:BlogDetailsCellIdentifier
                         image:image
                      callback:callback];
}

- (instancetype)initWithTitle:(NSString * __nonnull)title
                   identifier:(NSString * __nonnull)identifier
                        image:(UIImage * __nonnull)image
                     callback:(void(^)(void))callback
{
    return [self initWithTitle:title
                    identifier:identifier
       accessibilityIdentifier:nil
                         image:image
                      callback:callback];
}

- (instancetype)initWithTitle:(NSString * __nonnull)title
      accessibilityIdentifier:(NSString *__nullable)accessibilityIdentifier
                        image:(UIImage * __nonnull)image
                     callback:(void(^)(void))callback
{
    return [self initWithTitle:title
                    identifier:BlogDetailsCellIdentifier
       accessibilityIdentifier:accessibilityIdentifier
                         image:image
                      callback:callback];
}

- (instancetype)initWithTitle:(NSString * __nonnull)title
                   identifier:(NSString * __nonnull)identifier
       accessibilityIdentifier:(NSString *__nullable)accessibilityIdentifier
                        image:(UIImage * __nonnull)image
                     callback:(void(^)(void))callback
{
    return [self initWithTitle:title
                    identifier:identifier
       accessibilityIdentifier:accessibilityIdentifier
             accessibilityHint:nil
                         image:image
                      callback:callback];
}

- (instancetype)initWithTitle:(NSString * __nonnull)title
                   identifier:(NSString * __nonnull)identifier
      accessibilityIdentifier:(NSString *__nullable)accessibilityIdentifier
            accessibilityHint:(NSString *__nullable)accessibilityHint
                        image:(UIImage * __nonnull)image
                     callback:(void(^)(void))callback
{
    return [self initWithTitle:title
                    identifier:identifier
       accessibilityIdentifier:accessibilityIdentifier
             accessibilityHint:accessibilityHint
                         image:image
                    imageColor:[UIColor murielListIcon]
                 renderingMode:UIImageRenderingModeAlwaysTemplate
                      callback:callback];
}

- (instancetype)initWithTitle:(NSString * __nonnull)title
      accessibilityIdentifier:(NSString *__nullable)accessibilityIdentifier
            accessibilityHint:(NSString *__nullable)accessibilityHint
                        image:(UIImage * __nonnull)image
                     callback:(void(^)(void))callback
{
    return [self initWithTitle:title
                    identifier:BlogDetailsCellIdentifier
       accessibilityIdentifier:accessibilityIdentifier
             accessibilityHint:accessibilityHint
                         image:image
                      callback:callback];
}
    
- (instancetype)initWithTitle:(NSString *)title
      accessibilityIdentifier:(NSString *)accessibilityIdentifier
                        image:(UIImage *)image
                   imageColor:(UIColor *)imageColor
                     callback:(void (^)(void))callback
{
    return [self initWithTitle:title
                    identifier:BlogDetailsCellIdentifier
       accessibilityIdentifier:accessibilityIdentifier
             accessibilityHint:nil
                         image:image
                    imageColor:imageColor
                 renderingMode:UIImageRenderingModeAlwaysTemplate
                      callback:callback];
}

- (instancetype)initWithTitle:(NSString *)title
      accessibilityIdentifier:(NSString *)accessibilityIdentifier
                        image:(UIImage *)image
                   imageColor:(UIColor *)imageColor
                renderingMode:(UIImageRenderingMode)renderingMode
                     callback:(void (^)(void))callback
{
    return [self initWithTitle:title
                    identifier:BlogDetailsCellIdentifier
       accessibilityIdentifier:accessibilityIdentifier
             accessibilityHint:nil
                         image:image
                    imageColor:imageColor
                 renderingMode:renderingMode
                      callback:callback];
}


- (instancetype)initWithTitle:(NSString * __nonnull)title
      accessibilityIdentifier:(NSString *__nullable)accessibilityIdentifier
            accessibilityHint:(NSString * __nullable)accessibilityHint
                        image:(UIImage * __nonnull)image
                   imageColor:(UIColor * __nullable)imageColor
                     callback:(void(^_Nullable)(void))callback
{
    return [self initWithTitle:title
                 identifier:BlogDetailsCellIdentifier
    accessibilityIdentifier:accessibilityIdentifier
          accessibilityHint:nil
                      image:image
                 imageColor:imageColor
                 renderingMode:UIImageRenderingModeAlwaysTemplate
                   callback:callback];
}

- (instancetype)initWithTitle:(NSString * __nonnull)title
                   identifier:(NSString * __nonnull)identifier
      accessibilityIdentifier:(NSString *__nullable)accessibilityIdentifier
            accessibilityHint:(NSString *__nullable)accessibilityHint
                        image:(UIImage * __nonnull)image
                   imageColor:(UIColor * __nullable)imageColor
                renderingMode:(UIImageRenderingMode)renderingMode
                     callback:(void(^)(void))callback
{
    self = [super init];
    if (self) {
        _title = title;
        _image = [image imageWithRenderingMode:renderingMode];
        _imageColor = imageColor;
        _callback = callback;
        _identifier = identifier;
        _accessibilityIdentifier = accessibilityIdentifier;
        _accessibilityHint = accessibilityHint;
        _showsSelectionState = YES;
        _showsDisclosureIndicator = YES;
    }
    return self;
}

@end

@implementation BlogDetailsSection
- (instancetype)initWithTitle:(NSString *)title
                      andRows:(NSArray *)rows
                     category:(BlogDetailsSectionCategory)category
{
    return [self initWithTitle:title rows:rows footerTitle:nil category:category];
}

- (instancetype)initWithTitle:(NSString *)title
                         rows:(NSArray *)rows
                  footerTitle:(NSString *)footerTitle
                     category:(BlogDetailsSectionCategory)category
{
    self = [super init];
    if (self) {
        _title = title;
        _rows = rows;
        _footerTitle = footerTitle;
        _category = category;
    }
    return self;
}
@end

#pragma mark -

@interface BlogDetailsViewController () <UIActionSheetDelegate, UIAlertViewDelegate, WPSplitViewControllerDetailProvider, UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) NSArray *headerViewHorizontalConstraints;
@property (nonatomic, strong) NSArray<BlogDetailsSection *> *tableSections;
@property (nonatomic, strong) BlogService *blogService;
@property (nonatomic, strong) SiteIconPickerPresenter *siteIconPickerPresenter;
@property (nonatomic, strong) ImageCropViewController *imageCropViewController;

/// Used to restore the tableview selection during state restoration, and
/// also when switching between a collapsed and expanded split view controller presentation
@property (nonatomic, strong) NSIndexPath *restorableSelectedIndexPath;
@property (nonatomic) BlogDetailsSectionCategory selectedSectionCategory;

@property (nonatomic) BOOL hasLoggedDomainCreditPromptShownEvent;

@end

@implementation BlogDetailsViewController
@synthesize restorableSelectedIndexPath = _restorableSelectedIndexPath;

#pragma mark - State Restoration

+ (UIViewController *)viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder
{
    NSString *blogID = [coder decodeObjectForKey:WPBlogDetailsBlogKey];
    if (!blogID) {
        return nil;
    }

    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    NSManagedObjectID *objectID = [context.persistentStoreCoordinator managedObjectIDForURIRepresentation:[NSURL URLWithString:blogID]];
    if (!objectID) {
        return nil;
    }

    NSError *error = nil;
    Blog *restoredBlog = (Blog *)[context existingObjectWithID:objectID error:&error];
    if (error || !restoredBlog) {
        return nil;
    }

    // If there's already a blog details view controller for this blog in the primary
    // navigation stack, we'll return that instead of creating a new one.
    UISplitViewController *splitViewController = [self mySitesCoordinator].splitViewController;
    UINavigationController *navigationController = splitViewController.viewControllers.firstObject;
    if (navigationController && [navigationController isKindOfClass:[UINavigationController class]]) {
        BlogDetailsViewController *topViewController = (BlogDetailsViewController *)navigationController.topViewController;
        if ([topViewController isKindOfClass:[BlogDetailsViewController class]] && topViewController.blog == restoredBlog) {
            return topViewController;
        }
    }

    BlogDetailsViewController *viewController = [[self alloc] init];
    viewController.blog = restoredBlog;

    return viewController;
}


- (void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    [coder encodeObject:[[self.blog.objectID URIRepresentation] absoluteString] forKey:WPBlogDetailsBlogKey];

    WPSplitViewController *splitViewController = (WPSplitViewController *)self.splitViewController;

    UIViewController *detailViewController = [splitViewController rootDetailViewController];
    if (detailViewController && [detailViewController conformsToProtocol:@protocol(UIViewControllerRestoration)]) {
        // If the current detail view controller supports state restoration, store the current selection
        [coder encodeObject:self.restorableSelectedIndexPath forKey:WPBlogDetailsSelectedIndexPathKey];
    }

    [super encodeRestorableStateWithCoder:coder];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder
{
    NSIndexPath *indexPath = [coder decodeObjectForKey:WPBlogDetailsSelectedIndexPathKey];
    if (indexPath) {
        self.restorableSelectedIndexPath = indexPath;
    }

    [super decodeRestorableStateWithCoder:coder];
}

#pragma mark = Lifecycle Methods

- (void)dealloc
{
    [self stopObservingQuickStart];
}

- (instancetype)initWithMeScenePresenter:(id<ScenePresenter>)meScenePresenter
{
    self = [super init];
    
    if (self) {
        self.restorationIdentifier = WPBlogDetailsRestorationID;
        self.restorationClass = [self class];
        _meScenePresenter = meScenePresenter;
    }
    
    return self;
}

- (instancetype)init
{
    return [self initWithMeScenePresenter:[MeScenePresenter new]];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _tableView = [[IntrinsicTableView alloc] initWithFrame:CGRectZero style:UITableViewStyleInsetGrouped];
    self.tableView.scrollEnabled = false;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.translatesAutoresizingMaskIntoConstraints = false;
    [self.view addSubview:self.tableView];
    [self.view pinSubviewToAllEdges:self.tableView];
    
    UIRefreshControl *refreshControl = [UIRefreshControl new];
    [refreshControl addTarget:self action:@selector(pulledToRefresh) forControlEvents:UIControlEventValueChanged];
    self.tableView.refreshControl = refreshControl;

    self.tableView.accessibilityIdentifier = @"Blog Details Table";

    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
    [WPStyleGuide configureAutomaticHeightRowsFor:self.tableView];

    [self.tableView registerClass:[WPTableViewCell class] forCellReuseIdentifier:BlogDetailsCellIdentifier];
    [self.tableView registerClass:[WPTableViewCellValue1 class] forCellReuseIdentifier:BlogDetailsPlanCellIdentifier];
    [self.tableView registerClass:[WPTableViewCellValue1 class] forCellReuseIdentifier:BlogDetailsSettingsCellIdentifier];
    [self.tableView registerClass:[WPTableViewCell class] forCellReuseIdentifier:BlogDetailsRemoveSiteCellIdentifier];
    [self.tableView registerClass:[QuickActionsCell class] forCellReuseIdentifier:BlogDetailsQuickActionsCellIdentifier];
    UINib *qsHeaderViewNib = [UINib nibWithNibName:QuickStartHeaderViewNibName bundle:[NSBundle mainBundle]];
    [self.tableView registerNib:qsHeaderViewNib forHeaderFooterViewReuseIdentifier:BlogDetailsSectionHeaderViewIdentifier];
    [self.tableView registerClass:[QuickStartCell class] forCellReuseIdentifier:BlogDetailsQuickStartCellIdentifier];
    [self.tableView registerClass:[BlogDetailsSectionFooterView class] forHeaderFooterViewReuseIdentifier:BlogDetailsSectionFooterIdentifier];
    [self.tableView registerClass:[MigrationSuccessCell class] forCellReuseIdentifier:BlogDetailsMigrationSuccessCellIdentifier];
    [self.tableView registerClass:[JetpackBrandingMenuCardCell class] forCellReuseIdentifier:BlogDetailsJetpackBrandingCardCellIdentifier];
    [self.tableView registerClass:[JetpackRemoteInstallTableViewCell class] forCellReuseIdentifier:BlogDetailsJetpackInstallCardCellIdentifier];

    self.hasLoggedDomainCreditPromptShownEvent = NO;

    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    self.blogService = [[BlogService alloc] initWithCoreDataStack:[ContextManager sharedInstance]];
    [self preloadMetadata];

    if (self.blog.account && !self.blog.account.userID) {
        // User's who upgrade may not have a userID recorded.
        AccountService *acctService = [[AccountService alloc] initWithCoreDataStack:[ContextManager sharedInstance]];
        [acctService updateUserDetailsForAccount:self.blog.account success:nil failure:nil];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleDataModelChange:)
                                                 name:NSManagedObjectContextObjectsDidChangeNotification
                                               object:context];

    [self startObservingQuickStart];
    [self addMeButtonToNavigationBarWithEmail:self.blog.account.email meScenePresenter:self.meScenePresenter];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.splitViewControllerIsHorizontallyCompact) {
        self.restorableSelectedIndexPath = nil;
    }
    
    self.navigationItem.title = NSLocalizedString(@"My Site", @"Title of My Site tab");

    // Configure and reload table data when appearing to ensure pending comment count is updated
    [self configureTableViewData];

    [self reloadTableViewPreservingSelection];
    [self preloadBlogData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self createUserActivity];
    [self startAlertTimer];
    
    QuickStartTourGuide *tourGuide = [QuickStartTourGuide shared];
    
    // Visiting the site menu element in viewDidAppear ensures that this view controller is visible when the next step
    // in the tour is triggered. We want to avoid a situation where the next step in the tour is executed while this
    // view controller isn't visible yet, as this can cause issues with scrolling to the correct quick start element.
    if ([tourGuide currentElementInt] == QuickStartTourElementSiteMenu) {
        [tourGuide visited: QuickStartTourElementSiteMenu];
    }
    
    tourGuide.currentEntryPoint = QuickStartTourEntryPointBlogDetails;
    [WPAnalytics trackEvent: WPAnalyticsEventMySiteSiteMenuShown];

    if ([self shouldShowJetpackInstallCard]) {
        [WPAnalytics trackEvent:WPAnalyticsEventJetpackInstallFullPluginCardViewed
                     properties:@{WPAppAnalyticsKeyTabSource: @"site_menu"}];
    }
    
    if ([self shouldShowBlaze]) {
        [BlazeEventsTracker trackEntryPointDisplayedFor:BlazeSourceMenuItem];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self stopAlertTimer];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];

    // Required to add / remove "Home" section when switching between regular and compact width
    [self configureTableViewData];

    // Required to update disclosure indicators depending on split view status
    [self reloadTableViewPreservingSelection];
}

- (void)showDetailViewForSubsection:(BlogDetailsSubsection)section
{
    NSIndexPath *indexPath = [self indexPathForSubsection:section];

    switch (section) {
        case BlogDetailsSubsectionReminders:
        case BlogDetailsSubsectionDomainCredit:
        case BlogDetailsSubsectionHome:
        case BlogDetailsSubsectionMigrationSuccess:
            self.restorableSelectedIndexPath = indexPath;
            [self.tableView selectRowAtIndexPath:indexPath
                                        animated:NO
                                  scrollPosition:[self optimumScrollPositionForIndexPath:indexPath]];
            [self showDashboard];
            break;
        case BlogDetailsSubsectionQuickStart:
        case BlogDetailsSubsectionJetpackBrandingCard:
            self.restorableSelectedIndexPath = indexPath;
            [self.tableView selectRowAtIndexPath:indexPath
                                        animated:NO
                                  scrollPosition:[self optimumScrollPositionForIndexPath:indexPath]];
            break;
        case BlogDetailsSubsectionStats:
            self.restorableSelectedIndexPath = indexPath;
            [self.tableView selectRowAtIndexPath:indexPath
                                        animated:NO
                                  scrollPosition:[self optimumScrollPositionForIndexPath:indexPath]];
            [self showStatsFromSource:BlogDetailsNavigationSourceLink];
            break;
        case BlogDetailsSubsectionPosts:
            self.restorableSelectedIndexPath = indexPath;
            [self.tableView selectRowAtIndexPath:indexPath
                                        animated:NO
                                  scrollPosition:[self optimumScrollPositionForIndexPath:indexPath]];
            [self showPostListFromSource:BlogDetailsNavigationSourceLink];
            break;
        case BlogDetailsSubsectionThemes:
        case BlogDetailsSubsectionCustomize:
            if ([self.blog supports:BlogFeatureThemeBrowsing] || [self.blog supports:BlogFeatureMenus]) {
                self.restorableSelectedIndexPath = indexPath;
                [self.tableView selectRowAtIndexPath:indexPath
                                            animated:NO
                                      scrollPosition:[self optimumScrollPositionForIndexPath:indexPath]];
                [self showThemes];
            }
            break;
        case BlogDetailsSubsectionMedia:
            self.restorableSelectedIndexPath = indexPath;
            [self.tableView selectRowAtIndexPath:indexPath
                                        animated:NO
                                  scrollPosition:[self optimumScrollPositionForIndexPath:indexPath]];
            [self showMediaLibraryFromSource:BlogDetailsNavigationSourceLink];
            break;
        case BlogDetailsSubsectionPages:
            self.restorableSelectedIndexPath = indexPath;
            [self.tableView selectRowAtIndexPath:indexPath
                                        animated:NO
                                  scrollPosition:[self optimumScrollPositionForIndexPath:indexPath]];
            [self showPageListFromSource:BlogDetailsNavigationSourceLink];
            break;
        case BlogDetailsSubsectionActivity:
            if ([self.blog supports:BlogFeatureActivity]) {
                self.restorableSelectedIndexPath = indexPath;
                [self.tableView selectRowAtIndexPath:indexPath
                                            animated:NO
                                      scrollPosition:[self optimumScrollPositionForIndexPath:indexPath]];
                [self showActivity];
            }
            break;
        case BlogDetailsSubsectionBlaze:
            if ([self shouldShowBlaze]) {
                self.restorableSelectedIndexPath = indexPath;
                [self.tableView selectRowAtIndexPath:indexPath
                                            animated:NO
                                      scrollPosition:[self optimumScrollPositionForIndexPath:indexPath]];
                [self showBlaze];
            }
            break;
        case BlogDetailsSubsectionJetpackSettings:
            if ([self.blog supports:BlogFeatureActivity]) {
                self.restorableSelectedIndexPath = indexPath;
                [self.tableView selectRowAtIndexPath:indexPath
                                            animated:NO
                                      scrollPosition:[self optimumScrollPositionForIndexPath:indexPath]];
                [self showJetpackSettings];
            }
            break;
        case BlogDetailsSubsectionComments:
            self.restorableSelectedIndexPath = indexPath;
            [self.tableView selectRowAtIndexPath:indexPath
                                        animated:NO
                                  scrollPosition:[self optimumScrollPositionForIndexPath:indexPath]];
            [self showCommentsFromSource:BlogDetailsNavigationSourceLink];
            break;
        case BlogDetailsSubsectionSharing:
            if ([self.blog supports:BlogFeatureSharing]) {
                self.restorableSelectedIndexPath = indexPath;
                [self.tableView selectRowAtIndexPath:indexPath
                                            animated:NO
                                      scrollPosition:[self optimumScrollPositionForIndexPath:indexPath]];
                [self showSharingFromSource:BlogDetailsNavigationSourceLink];
            }
            break;
        case BlogDetailsSubsectionPeople:
            if ([self.blog supports:BlogFeaturePeople]) {
                self.restorableSelectedIndexPath = indexPath;
                [self.tableView selectRowAtIndexPath:indexPath
                                            animated:NO
                                      scrollPosition:[self optimumScrollPositionForIndexPath:indexPath]];
                [self showPeople];
            }
            break;
        case BlogDetailsSubsectionPlugins:
            if ([self.blog supports:BlogFeaturePluginManagement]) {
                self.restorableSelectedIndexPath = indexPath;
                [self.tableView selectRowAtIndexPath:indexPath
                                            animated:NO
                                      scrollPosition:[self optimumScrollPositionForIndexPath:indexPath]];
                [self showPlugins];
            }
            break;
    }
}

// MARK: Todo: this needs to adjust based on the existence of the QSv2 section
- (NSIndexPath *)indexPathForSubsection:(BlogDetailsSubsection)subsection
{
    BlogDetailsSectionCategory sectionCategory = [self sectionCategoryWithSubsection:subsection blog: self.blog];
    NSInteger section = [self findSectionIndexWithSections:self.tableSections category:sectionCategory];
    switch (subsection) {
        case BlogDetailsSubsectionReminders:
        case BlogDetailsSubsectionHome:
        case BlogDetailsSubsectionMigrationSuccess:
        case BlogDetailsSubsectionJetpackBrandingCard:
            return [NSIndexPath indexPathForRow:0 inSection:section];
        case BlogDetailsSubsectionDomainCredit:
            return [NSIndexPath indexPathForRow:0 inSection:section];
        case BlogDetailsSubsectionQuickStart:
            return [NSIndexPath indexPathForRow:0 inSection:section];
        case BlogDetailsSubsectionStats:
            return [NSIndexPath indexPathForRow:0 inSection:section];
        case BlogDetailsSubsectionActivity:
            return [NSIndexPath indexPathForRow:0 inSection:section];
        case BlogDetailsSubsectionBlaze:
            return [NSIndexPath indexPathForRow:0 inSection:section];
        case BlogDetailsSubsectionJetpackSettings:
            return [NSIndexPath indexPathForRow:1 inSection:section];
        case BlogDetailsSubsectionPosts:
            return [NSIndexPath indexPathForRow:0 inSection:section];
        case BlogDetailsSubsectionThemes:
        case BlogDetailsSubsectionCustomize:
            return [NSIndexPath indexPathForRow:0 inSection:section];
        case BlogDetailsSubsectionMedia:
            return [NSIndexPath indexPathForRow:2 inSection:section];
        case BlogDetailsSubsectionPages:
            return [NSIndexPath indexPathForRow:0 inSection:section];
        case BlogDetailsSubsectionComments:
            return [NSIndexPath indexPathForRow:3 inSection:section];
        case BlogDetailsSubsectionSharing:
            return [NSIndexPath indexPathForRow:0 inSection:section];
        case BlogDetailsSubsectionPeople:
            return [NSIndexPath indexPathForRow:1 inSection:section];
        case BlogDetailsSubsectionPlugins:
            return [NSIndexPath indexPathForRow:2 inSection:section];
    }
}

#pragma mark - Properties

- (NSIndexPath *)restorableSelectedIndexPath
{
    if (!_restorableSelectedIndexPath) {
        // If nil, default to stats subsection.
        BlogDetailsSubsection subsection = [self defaultSubsection];
        self.selectedSectionCategory = [self sectionCategoryWithSubsection:subsection blog: self.blog];
        NSUInteger section = [self findSectionIndexWithSections:self.tableSections category:self.selectedSectionCategory];
        _restorableSelectedIndexPath = [NSIndexPath indexPathForRow:0 inSection:section];
    }

    return _restorableSelectedIndexPath;
}

- (void)setRestorableSelectedIndexPath:(NSIndexPath *)restorableSelectedIndexPath
{
    if (restorableSelectedIndexPath != nil && restorableSelectedIndexPath.section < [self.tableSections count]) {
        BlogDetailsSection *section = [self.tableSections objectAtIndex:restorableSelectedIndexPath.section];
        switch (section.category) {
            case BlogDetailsSectionCategoryQuickAction:
            case BlogDetailsSectionCategoryQuickStart:
            case BlogDetailsSectionCategoryJetpackBrandingCard:
            case BlogDetailsSectionCategoryDomainCredit: {
                _restorableSelectedIndexPath = nil;
            }
                break;
            default: {
                self.selectedSectionCategory = section.category;
                _restorableSelectedIndexPath = restorableSelectedIndexPath;
            }
                break;
        }
        return;
    }

    _restorableSelectedIndexPath = nil;
}

- (SiteIconPickerPresenter *)siteIconPickerPresenter
{
    if (!_siteIconPickerPresenter) {
        _siteIconPickerPresenter = [[SiteIconPickerPresenter alloc]initWithBlog:self.blog];
    }
    return _siteIconPickerPresenter;
}

#pragma mark - iOS 10 bottom padding

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)sectionNum {
    BlogDetailsSection *section = self.tableSections[sectionNum];
    BOOL isLastSection = sectionNum == self.tableSections.count - 1;
    BOOL hasTitle = section.footerTitle != nil && ![section.footerTitle isEmpty];
    if (hasTitle) {
        return UITableViewAutomaticDimension;
    }
    if (isLastSection) {
        return BlogDetailSectionFooterHeight;
    }
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)sectionNum {
    BlogDetailsSection *section = self.tableSections[sectionNum];
    BOOL hasTitle = section.title != nil && ![section.title isEmpty];

    if (section.showQuickStartMenu == true) {
        return BlogDetailQuickStartSectionHeaderHeight;
    } else if (hasTitle) {
        return BlogDetailSectionTitleHeaderHeight;
    }
    return BlogDetailSectionsSpacing;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    BlogDetailsSection *detailSection = self.tableSections[section];
    NSString *footerTitle = detailSection.footerTitle;
    if (footerTitle != nil) {
        BlogDetailsSectionFooterView *footerView = (BlogDetailsSectionFooterView *)[tableView dequeueReusableHeaderFooterViewWithIdentifier:BlogDetailsSectionFooterIdentifier];
        // If the next section has title, gives extra spacing between two sections.
        BOOL shouldShowExtraSpacing = (self.tableSections.count > section + 1) ? (self.tableSections[section + 1].title != nil): NO;
        [footerView updateUIWithTitle:footerTitle shouldShowExtraSpacing:shouldShowExtraSpacing];
        return footerView;
    }

    return nil;
}

#pragma mark - Data Model setup

- (void)reloadTableViewPreservingSelection
{
    // Configure and reload table data when appearing to ensure pending comment count is updated
    [self.tableView reloadData];

    // Check if the last selected category index needs to be updated after a dynamic section is activated and displayed.
    // QuickStart and Use Domain are dynamic section, which means they can be removed or hidden at any time.
    NSUInteger sectionIndex = [self findSectionIndexWithSections:self.tableSections category:self.selectedSectionCategory];

    if (sectionIndex != NSNotFound && self.restorableSelectedIndexPath.section != sectionIndex) {
        BlogDetailsSection *section = [self.tableSections objectAtIndex:sectionIndex];

        NSUInteger row = 0;

        // For QuickStart and Use Domain cases we want to select the first row on the next available section
        switch (section.category) {
            case BlogDetailsSectionCategoryQuickAction:
            case BlogDetailsSectionCategoryQuickStart:
            case BlogDetailsSectionCategoryJetpackBrandingCard:
            case BlogDetailsSectionCategoryDomainCredit: {
                BlogDetailsSubsection subsection = [self defaultSubsection];
                BlogDetailsSectionCategory category = [self sectionCategoryWithSubsection:subsection blog: self.blog];
                sectionIndex = [self findSectionIndexWithSections:self.tableSections category:category];
            }
                break;
            default:
                row = self.restorableSelectedIndexPath.row;
                break;
        }

        self.restorableSelectedIndexPath = [NSIndexPath indexPathForRow:row inSection:sectionIndex];
    }

    BOOL isValidIndexPath = self.restorableSelectedIndexPath.section < self.tableView.numberOfSections &&
                            self.restorableSelectedIndexPath.row < [self.tableView numberOfRowsInSection:self.restorableSelectedIndexPath.section];
    if (isValidIndexPath && ![self splitViewControllerIsHorizontallyCompact]) {
        // And finally we'll reselect the selected row, if there is one
        [self.tableView selectRowAtIndexPath:self.restorableSelectedIndexPath
                                    animated:NO
                              scrollPosition:[self optimumScrollPositionForIndexPath:self.restorableSelectedIndexPath]];
    }
}

- (UITableViewScrollPosition)optimumScrollPositionForIndexPath:(NSIndexPath *)indexPath
{
    // Try and avoid scrolling if not necessary
    CGRect cellRect = [self.tableView rectForRowAtIndexPath:indexPath];
    BOOL cellIsNotFullyVisible = !CGRectContainsRect(self.tableView.bounds, cellRect);
    return (cellIsNotFullyVisible) ? UITableViewScrollPositionMiddle : UITableViewScrollPositionNone;
}

- (void)configureTableViewData
{
    NSMutableArray *marr = [NSMutableArray array];
    
    if (MigrationSuccessCardView.shouldShowMigrationSuccessCard == YES) {
        [marr addObject:[self migrationSuccessSectionViewModel]];
    }

    if ([self shouldShowJetpackInstallCard]) {
        [marr addObject:[self jetpackInstallSectionViewModel]];
    }

    if (self.shouldShowTopJetpackBrandingMenuCard == YES) {
        [marr addObject:[self jetpackCardSectionViewModel]];
    }

    if ([DomainCreditEligibilityChecker canRedeemDomainCreditWithBlog:self.blog]) {
        if (!self.hasLoggedDomainCreditPromptShownEvent) {
            [WPAnalytics track:WPAnalyticsStatDomainCreditPromptShown];
            self.hasLoggedDomainCreditPromptShownEvent = YES;
        }
        [marr addObject:[self domainCreditSectionViewModel]];
    }
    if ([self shouldShowQuickStartChecklist]) {
        [marr addObject:[self quickStartSectionViewModel]];
    }
    if ([self isDashboardEnabled] && ![self splitViewControllerIsHorizontallyCompact]) {
        [marr addObject:[self homeSectionViewModel]];
    }
    if ([self shouldAddJetpackSection]) {
        [marr addObject:[self jetpackSectionViewModel]];
    }
    
    if ([self shouldAddGeneralSection]) {
        [marr addObject:[self generalSectionViewModel]];
    }

    [marr addObject:[self publishTypeSectionViewModel]];
    
    if ([self shouldAddPersonalizeSection]) {
        [marr addObject:[self personalizeSectionViewModel]];
    }
    
    [marr addObject:[self configurationSectionViewModel]];
    [marr addObject:[self externalSectionViewModel]];
    if ([self.blog supports:BlogFeatureRemovable]) {
        [marr addObject:[self removeSiteSectionViewModel]];
    }
    
    if (self.shouldShowBottomJetpackBrandingMenuCard == YES) {
        [marr addObject:[self jetpackCardSectionViewModel]];
    }

    // Assign non mutable copy.
    self.tableSections = [NSArray arrayWithArray:marr];
}

- (BlogDetailsSection *)homeSectionViewModel
{
    __weak __typeof(self) weakSelf = self;
    NSMutableArray *rows = [NSMutableArray array];
    
    [rows addObject:[[BlogDetailsRow alloc] initWithTitle:NSLocalizedString(@"Home", @"Noun. Links to a blog's dashboard screen.")
                                  accessibilityIdentifier:@"Home Row"
                                                    image:[UIImage gridiconOfType:GridiconTypeHouse]
                                                 callback:^{
                                                    [weakSelf showDashboard];
                                                 }]];
    
    return [[BlogDetailsSection alloc] initWithTitle:nil andRows:rows category:BlogDetailsSectionCategoryHome];
}

- (BlogDetailsSection *)generalSectionViewModel
{
    __weak __typeof(self) weakSelf = self;
    NSMutableArray *rows = [NSMutableArray array];
    
    BlogDetailsRow *statsRow = [[BlogDetailsRow alloc] initWithTitle:NSLocalizedString(@"Stats", @"Noun. Abbv. of Statistics. Links to a blog's Stats screen.")
                                  accessibilityIdentifier:@"Stats Row"
                                                    image:[UIImage gridiconOfType:GridiconTypeStatsAlt]
                                                 callback:^{
        [weakSelf showStatsFromSource:BlogDetailsNavigationSourceRow];
                                                 }];
    statsRow.quickStartIdentifier = QuickStartTourElementStats;
    [rows addObject:statsRow];

    if ([self.blog supports:BlogFeatureActivity] && ![self.blog isWPForTeams]) {
        [rows addObject:[[BlogDetailsRow alloc] initWithTitle:NSLocalizedString(@"Activity", @"Noun. Links to a blog's Activity screen.")
                                                        image:[UIImage gridiconOfType:GridiconTypeHistory]
                                                     callback:^{
                                                         [weakSelf showActivity];
                                                     }]];
    }
    
    if ([self shouldShowBlaze]) {
        [rows addObject:[self blazeRow]];
    }

// Temporarily disabled
//    if ([self.blog supports:BlogFeaturePlans] && ![self.blog isWPForTeams]) {
//        BlogDetailsRow *plansRow = [[BlogDetailsRow alloc] initWithTitle:NSLocalizedString(@"Plans", @"Action title. Noun. Links to a blog's Plans screen.")
//                                                         identifier:BlogDetailsPlanCellIdentifier
//                                                              image:[UIImage gridiconOfType:GridiconTypePlans]
//                                                           callback:^{
//                                                               [weakSelf showPlansFromSource:BlogDetailsNavigationSourceRow];
//                                                           }];
//
//        plansRow.detail = self.blog.planTitle;
//        plansRow.quickStartIdentifier = QuickStartTourElementPlans;
//        [rows addObject:plansRow];
//    }

    return [[BlogDetailsSection alloc] initWithTitle:nil andRows:rows category:BlogDetailsSectionCategoryGeneral];
}

- (BlogDetailsSection *)jetpackSectionViewModel
{
    __weak __typeof(self) weakSelf = self;
    NSMutableArray *rows = [NSMutableArray array];
    
    BlogDetailsRow *statsRow = [[BlogDetailsRow alloc] initWithTitle:NSLocalizedString(@"Stats", @"Noun. Abbv. of Statistics. Links to a blog's Stats screen.")
                                  accessibilityIdentifier:@"Stats Row"
                                                    image:[UIImage gridiconOfType:GridiconTypeStatsAlt]
                                                 callback:^{
        [weakSelf showStatsFromSource:BlogDetailsNavigationSourceRow];
                                                 }];
    statsRow.quickStartIdentifier = QuickStartTourElementStats;
    [rows addObject:statsRow];

    if ([self.blog supports:BlogFeatureActivity] && ![self.blog isWPForTeams]) {
        [rows addObject:[[BlogDetailsRow alloc] initWithTitle:NSLocalizedString(@"Activity Log", @"Noun. Links to a blog's Activity screen.")
                                      accessibilityIdentifier:@"Activity Log Row"
                                                        image:[UIImage gridiconOfType:GridiconTypeHistory]
                                                     callback:^{
                                                         [weakSelf showActivity];
                                                     }]];
    }


    if ([self.blog isBackupsAllowed]) {
        [rows addObject:[[BlogDetailsRow alloc] initWithTitle:NSLocalizedString(@"Backup", @"Noun. Links to a blog's Jetpack Backups screen.")
                                      accessibilityIdentifier:@"Backup Row"
                                                        image:[UIImage gridiconOfType:GridiconTypeCloudUpload]
                                                     callback:^{
                                                         [weakSelf showBackup];
                                                     }]];
    }

    if ([self.blog isScanAllowed]) {
        [rows addObject:[[BlogDetailsRow alloc] initWithTitle:NSLocalizedString(@"Scan", @"Noun. Links to a blog's Jetpack Scan screen.")
                                      accessibilityIdentifier:@"Scan Row"
                                                        image:[UIImage imageNamed:@"jetpack-scan-menu-icon"]
                                                     callback:^{
                                                         [weakSelf showScan];
                                                     }]];
    }

    if ([self.blog supports:BlogFeatureJetpackSettings]) {
        BlogDetailsRow *settingsRow = [[BlogDetailsRow alloc] initWithTitle:NSLocalizedString(@"Jetpack Settings", @"Noun. Title. Links to the blog's Settings screen.")
                                                         identifier:BlogDetailsSettingsCellIdentifier
                                            accessibilityIdentifier:@"Jetpack Settings Row"
                                                              image:[UIImage gridiconOfType:GridiconTypeCog]
                                                           callback:^{
                                                               [weakSelf showJetpackSettings];
                                                           }];

        [rows addObject:settingsRow];
    }
    
    if ([self shouldShowBlaze]) {
        [rows addObject:[self blazeRow]];
    }
    NSString *title = @"";

    if ([self.blog supports:BlogFeatureJetpackSettings]) {
        title = NSLocalizedString(@"Jetpack", @"Section title for the publish table section in the blog details screen");
    }

    return [[BlogDetailsSection alloc] initWithTitle:title andRows:rows category:BlogDetailsSectionCategoryJetpack];
}

- (BlogDetailsRow *)blazeRow
{
    __weak __typeof(self) weakSelf = self;
    CGSize iconSize = CGSizeMake(BlogDetailGridiconSize, BlogDetailGridiconSize);
    UIImage *blazeIcon = [[UIImage imageNamed:@"icon-blaze"] resizedImage:iconSize interpolationQuality:kCGInterpolationHigh];
    BlogDetailsRow *blazeRow = [[BlogDetailsRow alloc] initWithTitle:NSLocalizedString(@"Blaze", @"Noun. Links to a blog's Blaze screen.")
                                             accessibilityIdentifier:@"Blaze Row"
                                                               image:[blazeIcon imageFlippedForRightToLeftLayoutDirection]
                                                          imageColor:nil
                                                       renderingMode:UIImageRenderingModeAlwaysOriginal
                                                            callback:^{
                                                                [weakSelf showBlaze];
                                                            }];
    blazeRow.showsSelectionState = NO;
    return blazeRow;
}

- (BlogDetailsSection *)publishTypeSectionViewModel
{
    __weak __typeof(self) weakSelf = self;
    NSMutableArray *rows = [NSMutableArray array];

    BlogDetailsRow *postsRow = [[BlogDetailsRow alloc] initWithTitle:NSLocalizedString(@"Posts", @"Noun. Title. Links to the blog's Posts screen.")
                                              accessibilityIdentifier:@"Blog Post Row"
                                                                image:[[UIImage gridiconOfType:GridiconTypePosts] imageFlippedForRightToLeftLayoutDirection]
                                                             callback:^{
                    [weakSelf showPostListFromSource:BlogDetailsNavigationSourceRow];
                                                             }];
    [rows addObject:postsRow];
    
    BlogDetailsRow *mediaRow = [[BlogDetailsRow alloc] initWithTitle:NSLocalizedString(@"Media", @"Noun. Title. Links to the blog's Media library.")
                                             accessibilityIdentifier:@"Media Row"
                                                               image:[UIImage gridiconOfType:GridiconTypeImage]
                                                            callback:^{
                   [weakSelf showMediaLibraryFromSource:BlogDetailsNavigationSourceRow];
                                                            }];
    mediaRow.quickStartIdentifier = QuickStartTourElementMediaScreen;
    [rows addObject:mediaRow];

    if ([self.blog supports:BlogFeaturePages]) {
        BlogDetailsRow *pagesRow = [[BlogDetailsRow alloc] initWithTitle:NSLocalizedString(@"Pages", @"Noun. Title. Links to the blog's Pages screen.")
                                                 accessibilityIdentifier:@"Site Pages Row"
                                                        image:[UIImage gridiconOfType:GridiconTypePages]
                                                     callback:^{
            [weakSelf showPageListFromSource:BlogDetailsNavigationSourceRow];
                                                     }];
        pagesRow.quickStartIdentifier = QuickStartTourElementPages;
        [rows addObject:pagesRow];
    }

    BlogDetailsRow *commentsRow = [[BlogDetailsRow alloc] initWithTitle:NSLocalizedString(@"Comments", @"Noun. Title. Links to the blog's Comments screen.")
                                                          image:[[UIImage gridiconOfType:GridiconTypeComment] imageFlippedForRightToLeftLayoutDirection]
                                                       callback:^{
        [weakSelf showCommentsFromSource:BlogDetailsNavigationSourceRow];
                                                       }];
    [rows addObject:commentsRow];

    NSString *title = NSLocalizedString(@"Publish", @"Section title for the publish table section in the blog details screen");
    return [[BlogDetailsSection alloc] initWithTitle:title andRows:rows category:BlogDetailsSectionCategoryPublish];
}

- (BlogDetailsSection *)personalizeSectionViewModel
{
    __weak __typeof(self) weakSelf = self;
    NSMutableArray *rows = [NSMutableArray array];
    if ([self.blog supports:BlogFeatureThemeBrowsing] && ![self.blog isWPForTeams]) {
        BlogDetailsRow *row = [[BlogDetailsRow alloc] initWithTitle:NSLocalizedString(@"Themes", @"Themes option in the blog details")
                                                              image:[UIImage gridiconOfType:GridiconTypeThemes]
                                                           callback:^{
                                                               [weakSelf showThemes];
                                                           }];
        row.quickStartIdentifier = QuickStartTourElementThemes;
        [rows addObject:row];
    }
    if ([self.blog supports:BlogFeatureMenus]) {
        [rows addObject:[[BlogDetailsRow alloc] initWithTitle:NSLocalizedString(@"Menus", @"Menus option in the blog details")
                                                        image:[[UIImage gridiconOfType:GridiconTypeMenus] imageFlippedForRightToLeftLayoutDirection]
                                                     callback:^{
                                                         [weakSelf showMenus];
                                                     }]];
    }
    NSString *title =NSLocalizedString(@"Personalize", @"Section title for the personalize table section in the blog details screen.");
    return [[BlogDetailsSection alloc] initWithTitle:title andRows:rows category:BlogDetailsSectionCategoryPersonalize];
}

- (BlogDetailsSection *)configurationSectionViewModel
{
    __weak __typeof(self) weakSelf = self;
    NSMutableArray *rows = [NSMutableArray array];

    if ([self shouldAddSharingRow]) {
        BlogDetailsRow *row = [[BlogDetailsRow alloc] initWithTitle:NSLocalizedString(@"Sharing", @"Noun. Title. Links to a blog's sharing options.")
                                        image:[UIImage gridiconOfType:GridiconTypeShare]
                                     callback:^{
            [weakSelf showSharingFromSource:BlogDetailsNavigationSourceRow];
                                     }];
        row.quickStartIdentifier = QuickStartTourElementSharing;
        [rows addObject:row];
    }

    if ([self shouldAddPeopleRow]) {
        [rows addObject:[[BlogDetailsRow alloc] initWithTitle:NSLocalizedString(@"People", @"Noun. Title. Links to the people management feature.")
                                      accessibilityIdentifier:@"People Row"
                                                        image:[UIImage gridiconOfType:GridiconTypeUser]
                                                     callback:^{
                                                         [weakSelf showPeople];
                                                     }]];
    }

    if ([self shouldAddPluginsRow]) {
        [rows addObject:[[BlogDetailsRow alloc] initWithTitle:NSLocalizedString(@"Plugins", @"Noun. Title. Links to the plugin management feature.")
                                                        image:[UIImage gridiconOfType:GridiconTypePlugins]
                                                     callback:^{
                                                         [weakSelf showPlugins];
                                                     }]];
    }

    BlogDetailsRow *row = [[BlogDetailsRow alloc] initWithTitle:NSLocalizedString(@"Site Settings", @"Noun. Title. Links to the blog's Settings screen.")
                                                     identifier:BlogDetailsSettingsCellIdentifier
                                        accessibilityIdentifier:@"Settings Row"
                                                          image:[UIImage gridiconOfType:GridiconTypeCog]
                                                       callback:^{
        [weakSelf showSettingsFromSource:BlogDetailsNavigationSourceRow];
                                                       }];

    [rows addObject:row];

    if ([self shouldAddDomainRegistrationRow]) {
        BlogDetailsRow *domainsRow = [[BlogDetailsRow alloc] initWithTitle:NSLocalizedString(@"Domains", @"Noun. Title. Links to the Domains screen.")
                                                                identifier:BlogDetailsSettingsCellIdentifier
                                                   accessibilityIdentifier:@"Domains Row"
                                                                     image:[UIImage gridiconOfType:GridiconTypeDomains]
                                                                  callback:^{
                                                                    [weakSelf showDomainsFromSource:BlogDetailsNavigationSourceRow];
                                                      }];
        [rows addObject:domainsRow];
    }

    NSString *title = NSLocalizedString(@"Configure", @"Section title for the configure table section in the blog details screen");
    return [[BlogDetailsSection alloc] initWithTitle:title andRows:rows category:BlogDetailsSectionCategoryConfigure];
}

- (BlogDetailsSection *)externalSectionViewModel
{
    __weak __typeof(self) weakSelf = self;
    NSMutableArray *rows = [NSMutableArray array];
    BlogDetailsRow *viewSiteRow = [[BlogDetailsRow alloc] initWithTitle:NSLocalizedString(@"View Site", @"Action title. Opens the user's site in an in-app browser")
                                                                  image:[UIImage gridiconOfType:GridiconTypeGlobe]
                                                               callback:^{
        [weakSelf showViewSiteFromSource:BlogDetailsNavigationSourceRow];
    }];
    viewSiteRow.showsSelectionState = NO;
    [rows addObject:viewSiteRow];

    if ([self shouldDisplayLinkToWPAdmin]) {
        BlogDetailsRow *row = [[BlogDetailsRow alloc] initWithTitle:[self adminRowTitle]
                                                              image:[UIImage gridiconOfType:GridiconTypeMySites]
                                                           callback:^{
                                                               [weakSelf showViewAdmin];
                                                               [weakSelf.tableView deselectSelectedRowWithAnimation:YES];
                                                           }];
        UIImage *image = [[UIImage gridiconOfType:GridiconTypeExternal withSize:CGSizeMake(BlogDetailGridiconAccessorySize, BlogDetailGridiconAccessorySize)] imageFlippedForRightToLeftLayoutDirection];
        UIImageView *accessoryView = [[UIImageView alloc] initWithImage:image];
        accessoryView.tintColor = [WPStyleGuide cellGridiconAccessoryColor]; // Match disclosure icon color.
        row.accessoryView = accessoryView;
        row.showsSelectionState = NO;
        [rows addObject:row];
    }

    NSString *title = NSLocalizedString(@"External", @"Section title for the external table section in the blog details screen");
    return [[BlogDetailsSection alloc] initWithTitle:title andRows:rows category:BlogDetailsSectionCategoryExternal];
}

- (BlogDetailsSection *)removeSiteSectionViewModel
{
    __weak __typeof(self) weakSelf = self;
    NSMutableArray *rows = [NSMutableArray array];
    BlogDetailsRow *removeSiteRow = [[BlogDetailsRow alloc] initWithTitle:NSLocalizedString(@"Remove Site", @"Button to remove a site from the app")
                                                               identifier:BlogDetailsRemoveSiteCellIdentifier
                                                                    image:nil
                                                                 callback:^{
                                                                     [weakSelf.tableView deselectSelectedRowWithAnimation:YES];
                                                                     [weakSelf showRemoveSiteAlert];
                                                                 }];
    removeSiteRow.showsSelectionState = NO;
    removeSiteRow.forDestructiveAction = YES;
    [rows addObject:removeSiteRow];

    return [[BlogDetailsSection alloc] initWithTitle:nil andRows:rows category:BlogDetailsSectionCategoryRemoveSite];

}

- (NSString *)adminRowTitle
{
    if (self.blog.isHostedAtWPcom) {
        return NSLocalizedString(@"Dashboard", @"Action title. Noun. Opens the user's WordPress.com dashboard in an external browser.");
    } else {
        return NSLocalizedString(@"WP Admin", @"Action title. Noun. Opens the user's WordPress Admin in an external browser.");
    }
}

// Non .com users and .com user whose accounts were created
// before LastWPAdminAccessDate should have access to WPAdmin
- (BOOL)shouldDisplayLinkToWPAdmin
{
    if (!self.blog.isHostedAtWPcom) {
        return YES;
    }
    NSDate *hideWPAdminDate = [NSDate dateWithISO8601String:HideWPAdminDate];
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    WPAccount *defaultAccount = [WPAccount lookupDefaultWordPressComAccountInContext:context];
    return [defaultAccount.dateCreated compare:hideWPAdminDate] == NSOrderedAscending;
}

#pragma mark Site Switching

- (void)switchToBlog:(Blog*)blog
{
    self.blog = blog;
    [self showInitialDetailsForBlog];
    [self.tableView reloadData];
    [self preloadMetadata];
}

- (void)showInitialDetailsForBlog
{
    if ([self splitViewControllerIsHorizontallyCompact]) {
        return;
    }

    self.restorableSelectedIndexPath = nil;
    
    WPSplitViewController *splitViewController = (WPSplitViewController *)self.splitViewController;
    splitViewController.isShowingInitialDetail = YES;
    BlogDetailsSubsection subsection = [self defaultSubsection];
    switch (subsection) {
        case BlogDetailsSubsectionHome:
            [self showDetailViewForSubsection:BlogDetailsSubsectionHome];
            break;
        case BlogDetailsSubsectionStats:
            [self showDetailViewForSubsection:BlogDetailsSubsectionStats];
            break;
        case BlogDetailsSubsectionPosts:
            [self showDetailViewForSubsection: BlogDetailsSubsectionPosts];
            break;
        default:
            break;
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.tableSections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    BlogDetailsSection *detailSection = [self.tableSections objectAtIndex:section];

    /// For larger texts we don't show the quick actions row
    if (detailSection.category == BlogDetailsSectionCategoryQuickAction && self.isAccessibilityCategoryEnabled) {
        return 0;
    }

    return [detailSection.rows count];
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    BlogDetailsSection *section = [self.tableSections objectAtIndex:indexPath.section];
    BlogDetailsRow *row = [section.rows objectAtIndex:indexPath.row];
    cell.textLabel.text = row.title;
    cell.accessibilityIdentifier = row.accessibilityIdentifier ?: row.identifier;
    cell.detailTextLabel.text = row.detail;
    cell.imageView.image = row.image;
    cell.imageView.tintColor = row.imageColor;
    if (row.accessoryView) {
        cell.accessoryView = row.accessoryView;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    BlogDetailsSection *section = [self.tableSections objectAtIndex:indexPath.section];

    if (section.category == BlogDetailsSectionCategoryJetpackInstallCard) {
        JetpackRemoteInstallTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:BlogDetailsJetpackInstallCardCellIdentifier];
        [cell configureWithBlog:self.blog viewController:self];
        return cell;
    }

    if (section.category == BlogDetailsSectionCategoryQuickAction) {
        QuickActionsCell *cell = [tableView dequeueReusableCellWithIdentifier:BlogDetailsQuickActionsCellIdentifier];
        [self configureQuickActionsWithCell: cell];
        return cell;
    }
    
    if (section.category == BlogDetailsSectionCategoryQuickStart) {
        QuickStartCell *cell = [tableView dequeueReusableCellWithIdentifier:BlogDetailsQuickStartCellIdentifier];
        [cell configureWithBlog:self.blog viewController:self];
        return cell;
    }

    if (section.category == BlogDetailsSectionCategoryMigrationSuccess && MigrationSuccessCardView.shouldShowMigrationSuccessCard == YES) {
        MigrationSuccessCell *cell = [tableView dequeueReusableCellWithIdentifier:BlogDetailsMigrationSuccessCellIdentifier];
        [cell configureWithViewController:self];
        return cell;
    }
    
    if (section.category == BlogDetailsSectionCategoryJetpackBrandingCard) {
        JetpackBrandingMenuCardCell *cell = [tableView dequeueReusableCellWithIdentifier:BlogDetailsJetpackBrandingCardCellIdentifier];
        [cell configureWithViewController:self];
        return cell;
    }

    BlogDetailsRow *row = [section.rows objectAtIndex:indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:row.identifier];
    cell.accessibilityHint = row.accessibilityHint;
    cell.accessoryView = nil;
    cell.textLabel.textAlignment = NSTextAlignmentNatural;
    if (row.forDestructiveAction) {
        cell.accessoryType = UITableViewCellAccessoryNone;
        [WPStyleGuide configureTableViewDestructiveActionCell:cell];
    } else {
        if (row.showsDisclosureIndicator) {
            cell.accessoryType = [self splitViewControllerIsHorizontallyCompact] ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        [WPStyleGuide configureTableViewCell:cell];
    }
    
    QuickStartTourGuide *tourGuide = [QuickStartTourGuide shared];
    
    
    BOOL shouldShowSpotlight =
        tourGuide.entryPointForCurrentTour == QuickStartTourEntryPointBlogDetails ||
        tourGuide.currentTourMustBeShownFromBlogDetails;
    
    if ([tourGuide isCurrentElement:row.quickStartIdentifier] && shouldShowSpotlight) {
        row.accessoryView = [QuickStartSpotlightView new];
    } else if ([row.accessoryView isKindOfClass:[QuickStartSpotlightView class]]) {
        row.accessoryView = nil;
    }

    [self configureCell:cell atIndexPath:indexPath];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    WPSplitViewController *splitViewController = (WPSplitViewController *)self.splitViewController;
    splitViewController.isShowingInitialDetail = NO;
    
    BlogDetailsSection *section = [self.tableSections objectAtIndex:indexPath.section];
    BlogDetailsRow *row = [section.rows objectAtIndex:indexPath.row];
    row.callback();

    if (row.showsSelectionState) {
        self.restorableSelectedIndexPath = indexPath;
    } else {
        if ([self splitViewControllerIsHorizontallyCompact]) {
            // Deselect current row when not in split view layout
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
        } else {
            // Reselect the previous row
            [tableView selectRowAtIndexPath:self.restorableSelectedIndexPath
                                   animated:YES
                             scrollPosition:UITableViewScrollPositionNone];
        }
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    BlogDetailsSection *detailSection = [self.tableSections objectAtIndex:section];
    if (detailSection.showQuickStartMenu) {
        return nil;
    }
    return detailSection.title;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)sectionNum {
    BlogDetailsSection *section = [self.tableSections objectAtIndex:sectionNum];
    if (section.showQuickStartMenu) {
        return [self quickStartHeaderWithTitle:section.title];
    }
    return nil;
}

- (UIView *)quickStartHeaderWithTitle:(NSString *)title
{
    __weak __typeof(self) weakSelf = self;
    BlogDetailsSectionHeaderView *view = [self.tableView dequeueReusableHeaderFooterViewWithIdentifier:BlogDetailsSectionHeaderViewIdentifier];
    [view setTitle:title];
    view.ellipsisButtonDidTouch = ^(BlogDetailsSectionHeaderView *header) {
        [weakSelf removeQuickStartFromBlog:weakSelf.blog
                                sourceView:header
                                sourceRect:header.ellipsisButton.frame];
    };
    return view;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    BOOL isNewSelection = (indexPath != tableView.indexPathForSelectedRow);

    if (isNewSelection) {
        return indexPath;
    } else {
        return nil;
    }
}

#pragma mark - Private methods

- (void)trackEvent:(WPAnalyticsStat)event fromSource:(BlogDetailsNavigationSource)source {
    
    NSString *sourceString = [self propertiesStringForSource:source];
    
    [WPAppAnalytics track:event withProperties:@{WPAppAnalyticsKeyTapSource: sourceString, WPAppAnalyticsKeyTabSource: @"site_menu"} withBlog:self.blog];
}

- (NSString *)propertiesStringForSource:(BlogDetailsNavigationSource)source {
    switch (source) {
        case BlogDetailsNavigationSourceRow:
            return @"row";
        case BlogDetailsNavigationSourceLink:
            return @"link";
        case BlogDetailsNavigationSourceButton:
            return @"button";
        default:
            return @"";
    }
}

- (void)preloadBlogData
{
    WordPressAppDelegate *appDelegate = [WordPressAppDelegate shared];
    BOOL isOnWifi = [appDelegate.internetReachability isReachableViaWiFi];

    // only preload on wifi
    if (isOnWifi) {
        [self preloadPosts];
        [self preloadPages];
        [self preloadComments];
        [self preloadMetadata];
        [self preloadDomains];
    }
}

- (void)preloadPosts
{
    [self preloadPostsOfType:PostServiceTypePost];
}

- (void)preloadPages
{
    [self preloadPostsOfType:PostServiceTypePage];
}

// preloads posts or pages.
- (void)preloadPostsOfType:(PostServiceType)postType
{
    // Temporarily disable posts preloading until we can properly resolve the issues on:
    // https://github.com/wordpress-mobile/WordPress-iOS/issues/6151
    // Brent C. Nov 3/2016
    BOOL preloadingPostsDisabled = YES;
    if (preloadingPostsDisabled) {
        return;
    }

    NSDate *lastSyncDate;
    if ([postType isEqual:PostServiceTypePage]) {
        lastSyncDate = self.blog.lastPagesSync;
    } else {
        lastSyncDate = self.blog.lastPostsSync;
    }
    NSTimeInterval now = [[NSDate date] timeIntervalSinceReferenceDate];
    NSTimeInterval lastSync = lastSyncDate.timeIntervalSinceReferenceDate;
    if (now - lastSync > PreloadingCacheTimeout) {
        NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
        PostService *postService = [[PostService alloc] initWithManagedObjectContext:context];
        PostListFilterSettings *filterSettings = [[PostListFilterSettings alloc] initWithBlog:self.blog postType:postType];
        PostListFilter *filter = [filterSettings currentPostListFilter];

        PostServiceSyncOptions *options = [PostServiceSyncOptions new];
        options.statuses = filter.statuses;
        options.authorID = [filterSettings authorIDFilter];
        options.purgesLocalSync = YES;

        if ([postType isEqual:PostServiceTypePage]) {
            self.blog.lastPagesSync = [NSDate date];
        } else {
            self.blog.lastPostsSync = [NSDate date];
        }
        NSError *error = nil;
        [self.blog.managedObjectContext save:&error];

        [postService syncPostsOfType:postType withOptions:options forBlog:self.blog success:nil failure:^(NSError *error) {
            NSDate *invalidatedDate = [NSDate dateWithTimeIntervalSince1970:0.0];
            if ([postType isEqual:PostServiceTypePage]) {
                self.blog.lastPagesSync = invalidatedDate;
            } else {
                self.blog.lastPostsSync = invalidatedDate;
            }
        }];
    }
}

- (void)preloadComments
{
    CommentService *commentService = [[CommentService alloc] initWithCoreDataStack:[ContextManager sharedInstance]];

    if ([CommentService shouldRefreshCacheFor:self.blog]) {
        [commentService syncCommentsForBlog:self.blog withStatus:CommentStatusFilterAll success:nil failure:nil];
    }
}

- (void)preloadMetadata
{
    __weak __typeof(self) weakSelf = self;
    [self.blogService syncBlogAndAllMetadata:self.blog
                           completionHandler:^{
                               [weakSelf configureTableViewData];
                               [weakSelf reloadTableViewPreservingSelection];
                           }];
}

- (void)preloadDomains
{
    if (![self shouldAddDomainRegistrationRow]) {
        return;
    }

    [self.blogService refreshDomainsFor:self.blog
                                success:nil
                                failure:nil];
}

- (void)scrollToElement:(QuickStartTourElement) element
{
    int sectionCount = 0;
    int rowCount = 0;
    
    MySiteViewController *parentVC = (MySiteViewController *)self.parentViewController;
    
    for (BlogDetailsSection *section in self.tableSections) {
        rowCount = 0;
        for (BlogDetailsRow *row in section.rows) {
            if (row.quickStartIdentifier == element) {
                NSIndexPath *path = [NSIndexPath indexPathForRow:rowCount inSection:sectionCount];
                UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:path];
                [parentVC.scrollView scrollVerticallyToView:cell animated:true];
            }
            rowCount++;
        }
        sectionCount++;
    }
}

- (void)showCommentsFromSource:(BlogDetailsNavigationSource)source
{
    [self trackEvent:WPAnalyticsStatOpenedComments fromSource:source];
    CommentsViewController *controller = [CommentsViewController controllerWithBlog:self.blog];
    controller.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    [self.presentationDelegate presentBlogDetailsViewController:controller];

    [[QuickStartTourGuide shared] visited:QuickStartTourElementBlogDetailNavigation];
}

- (void)showPostListFromSource:(BlogDetailsNavigationSource)source
{
    [self trackEvent:WPAnalyticsStatOpenedPosts fromSource:source];
    PostListViewController *controller = [PostListViewController controllerWithBlog:self.blog];
    controller.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    [self.presentationDelegate presentBlogDetailsViewController:controller];

    [[QuickStartTourGuide shared] visited:QuickStartTourElementBlogDetailNavigation];
}

- (void)showPageListFromSource:(BlogDetailsNavigationSource)source
{
    [self trackEvent:WPAnalyticsStatOpenedPages fromSource:source];
    PageListViewController *controller = [PageListViewController controllerWithBlog:self.blog];
    controller.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    [self.presentationDelegate presentBlogDetailsViewController:controller];

    [[QuickStartTourGuide shared] visited:QuickStartTourElementPages];
}

- (void)showMediaLibraryFromSource:(BlogDetailsNavigationSource)source
{
    [self trackEvent:WPAnalyticsStatOpenedMediaLibrary fromSource:source];
    MediaLibraryViewController *controller = [[MediaLibraryViewController alloc] initWithBlog:self.blog];
    controller.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    [self.presentationDelegate presentBlogDetailsViewController:controller];

    [[QuickStartTourGuide shared] visited:QuickStartTourElementMediaScreen];
}

- (void)showPeople
{
    UIViewController *controller = [PeopleViewController withJPBannerForBlog:self.blog];
    [self.presentationDelegate presentBlogDetailsViewController:controller];

    [[QuickStartTourGuide shared] visited:QuickStartTourElementBlogDetailNavigation];
}

- (void)showPlugins
{
    [WPAppAnalytics track:WPAnalyticsStatOpenedPluginDirectory withBlog:self.blog];
    PluginDirectoryViewController *controller = [self makePluginDirectoryViewControllerWithBlog:self.blog];
    controller.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    [self.presentationDelegate presentBlogDetailsViewController:controller];

    [[QuickStartTourGuide shared] visited:QuickStartTourElementBlogDetailNavigation];
}

- (void)showPlansFromSource:(BlogDetailsNavigationSource)source
{
    [self trackEvent:WPAnalyticsStatOpenedPlans fromSource:source];
    PlanListViewController *controller = [[PlanListViewController alloc] initWithStyle:UITableViewStyleGrouped];
    controller.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    [self.presentationDelegate presentBlogDetailsViewController:controller];

    [[QuickStartTourGuide shared] visited:QuickStartTourElementPlans];
}

- (void)showSettingsFromSource:(BlogDetailsNavigationSource)source
{
    [self trackEvent:WPAnalyticsStatOpenedSiteSettings fromSource:source];
    SiteSettingsViewController *controller = [[SiteSettingsViewController alloc] initWithBlog:self.blog];
    controller.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    [self.presentationDelegate presentBlogDetailsViewController:controller];

    [[QuickStartTourGuide shared] visited:QuickStartTourElementBlogDetailNavigation];
}

- (void)showDomainsFromSource:(BlogDetailsNavigationSource)source
{
    [DomainsDashboardCoordinator presentDomainsDashboardWithPresenter:self.presentationDelegate
                                                               source:[self propertiesStringForSource:source]
                                                                 blog:self.blog];
}

-(void)showJetpackSettings
{
    JetpackSettingsViewController *controller = [[JetpackSettingsViewController alloc] initWithBlog:self.blog];
    controller.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    [self.presentationDelegate presentBlogDetailsViewController:controller];
}

- (void)showSharingFromSource:(BlogDetailsNavigationSource)source
{
    UIViewController *controller;
    if (![self.blog supportsPublicize]) {
        // if publicize is disabled, show the sharing buttons settings.
        controller = [[SharingButtonsViewController alloc] initWithBlog:self.blog];

    } else {
        controller = [[SharingViewController alloc] initWithBlog:self.blog delegate:nil];
    }

    [self trackEvent:WPAnalyticsStatOpenedSharingManagement fromSource:source];
    controller.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    [self.presentationDelegate presentBlogDetailsViewController:controller];

    [[QuickStartTourGuide shared] visited:QuickStartTourElementSharing];
}

- (void)showStatsFromSource:(BlogDetailsNavigationSource)source
{
    [self trackEvent:WPAnalyticsStatStatsAccessed fromSource:source];
    UIViewController *statsView = [self viewControllerForStats];

    // Calling `showDetailViewController:sender:` should do this automatically for us,
    // but when showing stats from our 3D Touch shortcut iOS sometimes incorrectly
    // presents the stats view controller as modal instead of pushing it. As a
    // workaround for now, we'll manually decide whether to push or use `showDetail`.
    // @frosty 2016-09-05
    if (self.splitViewController.isCollapsed) {
        [self.navigationController pushViewController:statsView animated:YES];
    } else {
        [self.presentationDelegate presentBlogDetailsViewController:statsView];
    }

    [[QuickStartTourGuide shared] visited:QuickStartTourElementStats];
}

- (void)showDashboard
{
    BlogDashboardViewController *controller = [[BlogDashboardViewController alloc] initWithBlog:self.blog embeddedInScrollView:NO];
    controller.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    controller.extendedLayoutIncludesOpaqueBars = YES;
    [self.presentationDelegate presentBlogDetailsViewController:controller];
}

- (void)showActivity
{
    JetpackActivityLogViewController *controller = [[JetpackActivityLogViewController alloc] initWithBlog:self.blog];
    controller.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    [self.presentationDelegate presentBlogDetailsViewController:controller];

    [[QuickStartTourGuide shared] visited:QuickStartTourElementBlogDetailNavigation];
}

- (void)showBlaze
{
    [BlazeEventsTracker trackEntryPointTappedFor:BlazeSourceMenuItem];
    
    [BlazeFlowCoordinator presentBlazeInViewController:self
                                                source:BlazeSourceMenuItem
                                                  blog:self.blog
                                                  post:nil];
}

- (void)showScan
{
    UIViewController *controller = [JetpackScanViewController withJPBannerForBlog:self.blog];
    [self.presentationDelegate presentBlogDetailsViewController:controller];

    [[QuickStartTourGuide shared] visited:QuickStartTourElementBlogDetailNavigation];
}

- (void)showBackup
{
    UIViewController *controller = [BackupListViewController withJPBannerForBlog:self.blog];
    [self.presentationDelegate presentBlogDetailsViewController:controller];
}

- (void)showThemes
{
    [WPAppAnalytics track:WPAnalyticsStatThemesAccessedThemeBrowser withBlog:self.blog];
    ThemeBrowserViewController *viewController = [ThemeBrowserViewController browserWithBlog:self.blog];
    viewController.onWebkitViewControllerClose = ^(void) {
        [self startAlertTimer];
    };
    UIViewController *jpWrappedViewController = [viewController withJPBanner];
    [self.presentationDelegate presentBlogDetailsViewController:jpWrappedViewController];

    [[QuickStartTourGuide shared] visited:QuickStartTourElementThemes];
}

- (void)showMenus
{
    [WPAppAnalytics track:WPAnalyticsStatMenusAccessed withBlog:self.blog];
    UIViewController *viewController = [MenusViewController withJPBannerForBlog:self.blog];
    [self.presentationDelegate presentBlogDetailsViewController:viewController];

    [[QuickStartTourGuide shared] visited:QuickStartTourElementBlogDetailNavigation];
}

- (void)showViewSiteFromSource:(BlogDetailsNavigationSource)source
{
    [self trackEvent:WPAnalyticsStatOpenedViewSite fromSource:source];
    
    NSURL *targetURL = [NSURL URLWithString:self.blog.homeURL];

    void (^onWebViewControllerClose)(void) = ^(void) {
        [self startAlertTimer];
    };
    UIViewController *webViewController = [WebViewControllerFactory controllerWithUrl:targetURL
                                                                                 blog:self.blog
                                                                               source:@"my_site_view_site"
                                                                      withDeviceModes:true
                                                                              onClose:onWebViewControllerClose];
    LightNavigationController *navController = [[LightNavigationController alloc] initWithRootViewController:webViewController];
    if (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        navController.modalPresentationStyle = UIModalPresentationFullScreen;
    }

    [self presentViewController:navController
                       animated:YES
                     completion:nil];

    MySiteViewController *parentVC = (MySiteViewController *)self.parentViewController;
    
    QuickStartTourGuide *guide = [QuickStartTourGuide shared];

    if ([guide isCurrentElement:QuickStartTourElementViewSite]) {
        [[QuickStartTourGuide shared] visited:QuickStartTourElementViewSite];
        [parentVC toggleSpotlightOnSitePicker];
    } else {
        // Just mark as completed if we've viewed the site and aren't
        //  currently working on the View Site tour.
        [[QuickStartTourGuide shared] completeViewSiteTourForBlog:self.blog];
    }

}

- (void)showViewAdmin
{
    if (![ReachabilityUtils isInternetReachable]) {
        [ReachabilityUtils showAlertNoInternetConnection];
        return;
    }

    [WPAppAnalytics track:WPAnalyticsStatOpenedViewAdmin withBlog:self.blog];

    NSString *dashboardUrl;
    if (self.blog.isHostedAtWPcom) {
        dashboardUrl = [NSString stringWithFormat:@"%@%@", WPCalypsoDashboardPath, self.blog.hostname];
    } else {
        dashboardUrl = [self.blog adminUrlWithPath:@""];
    }
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:dashboardUrl] options:nil completionHandler:nil];

    [[QuickStartTourGuide shared] visited:QuickStartTourElementBlogDetailNavigation];
}

- (BOOL)shouldShowJetpackInstallCard
{
    return ![WPDeviceIdentification isiPad] && [JetpackInstallPluginHelper shouldShowCardFor:self.blog];
}

- (BOOL)shouldShowBlaze
{
    return [BlazeHelper isBlazeFlagEnabled] && [self.blog supports:BlogFeatureBlaze];
}

#pragma mark - Remove Site

- (void)showRemoveSiteAlert
{
    NSString *model = [[UIDevice currentDevice] localizedModel];
    NSString *message = [NSString stringWithFormat:NSLocalizedString(@"Are you sure you want to continue?\n All site data will be removed from your %@.", @"Title for the remove site confirmation alert, %@ will be replaced with iPhone/iPad/iPod Touch"), model];
    NSString *cancelTitle = NSLocalizedString(@"Cancel", nil);
    NSString *destructiveTitle = NSLocalizedString(@"Remove Site", @"Button to remove a site from the app");

    UIAlertControllerStyle alertStyle = [UIDevice isPad] ? UIAlertControllerStyleAlert : UIAlertControllerStyleActionSheet;
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil
                                                                             message:message
                                                                      preferredStyle:alertStyle];

    [alertController addCancelActionWithTitle:cancelTitle handler:nil];
    [alertController addDestructiveActionWithTitle:destructiveTitle handler:^(UIAlertAction *action) {
        [self confirmRemoveSite];
    }];

    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)confirmRemoveSite
{
    BlogService *blogService = [[BlogService alloc] initWithCoreDataStack:[ContextManager sharedInstance]];
    [blogService removeBlog:self.blog];
    [[WordPressAppDelegate shared] trackLogoutIfNeeded];

    if ([Feature enabled:FeatureFlagContentMigration] && [AppConfiguration isWordPress]) {
        [ContentMigrationCoordinator.shared cleanupExportedDataIfNeeded];
    }
    
    // Delete local data after removing the last site
    if (!AccountHelper.isLoggedIn) {
        [AccountHelper deleteAccountData];
    }

    [self.navigationController popToRootViewControllerAnimated:YES];
}

#pragma mark - Notification handlers

- (void)handleDataModelChange:(NSNotification *)note
{
    NSSet *deletedObjects = note.userInfo[NSDeletedObjectsKey];
    if ([deletedObjects containsObject:self.blog]) {
        [self.navigationController popToRootViewControllerAnimated:NO];
        return;
    }

    if (self.blog.account == nil || self.blog.account.isDeleted) {
        // No need to reload this screen if the blog's account is deleted (i.e. during logout)
        return;
    }

    BOOL isQuickStartSectionShownBefore = [self findSectionIndexWithSections:self.tableSections category:BlogDetailsSectionCategoryQuickStart] != NSNotFound;

    NSSet *updatedObjects = note.userInfo[NSUpdatedObjectsKey];
    if ([updatedObjects containsObject:self.blog] || [updatedObjects containsObject:self.blog.settings]) {
        [self configureTableViewData];
        BOOL isQuickStartSectionShownAfter = [self findSectionIndexWithSections:self.tableSections category:BlogDetailsSectionCategoryQuickStart] != NSNotFound;
        
        // quick start was just enabled
        if (!isQuickStartSectionShownBefore && isQuickStartSectionShownAfter) {
            [self showQuickStart];
        }
        [self reloadTableViewPreservingSelection];
    }
}

#pragma mark - WPSplitViewControllerDetailProvider

- (UIViewController *)initialDetailViewControllerForSplitView:(WPSplitViewController *)splitView
{
    if ([self shouldShowStats]) {
        StatsViewController *statsView = [StatsViewController new];
        statsView.blog = self.blog;
        return statsView;
    } else {
        PostListViewController *postsView = [PostListViewController controllerWithBlog:self.blog];
        postsView.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
        return postsView;
    }
}

#pragma mark - UIViewControllerTransitioningDelegate

- (UIPresentationController *)presentationControllerForPresentedViewController:(UIViewController *)presented presentingViewController:(UIViewController *)presenting sourceViewController:(UIViewController *)source
{
    if ([presented isKindOfClass:[FancyAlertViewController class]]) {
        return [[FancyAlertPresentationController alloc] initWithPresentedViewController:presented
                                                                presentingViewController:presenting];
    }

    return nil;
}

#pragma mark - Domain Registration

- (void)updateTableViewAndHeader
{
    [self updateTableView:^{}];
}

/// This method syncs the blog and its metadata, then reloads the table view.
///
- (void)updateTableView:(void(^)(void))completion
{
    __weak __typeof(self) weakSelf = self;
    [self.blogService syncBlogAndAllMetadata:self.blog
                           completionHandler:
     ^{
        [weakSelf configureTableViewData];
        [weakSelf reloadTableViewPreservingSelection];
        completion();
    }];
}

#pragma mark - Pull To Refresh

- (void)pulledToRefresh {
    [self pulledToRefreshWith:self.tableView.refreshControl onCompletion:^{}];
}

- (void)pulledToRefreshWith:(UIRefreshControl *)refreshControl onCompletion:( void(^)(void))completion {

    [self updateTableView: ^{
        // WORKAROUND: if we don't dispatch this asynchronously, the refresh end animation is clunky.
        // To recognize if we can remove this, simply remove the dispatch_async call and test pulling
        // down to refresh the site.
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [refreshControl endRefreshing];

            completion();
        });
    }];
}

@end
