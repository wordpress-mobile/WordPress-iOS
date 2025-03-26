#import "BlogDetailsViewController.h"

#import "AccountService.h"
#import "BlogService.h"
#import "CommentsViewController.h"
@import WordPressDataObjC;
#import "SiteSettingsViewController.h"
#import "SharingViewController.h"
#import "StatsViewController.h"
#import "WPAccount.h"
#import "WPAppAnalytics.h"
#import "WordPress-Swift.h"
#import "MenusViewController.h"
#import "NSMutableArray+NullableObjects.h"

@import Gridicons;
@import Reachability;
@import WordPressShared;

static NSString *const BlogDetailsCellIdentifier = @"BlogDetailsCell";
static NSString *const BlogDetailsPlanCellIdentifier = @"BlogDetailsPlanCell";
static NSString *const BlogDetailsSettingsCellIdentifier = @"BlogDetailsSettingsCell";
static NSString *const BlogDetailsRemoveSiteCellIdentifier = @"BlogDetailsRemoveSiteCell";
static NSString *const BlogDetailsSectionFooterIdentifier = @"BlogDetailsSectionFooterView";
static NSString *const BlogDetailsMigrationSuccessCellIdentifier = @"BlogDetailsMigrationSuccessCell";
static NSString *const BlogDetailsJetpackBrandingCardCellIdentifier = @"BlogDetailsJetpackBrandingCardCellIdentifier";
static NSString *const BlogDetailsJetpackInstallCardCellIdentifier = @"BlogDetailsJetpackInstallCardCellIdentifier";
static NSString *const BlogDetailsSotWCardCellIdentifier = @"BlogDetailsSotWCardCellIdentifier";

CGFloat const BlogDetailGridiconSize = 24.0;
CGFloat const BlogDetailGridiconAccessorySize = 17.0;
CGFloat const BlogDetailSectionTitleHeaderHeight = 40.0;
CGFloat const BlogDetailSectionsSpacing = 20.0;
CGFloat const BlogDetailSectionFooterHeight = 40.0;
NSTimeInterval const PreloadingCacheTimeout = 60.0 * 5; // 5 minutes
NSString * const HideWPAdminDate = @"2015-09-07T00:00:00Z";

CGFloat const BlogDetailReminderSectionHeaderHeight = 8.0;
CGFloat const BlogDetailReminderSectionFooterHeight = 1.0;

NSString * const WPCalypsoDashboardPath = @"https://wordpress.com/home/";

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
                    imageColor:[UIColor labelColor]
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

@interface BlogDetailsViewController () <UIActionSheetDelegate, UIAlertViewDelegate, UIAdaptivePresentationControllerDelegate>

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

@property (nonatomic, weak) UIViewController *presentedSiteSettingsViewController;

@end

@implementation BlogDetailsViewController
@synthesize restorableSelectedIndexPath = _restorableSelectedIndexPath;

#pragma mark = Lifecycle Methods

- (instancetype)init
{
    self = [super init];

    if (self) {
        self.isScrollEnabled = false;
    }

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    if (self.isSidebarModeEnabled) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    } else if (self.isScrollEnabled) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleInsetGrouped];
    } else {
        _tableView = [[IntrinsicTableView alloc] initWithFrame:CGRectZero style:UITableViewStyleInsetGrouped];
        self.tableView.scrollEnabled = false;
    }
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.translatesAutoresizingMaskIntoConstraints = false;
    if (self.isSidebarModeEnabled) {
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        self.additionalSafeAreaInsets = UIEdgeInsetsMake(0, 8, 0, 0); // Left inset
    }
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
    [self.tableView registerClass:[BlogDetailsSectionFooterView class] forHeaderFooterViewReuseIdentifier:BlogDetailsSectionFooterIdentifier];
    [self.tableView registerClass:[MigrationSuccessCell class] forCellReuseIdentifier:BlogDetailsMigrationSuccessCellIdentifier];
    [self.tableView registerClass:[JetpackBrandingMenuCardCell class] forCellReuseIdentifier:BlogDetailsJetpackBrandingCardCellIdentifier];
    [self.tableView registerClass:[JetpackRemoteInstallTableViewCell class] forCellReuseIdentifier:BlogDetailsJetpackInstallCardCellIdentifier];
    [self.tableView registerClass:[SotWTableViewCell class] forCellReuseIdentifier:BlogDetailsSotWCardCellIdentifier];

    self.tableView.cellLayoutMarginsFollowReadableWidth = YES;

    self.hasLoggedDomainCreditPromptShownEvent = NO;

    self.blogService = [[BlogService alloc] initWithCoreDataStack:[ContextManager sharedInstance]];
    [self preloadMetadata];

    if (self.blog.account && !self.blog.account.userID) {
        // User's who upgrade may not have a userID recorded.
        AccountService *acctService = [[AccountService alloc] initWithCoreDataStack:[ContextManager sharedInstance]];
        [acctService updateUserDetailsForAccount:self.blog.account success:nil failure:nil];
    }

    [self observeManagedObjectContextObjectsDidChangeNotification];

    [self observeGravatarImageUpdate];

    if (@available(iOS 17.0, *)) {
        [self registerForTraitChanges:@[[UITraitHorizontalSizeClass self]] withAction:@selector(handleTraitChanges)];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self observeWillEnterForegroundNotification];

    if (!self.isSplitViewDisplayed) {
        self.restorableSelectedIndexPath = nil;
    }

    // Configure and reload table data when appearing to ensure pending comment count is updated
    [self configureTableViewData];

    [self reloadTableViewPreservingSelection];
    [self preloadBlogData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self createUserActivity];

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
    [self stopObservingWillEnterForegroundNotification];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];

    if (@available(iOS 17.0, *)) {
        // Do nothing. `handleTraitChanges` is registered using iOS 17 API.
    } else {
        [self handleTraitChanges];
    }
}

- (void)handleTraitChanges
{
    // Required to add / remove "Home" section when switching between regular and compact width
    [self configureTableViewData];

    // Required to update disclosure indicators depending on split view status
    [self reloadTableViewPreservingSelection];
}

- (void)showDetailViewForSubsection:(BlogDetailsSubsection)section
{
    [self showDetailViewForSubsection:section userInfo:@{}];
}

