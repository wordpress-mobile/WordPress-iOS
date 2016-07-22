#import "BlogSelectorViewController.h"
#import "UIImageView+Gravatar.h"
#import "BlogDetailsViewController.h"
#import "WPBlogTableViewCell.h"
#import "ContextManager.h"
#import "Blog.h"
#import "WPAccount.h"
#import "AccountService.h"
#import "WordPress-Swift.h"

static NSString *const BlogCellIdentifier = @"BlogCell";
static CGFloat BlogCellRowHeight = 74.0;

@interface BlogSelectorViewController () <NSFetchedResultsControllerDelegate, UISearchControllerDelegate, UISearchResultsUpdating>

@property (nonatomic, strong) NSFetchedResultsController    *resultsController;
@property (nonatomic, strong) NSNumber                      *selectedObjectDotcomID;
@property (nonatomic, strong) NSManagedObjectID             *selectedObjectID;
@property (nonatomic,   copy) BlogSelectorSuccessHandler    successHandler;
@property (nonatomic,   copy) BlogSelectorDismissHandler    dismissHandler;
@property (nonatomic, strong) UISearchController            *searchController;

@end

@implementation BlogSelectorViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

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
    }

    return self;
}

- (instancetype)initWithSelectedBlogDotComID:(NSNumber *)dotComID
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
    
    // NSFetchedResultsController
    self.resultsController.delegate = self;
    [self.resultsController performFetch:nil];
    
    // TableView
    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
    
    [self.tableView registerClass:[WPBlogTableViewCell class] forCellReuseIdentifier:BlogCellIdentifier];
    [self.tableView reloadData];

    self.tableView.tableFooterView = [UIView new];

    [self configureSearchController];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self.navigationController setNavigationBarHidden:NO animated:animated];

    [self registerForKeyboardNotifications];
    [self syncBlogs];
    [self scrollToSelectedObjectID];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [self unregisterForKeyboardNotifications];

    self.resultsController.delegate = nil;
}

- (void)configureSearchController
{
    self.extendedLayoutIncludesOpaqueBars = YES;
    self.definesPresentationContext = YES;

    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.dimsBackgroundDuringPresentation = NO;

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
    return CGRectGetHeight(self.searchController.searchBar.bounds) + self.topLayoutGuide.length;
}

- (void)keyboardDidShow:(NSNotification *)notification
{
    CGRect keyboardFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat keyboardHeight = MAX(CGRectGetMaxY(self.tableView.frame) - keyboardFrame.origin.y, 0);

    UIEdgeInsets insets = self.tableView.contentInset;

    self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake([self searchBarHeight], insets.left, keyboardHeight, insets.right);
    self.tableView.contentInset = UIEdgeInsetsMake(self.topLayoutGuide.length, insets.left, keyboardHeight, insets.right);
}

- (void)keyboardDidHide:(NSNotification*)notification
{
    CGFloat tabBarHeight = self.tabBarController.tabBar.bounds.size.height;
    UIEdgeInsets insets = self.tableView.contentInset;
    insets.top = self.topLayoutGuide.length;
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
    
    NSManagedObject *obj = [self.resultsController.managedObjectContext objectWithID:self.selectedObjectID];
    NSIndexPath *indexPath = [self.resultsController indexPathForObject:obj];
    [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
}

- (NSManagedObjectID *)selectedObjectID
{
    if (_selectedObjectID != nil || _selectedObjectDotcomID == nil) {
        return _selectedObjectID;
    }
    
    // Retrieve
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    BlogService *service = [[BlogService alloc] initWithManagedObjectContext:context];
    Blog *selectedBlog = [service blogByBlogId:self.selectedObjectDotcomID];
    
    // Cache
    _selectedObjectID = selectedBlog.objectID;
    
    return _selectedObjectID;
}


#pragma mark - Notifications

- (void)wordPressComAccountChanged:(NSNotification *)note
{
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
}


#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
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


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.resultsController sections].count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *sections = self.resultsController.sections;
    if (sections.count == 0) {
        return 0;
    }
    
    id <NSFetchedResultsSectionInfo> sectionInfo = sections[section];
    return sectionInfo.numberOfObjects;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:BlogCellIdentifier];

    [WPStyleGuide configureTableViewBlogCell:cell];
    [self configureCell:cell atIndexPath:indexPath];

    return cell;
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    cell.textLabel.textAlignment = NSTextAlignmentLeft;
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.accessoryView = nil;

    Blog *blog = [self.resultsController objectAtIndexPath:indexPath];
    NSString *name = blog.settings.name;
    
    if (name.length != 0) {
        cell.textLabel.text = name;
        cell.detailTextLabel.text = blog.url;
    } else {
        cell.textLabel.text = blog.url;
    }

    [cell.imageView setImageWithSiteIcon:blog.icon];

    cell.accessoryType = blog.objectID == self.selectedObjectID ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    NSIndexPath *previousIndexPath;
    if (self.selectedObjectID) {
        for (Blog *blog in self.resultsController.fetchedObjects) {
            if (blog.objectID == self.selectedObjectID) {
                previousIndexPath = [self.resultsController indexPathForObject:blog];
                break;
            }
        }

        if (previousIndexPath && [previousIndexPath compare:indexPath] == NSOrderedSame) {
            // User tapped the already selected item. Treat this as a cancel event
            // so the picker can be dismissed without changes.
            [self cancelButtonTapped:nil];
            return;
        }
    }

    Blog *selectedBlog = [self.resultsController objectAtIndexPath:indexPath];
    self.selectedObjectID = selectedBlog.objectID;
    [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;

    if (previousIndexPath) {
        [tableView reloadRowsAtIndexPaths:@[previousIndexPath] withRowAnimation:UITableViewRowAnimationNone];
    }

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
    return BlogCellRowHeight;
}

