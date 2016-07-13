#import "BlogListViewController.h"
#import "WordPressAppDelegate.h"
#import "UIImageView+Gravatar.h"
#import "BlogDetailsViewController.h"
#import "WPTableViewCell.h"
#import "WPBlogTableViewCell.h"
#import "ContextManager.h"
#import "Blog.h"
#import "WPAccount.h"
#import "WPTableViewSectionHeaderFooterView.h"
#import "AccountService.h"
#import "BlogService.h"
#import "TodayExtensionService.h"
#import "WPTabBarController.h"
#import "WPFontManager.h"
#import "UILabel+SuggestSize.h"
#import "WordPress-Swift.h"
#import "WPGUIConstants.h"
#import "CreateNewBlogViewController.h"

static NSString *const BlogCellIdentifier = @"BlogCell";
static CGFloat const BLVCHeaderViewLabelPadding = 10.0;
static CGFloat const BLVCSiteRowHeight = 74.0;

static NSInteger HideAllMinSites = 10;
static NSInteger HideAllSitesThreshold = 6;
static NSTimeInterval HideAllSitesInterval = 2.0;

@interface BlogListViewController () <UIViewControllerRestoration,
                                        UIDataSourceModelAssociation,
                                        UITableViewDelegate,
                                        UITableViewDataSource,
                                        NSFetchedResultsControllerDelegate,
                                        UISearchResultsUpdating,
                                        UISearchControllerDelegate>

@property (nonatomic, strong) NSFetchedResultsController *resultsController;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UILabel *headerLabel;
@property (nonatomic, strong) UISearchController *searchController;
@property (nonatomic,   weak) UIAlertController *addSiteAlertController;
@property (nonatomic, strong) UIBarButtonItem *addSiteButton;

@property (nonatomic) NSDate *firstHide;
@property (nonatomic) NSInteger hideCount;

@end

@implementation BlogListViewController

+ (UIViewController *)viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder
{
    return [[WPTabBarController sharedInstance] blogListViewController];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.restorationIdentifier = NSStringFromClass([self class]);
        self.restorationClass = [self class];
        [self configureNavigationBar];
    }
    return self;
}

- (void)configureNavigationBar
{
    // show 'Switch Site' for the next page's back button
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Switch Site", @"")
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:nil
                                                                  action:nil];
    [self.navigationItem setBackBarButtonItem:backButton];
    
    self.addSiteButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon-post-add"]
                                                                                    style:UIBarButtonItemStylePlain
                                                                                   target:self
                                                                                   action:@selector(addSite)];

    self.navigationItem.title = NSLocalizedString(@"My Sites", @"");
}

- (NSString *)modelIdentifierForElementAtIndexPath:(NSIndexPath *)indexPath inView:(UIView *)view
{
    if (!indexPath || !view) {
        return nil;
    }

    // Preserve objectID
    NSManagedObject *managedObject = [self.resultsController objectAtIndexPath:indexPath];
    return [[managedObject.objectID URIRepresentation] absoluteString];
}

- (NSIndexPath *)indexPathForElementWithModelIdentifier:(NSString *)identifier inView:(UIView *)view
{
    if (!identifier || !view) {
        return nil;
    }

    // Map objectID back to indexPath
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    NSManagedObjectID *objectID = [context.persistentStoreCoordinator managedObjectIDForURIRepresentation:[NSURL URLWithString:identifier]];
    if (!objectID) {
        return nil;
    }

    NSError *error = nil;
    NSManagedObject *managedObject = [context existingObjectWithID:objectID error:&error];
    if (error || !managedObject) {
        return nil;
    }

    NSIndexPath *indexPath = [self.resultsController indexPathForObject:managedObject];

    return indexPath;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.tableView];
    [self.view pinSubviewToAllEdges:self.tableView];

    // Remove one-pixel gap resulting from a top-aligned grouped table view
    if ([WPDeviceIdentification isiPhone]) {
        UIEdgeInsets tableInset = [self.tableView contentInset];
        tableInset.top = -1;
        self.tableView.contentInset = tableInset;
    }

    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
    self.editButtonItem.accessibilityIdentifier = NSLocalizedString(@"Edit", @"");
    
    [self configureTableView];
    [self configureHeaderView];
    [self configureSearchController];
    
    [self registerForAccountChangeNotification];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self registerForKeyboardNotifications];

    self.resultsController.delegate = self;
    [self.resultsController performFetch:nil];
    [self.tableView reloadData];
    [self updateEditButton];
    [self maybeShowNUX];
    [self syncBlogs];
}

