#import "BlogSelectorViewController.h"
#import "BlogDetailsViewController.h"
#import "WPBlogTableViewCell.h"
#import "ContextManager.h"
#import "Blog.h"
#import "WPAccount.h"
#import "AccountService.h"
#import "WordPress-Swift.h"

@interface BlogSelectorViewController () <UISearchControllerDelegate, UISearchResultsUpdating>

@property (nonatomic, strong) NSNumber                      *selectedObjectDotcomID;
@property (nonatomic, strong) NSManagedObjectID             *selectedObjectID;
@property (nonatomic,   copy) BlogSelectorDismissHandler    dismissHandler;
@property (nonatomic, strong) UISearchController            *searchController;
@property (nonatomic, strong) BlogListDataSource            *dataSource;

@property (nonatomic) BOOL visible;
@end

@implementation BlogSelectorViewController

- (instancetype)initWithSelectedBlogObjectID:(NSManagedObjectID *)objectID
                              successHandler:(BlogSelectorSuccessHandler)successHandler
                              dismissHandler:(BlogSelectorDismissHandler)dismissHandler
{
    self = [super initWithStyle:UITableViewStylePlain];

    if (self) {
        _selectedObjectID = objectID;
        _successHandler = successHandler;
        _dismissHandler = dismissHandler;
        _displaysCancelButton = YES;
        _displaysNavigationBarWhenSearching = YES;
        [self configureDataSource];
    }

    return self;
}

- (instancetype)initWithSelectedBlogDotComID:(nullable NSNumber *)dotComID
                              successHandler:(BlogSelectorSuccessDotComHandler)successHandler
                              dismissHandler:(BlogSelectorDismissHandler)dismissHandler
{
    // Keep the Selected Dotcom ID
    _selectedObjectDotcomID = dotComID;
    
    // Wrap up the main callback into something useful to us
    BlogSelectorSuccessHandler wrappedSuccessHandler = ^(NSManagedObjectID *selectedObjectID) {
        NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
        Blog *blog = [context existingObjectWithID:selectedObjectID error:nil];
        successHandler(blog.dotComID);
    };
    
    return [self initWithSelectedBlogObjectID:nil
                               successHandler:wrappedSuccessHandler
                               dismissHandler:dismissHandler];
}

- (void)configureDataSource
{
    self.dataSource = [BlogListDataSource new];
    self.dataSource.selecting = YES;
    self.dataSource.selectedBlogId = self.selectedObjectID;
    __weak __typeof(self) weakSelf = self;
    self.dataSource.dataChanged = ^{
        if (weakSelf.visible) {
            [weakSelf dataChanged];
        }
    };
}

- (BOOL)displaysOnlyDefaultAccountSites {
    return (self.dataSource.account != nil);
}

- (void)setDisplaysOnlyDefaultAccountSites:(BOOL)onlyDefault
{
    if (onlyDefault) {
        NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
        AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
        WPAccount *defaultAccount = [accountService defaultWordPressComAccount];
        self.dataSource.account = defaultAccount;
    } else {
        self.dataSource.account = nil;
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Listen to Account Changes
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(wordPressComAccountChanged:)
                                                 name:WPAccountDefaultWordPressComAccountChangedNotification
                                               object:nil];

    // Cancel button
    if (self.displaysCancelButton) {
        UIBarButtonItem *cancelButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                          target:self
                                                                                          action:@selector(cancelButtonTapped:)];

        self.navigationItem.leftBarButtonItem = cancelButtonItem;
    }
    
    // TableView
    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
    
    [self.tableView registerClass:[WPBlogTableViewCell class] forCellReuseIdentifier:[WPBlogTableViewCell reuseIdentifier]];
    self.tableView.dataSource = self.dataSource;
    [self.tableView reloadData];

    self.tableView.tableFooterView = [UIView new];

    [self configureSearchController];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self.navigationController setNavigationBarHidden:NO animated:animated];

    [self registerForKeyboardNotifications];
    [self.tableView reloadData];
    [self syncBlogs];
    [self scrollToSelectedObjectID];
    self.title = NSLocalizedString(@"Select Site", comment: @"Blog Picker's Title");
    self.visible = YES;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [self unregisterForKeyboardNotifications];

    self.visible = NO;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    // Note:
    // We're toggling the SearchController as inactive, since, on iPad devices, upon rotation, an
    // active UISearchBar might break violently when Adaptivity kicks in.
    //
    self.searchController.active = NO;
}

- (void)configureSearchController
{
    self.extendedLayoutIncludesOpaqueBars = YES;
    self.definesPresentationContext = YES;

    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.obscuresBackgroundDuringPresentation = NO;
    self.searchController.hidesNavigationBarDuringPresentation = !_displaysNavigationBarWhenSearching;
    self.searchController.delegate = self;
    self.searchController.searchResultsUpdater = self;

    [WPStyleGuide configureSearchBar:self.searchController.searchBar];

    [self addSearchBarTableHeaderView];
}

- (void)addSearchBarTableHeaderView
{
    if (!self.tableView.tableHeaderView) {
        // Required to work around a bug where the search bar was extending a
        // grey background above the top of the tableview, which was visible when
        // pulling down further than offset zero
        SearchWrapperView *wrapperView = [SearchWrapperView new];
        [wrapperView addSubview:self.searchController.searchBar];
        wrapperView.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.searchController.searchBar.bounds.size.height);
        self.tableView.tableHeaderView = wrapperView;
    }
}

#pragma mark - Notifications

- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidShow:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidHide:)
                                                 name:UIKeyboardDidHideNotification
                                               object:nil];
}

- (void)unregisterForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidHideNotification object:nil];
}

- (CGFloat)searchBarHeight {
    return CGRectGetHeight(self.searchController.searchBar.bounds) + self.view.safeAreaInsets.top;
}

- (void)keyboardDidShow:(NSNotification *)notification
{
    CGRect keyboardFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat keyboardHeight = MAX(CGRectGetMaxY(self.tableView.frame) - keyboardFrame.origin.y, 0);

    UIEdgeInsets insets = self.tableView.contentInset;

    self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake([self searchBarHeight], insets.left, keyboardHeight, insets.right);
    self.tableView.contentInset = UIEdgeInsetsMake(self.view.safeAreaInsets.top, insets.left, keyboardHeight, insets.right);
}

- (void)keyboardDidHide:(NSNotification*)notification
{
    CGFloat tabBarHeight = self.tabBarController.tabBar.bounds.size.height;
    UIEdgeInsets insets = self.tableView.contentInset;
    insets.top = self.view.safeAreaInsets.top;
    insets.bottom = tabBarHeight;

    self.tableView.contentInset = insets;

    if (self.searchController.active) {
        insets.top = [self searchBarHeight];
    }

    self.tableView.scrollIndicatorInsets = insets;
}

#pragma mark - Helpers

- (void)syncBlogs
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] newDerivedContext];
    
    [context performBlock:^{
        AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
        BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:context];
        WPAccount *defaultAccount = [accountService defaultWordPressComAccount];
        
        if (!defaultAccount) {
            return;
        }
        
        [blogService syncBlogsForAccount:defaultAccount success:nil failure:nil];
    }];
}

- (void)scrollToSelectedObjectID
{
    if (self.selectedObjectID == nil) {
        return;
    }

    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    Blog *blog = (Blog *)[context objectWithID:self.selectedObjectID];
    NSIndexPath *indexPath = [self.dataSource indexPathForBlog:blog];
    [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
}

- (NSManagedObjectID *)selectedObjectID
{
    if (_selectedObjectID != nil || _selectedObjectDotcomID == nil) {
        return _selectedObjectID;
    }
    
    // Retrieve
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    Blog *selectedBlog = [Blog lookupWithID:self.selectedObjectDotcomID in:context];
    
    // Cache
    _selectedObjectID = selectedBlog.objectID;
    
    return _selectedObjectID;
}


#pragma mark - Notifications

- (void)wordPressComAccountChanged:(NSNotification *)note
{
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
}


#pragma mark - Data Listener

- (void)dataChanged
{
    [self.tableView reloadData];
}


#pragma mark - Actions

- (IBAction)cancelButtonTapped:(id)sender
{
    if (self.dismissHandler) {
        self.dismissHandler();
    }
    
    if (self.dismissOnCancellation) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - UITableView Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    Blog *selectedBlog = [self.dataSource blogAtIndexPath:indexPath];
    if (selectedBlog.objectID == self.selectedObjectID) {
        // User tapped the already selected item. Treat this as a cancel event
        // so the picker can be dismissed without changes.
        [self cancelButtonTapped:nil];
        return;
    }
    self.selectedObjectID = selectedBlog.objectID;
    self.dataSource.selectedBlogId = selectedBlog.objectID;

    // Fire off the selection after a short delay to let animations complete for selection/deselection
    if (self.successHandler) {
        double delayInSeconds = 0.2;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            self.successHandler(self.selectedObjectID);
            
            if (self.dismissOnCompletion) {
                [self dismissViewControllerAnimated:YES completion:nil];
            }
        });
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [WPBlogTableViewCell cellHeight];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    // If we have more than one section, show a 2px separator unless the section has a title.
    NSString *sectionTitle = nil;
    if ([tableView.dataSource respondsToSelector:@selector(tableView:titleForHeaderInSection:)]) {
        sectionTitle = [tableView.dataSource tableView:tableView titleForHeaderInSection:section];
    }
    if (section > 0 && [sectionTitle length] == 0) {
        return 2;
    }
    return UITableViewAutomaticDimension;
}

#pragma mark - UISearchController

- (void)willPresentSearchController:(UISearchController *)searchController
{
    self.dataSource.searching = YES;
}

- (void)willDismissSearchController:(UISearchController *)searchController
{
    self.dataSource.searching = NO;
}

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    self.dataSource.searchQuery = searchController.searchBar.text;
}

// Improves the appearance of the arrow when displayed in a popover, by matching
// its color to the topmost view in the scrollview
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (!self.popoverPresentationController) { return; }

    if (self.searchController.active) {
        self.popoverPresentationController.backgroundColor = self.searchController.searchBar.barTintColor;
        return;
    }

    UIColor *arrowColor;

    if (scrollView.contentOffset.y < self.tableView.tableHeaderView.frame.origin.y) {
        // Above the header view (search bar)
        arrowColor = self.tableView.backgroundColor;
    } else if (scrollView.contentOffset.y < self.searchController.searchBar.bounds.size.height) {
        // Within the search bar
        arrowColor = self.searchController.searchBar.barTintColor;
    } else {
        // Within the table content itself (cells have white backgrounds)
        arrowColor = [UIColor whiteColor];
    }

    if (arrowColor != self.popoverPresentationController.backgroundColor) {
        [UIView animateWithDuration:0.2 animations:^{
            self.popoverPresentationController.backgroundColor = arrowColor;
        }];
    }
}

@end
