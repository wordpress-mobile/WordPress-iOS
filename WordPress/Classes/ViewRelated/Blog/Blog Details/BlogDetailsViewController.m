#import "BlogDetailsViewController.h"

#import "AccountService.h"
#import "BlogService.h"
#import "CommentsViewController.h"
#import "ContextManager.h"
#import "ReachabilityUtils.h"
#import "SiteSettingsViewController.h"
#import "SharingViewController.h"
#import "StatsViewController.h"
#import "WPAccount.h"
#import "WPAppAnalytics.h"
#import "WPGUIConstants.h"
#import "WordPress-Swift.h"
#import "MenusViewController.h"
#import <Reachability/Reachability.h>
#import <WordPressShared/WPTableViewCell.h>

@import Gridicons;

static NSString *const BlogDetailsCellIdentifier = @"BlogDetailsCell";
static NSString *const BlogDetailsPlanCellIdentifier = @"BlogDetailsPlanCell";
static NSString *const BlogDetailsSettingsCellIdentifier = @"BlogDetailsSettingsCell";
static NSString *const BlogDetailsRemoveSiteCellIdentifier = @"BlogDetailsRemoveSiteCell";
static NSString *const BlogDetailsSectionHeaderViewIdentifier = @"BlogDetailsSectionHeaderView";
static NSString *const QuickStartHeaderViewNibName = @"BlogDetailsSectionHeaderView";
static NSString *const QuickStartListTitleCellNibName = @"QuickStartListTitleCell";
static NSString *const BlogDetailsSectionFooterIdentifier = @"BlogDetailsSectionFooterView";

NSString * const WPBlogDetailsRestorationID = @"WPBlogDetailsID";
NSString * const WPBlogDetailsBlogKey = @"WPBlogDetailsBlogKey";
NSString * const WPBlogDetailsSelectedIndexPathKey = @"WPBlogDetailsSelectedIndexPathKey";

CGFloat const BlogDetailGridiconAccessorySize = 17.0;
CGFloat const BlogDetailQuickStartSectionHeight = 35.0;
NSTimeInterval const PreloadingCacheTimeout = 60.0 * 5; // 5 minutes
NSString * const HideWPAdminDate = @"2015-09-07T00:00:00Z";

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
                      callback:callback];
}

- (instancetype)initWithTitle:(NSString * __nonnull)title
      accessibilityIdentifier:(NSString *__nullable)accessibilityIdentifier
            accessibilityHint:(NSString * __nullable)accessibilityHint
                        image:(UIImage * __nonnull)image
                   imageColor:(UIColor * __nonnull)imageColor
                     callback:(void(^_Nullable)(void))callback
{
    return [self initWithTitle:title
                 identifier:BlogDetailsCellIdentifier
    accessibilityIdentifier:accessibilityIdentifier
          accessibilityHint:nil
                      image:image
                 imageColor:imageColor
                   callback:callback];
}