- (void)viewWillDisappear:(BOOL)animated
{
    self.searchController.active = NO;
    [super viewWillDisappear:animated];
    [self unregisterForKeyboardNotifications];
    self.resultsController.delegate = nil;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        if (self.tableView.tableHeaderView == self.headerView) {
            [self updateHeaderSize];
            
            // this forces the tableHeaderView to resize
            self.tableView.tableHeaderView = self.headerView;
        }
    } completion:nil];
}

- (NSUInteger)numSites
{
    return [[self.resultsController fetchedObjects] count];
}

- (void)updateEditButton
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:context];
    if ([blogService blogCountForWPComAccounts] > 0) {
        self.navigationItem.leftBarButtonItem = self.editButtonItem;
    } else {
        self.navigationItem.leftBarButtonItem = nil;
    }
}

- (void)maybeShowNUX
{
    if ([self numSites] > 0) {
        return;
    }
    if (![self defaultWordPressComAccount]) {
        [WPAnalytics track:WPAnalyticsStatLogout];
        [[WordPressAppDelegate sharedInstance] showWelcomeScreenIfNeededAnimated:YES];
    }
}

- (void)syncBlogs
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] newDerivedContext];
    [context performBlock:^{
        AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
        BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:context];
        WPAccount *defaultAccount = [accountService defaultWordPressComAccount];

        if (defaultAccount) {
            [blogService syncBlogsForAccount:defaultAccount success:nil failure:nil];
        }
    }];
}

#pragma mark - Header methods

- (void)configureHeaderView
{
    self.headerView = [[UIView alloc] initWithFrame:CGRectZero];
    self.headerLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.headerLabel.numberOfLines = 0;
    self.headerLabel.textAlignment = NSTextAlignmentCenter;
    self.headerLabel.textColor = [WPStyleGuide allTAllShadeGrey];
    self.headerLabel.font = [WPFontManager systemRegularFontOfSize:14.0];
    self.headerLabel.text = NSLocalizedString(@"Select which sites will be shown in the site picker.", @"Blog list page edit mode header label");
    [self.headerView addSubview:self.headerLabel];
}

- (void)updateHeaderSize
{
    CGFloat labelWidth = CGRectGetWidth(self.view.bounds) - 2 * BLVCHeaderViewLabelPadding;

    CGSize labelSize = [self.headerLabel suggestSizeForString:self.headerLabel.text width:labelWidth];
    self.headerLabel.frame = CGRectMake(BLVCHeaderViewLabelPadding, BLVCHeaderViewLabelPadding, labelWidth, labelSize.height);
    self.headerView.frame = CGRectMake(0.0, 0.0, CGRectGetWidth(self.view.bounds), labelSize.height + (2 * BLVCHeaderViewLabelPadding));
}

#pragma mark - Public methods

- (BOOL)shouldBypassBlogListViewControllerWhenSelectedFromTabBar
{
    // Ensure our list of sites is up to date
    [self.resultsController performFetch:nil];
    
    return [self numSites] == 1;
}

- (void)bypassBlogListViewController
{
    if ([self shouldBypassBlogListViewControllerWhenSelectedFromTabBar]) {
        // We do a delay of 0.0 so that way this doesn't kick off until the next run loop.
        [self performSelector:@selector(selectFirstSite) withObject:nil afterDelay:0.0];
    }
}

