#import "MenuItemSourceResultsViewController.h"
#import "MenuItemSourceTextBar.h"
#import "Menu.h"
#import "MenuItemSourceFooterView.h"
#import "Blog.h"
#import "Menu+ViewDesign.h"
#import <WordPressShared/WPStyleGuide.h>
#import "WordPress-Swift.h"

static NSTimeInterval const SearchBarFetchRequestUpdateDelay = 0.10;
static NSTimeInterval const SearchBarRemoteServiceUpdateDelay = 0.25;

static CGFloat const SearchBarHeight = 44.0;

@interface MenuItemSourceResultsViewController () <MenuItemSourceTextBarDelegate>

/**
 View used as the tableView.tableHeaderView container view for self.stackView.
 */
@property (nonatomic, strong, readonly) UIView *stackedTableHeaderView;
@property (nonatomic, strong, readonly) MenuItemSourceFooterView *footerView;

@property (nonatomic, strong) NSFetchedResultsController *resultsController;

@property (nonatomic, assign) BOOL observeUserScrollingForEndOfTableView;

@end

@implementation MenuItemSourceResultsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.translatesAutoresizingMaskIntoConstraints = NO;
    self.view.backgroundColor = [UIColor murielListForeground];

    [self setupTableView];
    [self setupStackedTableHeaderView];
    [self setupStackView];
    [self setupFooterView];
}

