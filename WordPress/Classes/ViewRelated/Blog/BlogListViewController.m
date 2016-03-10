#import "BlogListViewController.h"
#import "WordPressAppDelegate.h"
#import "UIImageView+Gravatar.h"
#import "WordPressComApi.h"
#import "LoginViewController.h"
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
#import "WPSearchControllerConfigurator.h"
#import "WPGUIConstants.h"
#import "CreateNewBlogViewController.h"
#import "WordPress-Swift.h"

static NSString *const BlogCellIdentifier = @"BlogCell";
static CGFloat const BLVCHeaderViewLabelPadding = 10.0;
static CGFloat const BLVCSiteRowHeight = 74.0;

static NSInteger HideAllMinSites = 10;
static NSInteger HideAllSitesThreshold = 6;
static NSTimeInterval HideAllSitesInterval = 2.0;

@interface BlogListViewController () <UIViewControllerRestoration>

@property (nonatomic, strong) NSFetchedResultsController *resultsController;
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UILabel *headerLabel;
@property (nonatomic, strong) WPSearchController *searchController;
@property (nonatomic, strong) IBOutlet UIView *searchWrapperView;
@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *searchWrapperViewHeightConstraint;
@property (nonatomic, weak) UIAlertController *addSiteAlertController;
@property (nonatomic, strong) UIBarButtonItem *addSiteButton;
@property (nonatomic, strong) UIBarButtonItem *searchButton;

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
    
    self.searchButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon-post-search"]
                                                         style:UIBarButtonItemStylePlain
                                                        target:self
                                                        action:@selector(toggleSearch)];

    [self updateSearchButton];

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

    // Remove one-pixel gap resulting from a top-aligned grouped table view
    if (IS_IPHONE) {
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
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    self.resultsController.delegate = self;
    [self.resultsController performFetch:nil];
    [self.tableView reloadData];
    [self updateEditButton];
    [self updateSearchButton];
    [self maybeShowNUX];
    [self syncBlogs];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.searchController setActive:NO];
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
        
        if (![UIDevice isPad] && (self.searchWrapperViewHeightConstraint.constant > 0)) {
            self.searchWrapperViewHeightConstraint.constant = [self heightForSearchWrapperView];
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

- (void)updateSearchButton
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:context];
    if ([blogService blogCountForAllAccounts] <= 1) {
        // Hide the search button if there's only one blog
        self.navigationItem.rightBarButtonItems = @[ self.addSiteButton ];
    } else {
        self.navigationItem.rightBarButtonItems = @[ self.addSiteButton, self.searchButton ];
    }
}