- (void)selectFirstSite
{
    [self tableView:self.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
}

#pragma mark - Configuration

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void)configureTableView
{
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView registerClass:[WPBlogTableViewCell class] forCellReuseIdentifier:BlogCellIdentifier];
    self.tableView.allowsSelectionDuringEditing = YES;
    self.tableView.accessibilityIdentifier = NSLocalizedString(@"Blogs", @"");

    [WPStyleGuide resetReadableMarginsForTableView:self.tableView];
}

- (void)configureSearchController
{
    // Required for insets to work out correctly when the search bar becomes active
    self.extendedLayoutIncludesOpaqueBars = YES;

    self.definesPresentationContext = YES;

    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.dimsBackgroundDuringPresentation = NO;

    self.searchController.searchBar.translucent = NO;

    self.tableView.tableHeaderView = self.searchController.searchBar;

    self.searchController.delegate = self;
    self.searchController.searchResultsUpdater = self;

    UIEdgeInsets insets = self.tableView.scrollIndicatorInsets;
    insets.top = [self searchBarHeight];
    self.tableView.scrollIndicatorInsets = insets;
}

- (CGFloat)searchBarHeight {
    return CGRectGetHeight(self.searchController.searchBar.bounds) + self.topLayoutGuide.length;
}

- (void)configureSearchBarPlaceholder
{
    // Adjust color depending on where the search bar is being presented.
    UIColor *placeholderColor = [WPStyleGuide wordPressBlue];
    NSString *placeholderText = NSLocalizedString(@"Search", @"Placeholder text for the search bar on the post screen.");
    NSAttributedString *attrPlacholderText = [[NSAttributedString alloc] initWithString:placeholderText attributes:[WPStyleGuide defaultSearchBarTextAttributes:placeholderColor]];
    [[UITextField appearanceWhenContainedInInstancesOfClasses:@[ [UISearchBar class], [self class] ]] setAttributedPlaceholder:attrPlacholderText];
    [[UITextField appearanceWhenContainedInInstancesOfClasses:@[ [UISearchBar class], [self class] ]] setDefaultTextAttributes:[WPStyleGuide defaultSearchBarTextAttributes:[UIColor whiteColor]]];
}

#pragma mark - Notifications

- (void)registerForAccountChangeNotification
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(wordPressComAccountChanged:)
                                                 name:WPAccountDefaultWordPressComAccountChangedNotification
                                               object:nil];
}

- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)unregisterForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    CGRect keyboardFrame = [self localKeyboardFrameFromNotification:notification];
    CGFloat keyboardHeight = CGRectGetMaxY(self.tableView.frame) - keyboardFrame.origin.y;

    UIEdgeInsets insets = self.tableView.contentInset;

    self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake([self searchBarHeight], insets.left, keyboardHeight, insets.right);
    self.tableView.contentInset = UIEdgeInsetsMake(self.topLayoutGuide.length, insets.left, keyboardHeight, insets.right);
}

- (void)keyboardWillHide:(NSNotification*)notification
{
    CGFloat tabBarHeight = self.tabBarController.tabBar.bounds.size.height;

    UIEdgeInsets insets = self.tableView.contentInset;

    self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake([self searchBarHeight], insets.left, tabBarHeight, insets.right);
    self.tableView.contentInset = UIEdgeInsetsMake(self.topLayoutGuide.length, insets.left, tabBarHeight, insets.right);
}

-(CGRect)localKeyboardFrameFromNotification:(NSNotification *)notification
{
    CGRect keyboardFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    keyboardFrame = [self.view.window convertRect:keyboardFrame fromWindow:nil];
    keyboardFrame = [self.view convertRect:keyboardFrame fromView:nil];
    return keyboardFrame;
}