- (instancetype)initWithTitle:(NSString * __nonnull)title
                    identifier:(NSString * __nonnull)identifier
       accessibilityIdentifier:(NSString *__nullable)accessibilityIdentifier
             accessibilityHint:(NSString *__nullable)accessibilityHint
                         image:(UIImage * __nonnull)image
                    imageColor:(UIColor * __nonnull)imageColor
                      callback:(void(^)(void))callback
{
    self = [super init];
    if (self) {
        _title = title;
        _image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
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

@interface BlogDetailsViewController () <UIActionSheetDelegate, UIAlertViewDelegate, WPSplitViewControllerDetailProvider, BlogDetailHeaderViewDelegate, UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong, readwrite) id<BlogDetailHeader> headerView;
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

@property (nonatomic, strong) CreateButtonCoordinator *createButtonCoordinator;

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
    UISplitViewController *splitViewController = [[WPTabBarController sharedInstance] blogListSplitViewController];
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
    
    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.translatesAutoresizingMaskIntoConstraints = false;
    [self.view addSubview:self.tableView];
    [self.view pinSubviewToAllEdges:self.tableView];

    self.tableView.accessibilityIdentifier = @"Blog Details Table";

    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
    [WPStyleGuide configureAutomaticHeightRowsFor:self.tableView];

    [self.tableView registerClass:[WPTableViewCell class] forCellReuseIdentifier:BlogDetailsCellIdentifier];
    [self.tableView registerClass:[WPTableViewCellValue1 class] forCellReuseIdentifier:BlogDetailsPlanCellIdentifier];
    [self.tableView registerClass:[WPTableViewCellValue1 class] forCellReuseIdentifier:BlogDetailsSettingsCellIdentifier];
    [self.tableView registerClass:[WPTableViewCell class] forCellReuseIdentifier:BlogDetailsRemoveSiteCellIdentifier];
    UINib *qsHeaderViewNib = [UINib nibWithNibName:QuickStartHeaderViewNibName bundle:[NSBundle bundleForClass:[QuickStartListTitleCell class]]];
    [self.tableView registerNib:qsHeaderViewNib forHeaderFooterViewReuseIdentifier:BlogDetailsSectionHeaderViewIdentifier];
    UINib *qsTitleCellNib = [UINib nibWithNibName:QuickStartListTitleCellNibName bundle:[NSBundle bundleForClass:[QuickStartListTitleCell class]]];
    [self.tableView registerNib:qsTitleCellNib forCellReuseIdentifier:[QuickStartListTitleCell reuseIdentifier]];
    [self.tableView registerClass:[BlogDetailsSectionFooterView class] forHeaderFooterViewReuseIdentifier:BlogDetailsSectionFooterIdentifier];

    self.hasLoggedDomainCreditPromptShownEvent = NO;

    __weak __typeof(self) weakSelf = self;
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    self.blogService = [[BlogService alloc] initWithManagedObjectContext:context];
    [self.blogService syncBlogAndAllMetadata:_blog
                           completionHandler:^{
                               [weakSelf configureTableViewData];
                               [weakSelf reloadTableViewPreservingSelection];
                           }];
    if (self.blog.account && !self.blog.account.userID) {
        // User's who upgrade may not have a userID recorded.
        AccountService *acctService = [[AccountService alloc] initWithManagedObjectContext:context];
        [acctService updateUserDetailsForAccount:self.blog.account success:nil failure:nil];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleDataModelChange:)
                                                 name:NSManagedObjectContextObjectsDidChangeNotification
                                               object:context];

    [self configureBlogDetailHeader];
    [self.headerView setBlog:_blog];
    [self startObservingQuickStart];
    [self addMeButtonToNavigationBarWithEmail:self.blog.account.email meScenePresenter:self.meScenePresenter];
    
    [self.createButtonCoordinator addTo:self.view trailingAnchor:self.view.safeAreaLayoutGuide.trailingAnchor bottomAnchor:self.view.safeAreaLayoutGuide.bottomAnchor];
}

/// Resizes the `tableHeaderView` as necessary whenever its size changes.
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    [self.createButtonCoordinator presentingTraitCollectionWillChange:self.traitCollection newTraitCollection:self.traitCollection];
    
    UIView *headerView = self.tableView.tableHeaderView;
    
    CGSize size = [self.tableView.tableHeaderView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    if (headerView.frame.size.height != size.height) {
        headerView.frame = CGRectMake(headerView.frame.origin.x, headerView.frame.origin.y, headerView.frame.size.width, size.height);
        
        self.tableView.tableHeaderView = headerView;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if ([[QuickStartTourGuide shared] currentElementInt] != NSNotFound) {
        self.additionalSafeAreaInsets = UIEdgeInsetsMake(0, 0, [BlogDetailsViewController bottomPaddingForQuickStartNotices], 0);
    } else {
        self.additionalSafeAreaInsets = UIEdgeInsetsZero;
    }

    if (self.splitViewControllerIsHorizontallyCompact) {
        self.restorableSelectedIndexPath = nil;
    }
    
    self.navigationItem.title = NSLocalizedString(@"My Site", @"Title of My Site tab");

    [self.headerView setBlog:self.blog];

    // Configure and reload table data when appearing to ensure pending comment count is updated
    [self configureTableViewData];

    [self reloadTableViewPreservingSelection];
    [self preloadBlogData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if ([self.tabBarController isKindOfClass:[WPTabBarController class]]) {
        [self.createButtonCoordinator showCreateButtonFor:self.blog];
    }
    [self createUserActivity];
    [self startAlertTimer];

    if (self.shouldScrollToViewSite == YES) {
        [self scrollToElement:QuickStartTourElementViewSite];
        self.shouldScrollToViewSite = NO;
    }
    if([Feature enabled:FeatureFlagWhatIsNew]) {
        [WPTabBarController.sharedInstance presentWhatIsNewOn:self];
    }
}

- (CreateButtonCoordinator *)createButtonCoordinator
{
    if (!_createButtonCoordinator) {
        _createButtonCoordinator = [self makeCreateButtonCoordinator];
    }
    
    return _createButtonCoordinator;
}

- (void)willTransitionToTraitCollection:(UITraitCollection *)newCollection withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [self.createButtonCoordinator presentingTraitCollectionWillChange:self.traitCollection newTraitCollection:newCollection];
    [super willTransitionToTraitCollection:newCollection withTransitionCoordinator:coordinator];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self stopAlertTimer];
    if ([self.tabBarController isKindOfClass:[WPTabBarController class]]) {
        [self.createButtonCoordinator hideCreateButton];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];

    // Required to update disclosure indicators depending on split view status
    [self reloadTableViewPreservingSelection];
}