- (void)showDetailViewForSubsection:(BlogDetailsSubsection)section userInfo:(NSDictionary *)userInfo
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
        case BlogDetailsSubsectionJetpackBrandingCard:
            self.restorableSelectedIndexPath = indexPath;
            [self.tableView selectRowAtIndexPath:indexPath
                                        animated:NO
                                  scrollPosition:[self optimumScrollPositionForIndexPath:indexPath]];
            break;
        case BlogDetailsSubsectionStats: {
            self.restorableSelectedIndexPath = indexPath;
            [self.tableView selectRowAtIndexPath:indexPath
                                        animated:NO
                                  scrollPosition:[self optimumScrollPositionForIndexPath:indexPath]];
            NSNumber *sourceValue = userInfo[[BlogDetailsViewController userInfoSourceKey]];
            BlogDetailsNavigationSource source = sourceValue ? sourceValue.unsignedIntegerValue : BlogDetailsNavigationSourceLink;
            [self showStatsFromSource:source];
            break;
        }
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
            BOOL showPicker = userInfo[[BlogDetailsViewController userInfoShowPickerKey]] ?: NO;
            [self showMediaLibraryFromSource:BlogDetailsNavigationSourceLink showPicker: showPicker];
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
        case BlogDetailsSubsectionMe:
            [self showDetailViewForMeSubsectionWithUserInfo: userInfo];
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
            } else if ([self.blog selfHostedSiteRestApi]) {
                self.restorableSelectedIndexPath = indexPath;
                [self.tableView selectRowAtIndexPath:indexPath
                                            animated:NO
                                      scrollPosition:[self optimumScrollPositionForIndexPath:indexPath]];
                [self showUsers];
            }
            break;
        case BlogDetailsSubsectionPlugins:
            if ([self.blog supports:BlogFeaturePluginManagement]) {
                self.restorableSelectedIndexPath = indexPath;
                [self.tableView selectRowAtIndexPath:indexPath
                                            animated:NO
                                      scrollPosition:[self optimumScrollPositionForIndexPath:indexPath]];
                BOOL showManagemnet = userInfo[[BlogDetailsViewController userInfoShowManagemenetScreenKey]] ?: NO;
                if (showManagemnet) {
                    [self showManagePluginsScreen];
                } else {
                    [self showPlugins];
                }
            }
            break;
        case BlogDetailsSubsectionSiteMonitoring:
            if ([RemoteFeature enabled:RemoteFeatureFlagSiteMonitoring] && [self.blog supports:BlogFeatureSiteMonitoring]) {
                NSNumber *selectedTab = userInfo[[BlogDetailsViewController userInfoSiteMonitoringTabKey]];
                self.restorableSelectedIndexPath = indexPath;
                [self.tableView selectRowAtIndexPath:indexPath
                                            animated:NO
                                      scrollPosition:[self optimumScrollPositionForIndexPath:indexPath]];
                [self showSiteMonitoringWithSelectedTab:selectedTab];
            }
            break;

    }
}