- (void)wordPressComApiDidLogin:(NSNotification *)notification
{
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)wordPressComApiDidLogout:(NSNotification *)notification
{
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)wordPressComAccountChanged:(NSNotification *)notification
{
    [self setEditing:NO];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.resultsController.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id<NSFetchedResultsSectionInfo> sectionInfo;
    NSInteger numberOfRows = 0;
    if ([self.resultsController sections].count > section) {
        sectionInfo = [[self.resultsController sections] objectAtIndex:section];
        numberOfRows = sectionInfo.numberOfObjects;
    }

    return numberOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:BlogCellIdentifier];
    [self configureCell:cell atIndexPath:indexPath];

    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NSLocalizedString(@"Remove", @"Button label when removing a blog");
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleNone;
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    [self configureBlogCell:(WPBlogTableViewCell *)cell atIndexPath:indexPath];
    [WPStyleGuide configureTableViewBlogCell:cell];
}

- (void)configureBlogCell:(WPBlogTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    Blog *blog = [self.resultsController objectAtIndexPath:indexPath];
    NSString *name = blog.settings.name;

    if (name.length != 0) {
        cell.textLabel.text = name;
        cell.detailTextLabel.text = [blog displayURL];
    } else {
        cell.textLabel.text = [blog displayURL];
        cell.detailTextLabel.text = @"";
    }
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.selectionStyle = self.tableView.isEditing ? UITableViewCellSelectionStyleNone : UITableViewCellSelectionStyleBlue;
    cell.imageView.layer.borderColor = [UIColor whiteColor].CGColor;
    cell.imageView.layer.borderWidth = 1.5;
    [cell.imageView setImageWithSiteIcon:blog.icon];
    
    cell.visibilitySwitch.accessibilityIdentifier = [NSString stringWithFormat:@"Switch-Visibility-%@", name];
    cell.visibilitySwitch.on = blog.visible;
    
    __weak __typeof(self) weakSelf = self;
    cell.visibilitySwitchToggled = ^(WPBlogTableViewCell *cell) {
        [weakSelf setVisible:cell.visibilitySwitch.on forBlogAtIndexPath:indexPath];
    };

    // Make textLabel light gray if blog is not-visible
    if (!blog.visible) {
        [cell.textLabel setTextColor:[WPStyleGuide readGrey]];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return (self.tableView.isEditing) ? CGFLOAT_MIN : UITableViewAutomaticDimension;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (self.tableView.isEditing) {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        UISwitch *visibleSwitch = (UISwitch *)cell.accessoryView;
        if (visibleSwitch && [visibleSwitch isKindOfClass:[UISwitch class]]) {
            visibleSwitch.on = !visibleSwitch.on;
            [self setVisible:visibleSwitch.on forBlogAtIndexPath:indexPath];
        }
        return;
    } else {
        NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
        BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:context];
        Blog *blog = [self.resultsController objectAtIndexPath:indexPath];
        blog.visible = YES;
        [blogService flagBlogAsLastUsed:blog];

        BlogDetailsViewController *blogDetailsViewController = [[BlogDetailsViewController alloc] init];
        blogDetailsViewController.blog = blog;
        [self.navigationController pushViewController:blogDetailsViewController animated:YES];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return BLVCSiteRowHeight;
}

# pragma mark - UISearchController delegate methods

- (void)willDismissSearchController:(UISearchController *)searchController
{
    self.searchController.searchBar.text = nil;
}

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    [self updateFetchRequest];
}

# pragma mark - Navigation Bar

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    [self.tableView setEditing:editing animated:animated];
    [self toggleRightBarButtonItems:!editing];

    if (editing) {
        [self.addSiteAlertController dismissViewControllerAnimated:YES completion:nil];
        [self updateHeaderSize];
        self.tableView.tableHeaderView = self.headerView;

        self.firstHide = nil;
        self.hideCount = 0;
    }
    else {
        self.tableView.tableHeaderView = self.searchController.searchBar;
    }

    // Animate view to editing mode
    __block UIView *snapshot;
    if (animated) {
        snapshot = [self.view snapshotViewAfterScreenUpdates:NO];
        snapshot.frame = [self.view convertRect:self.view.frame fromView:self.view.superview];
        [self.view addSubview:snapshot];
    }

    // Update results controller to show hidden blogs
    [self updateFetchRequest];

    if (animated) {
        [UIView animateWithDuration:0.2 animations:^{
            snapshot.alpha = 0.0;
        } completion:^(BOOL finished) {
            [snapshot removeFromSuperview];
            snapshot = nil;
        }];
    }
}