- (void)showDetailViewForSubsection:(BlogDetailsSubsection)section
{
    NSIndexPath *indexPath = [self indexPathForSubsection:section];

    switch (section) {
        case BlogDetailsSubsectionDomainCredit:
        case BlogDetailsSubsectionQuickStart:
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
            [self showComments];
            break;
        case BlogDetailsSubsectionSharing:
            if ([self.blog supports:BlogFeatureSharing]) {
                self.restorableSelectedIndexPath = indexPath;
                [self.tableView selectRowAtIndexPath:indexPath
                                            animated:NO
                                      scrollPosition:[self optimumScrollPositionForIndexPath:indexPath]];
                [self showSharing];
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
    BlogDetailsSectionCategory sectionCategory = [self sectionCategoryWithSubsection:subsection];
    NSInteger section = [self findSectionIndexWithSections:self.tableSections category:sectionCategory];
    switch (subsection) {
        case BlogDetailsSubsectionDomainCredit:
            return [NSIndexPath indexPathForRow:0 inSection:section];
        case BlogDetailsSubsectionQuickStart:
            return [NSIndexPath indexPathForRow:0 inSection:section];
        case BlogDetailsSubsectionStats:
            return [self shouldShowQuickStartChecklist] ? [NSIndexPath indexPathForRow:1 inSection:section] : [NSIndexPath indexPathForRow:0 inSection:section];
        case BlogDetailsSubsectionActivity:
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
        BlogDetailsSubsection subsection = BlogDetailsSubsectionStats;
        self.selectedSectionCategory = [self sectionCategoryWithSubsection:subsection];
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
            case BlogDetailsSectionCategoryQuickStart:
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

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)sectionNum {
    BlogDetailsSection *section = self.tableSections[sectionNum];
    if (section.showQuickStartMenu == true) {
        return BlogDetailQuickStartSectionHeight;
    } else if (([section.title isEmpty] || section.title == nil) && sectionNum == 0) {
        // because tableView:viewForHeaderInSection: is implemented, this must explicitly be 0
        return 0.0;
    }
    return UITableViewAutomaticDimension;
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
            case BlogDetailsSectionCategoryQuickStart:
            case BlogDetailsSectionCategoryDomainCredit: {
                BlogDetailsSectionCategory category = [self sectionCategoryWithSubsection:BlogDetailsSubsectionStats];
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
    if (([self.blog supports:BlogFeatureActivity] && ![self.blog isWPForTeams]) || [self.blog supports:BlogFeatureJetpackSettings]) {
        [marr addObject:[self jetpackSectionViewModel]];
    } else {
        [marr addObject:[self generalSectionViewModel]];
    }

    [marr addObject:[self publishTypeSectionViewModel]];
    if ([self.blog supports:BlogFeatureThemeBrowsing] || [self.blog supports:BlogFeatureMenus]) {
        [marr addObject:[self personalizeSectionViewModel]];
    }
    [marr addObject:[self configurationSectionViewModel]];
    [marr addObject:[self externalSectionViewModel]];
    if ([self.blog supports:BlogFeatureRemovable]) {
        [marr addObject:[self removeSiteSectionViewModel]];
    }

    // Assign non mutable copy.
    self.tableSections = [NSArray arrayWithArray:marr];
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

// Temporarily disabled
//    if ([self.blog supports:BlogFeaturePlans] && ![self.blog isWPForTeams]) {
//        BlogDetailsRow *plansRow = [[BlogDetailsRow alloc] initWithTitle:NSLocalizedString(@"Plans", @"Action title. Noun. Links to a blog's Plans screen.")
//                                                         identifier:BlogDetailsPlanCellIdentifier
//                                                              image:[UIImage gridiconOfType:GridiconTypePlans]
//                                                           callback:^{
//                                                               [weakSelf showPlans];
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
                                                        image:[UIImage gridiconOfType:GridiconTypeHistory]
                                                     callback:^{
                                                         [weakSelf showActivity];
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

    NSString *title = NSLocalizedString(@"Jetpack", @"Section title for the publish table section in the blog details screen");
    return [[BlogDetailsSection alloc] initWithTitle:title andRows:rows category:BlogDetailsSectionCategoryJetpack];
}


- (BlogDetailsSection *)publishTypeSectionViewModel
{
    __weak __typeof(self) weakSelf = self;
    NSMutableArray *rows = [NSMutableArray array];

    BlogDetailsRow *pagesRow = [[BlogDetailsRow alloc] initWithTitle:NSLocalizedString(@"Site Pages", @"Noun. Title. Links to the blog's Pages screen.")
                                             accessibilityIdentifier:@"Site Pages Row"
                                                    image:[UIImage gridiconOfType:GridiconTypePages]
                                                 callback:^{
        [weakSelf showPageListFromSource:BlogDetailsNavigationSourceRow];
                                                 }];
    pagesRow.quickStartIdentifier = QuickStartTourElementPages;
    [rows addObject:pagesRow];

    [rows addObject:[[BlogDetailsRow alloc] initWithTitle:NSLocalizedString(@"Blog Posts", @"Noun. Title. Links to the blog's Posts screen.")
                                  accessibilityIdentifier:@"Blog Post Row"
                                                    image:[[UIImage gridiconOfType:GridiconTypePosts] imageFlippedForRightToLeftLayoutDirection]
                                                 callback:^{
        [weakSelf showPostListFromSource:BlogDetailsNavigationSourceRow];
                                                 }]];


    [rows addObject:[[BlogDetailsRow alloc] initWithTitle:NSLocalizedString(@"Media", @"Noun. Title. Links to the blog's Media library.")
                                  accessibilityIdentifier:@"Media Row"
                                                    image:[UIImage gridiconOfType:GridiconTypeImage]
                                                 callback:^{
        [weakSelf showMediaLibraryFromSource:BlogDetailsNavigationSourceRow];
                                                 }]];

    BlogDetailsRow *row = [[BlogDetailsRow alloc] initWithTitle:NSLocalizedString(@"Comments", @"Noun. Title. Links to the blog's Comments screen.")
                                                          image:[[UIImage gridiconOfType:GridiconTypeComment] imageFlippedForRightToLeftLayoutDirection]
                                                       callback:^{
                                                           [weakSelf showComments];
                                                       }];
    NSUInteger numberOfPendingComments = [self.blog numberOfPendingComments];
    if (numberOfPendingComments > 0) {
        row.detail = [NSString stringWithFormat:@"%d", numberOfPendingComments];
    }
    [rows addObject:row];

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

    if ([self.blog supports:BlogFeatureSharing]) {
        BlogDetailsRow *row = [[BlogDetailsRow alloc] initWithTitle:NSLocalizedString(@"Sharing", @"Noun. Title. Links to a blog's sharing options.")
                                        image:[UIImage gridiconOfType:GridiconTypeShare]
                                     callback:^{
                                         [weakSelf showSharing];
                                     }];
        row.quickStartIdentifier = QuickStartTourElementSharing;
        [rows addObject:row];
    }

    if ([self.blog supports:BlogFeaturePeople]) {
        [rows addObject:[[BlogDetailsRow alloc] initWithTitle:NSLocalizedString(@"People", @"Noun. Title. Links to the people management feature.")
                                                        image:[UIImage gridiconOfType:GridiconTypeUser]
                                                     callback:^{
                                                         [weakSelf showPeople];
                                                     }]];
    }

    if ([self.blog supports:BlogFeaturePluginManagement]) {
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
                                                           [weakSelf showSettings];
                                                       }];

    [rows addObject:row];

    NSString *title = NSLocalizedString(@"Configure", @"Section title for the configure table section in the blog details screen");
    return [[BlogDetailsSection alloc] initWithTitle:title andRows:rows category:BlogDetailsSectionCategoryConfigure];
}

- (BlogDetailsSection *)externalSectionViewModel
{
    __weak __typeof(self) weakSelf = self;
    NSMutableArray *rows = [NSMutableArray array];
    BlogDetailsRow *viewSiteRow = [[BlogDetailsRow alloc] initWithTitle:NSLocalizedString(@"View Site", @"Action title. Opens the user's site in an in-app browser")
                                                                  image:[UIImage gridiconOfType:GridiconTypeHouse]
                                                               callback:^{
                                                                   [weakSelf showViewSite];
                                                               }];
    viewSiteRow.quickStartIdentifier = QuickStartTourElementViewSite;
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
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
    WPAccount *defaultAccount = [accountService defaultWordPressComAccount];
    return [defaultAccount.dateCreated compare:hideWPAdminDate] == NSOrderedAscending;
}

#pragma mark - Configuration

- (void)configureBlogDetailHeader
{
    id<BlogDetailHeader> headerView = [self configureHeaderView];
    headerView.delegate = self;

    self.headerView = headerView;

    self.tableView.tableHeaderView = headerView.asView;
}

#pragma mark BlogDetailHeaderViewDelegate

- (void)siteIconTapped
{
    if (![self siteIconShouldAllowDroppedImages]) {
        // Gracefully ignore the tap for users that can not upload files or
        // blogs that do not have capabilities since those will not support the REST API icon update
        return;
    }
    [WPAnalytics track:WPAnalyticsStatSiteSettingsSiteIconTapped];
    [self showUpdateSiteIconAlert];
}

- (void)siteIconReceivedDroppedImage:(UIImage *)image
{
    if (![self siteIconShouldAllowDroppedImages]) {
        // Gracefully ignore the drop for users that can not upload files or
        // blogs that do not have capabilities since those will not support the REST API icon update
        self.headerView.updatingIcon = NO;
        return;
    }
    [self presentCropViewControllerForDroppedSiteIcon:image];
}

- (BOOL)siteIconShouldAllowDroppedImages
{
    if (!self.blog.isAdmin || !self.blog.isUploadingFilesAllowed) {
        return NO;
    }

    return YES;
}

- (void)siteTitleTapped
{
    [self showSiteTitleSettings];
}

#pragma mark Site Icon Update Management

- (void)showUpdateSiteIconAlert
{
    UIAlertController *updateIconAlertController = [UIAlertController alertControllerWithTitle:nil
                                                                                       message:nil
                                                                                preferredStyle:UIAlertControllerStyleActionSheet];

    updateIconAlertController.popoverPresentationController.sourceView = self.headerView.blavatarImageView.superview;
    updateIconAlertController.popoverPresentationController.sourceRect = self.headerView.blavatarImageView.frame;
    updateIconAlertController.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionAny;

    [updateIconAlertController addDefaultActionWithTitle:NSLocalizedString(@"Change Site Icon", @"Change site icon button")
                                                 handler:^(UIAlertAction *action) {
                                                     [self updateSiteIcon];
                                                 }];
    if (self.blog.hasIcon) {
        [updateIconAlertController addDestructiveActionWithTitle:NSLocalizedString(@"Remove Site Icon", @"Remove site icon button")
                                                         handler:^(UIAlertAction *action) {
                                                             [self removeSiteIcon];
                                                         }];
    }
    [updateIconAlertController addCancelActionWithTitle:NSLocalizedString(@"Cancel", @"Cancel button")
                                                handler:^(UIAlertAction *action) {
                                                    [self startAlertTimer];
                                                }];

    [self presentViewController:updateIconAlertController animated:YES completion:nil];
}

- (void)presentCropViewControllerForDroppedSiteIcon:(UIImage *)image
{
    self.imageCropViewController = [[ImageCropViewController alloc] initWithImage:image];
    self.imageCropViewController.maskShape = ImageCropOverlayMaskShapeSquare;
    self.imageCropViewController.shouldShowCancelButton = YES;

    __weak __typeof(self) weakSelf = self;
    self.imageCropViewController.onCancel = ^(void) {
        [weakSelf dismissViewControllerAnimated:YES completion:nil];
        weakSelf.headerView.updatingIcon = NO;
    };

    self.imageCropViewController.onCompletion = ^(UIImage *image, BOOL modified) {
        [weakSelf dismissViewControllerAnimated:YES completion:nil];
        [weakSelf uploadDroppedSiteIcon:image onCompletion:^{
            weakSelf.headerView.blavatarImageView.image = image;
            weakSelf.headerView.updatingIcon = NO;
        }];
    };
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:self.imageCropViewController];
    navController.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:navController animated:YES completion:nil];
}

- (void)uploadDroppedSiteIcon:(UIImage *)image onCompletion:(void(^)(void))completion
{
    if (self.blog.objectID == nil) {
        return;
    }

    __weak __typeof(self) weakSelf = self;
    MediaService *mediaService = [[MediaService alloc] initWithManagedObjectContext:[ContextManager sharedInstance].mainContext];
    NSProgress *mediaCreateProgress;
    [mediaService createMediaWith:image blog:self.blog post:nil progress:&mediaCreateProgress thumbnailCallback:nil completion:^(Media *media, NSError *error) {
        if (media == nil || error != nil) {
            return;
        }
        NSProgress *uploadProgress;
        [mediaService uploadMedia:media
                   automatedRetry:false
                         progress:&uploadProgress
                          success:^{
            [weakSelf updateBlogIconWithMedia:media];
            completion();
        } failure:^(NSError * _Nonnull error) {
            [weakSelf showErrorForSiteIconUpdate];
            completion();
        }];
    }];
}

- (void)updateSiteIcon
{
    self.siteIconPickerPresenter = [[SiteIconPickerPresenter alloc]initWithBlog:self.blog];
    __weak __typeof(self) weakSelf = self;
    self.siteIconPickerPresenter.onCompletion = ^(Media *media, NSError *error) {
        if (error) {
            [weakSelf showErrorForSiteIconUpdate];
        } else if (media) {
            [weakSelf updateBlogIconWithMedia:media];
        } else {
            // If no media and no error the picker was canceled
            [weakSelf dismissViewControllerAnimated:YES completion:nil];
        }
        weakSelf.siteIconPickerPresenter = nil;
        [weakSelf startAlertTimer];
    };
    self.siteIconPickerPresenter.onIconSelection = ^() {
        weakSelf.headerView.updatingIcon = YES;
        [weakSelf dismissViewControllerAnimated:YES completion:nil];
    };
    [self.siteIconPickerPresenter presentPickerFrom:self];
}

- (void)removeSiteIcon
{
    self.headerView.updatingIcon = YES;
    self.blog.settings.iconMediaID = @0;
    [self updateBlogSettingsAndRefreshIcon];
    [WPAnalytics track:WPAnalyticsStatSiteSettingsSiteIconRemoved];
}

- (void)refreshSiteIcon
{
    [self.headerView refreshIconImage];
}

- (void)toggleSpotlightForSiteTitle
{
    [self.headerView toggleSpotlightOnSiteTitle];
}

- (void)toggleSpotlightOnHeaderView
{
    [self.headerView toggleSpotlightOnSiteTitle];
    [self.headerView toggleSpotlightOnSiteIcon];
}

- (void)updateBlogIconWithMedia:(Media *)media
{
    self.blog.settings.iconMediaID = media.mediaID;
    [self updateBlogSettingsAndRefreshIcon];
}

- (void)updateBlogSettingsAndRefreshIcon
{
    BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:self.blog.managedObjectContext];
    [blogService updateSettingsForBlog:self.blog
                               success:^{
        [blogService syncBlog:self.blog
                      success:^{
            self.headerView.updatingIcon = NO;
            [self.headerView refreshIconImage];
        } failure:nil];
     } failure:^(NSError *error){
         [self showErrorForSiteIconUpdate];
     }];
}

- (void)showErrorForSiteIconUpdate
{
    [SVProgressHUD showDismissibleErrorWithStatus:NSLocalizedString(@"Icon update failed", @"Message to show when site icon update failed")];
    self.headerView.updatingIcon = NO;
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
    if ([cell isKindOfClass:[QuickStartListTitleCell class]]) {
        ((QuickStartListTitleCell *) cell).state = row.quickStartTitleState;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    BlogDetailsSection *section = [self.tableSections objectAtIndex:indexPath.section];
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
    if ([[QuickStartTourGuide shared] isCurrentElement:row.quickStartIdentifier]) {
        row.accessoryView = [QuickStartSpotlightView new];
    } else if ([row.accessoryView isKindOfClass:[QuickStartSpotlightView class]]) {
        row.accessoryView = nil;
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
    } else {
        return nil;
    }
}

- (UIView *)quickStartHeaderWithTitle:(NSString *)title
{
    __weak __typeof(self) weakSelf = self;
    BlogDetailsSectionHeaderView *view = [self.tableView dequeueReusableHeaderFooterViewWithIdentifier:BlogDetailsSectionHeaderViewIdentifier];
    [view setTitle:title];
    view.ellipsisButtonDidTouch = ^(BlogDetailsSectionHeaderView *header) {
        [weakSelf removeQuickStartSection:header];
    };
    return view;
}

- (void)removeQuickStartSection:(BlogDetailsSectionHeaderView *)view
{
    NSString *removeTitle = NSLocalizedString(@"Remove Next Steps", @"Title for action that will remove the next steps/quick start menus.");
    NSString *removeMessage = NSLocalizedString(@"Removing Next Steps will hide all tours on this site. This action cannot be undone.", @"Explanation of what will happen if the user confirms this alert.");
    NSString *confirmationTitle = NSLocalizedString(@"Remove", @"Title for button that will confirm removing the next steps/quick start menus.");
    NSString *cancelTitle = NSLocalizedString(@"Cancel", @"Cancel button");
    
    UIAlertController *removeConfirmation = [UIAlertController alertControllerWithTitle:removeTitle message:removeMessage preferredStyle:UIAlertControllerStyleAlert];
    [removeConfirmation addCancelActionWithTitle:cancelTitle handler:^(UIAlertAction * _Nonnull action) {
        [WPAnalytics track:WPAnalyticsStatQuickStartRemoveDialogButtonCancelTapped];
    }];
    [removeConfirmation addDefaultActionWithTitle:confirmationTitle handler:^(UIAlertAction * _Nonnull action) {
        [WPAnalytics track:WPAnalyticsStatQuickStartRemoveDialogButtonRemoveTapped];
        
        [[QuickStartTourGuide shared] removeFrom:self.blog];
    }];
    
    UIAlertController *removeSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    removeSheet.popoverPresentationController.sourceView = view;
    removeSheet.popoverPresentationController.sourceRect = view.ellipsisButton.frame;
    [removeSheet addDestructiveActionWithTitle:removeTitle handler:^(UIAlertAction * _Nonnull action) {
        [self presentViewController:removeConfirmation animated:YES completion:nil];
    }];
    [removeSheet addCancelActionWithTitle:cancelTitle handler:nil];
    
    [self presentViewController:removeSheet animated:YES completion:nil];
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
    
    NSString *sourceString;
    
    switch (source) {
        case BlogDetailsNavigationSourceRow:
            sourceString = @"row";
            break;
            
        case BlogDetailsNavigationSourceLink:
            sourceString = @"link";
            break;
            
        case BlogDetailsNavigationSourceButton:
            sourceString = @"button";
            break;
            
        default:
            break;
    }
    
    [WPAppAnalytics track:event withProperties:@{WPAppAnalyticsKeyTapSource: sourceString} withBlog:self.blog];
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
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    CommentService *commentService = [[CommentService alloc] initWithManagedObjectContext:context];

    if ([CommentService shouldRefreshCacheFor:self.blog]) {
        [commentService syncCommentsForBlog:self.blog success:nil failure:nil];
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

- (void)scrollToElement:(QuickStartTourElement) element
{
    int sectionCount = 0;
    int rowCount = 0;
    for (BlogDetailsSection *section in self.tableSections) {
        rowCount = 0;
        for (BlogDetailsRow *row in section.rows) {
            if (row.quickStartIdentifier == element) {
                self.additionalSafeAreaInsets = UIEdgeInsetsMake(0, 0, [BlogDetailsViewController bottomPaddingForQuickStartNotices], 0);
                NSIndexPath *path = [NSIndexPath indexPathForRow:rowCount inSection:sectionCount];
                [self.tableView scrollToRowAtIndexPath:path atScrollPosition:UITableViewScrollPositionTop animated:true];
            }
            rowCount++;
        }
        sectionCount++;
    }
}

- (void)showComments
{
    [WPAppAnalytics track:WPAnalyticsStatOpenedComments withBlog:self.blog];
    CommentsViewController *controller = [[CommentsViewController alloc] initWithStyle:UITableViewStylePlain];
    controller.blog = self.blog;
    [self showDetailViewController:controller sender:self];

    [[QuickStartTourGuide shared] visited:QuickStartTourElementBlogDetailNavigation];
}

- (void)showPostListFromSource:(BlogDetailsNavigationSource)source
{
    [self trackEvent:WPAnalyticsStatOpenedPosts fromSource:source];
    PostListViewController *controller = [PostListViewController controllerWithBlog:self.blog];
    [self showDetailViewController:controller sender:self];

    [[QuickStartTourGuide shared] visited:QuickStartTourElementBlogDetailNavigation];
}

- (void)showPageListFromSource:(BlogDetailsNavigationSource)source
{
    [self trackEvent:WPAnalyticsStatOpenedPages fromSource:source];
    PageListViewController *controller = [PageListViewController controllerWithBlog:self.blog];
    [self showDetailViewController:controller sender:self];

    [[QuickStartTourGuide shared] visited:QuickStartTourElementPages];
}

- (void)showMediaLibraryFromSource:(BlogDetailsNavigationSource)source
{
    [self trackEvent:WPAnalyticsStatOpenedMediaLibrary fromSource:source];
    MediaLibraryViewController *controller = [[MediaLibraryViewController alloc] initWithBlog:self.blog];
    [self showDetailViewController:controller sender:self];

    [[QuickStartTourGuide shared] visited:QuickStartTourElementBlogDetailNavigation];
}

- (void)showPeople
{
    [WPAppAnalytics track:WPAnalyticsStatOpenedPeople withBlog:self.blog];
    PeopleViewController *controller = [PeopleViewController controllerWithBlog:self.blog];
    [self showDetailViewController:controller sender:self];

    [[QuickStartTourGuide shared] visited:QuickStartTourElementBlogDetailNavigation];
}

- (void)showPlugins
{
    [WPAppAnalytics track:WPAnalyticsStatOpenedPluginDirectory withBlog:self.blog];
    PluginDirectoryViewController *controller = [[PluginDirectoryViewController alloc] initWithBlog:self.blog];
    [self showDetailViewController:controller sender:self];

    [[QuickStartTourGuide shared] visited:QuickStartTourElementBlogDetailNavigation];
}

- (void)showPlans
{
    [WPAppAnalytics track:WPAnalyticsStatOpenedPlans withBlog:self.blog];
    PlanListViewController *controller = [[PlanListViewController alloc] initWithStyle:UITableViewStyleGrouped];
    [self showDetailViewController:controller sender:self];

    [[QuickStartTourGuide shared] visited:QuickStartTourElementPlans];
}

- (void)showSettings
{
    [WPAppAnalytics track:WPAnalyticsStatOpenedSiteSettings withBlog:self.blog];
    SiteSettingsViewController *controller = [[SiteSettingsViewController alloc] initWithBlog:self.blog];
    [self showDetailViewController:controller sender:self];

    [[QuickStartTourGuide shared] visited:QuickStartTourElementBlogDetailNavigation];
}

-(void)showJetpackSettings
{
    JetpackSettingsViewController *controller = [[JetpackSettingsViewController alloc] initWithBlog:self.blog];
    [self showDetailViewController:controller sender:self];
}

- (void)showSharing
{
    UIViewController *controller;
    if (![self.blog supportsPublicize]) {
        // if publicize is disabled, show the sharing buttons settings.
        controller = [[SharingButtonsViewController alloc] initWithBlog:self.blog];

    } else {
        controller = [[SharingViewController alloc] initWithBlog:self.blog];
    }

    [WPAppAnalytics track:WPAnalyticsStatOpenedSharingManagement withBlog:self.blog];
    [self showDetailViewController:controller sender:self];

    [[QuickStartTourGuide shared] visited:QuickStartTourElementSharing];
}

- (void)showStatsFromSource:(BlogDetailsNavigationSource)source
{
    [self trackEvent:WPAnalyticsStatStatsAccessed fromSource:source];
    StatsViewController *statsView = [StatsViewController new];
    statsView.blog = self.blog;

    // Calling `showDetailViewController:sender:` should do this automatically for us,
    // but when showing stats from our 3D Touch shortcut iOS sometimes incorrectly
    // presents the stats view controller as modal instead of pushing it. As a
    // workaround for now, we'll manually decide whether to push or use `showDetail`.
    // @frosty 2016-09-05
    if (self.splitViewController.isCollapsed) {
        [self.navigationController pushViewController:statsView animated:YES];
    } else {
        [self showDetailViewController:statsView sender:self];
    }

    [[QuickStartTourGuide shared] visited:QuickStartTourElementStats];
}

- (void)showActivity
{
    ActivityListViewController *controller = [[ActivityListViewController alloc] initWithBlog:self.blog];
    [self showDetailViewController:controller sender:self];

    [[QuickStartTourGuide shared] visited:QuickStartTourElementBlogDetailNavigation];
}

- (void)showThemes
{
    [WPAppAnalytics track:WPAnalyticsStatThemesAccessedThemeBrowser withBlog:self.blog];
    ThemeBrowserViewController *viewController = [ThemeBrowserViewController browserWithBlog:self.blog];
    viewController.onWebkitViewControllerClose = ^(void) {
        [self startAlertTimer];
    };
    [self showDetailViewController:viewController sender:self];

    [[QuickStartTourGuide shared] visited:QuickStartTourElementThemes];
}

- (void)showMenus
{
    [WPAppAnalytics track:WPAnalyticsStatMenusAccessed withBlog:self.blog];
    MenusViewController *viewController = [MenusViewController controllerWithBlog:self.blog];
    [self showDetailViewController:viewController sender:self];

    [[QuickStartTourGuide shared] visited:QuickStartTourElementBlogDetailNavigation];
}

- (void)showViewSite
{
    [WPAppAnalytics track:WPAnalyticsStatOpenedViewSite withBlog:self.blog];
    NSURL *targetURL = [NSURL URLWithString:self.blog.homeURL];

    if (self.blog.jetpack) {
        targetURL = [targetURL appendingHideMasterbarParameters];
    }

    UIViewController *webViewController = [WebViewControllerFactory controllerWithUrl:targetURL blog:self.blog];
    LightNavigationController *navController = [[LightNavigationController alloc] initWithRootViewController:webViewController];
    if (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        navController.modalPresentationStyle = UIModalPresentationFullScreen;
    }

    [self presentViewController:navController
                       animated:YES
                     completion:^(void) {
        [self toggleSpotlightOnHeaderView];
    }];

    [[QuickStartTourGuide shared] visited:QuickStartTourElementViewSite];
    self.additionalSafeAreaInsets = UIEdgeInsetsZero;
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
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:context];
    [blogService removeBlog:self.blog];
    [[WordPressAppDelegate shared] trackLogoutIfNeeded];
    [self.navigationController popToRootViewControllerAnimated:YES];
}

#pragma mark - Notification handlers

- (void)handleDataModelChange:(NSNotification *)note
{
    NSSet *deletedObjects = note.userInfo[NSDeletedObjectsKey];
    if ([deletedObjects containsObject:self.blog]) {
        [self.navigationController popToRootViewControllerAnimated:NO];
    }

    BOOL isQuickStartSectionShownBefore = [self findSectionIndexWithSections:self.tableSections category:BlogDetailsSectionCategoryQuickStart] != NSNotFound;

    NSSet *updatedObjects = note.userInfo[NSUpdatedObjectsKey];
    if ([updatedObjects containsObject:self.blog] || [updatedObjects containsObject:self.blog.settings]) {
        [self configureTableViewData];
        BOOL isQuickStartSectionShownAfter = [self findSectionIndexWithSections:self.tableSections category:BlogDetailsSectionCategoryQuickStart] != NSNotFound;
        
        // quick start was just enabled
        if (!isQuickStartSectionShownBefore && isQuickStartSectionShownAfter) {
            [self showQuickStartCustomize];
        }
        [self reloadTableViewPreservingSelection];
    }
}

#pragma mark - WPSplitViewControllerDetailProvider

- (UIViewController *)initialDetailViewControllerForSplitView:(WPSplitViewController *)splitView
{
    StatsViewController *statsView = [StatsViewController new];
    statsView.blog = self.blog;

    return statsView;
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

@end
