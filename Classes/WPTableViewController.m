//
//  WPTableViewController.m
//  WordPress
//
//  Created by Brad Angelcyk on 5/22/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import "WPTableViewController.h"
#import "WPTableViewControllerSubclass.h"
#import "EGORefreshTableHeaderView.h" 

NSTimeInterval const WPTableViewControllerRefreshTimeout = 300; // 5 minutes

@interface WPTableViewController () <NSFetchedResultsControllerDelegate, EGORefreshTableHeaderDelegate>
@property (nonatomic,retain) NSFetchedResultsController *resultsController;
- (void)simulatePullToRefresh;
@end

@implementation WPTableViewController {
    EGORefreshTableHeaderView *_refreshHeaderView;
    NSIndexPath *_indexPathSelectedBeforeUpdates;
    NSIndexPath *_indexPathSelectedAfterUpdates;
}
@synthesize blog = _blog;
@synthesize resultsController = _resultsController;

- (void)dealloc
{
    [_refreshHeaderView release];
    [_indexPathSelectedBeforeUpdates release];
    [_indexPathSelectedAfterUpdates release];
    _resultsController.delegate = nil;
    [_resultsController release];
    [_blog release];
    [super dealloc];
}

- (id)initWithBlog:(Blog *)blog {
    if (self) {
        _blog = [blog retain];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (_refreshHeaderView == nil) {
		_refreshHeaderView = [[EGORefreshTableHeaderView alloc] initWithFrame:CGRectMake(0.0f, 0.0f - self.tableView.bounds.size.height, self.view.frame.size.width, self.tableView.bounds.size.height)];
		_refreshHeaderView.delegate = self;
		[self.tableView addSubview:_refreshHeaderView];
	}
	
	//  update the last update date
	[_refreshHeaderView refreshLastUpdatedDate];

    self.tableView.allowsSelectionDuringEditing = YES;
    self.tableView.backgroundColor = TABLE_VIEW_BACKGROUND_COLOR;
}

- (void)viewDidUnload
{
    [super viewDidUnload];

    [_refreshHeaderView release]; _refreshHeaderView = nil;
}

- (void)viewDidAppear:(BOOL)animated {
    NSDate *lastSynced = [self lastSyncDate];
    if (lastSynced == nil || ABS([lastSynced timeIntervalSinceNow]) > WPTableViewControllerRefreshTimeout) {
        // If table is at the original scroll position, simulate a pull to refresh
        if (self.tableView.contentOffset.y == 0) {
            [self simulatePullToRefresh];
        } else {
        // Otherwise, just update in the background
            [self syncItemsWithUserInteraction:NO];
        }
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    _refreshHeaderView.hidden = editing;
}

#pragma mark - Property accessors

- (void)setBlog:(Blog *)blog {
    if (_blog == blog) 
        return;

    [_blog release];
    _blog = [blog retain];

    self.resultsController = nil;
    [self.tableView reloadData];
    if ([self.resultsController.fetchedObjects count] == 0 && ![self isSyncing]) {
        [self simulatePullToRefresh];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[self.resultsController sections] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.resultsController sections] objectAtIndex:section];
    return [sectionInfo name];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = nil;
    sectionInfo = [[self.resultsController sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self newCell];

    if (IS_IPAD || self.tableView.isEditing) {
		cell.accessoryType = UITableViewCellAccessoryNone;
	} else {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    [self configureCell:cell atIndexPath:indexPath];

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return kCellHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return kSectionHeaderHight;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleNone;
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

#pragma mark -
#pragma mark Fetched results controller

- (NSFetchedResultsController *)resultsController {
    if (_resultsController != nil) {
        return _resultsController;
    }

    NSManagedObjectContext *moc = self.blog.managedObjectContext;    
    _resultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:[self fetchRequest]
                                                             managedObjectContext:moc
                                                               sectionNameKeyPath:[self sectionNameKeyPath]
                                                                        cacheName:[NSString stringWithFormat:@"%@-%@", [self entityName], [self.blog objectID]]];
    _resultsController.delegate = self;
        
    NSError *error = nil;
    if (![_resultsController performFetch:&error]) {
        WPFLog(@"%@ couldn't fetch %@: %@", self, [self entityName], [error localizedDescription]);
        _resultsController = nil;
    }
    
    return _resultsController;
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    _indexPathSelectedBeforeUpdates = [[self.tableView indexPathForSelectedRow] retain];
    [self.tableView beginUpdates];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView endUpdates];
    if (_indexPathSelectedAfterUpdates) {
        [self.tableView selectRowAtIndexPath:_indexPathSelectedAfterUpdates animated:NO scrollPosition:UITableViewScrollPositionNone];

        [_indexPathSelectedBeforeUpdates release];
        _indexPathSelectedBeforeUpdates = nil;
        [_indexPathSelectedAfterUpdates release];
        _indexPathSelectedAfterUpdates = nil;
    }
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {

    if (NSFetchedResultsChangeUpdate == type && newIndexPath && ![newIndexPath isEqual:indexPath]) {
        // Seriously, Apple?
        // http://developer.apple.com/library/ios/#releasenotes/iPhone/NSFetchedResultsChangeMoveReportedAsNSFetchedResultsChangeUpdate/_index.html
        type = NSFetchedResultsChangeMove;
    }
    if (newIndexPath == nil) {
        // It seems in some cases newIndexPath can be nil for updates
        newIndexPath = indexPath;
    }

    switch(type) {            
        case NSFetchedResultsChangeInsert:
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            if ([_indexPathSelectedBeforeUpdates isEqual:indexPath]) {
                [self.panelNavigationController popToViewController:self animated:YES];
            }
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[self.tableView cellForRowAtIndexPath:indexPath] atIndexPath:newIndexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [self.tableView deleteRowsAtIndexPaths:[NSArray
                                                       arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView insertRowsAtIndexPaths:[NSArray
                                                       arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            if ([_indexPathSelectedBeforeUpdates isEqual:indexPath] && _indexPathSelectedAfterUpdates == nil) {
                _indexPathSelectedAfterUpdates = [newIndexPath retain];
            }
            break;
    }    
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id )sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

#pragma mark - EGORefreshTableHeaderDelegate Methods

- (void)egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView *)view{
	[self syncItemsWithUserInteraction:YES];
}

- (BOOL)egoRefreshTableHeaderDataSourceIsLoading:(EGORefreshTableHeaderView *)view{
	return [self isSyncing]; // should return if data source model is reloading
}

- (NSDate*)egoRefreshTableHeaderDataSourceLastUpdated:(EGORefreshTableHeaderView *)view{
	return [self lastSyncDate]; // should return date data source was last changed
}

#pragma mark -
#pragma mark UIScrollViewDelegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
	if (!self.editing)
        [_refreshHeaderView egoRefreshScrollViewDidScroll:scrollView];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
	if (!self.editing)
		[_refreshHeaderView egoRefreshScrollViewDidEndDragging:scrollView];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (self.panelNavigationController) {
        [self.panelNavigationController viewControllerWantsToBeFullyVisible:self];
    }
}

#pragma mark - Private Methods

- (void)simulatePullToRefresh {
    CGPoint offset = self.tableView.contentOffset;
    offset.y = - 65.0f;
    [self.tableView setContentOffset:offset];
    [_refreshHeaderView egoRefreshScrollViewDidEndDragging:self.tableView];
}

- (void)syncItemsWithUserInteraction:(BOOL)userInteraction {
    [self syncItemsWithUserInteraction:userInteraction success:^{
        [_refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:self.tableView];
    } failure:^(NSError *error) {
        [WPError showAlertWithError:error title:NSLocalizedString(@"Couldn't sync", @"")];
        [_refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:self.tableView];
    }];
}

#pragma mark - Subclass methods

#define AssertSubclassMethod() @throw [NSException exceptionWithName:NSInternalInconsistencyException\
                                                    reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)] \
                                                    userInfo:nil]

- (NSString *)entityName {
    AssertSubclassMethod();
}

- (NSDate *)lastSyncDate {
    AssertSubclassMethod();
}

- (NSFetchRequest *)fetchRequest {
    NSFetchRequest *fetchRequest = [[[NSFetchRequest alloc] init] autorelease];
    [fetchRequest setEntity:[NSEntityDescription entityForName:[self entityName] inManagedObjectContext:self.blog.managedObjectContext]];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"blog == %@", self.blog]];

    return fetchRequest;
}

- (NSString *)sectionNameKeyPath {
    return nil;
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    AssertSubclassMethod();
}

- (void)syncItemsWithUserInteraction:(BOOL)userInteraction success:(void (^)())success failure:(void (^)(NSError *))failure {
    AssertSubclassMethod();
}

- (BOOL)isSyncing {
	AssertSubclassMethod();
}

- (UITableViewCell *)newCell {
    NSString *cellIdentifier = [NSString stringWithFormat:@"_WPTable_%@_Cell", [self entityName]];
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];
    }
    return cell;
}

- (BOOL)hasMoreContent {
    return NO;
}

- (void)loadMoreContent {
}

@end