- (void)toggleRightBarButtonItems:(BOOL)enabled
{
    for (UIBarButtonItem *buttonItem in self.navigationItem.rightBarButtonItems) {
        buttonItem.enabled = enabled;
    }
}

- (void)addSite
{
    UIAlertController *addSiteAlertController = [UIAlertController alertControllerWithTitle:nil
                                                                                    message:nil
                                                                             preferredStyle:UIAlertControllerStyleActionSheet];
    if ([self defaultWordPressComAccount]) {
        UIAlertAction *addNewWordPressAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Create WordPress.com site", @"Create WordPress.com site button")
                                                                        style:UIAlertActionStyleDefault
                                                                      handler:^(UIAlertAction *action) {
                                                                          [self showAddNewWordPressController];
                                                                      }];
        [addSiteAlertController addAction:addNewWordPressAction];
    }

    UIAlertAction *addSiteAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Add self-hosted site", @"Add self-hosted site button")
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction *action) {
                                                              [self showLoginControllerForAddingSelfHostedSite];
                                                          }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel button")
                                                     style:UIAlertActionStyleCancel
                                                   handler:nil];

    [addSiteAlertController addAction:addSiteAction];
    [addSiteAlertController addAction:cancel];
    addSiteAlertController.popoverPresentationController.barButtonItem = self.addSiteButton;
    
    [self presentViewController:addSiteAlertController animated:YES completion:nil];
    self.addSiteAlertController = addSiteAlertController;
}

- (WPAccount *)defaultWordPressComAccount
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
    return [accountService defaultWordPressComAccount];
}

- (void)showAddNewWordPressController
{
    [self setEditing:NO animated:NO];
    CreateNewBlogViewController *createNewBlogViewController = [[CreateNewBlogViewController alloc] init];
    [self.navigationController presentViewController:createNewBlogViewController animated:YES completion:nil];
}

- (void)showLoginControllerForAddingSelfHostedSite
{
    [self setEditing:NO animated:NO];
    [SigninHelpers showSigninForSelfHostedSite:self];
}

- (void)setVisible:(BOOL)visible forBlogAtIndexPath:(NSIndexPath *)indexPath
{
    Blog *blog = [self.resultsController objectAtIndexPath:indexPath];
    if(!visible && [self.tableView numberOfRowsInSection:indexPath.section] > HideAllMinSites) {
        if (self.hideCount == 0) {
            self.firstHide = [NSDate date];
        }
        self.hideCount += 1;

        if (self.hideCount >= HideAllSitesThreshold && (self.firstHide.timeIntervalSinceNow * -1) < HideAllSitesInterval) {
            
            NSString *message = NSLocalizedString(@"Would you like to hide all WordPress.com Sites?",
                                                  @"Message offering to hide all WPCom Sites");

            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Hide All Sites", @"Hide All Sites")
                                                                                     message:message
                                                                              preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel")
                                                                   style:UIAlertActionStyleCancel
                                                                 handler:^(UIAlertAction *action){}];
            
            UIAlertAction *hideAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Hide All", @"Hide All")
                                                                   style:UIAlertActionStyleDestructive
                                                                 handler:^(UIAlertAction *action){
                                                                     NSManagedObjectContext *context = [[ContextManager sharedInstance] newDerivedContext];
                                                                     [context performBlock:^{
                                                                         BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:context];
                                                                         NSArray *blogs = [blogService blogsWithPredicate:[self fetchRequestPredicateForHideableBlogs]];
                                                                         
                                                                         if(blogs == nil) {
                                                                             return;
                                                                         }
                                                                         
                                                                         AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
                                                                         [accountService setVisibility:visible forBlogs:blogs];
                                                                         [[ContextManager sharedInstance] saveDerivedContext:context];
                                                                     }];
                                                                 }];
            [alertController addAction:cancelAction];
            [alertController addAction:hideAction];
            [self presentViewController:alertController animated:YES completion:nil];
        }
    }
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:[[ContextManager sharedInstance] mainContext]];
    [accountService setVisibility:visible forBlogs:@[blog]];
}


