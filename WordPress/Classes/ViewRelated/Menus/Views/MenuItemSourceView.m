#import "MenuItemSourceView.h"
#import "MenuItemSourceTextBar.h"
#import "MenusDesign.h"
#import "Menu.h"
#import "MenuItemSourceLoadingView.h"
#import "Blog.h"

static NSTimeInterval const SearchBarFetchRequestUpdateDelay = 0.10;
static NSTimeInterval const SearchBarRemoteServiceUpdateDelay = 0.25;

@interface MenuItemSourceView () <MenuItemSourceTextBarDelegate>

/* View used as the tableView.tableHeaderView container view for self.stackView.
 */
@property (nonatomic, strong) UIView *stackedTableHeaderView;

@property (nonatomic, strong) MenuItemSourceLoadingView *loadingView;
@property (nonatomic, assign) BOOL observeUserScrollingForEndOfTableView;

@end

@implementation MenuItemSourceView

- (id)init
{
    self = [super init];
    if(self) {
        
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.backgroundColor = [UIColor whiteColor];
        
        {
            UITableView *tableView = [[UITableView alloc] init];
            tableView.translatesAutoresizingMaskIntoConstraints = NO;
            tableView.dataSource = self;
            tableView.delegate = self;
            tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
            UIEdgeInsets inset = tableView.contentInset;
            inset.top = MenusDesignDefaultContentSpacing / 2.0;
            tableView.contentInset = inset;
            [self addSubview:tableView];
            
            [NSLayoutConstraint activateConstraints:@[
                                                      [tableView.topAnchor constraintEqualToAnchor:self.topAnchor],
                                                      [tableView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
                                                      [tableView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
                                                      [tableView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor]
                                                      ]];
            _tableView = tableView;
        }
        {
            // setup the tableHeaderView and keep translatesAutoresizingMaskIntoConstraints to default YES
            // this allows the tableView to handle sizing the view as any other tableHeaderView
            UIView *stackedTableHeaderView = [[UIView alloc] init];
            self.stackedTableHeaderView = stackedTableHeaderView;
        }
        {
            UIStackView *stackView = [[UIStackView alloc] init];
            stackView.translatesAutoresizingMaskIntoConstraints = NO;
            stackView.distribution = UIStackViewDistributionFill;
            stackView.alignment = UIStackViewAlignmentFill;
            stackView.axis = UILayoutConstraintAxisVertical;
            stackView.spacing = MenusDesignDefaultContentSpacing / 2.0;
            
            UIEdgeInsets margins = UIEdgeInsetsZero;
            margins.bottom = stackView.spacing;
            margins.left = MenusDesignDefaultContentSpacing;
            margins.right = MenusDesignDefaultContentSpacing;
            stackView.layoutMargins = margins;
            stackView.layoutMarginsRelativeArrangement = YES;
            
            [self.stackedTableHeaderView addSubview:stackView];
            // setup the constraints for the stackView
            // constrain the horiztonal edges to sync the width to the stackedTableHeaderView
            // do not include a bottom constraint so the stackView can layout its intrinsic height
            [NSLayoutConstraint activateConstraints:@[
                                                      [stackView.topAnchor constraintEqualToAnchor:self.stackedTableHeaderView.topAnchor],
                                                      [stackView.leadingAnchor constraintEqualToAnchor:self.stackedTableHeaderView.leadingAnchor],
                                                      [stackView.trailingAnchor constraintEqualToAnchor:self.stackedTableHeaderView.trailingAnchor]
                                                      ]];
            _stackView = stackView;
        }
        {
            MenuItemSourceLoadingView *loadingView = [[MenuItemSourceLoadingView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 50.0)];
            self.tableView.tableFooterView = loadingView;
            self.loadingView = loadingView;
        }
    }
    
    return self;
}

- (BOOL)resignFirstResponder
{
    if([self.searchBar isFirstResponder]) {
        return [self.searchBar resignFirstResponder];
    }
    return [super resignFirstResponder];
}

#pragma mark - view configuration

- (void)layoutSubviews
{
    [super layoutSubviews];
        
    if(!self.tableView.tableHeaderView) {
        // set the tableHeaderView after we have called layoutSubviews the first time
        // this add the stackedTableHeaderView to view hierarchy
        self.tableView.tableHeaderView = self.stackedTableHeaderView;
        [self.stackedTableHeaderView layoutIfNeeded];
    }

    // set the stackedTableHeaderView frame height to the intrinsic height of the stackView
    CGRect frame = self.stackView.bounds;
    self.stackedTableHeaderView.frame = frame;
    // reset the tableHeaderView to update the size change
    self.tableView.tableHeaderView = self.stackedTableHeaderView;
}

- (void)refresh
{
    [self.tableView reloadData];
}

- (void)insertSearchBarIfNeeded
{
    if(self.searchBar) {
        return;
    }
    
    MenuItemSourceTextBar *searchBar = [[MenuItemSourceTextBar alloc] initAsSearchBar];
    searchBar.translatesAutoresizingMaskIntoConstraints = NO;
    searchBar.delegate = self;
    [self.stackView addArrangedSubview:searchBar];
    
    NSLayoutConstraint *heightConstraint = [searchBar.heightAnchor constraintEqualToConstant:48.0];
    heightConstraint.priority = UILayoutPriorityDefaultHigh;
    heightConstraint.active = YES;
    
    [searchBar setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisVertical];
    _searchBar = searchBar;
    
    __weak MenuItemSourceView *weakSelf = self;
    {
        MenuItemSourceTextBarFieldObserver *observer = [[MenuItemSourceTextBarFieldObserver alloc] init];
        observer.interval = SearchBarFetchRequestUpdateDelay;
        [observer setOnTextChange:^(NSString *text) {
            [weakSelf searchBarInputChangeDetectedForLocalResultsUpdateWithText:text];
        }];
        [_searchBar addTextObserver:observer];
    }
    {
        MenuItemSourceTextBarFieldObserver *observer = [[MenuItemSourceTextBarFieldObserver alloc] init];
        observer.interval = SearchBarRemoteServiceUpdateDelay;
        [observer setOnTextChange:^(NSString *text) {
            [weakSelf searchBarInputChangeDetectedForRemoteResultsUpdateWithText:text];
        }];
        [_searchBar addTextObserver:observer];
    }
}

- (BOOL)searchBarInputIsActive
{
    return [self.searchBar isFirstResponder] || self.searchBar.textField.text.length > 0;
}

- (void)searchBarInputChangeDetectedForLocalResultsUpdateWithText:(NSString *)searchText
{
    // overrided in subclasses
}

- (void)searchBarInputChangeDetectedForRemoteResultsUpdateWithText:(NSString *)searchText
{
    // overrided in subclasses
}

- (void)showLoadingSourcesIndicatorIfEmpty
{
    if (self.resultsController.sections.count) {
        id <NSFetchedResultsSectionInfo> sectionInfo = [[self.resultsController sections] firstObject];
        if ([sectionInfo numberOfObjects] == 0) {
            [self showLoadingSourcesIndicator];
        }
    } else {
        [self showLoadingSourcesIndicator];
    }
}

- (void)showLoadingSourcesIndicator
{
    [self.loadingView startAnimating];
}

- (void)hideLoadingSourcesIndicator
{
    [self.loadingView stopAnimating];
}

#pragma mark - NSFetchedResultsController and subclass methods

- (NSFetchedResultsController *)resultsController
{
    NSFetchRequest *fetchRequest = nil;
    if(!_resultsController && [self managedObjectContext] && (fetchRequest = [self fetchRequest])) {
        
        NSFetchedResultsController *resultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:[self managedObjectContext] sectionNameKeyPath:[self fetechedResultsControllerSectionNameKeyPath] cacheName:nil];
        resultsController.delegate = self;
        _resultsController = resultsController;
    }
    
    return _resultsController;
}

- (NSManagedObjectContext *)managedObjectContext
{
    return self.blog.managedObjectContext;
}

- (NSFetchRequest *)fetchRequest
{
    // overrided in subclasses
    return nil;
}

- (NSPredicate *)defaultFetchRequestPredicate
{
    // overrided in subclasses if needed
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"blog == %@", [self blog]];
    return predicate;
}