- (MeViewController *)showDetailViewForMeSubsectionWithUserInfo:(NSDictionary *)userInfo {
    NSIndexPath *indexPath = [self indexPathForSubsection:BlogDetailsSubsectionMe];
    self.restorableSelectedIndexPath = indexPath;
    [self.tableView selectRowAtIndexPath:indexPath
                                animated:NO
                          scrollPosition:[self optimumScrollPositionForIndexPath:indexPath]];
    return [self showMe];
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
        case BlogDetailsSubsectionStats:
            return [NSIndexPath indexPathForRow:0 inSection:section];
        case BlogDetailsSubsectionActivity:
            return [NSIndexPath indexPathForRow:0 inSection:section];
        case BlogDetailsSubsectionSiteMonitoring:
            return [NSIndexPath indexPathForRow:2 inSection:section];
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
        case BlogDetailsSubsectionMe:
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

    if (hasTitle) {
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

#pragma mark - Rows

- (BlogDetailsRow *)postsRow
{
    __weak __typeof(self) weakSelf = self;
    BlogDetailsRow *row = [[BlogDetailsRow alloc] initWithTitle:NSLocalizedString(@"Posts", @"Noun. Title. Links to the blog's Posts screen.")
                                        accessibilityIdentifier:@"Blog Post Row"
                                                          image:[[UIImage imageNamed:@"site-menu-posts"] imageFlippedForRightToLeftLayoutDirection]
                                                       callback:^{
        [weakSelf showPostListFromSource:BlogDetailsNavigationSourceRow];
    }];
    return row;
}

- (BlogDetailsRow *)pagesRow
{
    __weak __typeof(self) weakSelf = self;
    BlogDetailsRow *row = [[BlogDetailsRow alloc] initWithTitle:NSLocalizedString(@"Pages", @"Noun. Title. Links to the blog's Pages screen.")
                                        accessibilityIdentifier:@"Site Pages Row"
                                                          image:[UIImage imageNamed:@"site-menu-pages"]
                                                       callback:^{
        [weakSelf showPageListFromSource:BlogDetailsNavigationSourceRow];
    }];
    return row;
}

- (BlogDetailsRow *)mediaRow
{
    __weak __typeof(self) weakSelf = self;
    BlogDetailsRow *row = [[BlogDetailsRow alloc] initWithTitle:NSLocalizedString(@"Media", @"Noun. Title. Links to the blog's Media library.")
                                        accessibilityIdentifier:@"Media Row"
                                                          image:[UIImage imageNamed:@"site-menu-media"]
                                                       callback:^{
        [weakSelf showMediaLibraryFromSource:BlogDetailsNavigationSourceRow];
    }];
    return row;
}

- (BlogDetailsRow *)commentsRow
{
    __weak __typeof(self) weakSelf = self;
    BlogDetailsRow *row = [[BlogDetailsRow alloc] initWithTitle:NSLocalizedString(@"Comments", @"Noun. Title. Links to the blog's Comments screen.")
                                                          image:[[UIImage imageNamed:@"site-menu-comments"] imageFlippedForRightToLeftLayoutDirection]
                                                       callback:^{
        [weakSelf showCommentsFromSource:BlogDetailsNavigationSourceRow];
    }];
    return row;
}

- (BlogDetailsRow *)statsRow
{
    __weak __typeof(self) weakSelf = self;
    BlogDetailsRow *statsRow = [[BlogDetailsRow alloc] initWithTitle:NSLocalizedString(@"Stats", @"Noun. Abbv. of Statistics. Links to a blog's Stats screen.")
                                             accessibilityIdentifier:@"Stats Row"
                                                               image:[UIImage imageNamed:@"site-menu-stats"]
                                                            callback:^{
        [weakSelf showStatsFromSource:BlogDetailsNavigationSourceRow];
    }];
    return statsRow;
}

- (BlogDetailsRow *)blazeRow
{
    __weak __typeof(self) weakSelf = self;
    CGSize iconSize = CGSizeMake(BlogDetailGridiconSize, BlogDetailGridiconSize);
    UIImage *blazeIcon = [[UIImage imageNamed:@"icon-blaze"] resizedTo:iconSize format:ScalingModeScaleAspectFit];
    BlogDetailsRow *blazeRow = [[BlogDetailsRow alloc] initWithTitle:NSLocalizedString(@"Blaze", @"Noun. Links to a blog's Blaze screen.")
                                             accessibilityIdentifier:@"Blaze Row"
                                                               image:[blazeIcon imageFlippedForRightToLeftLayoutDirection]
                                                          imageColor:nil
                                                       renderingMode:UIImageRenderingModeAlwaysOriginal
                                                            callback:^{
        [weakSelf showBlaze];
    }];
    blazeRow.showsSelectionState = [RemoteFeature enabled:RemoteFeatureFlagBlazeManageCampaigns];
    return blazeRow;
}

- (BlogDetailsRow *)socialRow
{
    __weak __typeof(self) weakSelf = self;

    NSString *title = [AppConfiguration isWordPress]
    ? NSLocalizedString(@"Sharing", @"Noun. Title. Links to a blog's sharing options.")
    : [BlogDetailsViewControllerStrings socialRowTitle];

    BlogDetailsRow *row = [[BlogDetailsRow alloc] initWithTitle:title
                                                          image:[UIImage imageNamed:@"site-menu-social"]
                                                       callback:^{
        [weakSelf showSharingFromSource:BlogDetailsNavigationSourceRow];
    }];
    return row;
}

- (BlogDetailsRow *)siteMonitoringRow
{
     __weak __typeof(self) weakSelf = self;
    BlogDetailsRow *row = [[BlogDetailsRow alloc] initWithTitle:[BlogDetailsViewControllerStrings siteMonitoringRowTitle]
                                        accessibilityIdentifier:@"Site Monitoring Row"
                                                          image:[UIImage imageNamed:@"tool"]
                                                       callback:^{
        [weakSelf showSiteMonitoring];
    }];
    return row;
}

- (BlogDetailsRow *)activityRow
{
    __weak __typeof(self) weakSelf = self;
    BlogDetailsRow *row = [[BlogDetailsRow alloc] initWithTitle:NSLocalizedString(@"Activity Log", @"Noun. Links to a blog's Activity screen.")
                                        accessibilityIdentifier:@"Activity Log Row"
                                                          image:[UIImage imageNamed:@"site-menu-activity"]
                                                       callback:^{
        [weakSelf showActivity];
    }];
    return row;
}

- (BlogDetailsRow *)backupRow
{
    __weak __typeof(self) weakSelf = self;
    BlogDetailsRow *row = [[BlogDetailsRow alloc] initWithTitle:NSLocalizedString(@"Backup", @"Noun. Links to a blog's Jetpack Backups screen.")
                                        accessibilityIdentifier:@"Backup Row"
                                                          image:[UIImage gridiconOfType:GridiconTypeCloudOutline]
                                                       callback:^{
        [weakSelf showBackup];
    }];
    return row;
}

- (BlogDetailsRow *)scanRow
{
    __weak __typeof(self) weakSelf = self;
    BlogDetailsRow *row = [[BlogDetailsRow alloc] initWithTitle:NSLocalizedString(@"Scan", @"Noun. Links to a blog's Jetpack Scan screen.")
                                        accessibilityIdentifier:@"Scan Row"
                                                          image:[UIImage imageNamed:@"jetpack-scan-menu-icon"]
                                                       callback:^{
        [weakSelf showScan];
    }];
    return row;
}

- (BlogDetailsRow *)peopleRow
{
    __weak __typeof(self) weakSelf = self;
    BlogDetailsRow *row = [[BlogDetailsRow alloc] initWithTitle:NSLocalizedString(@"People", @"Noun. Title. Links to the people management feature.")
                                        accessibilityIdentifier:@"People Row"
                                                          image:[UIImage imageNamed:@"site-menu-people"]
                                                       callback:^{
        [weakSelf showPeople];
    }];
    return row;
}

- (BlogDetailsRow *)usersRow
{
    __weak __typeof(self) weakSelf = self;
    BlogDetailsRow *row = [[BlogDetailsRow alloc] initWithTitle:NSLocalizedString(@"Users", @"Noun. Title. Links to the user management feature.")
                                        accessibilityIdentifier:@"User Row"
                                                          image:[UIImage imageNamed:@"site-menu-people"]
                                                       callback:^{
        [weakSelf showUsers];
    }];
    return row;
}

- (BlogDetailsRow *)pluginsRow
{
    __weak __typeof(self) weakSelf = self;
    BlogDetailsRow *row = [[BlogDetailsRow alloc] initWithTitle:NSLocalizedString(@"Plugins", @"Noun. Title. Links to the plugin management feature.")
                                                          image:[UIImage imageNamed:@"site-menu-plugins"]
                                                       callback:^{
        [weakSelf showPlugins];
    }];
    return row;
}

- (BlogDetailsRow *)themesRow
{
    __weak __typeof(self) weakSelf = self;
    BlogDetailsRow *row = [[BlogDetailsRow alloc] initWithTitle:NSLocalizedString(@"Themes", @"Themes option in the blog details")
                                                          image:[UIImage imageNamed:@"site-menu-themes"]
                                                       callback:^{
        [weakSelf showThemes];
    }];
    return row;
}

- (BlogDetailsRow *)menuRow
{
    __weak __typeof(self) weakSelf = self;
    BlogDetailsRow *row = [[BlogDetailsRow alloc] initWithTitle:NSLocalizedString(@"Menus", @"Menus option in the blog details")
                                                          image:[[UIImage gridiconOfType:GridiconTypeMenus] imageFlippedForRightToLeftLayoutDirection]
                                                       callback:^{
        [weakSelf showMenus];
    }];
    return row;
}

- (BlogDetailsRow *)domainsRow
{
    __weak __typeof(self) weakSelf = self;
    BlogDetailsRow *row = [[BlogDetailsRow alloc] initWithTitle:NSLocalizedString(@"Domains", @"Noun. Title. Links to the Domains screen.")
                                                     identifier:BlogDetailsSettingsCellIdentifier
                                        accessibilityIdentifier:@"Domains Row"
                                                          image:[UIImage imageNamed:@"site-menu-domains"]
                                                       callback:^{
        [weakSelf showDomainsFromSource:BlogDetailsNavigationSourceRow];
    }];
    return row;
}

- (BlogDetailsRow *)siteSettingsRow
{
    __weak __typeof(self) weakSelf = self;
    BlogDetailsRow *row = [[BlogDetailsRow alloc] initWithTitle:NSLocalizedString(@"Site Settings", @"Noun. Title. Links to the blog's Settings screen.")
                                                     identifier:BlogDetailsSettingsCellIdentifier
                                        accessibilityIdentifier:@"Settings Row"
                                                          image:[UIImage imageNamed:@"site-menu-settings"]
                                                       callback:^{
        [weakSelf showSettingsFromSource:BlogDetailsNavigationSourceRow];
    }];
    return row;
}

- (BlogDetailsRow *)adminRow
{
    __weak __typeof(self) weakSelf = self;
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
    return row;
}

#pragma mark - Data Model setup

- (void)reloadTableViewPreservingSelection
{
    // Configure and reload table data when appearing to ensure pending comment count is updated
    [self.tableView reloadData];

    // Check if the last selected category index needs to be updated after a dynamic section is activated and displayed.
    // and Use Domain are dynamic section, which means they can be removed or hidden at any time.
    NSUInteger sectionIndex = [self findSectionIndexWithSections:self.tableSections category:self.selectedSectionCategory];

    if (sectionIndex != NSNotFound && self.restorableSelectedIndexPath.section != sectionIndex) {
        BlogDetailsSection *section = [self.tableSections objectAtIndex:sectionIndex];

        NSUInteger row = 0;

        //  Use Domain cases we want to select the first row on the next available section
        switch (section.category) {
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
    if (isValidIndexPath && [self isSplitViewDisplayed]) {
        // And finally we'll reselect the selected row, if there is one
        [self.tableView selectRowAtIndexPath:self.restorableSelectedIndexPath
                                    animated:NO
                              scrollPosition:[self optimumScrollPositionForIndexPath:self.restorableSelectedIndexPath]];
    }
}

- (UITableViewScrollPosition)optimumScrollPositionForIndexPath:(NSIndexPath *)indexPath
{
    if (self.isSidebarModeEnabled) {
        return UITableViewScrollPositionNone;
    }
    // Try and avoid scrolling if not necessary
    CGRect cellRect = [self.tableView rectForRowAtIndexPath:indexPath];
    BOOL cellIsNotFullyVisible = !CGRectContainsRect(self.tableView.bounds, cellRect);
    return (cellIsNotFullyVisible) ? UITableViewScrollPositionMiddle : UITableViewScrollPositionNone;
}

- (void)configureTableViewData
{
    NSMutableArray *marr = [NSMutableArray array];

    // TODO: Add the SoTW card here.
    if ([self shouldShowSotW2023Card]) {
        [marr addNullableObject:[self sotw2023SectionViewModel]];
    }

    if ([self shouldShowJetpackInstallCard]) {
        [marr addNullableObject:[self jetpackInstallSectionViewModel]];
    }

    if (self.shouldShowTopJetpackBrandingMenuCard == YES) {
        [marr addNullableObject:[self jetpackCardSectionViewModel]];
    }

    if ([self isDashboardEnabled] && [self isSplitViewDisplayed]) {
        [marr addNullableObject:[self homeSectionViewModel]];
    }

    if ([AppConfiguration isWordPress]) {
        if ([self shouldAddJetpackSection]) {
            [marr addNullableObject:[self jetpackSectionViewModel]];
        }

        if ([self shouldAddGeneralSection]) {
            [marr addNullableObject:[self generalSectionViewModel]];
        }

        [marr addNullableObject:[self publishTypeSectionViewModel]];

        if ([self shouldAddPersonalizeSection]) {
            [marr addNullableObject:[self personalizeSectionViewModel]];
        }

        [marr addNullableObject:[self configurationSectionViewModel]];
        [marr addNullableObject:[self externalSectionViewModel]];
    } else {
        [marr addNullableObject:[self contentSectionViewModel]];
        [marr addNullableObject:[self trafficSectionViewModel]];
        [marr addObjectsFromArray:[self maintenanceSectionViewModel]];
    }

    if ([self.blog supports:BlogFeatureRemovable]) {
        [marr addNullableObject:[self removeSiteSectionViewModel]];
    }

    if (self.shouldShowBottomJetpackBrandingMenuCard == YES) {
        [marr addNullableObject:[self jetpackCardSectionViewModel]];
    }

    // Assign non mutable copy.
    self.tableSections = [NSArray arrayWithArray:marr];
}

- (Boolean)isSplitViewDisplayed {
    return self.isSidebarModeEnabled;
}

/// This section is available on Jetpack only.
- (BlogDetailsSection *)contentSectionViewModel
{
    NSMutableArray *rows = [NSMutableArray array];

    [rows addObject:[self postsRow]];
    if ([self.blog supports:BlogFeaturePages]) {
        [rows addObject:[self pagesRow]];
    }
    [rows addObject:[self mediaRow]];
    [rows addObject:[self commentsRow]];

    NSString *title = self.isSidebarModeEnabled ? nil : [BlogDetailsViewControllerStrings contentSectionTitle];
    return [[BlogDetailsSection alloc] initWithTitle:title andRows:rows category:BlogDetailsSectionCategoryContent];
}

/// This section is available on Jetpack only.
- (BlogDetailsSection *)trafficSectionViewModel
{
    // Init rows
    NSMutableArray *rows = [NSMutableArray array];

    // Stats row
    if ([self.blog isViewingStatsAllowed]) {
        [rows addObject:[self statsRow]];
    }

    // Social row
    if ([self shouldAddSharingRow]) {
        [rows addObject:[self socialRow]];
    }

    // Blaze row
    if ([self shouldShowBlaze]) {
        [rows addObject:[self blazeRow]];
    }

    if (rows.count == 0) {
        return nil;
    }

    // Return
    NSString *title = [BlogDetailsViewControllerStrings trafficSectionTitle];
    return [[BlogDetailsSection alloc] initWithTitle:title andRows:rows category:BlogDetailsSectionCategoryTraffic];
}

/// Returns a list of sections. Available on Jetpack only.
- (NSArray<BlogDetailsSection *> *)maintenanceSectionViewModel
{
    // Init array
    NSMutableArray<BlogDetailsSection *> *sections = [NSMutableArray array];
    NSMutableArray *firstSectionRows = [NSMutableArray array];
    NSMutableArray *secondSectionRows = [NSMutableArray array];
    NSMutableArray *thirdSectionRows = [NSMutableArray array];

    // The 1st section
    if ([self.blog supports:BlogFeatureActivity] && ![self.blog isWPForTeams]) {
        [firstSectionRows addObject:[self activityRow]];
    }
    if ([self.blog isBackupsAllowed]) {
        [firstSectionRows addObject:[self backupRow]];
    }
    if ([self.blog isScanAllowed]) {
        [firstSectionRows addObject:[self scanRow]];
    }
    if ([RemoteFeature enabled:RemoteFeatureFlagSiteMonitoring] && [self.blog supports:BlogFeatureSiteMonitoring]) {
        [firstSectionRows addObject:[self siteMonitoringRow]];
    }

    // The 2nd section
    if ([self shouldAddPeopleRow]) {
        [secondSectionRows addObject:[self peopleRow]];
    }
    if ([self shouldAddUsersRow]) {
        [secondSectionRows addObject:[self usersRow]];
    }
    if ([self shouldAddPluginsRow]) {
        [secondSectionRows addObject:[self pluginsRow]];
    }
    if ([self.blog supports:BlogFeatureThemeBrowsing] && ![self.blog isWPForTeams]) {
        [secondSectionRows addObject:[self themesRow]];
    }
    if ([self.blog supports:BlogFeatureMenus]) {
        [secondSectionRows addObject:[self menuRow]];
    }
    if ([self shouldAddDomainRegistrationRow]) {
        [secondSectionRows addObject:[self domainsRow]];
    }
    [secondSectionRows addObject:[self siteSettingsRow]];

    // Third section
    if ([self shouldDisplayLinkToWPAdmin]) {
        [thirdSectionRows addObject:[self adminRow]];
    }

    // Add sections
    NSString *sectionTitle = [BlogDetailsViewControllerStrings maintenanceSectionTitle];
    BOOL shouldAddSectionTitle = YES;
    if ([firstSectionRows count] > 0) {
        BlogDetailsSection *section = [[BlogDetailsSection alloc] initWithTitle:sectionTitle
                                                                        andRows:firstSectionRows
                                                                       category:BlogDetailsSectionCategoryMaintenance];
        [sections addObject:section];
        shouldAddSectionTitle = NO;
    }
    if ([secondSectionRows count] > 0) {
        NSString *title = shouldAddSectionTitle ? sectionTitle : nil;
        BlogDetailsSection *section = [[BlogDetailsSection alloc] initWithTitle:title
                                                                        andRows:secondSectionRows
                                                                       category:BlogDetailsSectionCategoryMaintenance];
        [sections addObject:section];
        shouldAddSectionTitle = NO;
    }
    if ([thirdSectionRows count] > 0) {
        NSString *title = shouldAddSectionTitle ? sectionTitle : nil;
        BlogDetailsSection *section = [[BlogDetailsSection alloc] initWithTitle:title
                                                                        andRows:thirdSectionRows
                                                                       category:BlogDetailsSectionCategoryMaintenance];
        [sections addObject:section];
    }

    // Return
    return sections;
}

- (BlogDetailsSection *)homeSectionViewModel
{
    __weak __typeof(self) weakSelf = self;
    NSMutableArray *rows = [NSMutableArray array];

    [rows addObject:[[BlogDetailsRow alloc] initWithTitle:NSLocalizedString(@"Home", @"Noun. Links to a blog's dashboard screen.")
                                  accessibilityIdentifier:@"Home Row"
                                                    image:[UIImage imageNamed:@"site-menu-home"]
                                                 callback:^{
                                                    [weakSelf showDashboard];
                                                 }]];

    return [[BlogDetailsSection alloc] initWithTitle:nil andRows:rows category:BlogDetailsSectionCategoryHome];
}

- (BlogDetailsSection *)generalSectionViewModel
{
    __weak __typeof(self) weakSelf = self;
    NSMutableArray *rows = [NSMutableArray array];

    if ([self.blog isViewingStatsAllowed]) {
        [rows addObject:[self statsRow]];
    }

    if ([self.blog supports:BlogFeatureActivity] && ![self.blog isWPForTeams]) {
        [rows addObject:[[BlogDetailsRow alloc] initWithTitle:NSLocalizedString(@"Activity", @"Noun. Links to a blog's Activity screen.")
                                                        image:[UIImage imageNamed:@"site-menu-activity"]
                                                     callback:^{
                                                         [weakSelf showActivity];
                                                     }]];
    }

    if ([self shouldShowBlaze]) {
        [rows addObject:[self blazeRow]];
    }

    if (rows.count == 0) {
        return nil;
    }

    return [[BlogDetailsSection alloc] initWithTitle:nil andRows:rows category:BlogDetailsSectionCategoryGeneral];
}

- (BlogDetailsSection *)jetpackSectionViewModel
{
    __weak __typeof(self) weakSelf = self;
    NSMutableArray *rows = [NSMutableArray array];

    if ([self.blog isViewingStatsAllowed]) {
        [rows addObject:[self statsRow]];
    }

    if ([self.blog supports:BlogFeatureActivity] && ![self.blog isWPForTeams]) {
        [rows addObject:[[BlogDetailsRow alloc] initWithTitle:NSLocalizedString(@"Activity Log", @"Noun. Links to a blog's Activity screen.")
                                      accessibilityIdentifier:@"Activity Log Row"
                                                        image:[UIImage imageNamed:@"site-menu-activity"]
                                                     callback:^{
                                                         [weakSelf showActivity];
                                                     }]];
    }


    if ([self.blog isBackupsAllowed]) {
        [rows addObject:[[BlogDetailsRow alloc] initWithTitle:NSLocalizedString(@"Backup", @"Noun. Links to a blog's Jetpack Backups screen.")
                                      accessibilityIdentifier:@"Backup Row"
                                                        image:[UIImage gridiconOfType:GridiconTypeCloudOutline]
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
                                                              image:[UIImage imageNamed:@"site-menu-settings"]
                                                           callback:^{
                                                               [weakSelf showJetpackSettings];
                                                           }];

        [rows addObject:settingsRow];
    }

    if ([self shouldShowBlaze]) {
        [rows addObject:[self blazeRow]];
    }

    if (rows.count == 0) {
        return nil;
    }

    NSString *title = @"";

    if ([self.blog supports:BlogFeatureJetpackSettings]) {
        title = NSLocalizedString(@"Jetpack", @"Section title for the publish table section in the blog details screen");
    }

    return [[BlogDetailsSection alloc] initWithTitle:title andRows:rows category:BlogDetailsSectionCategoryJetpack];
}

- (BlogDetailsSection *)publishTypeSectionViewModel
{
    NSMutableArray *rows = [NSMutableArray array];

    [rows addObject:[self postsRow]];
    [rows addObject:[self mediaRow]];
    if ([self.blog supports:BlogFeaturePages]) {
        [rows addObject:[self pagesRow]];
    }
    [rows addObject:[self commentsRow]];

    NSString *title = NSLocalizedString(@"Publish", @"Section title for the publish table section in the blog details screen");
    return [[BlogDetailsSection alloc] initWithTitle:title andRows:rows category:BlogDetailsSectionCategoryContent];
}

- (BlogDetailsSection *)personalizeSectionViewModel
{
    __weak __typeof(self) weakSelf = self;
    NSMutableArray *rows = [NSMutableArray array];
    if ([self.blog supports:BlogFeatureThemeBrowsing] && ![self.blog isWPForTeams]) {
        BlogDetailsRow *row = [[BlogDetailsRow alloc] initWithTitle:NSLocalizedString(@"Themes", @"Themes option in the blog details")
                                                              image:[UIImage imageNamed:@"site-menu-themes"]
                                                           callback:^{
                                                               [weakSelf showThemes];
                                                           }];
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

    if ([self shouldAddMeRow]) {
        BlogDetailsRow *row = [[BlogDetailsRow alloc] initWithTitle:NSLocalizedString(@"Me", @"Noun. Title. Links to the Me screen.")
                                        image:[UIImage gridiconOfType:GridiconTypeUserCircle]
                                     callback:^{
                                         [weakSelf showMe];
                                     }];
        [self downloadGravatarImageFor:row forceRefresh: NO];
        self.meRow = row;
        [rows addObject:row];
    }

    if ([self shouldAddSharingRow]) {
        BlogDetailsRow *row = [[BlogDetailsRow alloc] initWithTitle:NSLocalizedString(@"Sharing", @"Noun. Title. Links to a blog's sharing options.")
                                        image:[UIImage imageNamed:@"site-menu-social"]
                                     callback:^{
            [weakSelf showSharingFromSource:BlogDetailsNavigationSourceRow];
                                     }];
        [rows addObject:row];
    }

    if ([self shouldAddPeopleRow]) {
        [rows addObject:[[BlogDetailsRow alloc] initWithTitle:NSLocalizedString(@"People", @"Noun. Title. Links to the people management feature.")
                                      accessibilityIdentifier:@"People Row"
                                                        image:[UIImage imageNamed:@"site-menu-people"]
                                                     callback:^{
                                                         [weakSelf showPeople];
                                                     }]];
    }

    if ([self shouldAddUsersRow]) {
        [rows addObject:[self usersRow]];
    }

    if ([self shouldAddPluginsRow]) {
        [rows addObject:[[BlogDetailsRow alloc] initWithTitle:NSLocalizedString(@"Plugins", @"Noun. Title. Links to the plugin management feature.")
                                                        image:[UIImage imageNamed:@"site-menu-plugins"]
                                                     callback:^{
                                                         [weakSelf showPlugins];
                                                     }]];
    }

    BlogDetailsRow *row = [[BlogDetailsRow alloc] initWithTitle:NSLocalizedString(@"Site Settings", @"Noun. Title. Links to the blog's Settings screen.")
                                                     identifier:BlogDetailsSettingsCellIdentifier
                                        accessibilityIdentifier:@"Settings Row"
                                                          image:[UIImage imageNamed:@"site-menu-settings"]
                                                       callback:^{
        [weakSelf showSettingsFromSource:BlogDetailsNavigationSourceRow];
                                                       }];

    [rows addObject:row];

    if ([self shouldAddDomainRegistrationRow]) {
        BlogDetailsRow *domainsRow = [[BlogDetailsRow alloc] initWithTitle:NSLocalizedString(@"Domains", @"Noun. Title. Links to the Domains screen.")
                                                                identifier:BlogDetailsSettingsCellIdentifier
                                                   accessibilityIdentifier:@"Domains Row"
                                                                     image:[UIImage imageNamed:@"site-menu-domains"]
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
    if (![self isSplitViewDisplayed]) {
        return;
    }

    self.restorableSelectedIndexPath = nil;

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

    if (section.category == BlogDetailsSectionCategorySotW2023Card) {
        SotWTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:BlogDetailsSotWCardCellIdentifier];
        __weak __typeof(self) weakSelf = self;
        [cell configureOnCardHidden:^{
            [weakSelf configureTableViewData];
            [weakSelf reloadTableViewPreservingSelection];
        }];

        return cell;
    }

    if (section.category == BlogDetailsSectionCategoryJetpackInstallCard) {
        JetpackRemoteInstallTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:BlogDetailsJetpackInstallCardCellIdentifier];
        [cell configureWithBlog:self.blog viewController:self];
        return cell;
    }

    if (section.category == BlogDetailsSectionCategoryMigrationSuccess) {
        MigrationSuccessCell *cell = [tableView dequeueReusableCellWithIdentifier:BlogDetailsMigrationSuccessCellIdentifier];
        if (self.isSidebarModeEnabled) {
            [cell configureForSidebarMode];
        }
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

    if (cell == nil) {
        DDLogError(@"Cell with identifier '%@' at index path '%@' is nil", row.identifier, indexPath);
    }

    cell.accessibilityHint = row.accessibilityHint;
    cell.accessoryView = nil;
    cell.textLabel.textAlignment = NSTextAlignmentNatural;

    if (row.forDestructiveAction) {
        cell.accessoryType = UITableViewCellAccessoryNone;
        [WPStyleGuide configureTableViewDestructiveActionCell:cell];
    } else {
        if (row.showsDisclosureIndicator) {
            cell.accessoryType = [self isSplitViewDisplayed] ? UITableViewCellAccessoryNone : UITableViewCellAccessoryDisclosureIndicator;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        [WPStyleGuide configureTableViewCell:cell];
    }

    [self configureCell:cell atIndexPath:indexPath];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    BlogDetailsSection *section = [self.tableSections objectAtIndex:indexPath.section];
    BlogDetailsRow *row = [section.rows objectAtIndex:indexPath.row];
    row.callback();

    if (row.showsSelectionState) {
        self.restorableSelectedIndexPath = indexPath;
    } else {
        if (![self isSplitViewDisplayed]) {
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
    return detailSection.title;
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
        case BlogDetailsNavigationSourceWidget:
            return @"widget";
        case BlogDetailsNavigationSourceOnboarding:
            return @"onboarding";
        case BlogDetailsNavigationSourceNotification:
            return @"notification";
        case BlogDetailsNavigationSourceShortcut:
            return @"shortcut";
        case BlogDetailsNavigationSourceTodayStatsCard:
            return @"todays_stats_card";
        default:
            return @"";
    }
}

- (void)preloadBlogData
{
    // only preload on wifi
    if ([ReachabilityUtils.internetReachability isReachableViaWiFi] == false) {
        return;
    }

    [self preloadComments];
    [self preloadMetadata];
    [self preloadDomains];
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

- (void)showCommentsFromSource:(BlogDetailsNavigationSource)source
{
    [self trackEvent:WPAnalyticsStatOpenedComments fromSource:source];
    CommentsViewController *commentsVC = [CommentsViewController controllerWithBlog:self.blog];
    commentsVC.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;

    if (self.isSidebarModeEnabled) {
        commentsVC.isSidebarModeEnabled = YES;

        UISplitViewController *splitVC = [[UISplitViewController alloc] initWithStyle:UISplitViewControllerStyleDoubleColumn];
        splitVC.presentsWithGesture = NO;
        splitVC.preferredDisplayMode = UISplitViewControllerDisplayModeOneBesideSecondary;
        [splitVC setPreferredPrimaryColumnWidth:320];
        [splitVC setMinimumPrimaryColumnWidth:375];
        [splitVC setMaximumPrimaryColumnWidth:400];
        [splitVC setViewController:commentsVC forColumn:UISplitViewControllerColumnPrimary];

        UIViewController *noSelectionVC = [UIViewController new];
        noSelectionVC.view.backgroundColor = [UIColor systemBackgroundColor];
        [splitVC setViewController:noSelectionVC forColumn:UISplitViewControllerColumnSecondary];

        [self.presentationDelegate presentBlogDetailsViewController:splitVC];
    } else {
        [self.presentationDelegate presentBlogDetailsViewController:commentsVC];
    }
}

- (void)showPostListFromSource:(BlogDetailsNavigationSource)source
{
    [self trackEvent:WPAnalyticsStatOpenedPosts fromSource:source];
    PostListViewController *controller = [PostListViewController controllerWithBlog:self.blog];
    controller.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    [self.presentationDelegate presentBlogDetailsViewController:controller];
}

- (void)showPageListFromSource:(BlogDetailsNavigationSource)source
{
    [self trackEvent:WPAnalyticsStatOpenedPages fromSource:source];
    PageListViewController *controller = [PageListViewController controllerWithBlog:self.blog];
    controller.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    [self.presentationDelegate presentBlogDetailsViewController:controller];
}

- (void)showMediaLibraryFromSource:(BlogDetailsNavigationSource)source {
    [self showMediaLibraryFromSource:source showPicker:false];
}

- (void)showMediaLibraryFromSource:(BlogDetailsNavigationSource)source showPicker:(BOOL)showPicker
{
    [self trackEvent:WPAnalyticsStatOpenedMediaLibrary fromSource:source];
    SiteMediaViewController *controller = [[SiteMediaViewController alloc] initWithBlog:self.blog showPicker:showPicker];
    [self.presentationDelegate presentBlogDetailsViewController:controller];
}

- (MeViewController *)showMe
{
    MeViewController *controller = [[MeViewController alloc] init];
    [self.presentationDelegate presentBlogDetailsViewController:controller];
    return controller;
}

- (void)showPeople
{
    UIViewController *controller = [PeopleViewController withJPBannerForBlog:self.blog];
    [self.presentationDelegate presentBlogDetailsViewController:controller];
}

- (void)showPlugins
{
    [WPAppAnalytics track:WPAnalyticsStatOpenedPluginDirectory withBlog:self.blog];

    if ([Feature enabled:FeatureFlagPluginManagementOverhaul]) {
        [self showManagePluginsScreen];
        return;
    }

    PluginDirectoryViewController *controller = [self makePluginDirectoryViewControllerWithBlog:self.blog];
    controller.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    [self.presentationDelegate presentBlogDetailsViewController:controller];
}

- (void)showSettingsFromSource:(BlogDetailsNavigationSource)source
{
    [self trackEvent:WPAnalyticsStatOpenedSiteSettings fromSource:source];
    SiteSettingsViewController *controller = [[SiteSettingsViewController alloc] initWithBlog:self.blog];
    controller.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    if (self.isSidebarModeEnabled) {
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
        __weak BlogDetailsViewController *weakSelf = self;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-parameter"
        controller.navigationItem.rightBarButtonItem  = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone primaryAction:[UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
            [weakSelf.tableView deselectSelectedRowWithAnimation:YES];
            [weakSelf dismissViewControllerAnimated:YES completion:nil];
        }]];
#pragma clang diagnostic pop
        navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
        [self presentViewController:navigationController animated:YES completion:nil];
        self.presentedSiteSettingsViewController = navigationController;
        navigationController.presentationController.delegate = self;
    } else {
        [self.presentationDelegate presentBlogDetailsViewController:controller];
    }
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
}

- (void)showDashboard
{
    if (self.isSidebarModeEnabled) {
        MySiteViewController *controller = [MySiteViewController makeForBlog:self.blog isSidebarModeEnabled:true];
        [self.presentationDelegate presentBlogDetailsViewController:controller];
    } else {
        BlogDashboardViewController *controller = [[BlogDashboardViewController alloc] initWithBlog:self.blog embeddedInScrollView:NO];
        controller.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
        controller.extendedLayoutIncludesOpaqueBars = YES;
        [self.presentationDelegate presentBlogDetailsViewController:controller];
    }
}

- (void)showActivity
{
    JetpackActivityLogViewController *controller = [[JetpackActivityLogViewController alloc] initWithBlog:self.blog];
    controller.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    [self.presentationDelegate presentBlogDetailsViewController:controller];

    [WPAnalytics track:WPAnalyticsStatActivityLogViewed
                 withProperties:@{WPAppAnalyticsKeyTapSource: @"site_menu"}];
}

- (void)showBlaze
{
    [BlazeEventsTracker trackEntryPointTappedFor:BlazeSourceMenuItem];

    if ([RemoteFeature enabled:RemoteFeatureFlagBlazeManageCampaigns]) {
        BlazeCampaignsViewController *controller =  [BlazeCampaignsViewController makeWithSource:BlazeSourceMenuItem
                                                                                            blog:self.blog];
        [self.presentationDelegate presentBlogDetailsViewController:controller];
    } else {
        [BlazeFlowCoordinator presentBlazeInViewController:self
                                                    source:BlazeSourceMenuItem
                                                      blog:self.blog
                                                      post:nil];
    }
}

- (void)showScan
{
    UIViewController *controller = [JetpackScanViewController withJPBannerForBlog:self.blog];
    [self.presentationDelegate presentBlogDetailsViewController:controller];
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
    viewController.hidesBottomBarWhenPushed = YES;
    UIViewController *jpWrappedViewController = [viewController withJPBanner];
    [self.presentationDelegate presentBlogDetailsViewController:jpWrappedViewController];
}

- (void)showMenus
{
    [WPAppAnalytics track:WPAnalyticsStatMenusAccessed withBlog:self.blog];
    UIViewController *viewController = [MenusViewController withJPBannerForBlog:self.blog];
    [self.presentationDelegate presentBlogDetailsViewController:viewController];
}

- (void)showViewSiteFromSource:(BlogDetailsNavigationSource)source
{
    [self trackEvent:WPAnalyticsStatOpenedViewSite fromSource:source];

    NSURL *targetURL = [NSURL URLWithString:self.blog.homeURL];

    UIViewController *webViewController = [WebViewControllerFactory controllerWithUrl:targetURL
                                                                                 blog:self.blog
                                                                               source:@"my_site_view_site"
                                                                      withDeviceModes:true
                                                                              onClose:nil];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:webViewController];
    if (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        navController.modalPresentationStyle = UIModalPresentationFullScreen;
    }

    [self presentViewController:navController
                       animated:YES
                     completion:nil];
}

- (void)showViewAdmin
{
    [WPAppAnalytics track:WPAnalyticsStatOpenedViewAdmin withBlog:self.blog];

    NSString *dashboardUrl;
    if (self.blog.isHostedAtWPcom) {
        dashboardUrl = [NSString stringWithFormat:@"%@%@", WPCalypsoDashboardPath, self.blog.hostname];
    } else {
        dashboardUrl = [self.blog adminUrlWithPath:@""];
    }
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:dashboardUrl] options:nil completionHandler:nil];
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
    [alertController addDestructiveActionWithTitle:destructiveTitle handler:^(UIAlertAction * __unused action) {
        [self confirmRemoveSite];
    }];

    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)confirmRemoveSite
{
    BlogService *blogService = [[BlogService alloc] initWithCoreDataStack:[ContextManager sharedInstance]];
    [blogService removeBlog:self.blog];
    [[WordPressAppDelegate shared] trackLogoutIfNeeded];

    if ([AppConfiguration isWordPress]) {
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

    NSSet *updatedObjects = note.userInfo[NSUpdatedObjectsKey];
    if ([updatedObjects containsObject:self.blog] || [updatedObjects containsObject:self.blog.settings]) {
        [self configureTableViewData];
        [self reloadTableViewPreservingSelection];
    }
}

- (void)handleWillEnterForegroundNotification:(NSNotification *)note
{
    [self configureTableViewData];
    [self reloadTableViewPreservingSelection];
}

- (void)observeManagedObjectContextObjectsDidChangeNotification
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleDataModelChange:)
                                                 name:NSManagedObjectContextObjectsDidChangeNotification
                                               object:context];
}

- (void)observeWillEnterForegroundNotification
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleWillEnterForegroundNotification:)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
}

- (void)stopObservingWillEnterForegroundNotification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationWillEnterForegroundNotification
                                                  object:nil];
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

#pragma mark - UIAdaptivePresentationControllerDelegate

- (void)presentationControllerWillDismiss:(UIPresentationController *)presentationController {
    if (presentationController.presentedViewController == self.presentedSiteSettingsViewController) {
        [self.tableView deselectSelectedRowWithAnimation:YES];
    }
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

#pragma mark - Constants

+ (NSString *)userInfoShowPickerKey {
    return @"show-picker";
}

+ (NSString *)userInfoSiteMonitoringTabKey {
    return @"site-monitoring-tab";
}

+ (NSString *)userInfoShowManagemenetScreenKey {
    return @"show-manage-plugins";
}

+ (NSString *)userInfoSourceKey {
    return @"source";
}

@end