- (void)maybeShowNUX
{
    if ([self numSites] > 0) {
        return;
    }
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
    WPAccount *defaultAccount = [accountService defaultWordPressComAccount];
    if (!defaultAccount) {
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
}

- (void)configureSearchController
{
    self.searchController = [[WPSearchController alloc] initWithSearchResultsController:nil];
    
    WPSearchControllerConfigurator *searchControllerConfigurator = [[WPSearchControllerConfigurator alloc] initWithSearchController:self.searchController
                                                                                                    withSearchWrapperView:self.searchWrapperView];
    [searchControllerConfigurator configureSearchControllerAndWrapperView];
    [self configureSearchBarPlaceholder];
    self.searchController.delegate = self;
    self.searchController.searchResultsUpdater = self;
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

- (CGFloat)heightForSearchWrapperView
{
    UINavigationBar *navBar = self.navigationController.navigationBar;
    CGFloat height = CGRectGetHeight(navBar.frame) + [UIApplication sharedApplication].statusBarFrame.size.height;
    return MAX(height, SearchWrapperViewMinHeight);
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
                                             selector:@selector(keyboardDidShow:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)unregisterForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardDidShow:(NSNotification *)notification
{
    NSDictionary *info = notification.userInfo;
    CGFloat keyboardHeight = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height;
    CGFloat tabBarHeight = self.tabBarController.tabBar.bounds.size.height;
    
    UIEdgeInsets newInsets = UIEdgeInsetsMake(0.0, 0.0, keyboardHeight - tabBarHeight, 0.0);
    self.tableView.contentInset = newInsets;
    self.tableView.scrollIndicatorInsets = newInsets;
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    self.tableView.contentInset = UIEdgeInsetsZero;
    self.tableView.scrollIndicatorInsets = UIEdgeInsetsZero;
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
    return 1;
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
    cell.visibilitySwitch.on = blog.visible;
    cell.visibilitySwitch.tag = indexPath.row;
    [cell.visibilitySwitch addTarget:self action:@selector(visibilitySwitchAction:) forControlEvents:UIControlEventValueChanged];
    cell.visibilitySwitch.accessibilityIdentifier = [NSString stringWithFormat:@"Switch-Visibility-%@", name];

    // Make textLabel light gray if blog is not-visible
    if (!blog.visible) {
        [cell.textLabel setTextColor:[WPStyleGuide readGrey]];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return nil;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    // since we show a tableHeaderView while editing, we want to keep the section header short for iPad during edit
    return (IS_IPHONE || self.tableView.isEditing) ? CGFLOAT_MIN : WPTableHeaderPadFrame.size.height;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    // Use the standard dimension on the last section
    return section == [tableView numberOfSections] - 1 ? UITableViewAutomaticDimension : 0.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (self.tableView.isEditing) {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        UISwitch *visibleSwitch = (UISwitch *)cell.accessoryView;
        if (visibleSwitch && [visibleSwitch isKindOfClass:[UISwitch class]]) {
            visibleSwitch.on = !visibleSwitch.on;
            [self visibilitySwitchAction:visibleSwitch];
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

# pragma mark - WPSeachController delegate methods

- (void)presentSearchController:(WPSearchController *)searchController
{
    [self.navigationController setNavigationBarHidden:YES animated:YES]; // Remove this line when switching to UISearchController.
    self.searchWrapperViewHeightConstraint.constant = [self heightForSearchWrapperView];
    [UIView animateWithDuration:SearchBarAnimationDuration
                          delay:0.0
                        options:0
                     animations:^{
                         [self.view layoutIfNeeded];
                     } completion:^(BOOL finished) {
                         [self.searchController.searchBar becomeFirstResponder];
                     }];
}

- (void)willDismissSearchController:(WPSearchController *)searchController
{
    [self.searchController.searchBar resignFirstResponder];
    [self.navigationController setNavigationBarHidden:NO animated:YES]; // Remove this line when switching to UISearchController.
    self.searchWrapperViewHeightConstraint.constant = 0;
    [UIView animateWithDuration:SearchBarAnimationDuration animations:^{
        [self.view layoutIfNeeded];
    }];
    
    self.searchController.searchBar.text = nil;
}

- (void)updateSearchResultsForSearchController:(WPSearchController *)searchController
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
        // setting the table header view to nil creates extra space, empty view is a way around that
        self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, CGFLOAT_MIN)];
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

- (void)toggleSearch
{
    [self.addSiteAlertController dismissViewControllerAnimated:YES completion:nil];
    self.searchController.active = !self.searchController.active;
}

- (void)addSite
{
    UIAlertController *addSiteAlertController = [UIAlertController alertControllerWithTitle:nil
                                                                                    message:nil
                                                                             preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *addNewWordPressAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Create WordPress.com site", @"Create WordPress.com site button")
                                                                    style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction *action) {
                                                                      [self showAddNewWordPressController];
                                                                  }];
    UIAlertAction *addSiteAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Add self-hosted site", @"Add self-hosted site button")
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction *action) {
                                                              [self showLoginControllerForAddingSelfHostedSite];
                                                          }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel button")
                                                     style:UIAlertActionStyleCancel
                                                   handler:nil];
    [addSiteAlertController addAction:addNewWordPressAction];
    [addSiteAlertController addAction:addSiteAction];
    [addSiteAlertController addAction:cancel];
    addSiteAlertController.popoverPresentationController.barButtonItem = self.addSiteButton;
    
    [self presentViewController:addSiteAlertController animated:YES completion:nil];
    self.addSiteAlertController = addSiteAlertController;
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
    LoginViewController *loginViewController = [[LoginViewController alloc] init];
    loginViewController.cancellable = YES;
    
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
    WPAccount *defaultAccount = [accountService defaultWordPressComAccount];
    
    if (!defaultAccount) {
        loginViewController.prefersSelfHosted = YES;
    }
    loginViewController.dismissBlock = ^(BOOL cancelled){
        [self dismissViewControllerAnimated:YES completion:nil];
    };
    UINavigationController *loginNavigationController = [[UINavigationController alloc] initWithRootViewController:loginViewController];
    [self presentViewController:loginNavigationController animated:YES completion:nil];
}

- (void)visibilitySwitchAction:(id)sender
{
    UISwitch *switcher = (UISwitch *)sender;
    Blog *blog = [self.resultsController objectAtIndexPath:[NSIndexPath indexPathForRow:switcher.tag inSection:0]];
    if(!switcher.on && [self.tableView numberOfRowsInSection:0] > HideAllMinSites) {
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
                                                                         [accountService setVisibility:switcher.on forBlogs:blogs];
                                                                         [[ContextManager sharedInstance] saveDerivedContext:context];
                                                                     }];
                                                                 }];
            [alertController addAction:cancelAction];
            [alertController addAction:hideAction];
            [self presentViewController:alertController animated:YES completion:nil];
        }
    }
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:[[ContextManager sharedInstance] mainContext]];
    [accountService setVisibility:switcher.on forBlogs:@[blog]];
}

#pragma mark - NSFetchedResultsController

- (NSFetchedResultsController *)resultsController
{
    if (_resultsController) {
        return _resultsController;
    }

    NSManagedObjectContext *moc = [[ContextManager sharedInstance] mainContext];
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Blog"];
    [fetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"settings.name" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)]]];
    [fetchRequest setPredicate:[self fetchRequestPredicate]];

    _resultsController = [[NSFetchedResultsController alloc]
                          initWithFetchRequest:fetchRequest
                          managedObjectContext:moc
                          sectionNameKeyPath:nil
                          cacheName:nil];
    _resultsController.delegate = self;

    NSError *error = nil;
    if (![_resultsController performFetch:&error]) {
        DDLogError(@"Couldn't fetch sites: %@", [error localizedDescription]);
        _resultsController = nil;
    }
    
    return _resultsController;
}

- (NSPredicate *)fetchRequestPredicate
{
    if ([self.tableView isEditing]) {
        return [self fetchRequestPredicateForHideableBlogs];
    } else if ([self.searchController isActive]) {
        return [self fetchRequestPredicateForSearch];
    }

    return [NSPredicate predicateWithFormat:@"visible = YES"];
}

- (NSPredicate *)fetchRequestPredicateForSearch
{
    NSString *searchText = self.searchController.searchBar.text;
    if ([searchText isEmpty]) {
        return [self fetchRequestPredicateForHideableBlogs];
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

- (void)updateFetchRequest
{
    self.resultsController.fetchRequest.predicate = [self fetchRequestPredicate];

    NSError *error = nil;
    if (![self.resultsController performFetch:&error]) {
        DDLogError(@"Couldn't fetch sites: %@", [error localizedDescription]);
    }

    [self.tableView reloadData];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView reloadData];
    [self updateEditButton];
    [self maybeShowNUX];
}

@end