- (void)setupTableView
{
    UITableView *tableView = [[UITableView alloc] init];
    tableView.translatesAutoresizingMaskIntoConstraints = NO;
    tableView.dataSource = self;
    tableView.delegate = self;
    tableView.separatorColor = [UIColor murielNeutral10];
    tableView.cellLayoutMarginsFollowReadableWidth = NO;
    UIEdgeInsets inset = tableView.contentInset;
    inset.top = MenusDesignDefaultContentSpacing / 2.0;
    tableView.contentInset = inset;
    [self.view addSubview:tableView];

    [NSLayoutConstraint activateConstraints:@[
                                              [tableView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
                                              [tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
                                              [tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
                                              [tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
                                              ]];
    _tableView = tableView;
}

- (void)setupStackedTableHeaderView
{
    // setup the tableHeaderView and keep translatesAutoresizingMaskIntoConstraints to default YES
    // this allows the tableView to handle sizing the view as any other tableHeaderView
    UIView *stackedTableHeaderView = [[UIView alloc] init];
    _stackedTableHeaderView = stackedTableHeaderView;
}

- (void)setupStackView
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

    NSAssert(_stackedTableHeaderView != nil, @"stackedTableHeaderView is nil");
    [_stackedTableHeaderView addSubview:stackView];
    // setup the constraints for the stackView
    // constrain the horiztonal edges to sync the width to the stackedTableHeaderView
    // do not include a bottom constraint so the stackView can layout its intrinsic height
    [NSLayoutConstraint activateConstraints:@[
                                              [stackView.topAnchor constraintEqualToAnchor:_stackedTableHeaderView.topAnchor],
                                              [stackView.leadingAnchor constraintEqualToAnchor:_stackedTableHeaderView.leadingAnchor],
                                              [stackView.trailingAnchor constraintEqualToAnchor:_stackedTableHeaderView.trailingAnchor]
                                              ]];
    _stackView = stackView;
}

- (void)setupFooterView
{
    MenuItemSourceFooterView *footerView = [[MenuItemSourceFooterView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 60.0)];

    NSAssert(_tableView != nil, @"tableView is nil");
    _tableView.tableFooterView = footerView;

    _footerView = footerView;
}

- (BOOL)isFirstResponder
{
    if ([self.searchBar isFirstResponder]) {
        return [self.searchBar isFirstResponder];
    }
    return [super isFirstResponder];
}

- (BOOL)resignFirstResponder
{
    if ([self.searchBar isFirstResponder]) {
        return [self.searchBar resignFirstResponder];
    }
    return [super resignFirstResponder];
}

#pragma mark - view configuration

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

    BOOL needsOffsetFix = NO;
    if (!self.tableView.tableHeaderView) {
        // set the tableHeaderView after we have called layoutSubviews the first time
        // this add the stackedTableHeaderView to view hierarchy
        self.tableView.tableHeaderView = self.stackedTableHeaderView;
        [self.stackedTableHeaderView layoutIfNeeded];
        needsOffsetFix = YES;
    }

    // set the stackedTableHeaderView frame height to the intrinsic height of the stackView
    CGRect frame = self.stackView.bounds;
    self.stackedTableHeaderView.frame = frame;
    // reset the tableHeaderView to update the size change
    self.tableView.tableHeaderView = self.stackedTableHeaderView;

    if (needsOffsetFix) {
        if (self.tableView.contentOffset.y == 0.0) {
            CGPoint offset = self.tableView.contentOffset;
            offset.y = -self.tableView.contentInset.top;
            self.tableView.contentOffset = offset;
        }
    }
}

- (void)refresh
{
    [self.tableView reloadData];
}

- (void)insertSearchBarIfNeeded
{
    if (self.searchBar) {
        return;
    }

    MenuItemSourceTextBar *searchBar = [[MenuItemSourceTextBar alloc] initAsSearchBar];
    searchBar.translatesAutoresizingMaskIntoConstraints = NO;
    searchBar.delegate = self;

    NSAssert(_stackView != nil, @"stackView is nil");
    [_stackView addArrangedSubview:searchBar];

    NSLayoutConstraint *heightConstraint = [searchBar.heightAnchor constraintEqualToConstant:SearchBarHeight];
    heightConstraint.priority = UILayoutPriorityDefaultHigh;
    heightConstraint.active = YES;

    [searchBar setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisVertical];
    _searchBar = searchBar;

    __weak MenuItemSourceResultsViewController *weakSelf = self;
    MenuItemSourceTextBarFieldObserver *localSearchObserver = [[MenuItemSourceTextBarFieldObserver alloc] init];
    localSearchObserver.interval = SearchBarFetchRequestUpdateDelay;
    [localSearchObserver setOnTextChange:^(NSString *text) {
        [weakSelf searchBarInputChangeDetectedForLocalResultsUpdateWithText:text];
    }];
    [_searchBar addTextObserver:localSearchObserver];

    MenuItemSourceTextBarFieldObserver *remoteSearchObserver = [[MenuItemSourceTextBarFieldObserver alloc] init];
    remoteSearchObserver.interval = SearchBarRemoteServiceUpdateDelay;
    [remoteSearchObserver setOnTextChange:^(NSString *text) {
        [weakSelf searchBarInputChangeDetectedForRemoteResultsUpdateWithText:text];
    }];
    [_searchBar addTextObserver:remoteSearchObserver];
}

- (BOOL)searchBarInputIsActive
{
    return [self.searchBar isFirstResponder] || self.searchBar.textField.text.length > 0;
}

- (void)searchBarInputChangeDetectedForLocalResultsUpdateWithText:(NSString *)searchText
{
    AssertSubclassMethod();
}

- (void)searchBarInputChangeDetectedForRemoteResultsUpdateWithText:(NSString *)searchText
{
    AssertSubclassMethod();
}

- (void)showLoadingSourcesIndicatorIfEmpty
{
    if ([self fetchedResultsAreEmpty]) {
        [self showLoadingSourcesIndicator];
    }
}

- (void)showLoadingSourcesIndicator
{
    [self.footerView startLoadingIndicatorAnimation];
}

- (void)hideLoadingSourcesIndicator
{
    [self.footerView stopLoadingIndicatorAnimation];
    [self toggleNoResultsIndiciator];
}

- (void)showLoadingErrorMessageForResults
{
    NSString *text = NSLocalizedString(@"An error occurred loading the results, please try again in a moment.", @"The error message displayed when a user is editing a MenuItem and the results cannot be loaded, such as posts, pages, etc.");
    [self.footerView toggleMessageWithText:text];
}

- (BOOL)itemTypeMatchesSourceItemType
{
    return [self.item.type isEqualToString:[self sourceItemType]];
}

- (void)setItemSourceWithContentID:(NSNumber *)contentID name:(NSString *)name
{
    MenuItem *item = self.item;
    if (item.contentID.integerValue == contentID.integerValue && item.type == [self sourceItemType]) {
        // No update needed.
        return;
    }
    item.contentID = contentID;
    item.type = [self sourceItemType];
    if (name.length && [self.delegate sourceResultsViewControllerCanOverrideItemName:self]) {
        item.name = name;
    }
    [self.delegate sourceResultsViewControllerDidUpdateItem:self];
}

- (NSString *)sourceItemType
{
    AssertSubclassMethod();
    return nil;
}

- (void)toggleNoResultsIndiciator
{
    if ([self fetchedResultsAreEmpty] && !self.defersFooterViewMessageUpdates) {
        if (self.searchBarInputIsActive) {
            [self.footerView toggleMessageWithText:NSLocalizedString(@"No results. Please try a different search.", @"Shown when user is searching for specific Menu item options and no items are available, such as posts, pages, etc.")];
        } else {
            [self.footerView toggleMessageWithText:NSLocalizedString(@"Nothing found.", @"Shown when user is loading Menu item options and no items are available, such as posts, pages, etc.")];
        }
    } else {
        [self.footerView toggleMessageWithText:nil];
    }
}

#pragma mark - NSFetchedResultsController and subclass methods

- (NSFetchedResultsController *)resultsController
{
    NSFetchRequest *fetchRequest = nil;
    if (!_resultsController && [self managedObjectContext] && (fetchRequest = [self fetchRequest])) {

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
    return nil;
}

- (void)performResultsControllerFetchRequest
{
    if (!self.resultsController) {
        return;
    }
    NSError *error;
    if (![self.resultsController performFetch:&error]) {
        DDLogError(@"Error occurred preforming fetch for MenuItem source of type: %@ error: %@", [self sourceItemType], error);
    }
    [self toggleNoResultsIndiciator];
}

- (BOOL)fetchedResultsAreEmpty
{
    return self.resultsController.fetchedObjects.count == 0;
}

- (void)deselectVisibleSourceCellsIfNeeded
{
    NSArray *cells = [self.tableView visibleCells];
    for (MenuItemSourceCell *cell in cells) {
        if (![cell isKindOfClass:[MenuItemSourceCell class]]) {
            continue;
        }
        if (cell.sourceSelected) {
            cell.sourceSelected = NO;
        }
    }
}

#pragma mark - subclass configuration

- (void)configureSourceCell:(MenuItemSourceCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
    AssertSubclassMethod();
}

- (void)scrollingWillDisplayEndOfTableView:(UITableView *)tableView
{
    // Available to subclasses if needed.
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
    if (!self.observeUserScrollingForEndOfTableView ) {
        // Not observing scrolling for reaching the end of the tableView.
        return;
    }

    if (cell.frame.origin.y < tableView.bounds.size.height) {
        // Cell is already within the frame bounds, no need to observe scrolling.
        return;
    }

    NSInteger numSections = self.resultsController.sections.count;
    if (indexPath.section < numSections - 1) {
        // Not observing or not the last section of the tableView.
        return;
    }

    NSInteger numRowsInSection = [tableView numberOfRowsInSection:indexPath.section];
    if (indexPath.row < numRowsInSection - 1) {
        // Not the last row in the section.
        return;
    }

    // Reached the end of the tableView and will display the last cell from off-screen.
    self.observeUserScrollingForEndOfTableView = NO;
    dispatch_async(dispatch_get_main_queue(), ^{
        /*  Since we're firing a method as a cell is about to be displayed,
         we should dispatch this method async, as any implementation of
         the method may trigger additional table updates and on the same cell.
         */
        [self scrollingWillDisplayEndOfTableView:tableView];
    });
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * const identifier = @"MenuItemSourceCell";
    MenuItemSourceCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
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
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - delegate

- (void)tellDelegateDidBeginEditingWithKeyBoard
{
    [self.delegate sourceResultsViewControllerDidBeginEditingWithKeyBoard:self];
}

- (void)tellDelegateDidEndEditingWithKeyBoard
{
    [self.delegate sourceResultsViewControllerDidEndEditingWithKeyboard:self];
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
    // Available to subclasses if needed.
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView reloadData];
    [self toggleNoResultsIndiciator];
}

@end
