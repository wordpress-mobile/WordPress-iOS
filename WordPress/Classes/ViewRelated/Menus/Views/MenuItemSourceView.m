#import "MenuItemSourceView.h"
#import "MenuItemSourceTextBar.h"
#import "MenusDesign.h"
#import "MenuItem.h"
#import "Menu.h"

static NSTimeInterval const SearchBarFetchRequestUpdateDelay = 0.10;
static NSTimeInterval const SearchBarRemoteServiceUpdateDelay = 0.25;

@interface MenuItemSourceView () <MenuItemSourceTextBarDelegate>

/* View used as the tableView.tableHeaderView container view for self.stackView.
 */
@property (nonatomic, strong) UIView *stackedTableHeaderView;

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
            inset.top = MenusDesignDefaultContentSpacing / 2.02;
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
    }
    
    return self;
}

#pragma mark - view configuration

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if(!self.tableView.tableHeaderView) {
        // set the tableHeaderView after we have called layoutSubviews the first time
        self.tableView.tableHeaderView = self.stackedTableHeaderView;
        [self.tableView layoutIfNeeded];
    }

    // set the stackedTableHeaderView frame height to the intrinsic height of the stackView
    CGRect frame = self.stackView.bounds;
    self.stackedTableHeaderView.frame = frame;
    // reset the tableHeaderView to update the size change
    self.tableView.tableHeaderView = self.stackedTableHeaderView;
}

- (BOOL)resignFirstResponder
{
    if([self.searchBar isFirstResponder]) {
        return [self.searchBar resignFirstResponder];
    }
    return [super resignFirstResponder];
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

- (void)searchBarInputChangeDetectedForLocalResultsUpdateWithText:(NSString *)searchText
{
    // overrided in subclasses
}

- (void)searchBarInputChangeDetectedForRemoteResultsUpdateWithText:(NSString *)searchText
{
    // overrided in subclasses
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

- (Blog *)blog
{
    return self.item.menu.blog;
}

- (NSManagedObjectContext *)managedObjectContext
{
    return self.item.managedObjectContext;
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

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    UITableView *tableView = self.tableView;
    switch(type) {
        case NSFetchedResultsChangeInsert:
        {
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
        }
            break;
        case NSFetchedResultsChangeDelete:
        {
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        }
            break;
        case NSFetchedResultsChangeUpdate:
        {
            [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        }
            break;
        case NSFetchedResultsChangeMove:
        {
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
        }
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller
  didChangeSection:(id )sectionInfo
           atIndex:(NSUInteger)sectionIndex
     forChangeType:(NSFetchedResultsChangeType)type
{
    if (type == NSFetchedResultsChangeInsert) {
        [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
    } else if (type == NSFetchedResultsChangeDelete) {
        [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
}

@end