#pragma mark - NSFetchedResultsController

- (NSFetchedResultsController *)resultsController
{
    if (_resultsController) {
        return _resultsController;
    }

    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:self.entityName];
    request.sortDescriptors = _displaysPrimaryBlogOnTop ? self.sortDescriptorsWithAccountKeyPath : self.sortDescriptors;
    request.predicate = [self fetchRequestPredicate];

    _resultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                             managedObjectContext:context
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

- (NSString *)entityName
{
    return NSStringFromClass([Blog class]);
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
    NSPredicate *predicate;

    if ([self.searchController isActive]) {
        predicate = [self fetchRequestPredicateForSearch];
    } else {
        predicate = [self fetchRequestPredicateForVisibleBlogs];
    }

    if (!self.displaysOnlyDefaultAccountSites) {
        return predicate;
    } else {
        NSPredicate *accountPredicate = [self fetchRequestPredicateForDotComBlogs];
        return [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate, accountPredicate]];
    }
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

- (NSPredicate *)fetchRequestPredicateForVisibleBlogs
{
    NSPredicate *visiblePredicate = [NSPredicate predicateWithFormat:@"visible = YES"];

    if (self.selectedObjectID) {
        NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
        NSManagedObject *currentBlog = [context existingObjectWithID:self.selectedObjectID error:nil];
        if (currentBlog) {
            NSPredicate *currentBlogPredicate = [NSPredicate predicateWithFormat:@"self = %@", currentBlog];
            visiblePredicate = [NSCompoundPredicate orPredicateWithSubpredicates:@[visiblePredicate, currentBlogPredicate]];
        }
    }

    return visiblePredicate;
}

- (NSPredicate *)fetchRequestPredicateForDotComBlogs
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
    WPAccount *defaultAccount = [accountService defaultWordPressComAccount];

    NSPredicate *accountPredicate = [NSPredicate predicateWithFormat:@"account == %@ OR jetpackAccount == %@", defaultAccount, defaultAccount];
    return accountPredicate;
}

- (NSPredicate *)fetchRequestPredicateForAllBlogs
{
    return [NSPredicate predicateWithValue:YES];
}

- (NSArray *)sortDescriptors
{
    return @[[NSSortDescriptor sortDescriptorWithKey:self.siteNameKeyPath
                                           ascending:YES
                                            selector:@selector(localizedCaseInsensitiveCompare:)]];
}

- (NSArray *)sortDescriptorsWithAccountKeyPath
{
    NSMutableArray *descriptors = [@[[NSSortDescriptor sortDescriptorWithKey:self.defaultBlogAccountIdKeyPath
                                                                   ascending:NO
                                                                    selector:@selector(compare:)]]
                                   mutableCopy];
    
    [descriptors addObjectsFromArray:self.sortDescriptors];
    return descriptors;
}

#pragma mark - UISearchController

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    self.resultsController.fetchRequest.predicate = [self fetchRequestPredicate];

    NSError *error = nil;
    if (![self.resultsController performFetch:&error]) {
        DDLogError(@"Couldn't fetch sites: %@", [error localizedDescription]);
    }

    [self.tableView reloadData];
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