#pragma mark - NSFetchedResultsController

- (NSFetchedResultsController *)resultsController
{
    if (_resultsController) {
        return _resultsController;
    }

    // Notes:
    // ======
    //
    //  -   We're grouping "Primary Sites" at the top of the list, by means of the sectionNameKeyPath property.
    //
    //  -   NSFetchedResultsController *requires and enforces* sectionNameKeypath never to be nil.
    //      Otherwise, unpredictable behavior arises. This property *may* be calculated (YAY!)
    //
    //  -   NSFetchRequest's NSSortDescriptor(s) are required to hit actual Core Data properties, and cannot
    //      be calculated. For that reason, we can't hit the same getter as above.
    //
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:self.entityName];
    
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:self.defaultBlogAccountIdKeyPath
                                                                   ascending:NO
                                                                    selector:@selector(compare:)],
                                     
                                     [NSSortDescriptor sortDescriptorWithKey:self.siteNameKeyPath
                                                                   ascending:YES
                                                                    selector:@selector(localizedCaseInsensitiveCompare:)]];
    fetchRequest.predicate = [self fetchRequestPredicate];

    _resultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                             managedObjectContext:context
                                                               sectionNameKeyPath:self.sectionNameKeyPath
                                                                        cacheName:nil];
    _resultsController.delegate = self;

    NSError *error = nil;
    if (![_resultsController performFetch:&error]) {
        DDLogError(@"Couldn't fetch sites: %@", [error localizedDescription]);
        _resultsController = nil;
    }
    
    return _resultsController;
}

- (NSString *)entityName
{
    return NSStringFromClass([Blog class]);
}

- (NSString *)sectionNameKeyPath
{
    return @"sectionIdentifier";
}

- (NSString *)defaultBlogAccountIdKeyPath
{
    return @"accountForDefaultBlog.userID";
}

- (NSString *)siteNameKeyPath
{
    return @"settings.name";
}

- (NSPredicate *)fetchRequestPredicate
{
    if ([self.tableView isEditing]) {
        return [self fetchRequestPredicateForHideableBlogs];
    } else if ([self.searchController isActive]) {
        return [self fetchRequestPredicateForSearch];
    }

    return [self fetchRequestPredicateForVisibleBlogs];
}

- (NSPredicate *)fetchRequestPredicateForSearch
{
    NSString *searchText = self.searchController.searchBar.text;
    if ([searchText isEmpty]) {
         // Don't filter – show all sites
        return [self fetchRequestPredicateForAllBlogs];
    }
    
    return [NSPredicate predicateWithFormat:@"( settings.name contains[cd] %@ ) OR ( url contains[cd] %@)", searchText, searchText];
}

- (NSPredicate *)fetchRequestPredicateForHideableBlogs
{
    /*
     -[Blog supports:BlogFeatureVisibility] should match this, but the logic needs
     to be duplicated because core data can't take block predicates.
     */
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
    WPAccount *defaultAccount = [accountService defaultWordPressComAccount];

    return [NSPredicate predicateWithFormat:@"account != NULL AND account = %@", defaultAccount];
}

- (NSPredicate *)fetchRequestPredicateForVisibleBlogs
{
    return [NSPredicate predicateWithFormat:@"visible = YES"];
}

- (NSPredicate *)fetchRequestPredicateForAllBlogs
{
    return [NSPredicate predicateWithValue:YES];
}

- (void)updateFetchRequest
{
    self.resultsController.fetchRequest.predicate = [self fetchRequestPredicate];

    NSError *error = nil;
    if (![self.resultsController performFetch:&error]) {
        DDLogError(@"Couldn't fetch sites: %@", [error localizedDescription]);
    }

    [self.tableView reloadData];
}


#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView reloadData];
    [self updateEditButton];
    [self maybeShowNUX];
}

@end