- (NSString *)fetechedResultsControllerSectionNameKeyPath
{
    // overrided in subclasses
    return nil;
}

- (void)performResultsControllerFetchRequest
{
    if(!self.resultsController) {
        return;
    }
    
    NSError *error;
    if(![self.resultsController performFetch:&error]) {
        NSLog(@"an error ocurred: %@", error);
        // TODO: handle errors
    }
}

#pragma mark - subclass configuration

- (void)configureSourceCell:(MenuItemSourceCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
    // overrided in subclasses
}

- (void)scrollingWillDisplayEndOfTableView:(UITableView *)tableView
{
    // overrided in subclasses
}

#pragma mark - UIScrollView

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    self.observeUserScrollingForEndOfTableView = YES;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate) {
        self.observeUserScrollingForEndOfTableView = NO;
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    self.observeUserScrollingForEndOfTableView = NO;
}

#pragma mark - UITableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.resultsController.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.resultsController sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewAutomaticDimension;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(nonnull UITableViewCell *)cell forRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    NSInteger numSections = self.resultsController.sections.count;
    if (indexPath.section == numSections - 1 && self.observeUserScrollingForEndOfTableView) {
        NSInteger numRowsInSection = [tableView numberOfRowsInSection:indexPath.section];
        if (indexPath.row == numRowsInSection - 1) {
            if (cell.frame.origin.y > tableView.bounds.size.height) {
                self.observeUserScrollingForEndOfTableView = NO;
                dispatch_async(dispatch_get_main_queue(), ^{
                    /*  Since we're firing a method as a cell is about to be displayed,
                     we should dispatch this method async, as any implementation of
                     the method may trigger additional table updates and on the same cell.
                     */
                    [self scrollingWillDisplayEndOfTableView:tableView];
                });
            }
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * const identifier = @"MenuItemSourceCell";
    MenuItemSourceCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if(!cell) {
        cell = [[MenuItemSourceCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    
    [self configureSourceCell:cell forIndexPath:indexPath];
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.resultsController sections] objectAtIndex:section];
    return [sectionInfo name];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark - delegate

- (void)tellDelegateDidBeginEditingWithKeyBoard
{
    [self.delegate sourceViewDidBeginEditingWithKeyBoard:self];
}

- (void)tellDelegateDidEndEditingWithKeyBoard
{
    [self.delegate sourceViewDidEndEditingWithKeyboard:self];
}

#pragma mark - MenuItemSourceTextBarDelegate

- (void)sourceTextBarDidBeginEditing:(MenuItemSourceTextBar *)textBar
{
    [self tellDelegateDidBeginEditingWithKeyBoard];
}

- (void)sourceTextBarDidEndEditing:(MenuItemSourceTextBar *)textBar
{
    [self tellDelegateDidEndEditingWithKeyBoard];
}

- (void)sourceTextBar:(MenuItemSourceTextBar *)textBar didUpdateWithText:(NSString *)text
{
    // overrided in sublcasses
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView reloadData];
}

@end
