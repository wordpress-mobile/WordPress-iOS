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
#import "WordPressAppDelegate.h"
#import "EditSiteViewController.h"
#import "ReachabilityUtils.h"
#import "WPWebViewController.h"
#import "SoundUtil.h"
#import "WPInfoView.h"

NSTimeInterval const WPTableViewControllerRefreshTimeout = 300; // 5 minutes

@interface WPTableViewController () <EGORefreshTableHeaderDelegate>

@property (nonatomic, strong) NSFetchedResultsController *resultsController;
@property (nonatomic) BOOL swipeActionsEnabled;
@property (nonatomic) BOOL infiniteScrollEnabled;
@property (nonatomic, strong, readonly) UIView *swipeView;
@property (nonatomic, strong) UITableViewCell *swipeCell;
@property (nonatomic, strong) UIView *noResultsView;

- (void)simulatePullToRefresh;
- (void)enableSwipeGestureRecognizer;
- (void)disableSwipeGestureRecognizer;
- (void)swipe:(UISwipeGestureRecognizer *)recognizer direction:(UISwipeGestureRecognizerDirection)direction;
- (void)swipeLeft:(UISwipeGestureRecognizer *)recognizer;
- (void)swipeRight:(UISwipeGestureRecognizer *)recognizer;
- (void)dismissModal:(id)sender;
- (void)hideRefreshHeader;
- (void)configureNoResultsView;

@end

@implementation WPTableViewController {
    EGORefreshTableHeaderView *_refreshHeaderView;
    EditSiteViewController *editSiteViewController;
    UIView *noResultsView;
    NSIndexPath *_indexPathSelectedBeforeUpdates;
    NSIndexPath *_indexPathSelectedAfterUpdates;
    UISwipeGestureRecognizer *_leftSwipeGestureRecognizer;
    UISwipeGestureRecognizer *_rightSwipeGestureRecognizer;
    UISwipeGestureRecognizerDirection _swipeDirection;
    UIActivityIndicatorView *_activityFooter;
    BOOL _animatingRemovalOfModerationSwipeView;
    BOOL didPromptForCredentials;
    BOOL didPlayPullSound;
    BOOL didTriggerRefresh;
    CGPoint savedScrollOffset;
    BOOL _isSyncing;
}

@synthesize blog = _blog;
@synthesize resultsController = _resultsController;
@synthesize swipeActionsEnabled = _swipeActionsEnabled;
@synthesize infiniteScrollEnabled = _infiniteScrollEnabled;
@synthesize swipeView = _swipeView;
@synthesize swipeCell = _swipeCell;
@synthesize noResultsView;

- (void)dealloc
{
    if([self.tableView observationInfo])
        [self.tableView removeObserver:self forKeyPath:@"contentOffset"];

    _resultsController.delegate = nil;
    editSiteViewController.delegate = nil;
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
    self.tableView.separatorColor = [UIColor colorWithRed:204.0f/255.0f green:204.0f/255.0f blue:204.0f/255.0f alpha:1.0f];
    
    if (self.swipeActionsEnabled) {
        [self enableSwipeGestureRecognizer];
    }
    
    if (self.infiniteScrollEnabled) {
        [self enableInfiniteScrolling];
    }

    [self.tableView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];
    
    [self configureNoResultsView];
}

- (void)viewDidUnload
{
    if([self.tableView observationInfo])
        [self.tableView removeObserver:self forKeyPath:@"contentOffset"];
    
    [super viewDidUnload];
    
     _refreshHeaderView = nil;
    
    if (self.swipeActionsEnabled) {
        [self disableSwipeGestureRecognizer];
    }

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    CGSize contentSize = self.tableView.contentSize;
    if(contentSize.height > savedScrollOffset.y) {
        [self.tableView scrollRectToVisible:CGRectMake(savedScrollOffset.x, savedScrollOffset.y, 0.0, 0.0) animated:NO];
    } else {
        [self.tableView scrollRectToVisible:CGRectMake(0.0, contentSize.height, 0.0, 0.0) animated:NO];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    WordPressAppDelegate *appDelegate = [WordPressAppDelegate sharedWordPressApplicationDelegate];
    if( appDelegate.connectionAvailable == NO ) return; //do not start auto-synch if connection is down

    // Don't try to refresh if we just canceled editing credentials
    if (didPromptForCredentials) {
        return;
    }
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

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (IS_IPHONE) {
        savedScrollOffset = self.tableView.contentOffset;
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return [super shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}


- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [self removeSwipeView:NO];
    [super setEditing:editing animated:animated];
    _refreshHeaderView.hidden = editing;
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if(![keyPath isEqualToString:@"contentOffset"])
        return;
    
    CGPoint newValue = [[change objectForKey:NSKeyValueChangeNewKey] CGPointValue];
    CGPoint oldValue = [[change objectForKey:NSKeyValueChangeOldKey] CGPointValue];
    
    if (newValue.y > oldValue.y && newValue.y > -65.0f) {
        didPlayPullSound = NO;
    }
    
    if(newValue.y == oldValue.y) return;

    if(newValue.y <= -65.0f && newValue.y < oldValue.y && ![self isSyncing] && !didPlayPullSound && !didTriggerRefresh) {
        // triggered
        [SoundUtil playPullSound];
        didPlayPullSound = YES;
    }
    
}


#pragma mark - Property accessors

- (void)setBlog:(Blog *)blog {
    if (_blog == blog) 
        return;

    _blog = blog;

    self.resultsController = nil;
    [self.tableView reloadData];
    WordPressAppDelegate *appDelegate = [WordPressAppDelegate sharedWordPressApplicationDelegate];
    if ( appDelegate.connectionAvailable == YES && [self.resultsController.fetchedObjects count] == 0 && ![self isSyncing] ) {
        [self simulatePullToRefresh];
    }
}

- (void)setSwipeActionsEnabled:(BOOL)swipeActionsEnabled {
    if (swipeActionsEnabled == _swipeActionsEnabled)
        return;

    _swipeActionsEnabled = swipeActionsEnabled;
    if (self.isViewLoaded) {
        if (_swipeActionsEnabled) {
            [self enableSwipeGestureRecognizer];
        } else {
            [self disableSwipeGestureRecognizer];
        }
    }
}

- (BOOL)swipeActionsEnabled {
    return _swipeActionsEnabled && !self.editing;
}

- (UIView *)swipeView {
    if (_swipeView) {
        return _swipeView;
    }

    _swipeView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, kCellHeight)];
    _swipeView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"background.png"]];
    
    UIImage *shadow = [[UIImage imageNamed:@"inner-shadow.png"] stretchableImageWithLeftCapWidth:0 topCapHeight:0];
    UIImageView *shadowImageView = [[UIImageView alloc] initWithFrame:_swipeView.frame];
    shadowImageView.alpha = 0.5;
    shadowImageView.image = shadow;
    shadowImageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [_swipeView insertSubview:shadowImageView atIndex:0];  

    return _swipeView;
}

- (void)setInfiniteScrollEnabled:(BOOL)infiniteScrollEnabled {
    if (infiniteScrollEnabled == _infiniteScrollEnabled)
        return;

    _infiniteScrollEnabled = infiniteScrollEnabled;
    if (self.isViewLoaded) {
        if (_infiniteScrollEnabled) {
            [self enableInfiniteScrolling];
        } else {
            [self disableInfiniteScrolling];
        }
    }
}

- (BOOL)infiniteScrollEnabled {
    return _infiniteScrollEnabled;
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

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (IS_IPAD == YES) {
		cell.accessoryType = UITableViewCellAccessoryNone;
	}

    // Are we approaching the end of the table?
    if ((indexPath.section + 1 == [self numberOfSectionsInTableView:tableView]) && (indexPath.row + 4 >= [self tableView:tableView numberOfRowsInSection:indexPath.section]) && [self tableView:tableView numberOfRowsInSection:indexPath.section] > 10) {
        // Only 3 rows till the end of table
        if (![self isSyncing] && [self hasMoreContent]) {
            [_activityFooter startAnimating];
            [self loadMoreWithSuccess:^{
                [_activityFooter stopAnimating];
            } failure:^(NSError *error) {
                [_activityFooter stopAnimating];
            }];
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return kCellHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = nil;
    sectionInfo = [[self.resultsController sections] objectAtIndex:section];
    // Don't show section headers if there are no named sections
    // [sectionInfo name] is sometimes nil and sometimes and empty string (#!?) so we check the length
    if ([[self.resultsController sections] count] <= 1 && [[sectionInfo name] length] == 0) {
        return 0.f;
    }
    return kSectionHeaderHight;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleNone;
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (NSIndexPath *)tableView:(UITableView *)theTableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!self.editing) {
        [self removeSwipeView:YES];
    }
    return indexPath;
}

#pragma mark -
#pragma mark Fetched results controller

- (NSFetchedResultsController *)resultsController {
    if (_resultsController != nil) {
        return _resultsController;
    }

    NSManagedObjectContext *moc;
    NSString *cacheName;
    if (self.blog) {
        moc = self.blog.managedObjectContext;
        cacheName = [NSString stringWithFormat:@"%@-%@", [self entityName], [self.blog objectID]];
    } else {
        moc = [[WordPressAppDelegate sharedWordPressApplicationDelegate] managedObjectContext];
        cacheName = [self entityName];
    }
    _resultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:[self fetchRequest]
                                                             managedObjectContext:moc
                                                               sectionNameKeyPath:[self sectionNameKeyPath]
                                                                        cacheName:cacheName];
    _resultsController.delegate = self;
        
    NSError *error = nil;
    if (![_resultsController performFetch:&error]) {
        WPFLog(@"%@ couldn't fetch %@: %@", self, [self entityName], [error localizedDescription]);
        _resultsController = nil;
    }
    
    return _resultsController;
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    _indexPathSelectedBeforeUpdates = [self.tableView indexPathForSelectedRow];
    [self.tableView beginUpdates];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView endUpdates];
    if (_indexPathSelectedAfterUpdates) {
        [self.tableView selectRowAtIndexPath:_indexPathSelectedAfterUpdates animated:NO scrollPosition:UITableViewScrollPositionNone];

        _indexPathSelectedBeforeUpdates = nil;
        _indexPathSelectedAfterUpdates = nil;
    }
    
    [self configureNoResultsView];
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
                _indexPathSelectedAfterUpdates = newIndexPath;
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
    didTriggerRefresh = YES;
	[self syncItemsWithUserInteraction:YES];
    [noResultsView removeFromSuperview];
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
    if (self.swipeActionsEnabled) {
        [self removeSwipeView:YES];
    }
}


#pragma mark -
#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex { 
	switch(buttonIndex) {
		case 0: {
            HelpViewController *helpViewController = [[HelpViewController alloc] init];
            helpViewController.isBlogSetup = YES;
            helpViewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismissModal:)];
            // Probably should be modal
            UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:helpViewController];
            if (IS_IPAD) {
                navController.modalPresentationStyle = UIModalPresentationFormSheet;
                navController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
            }
            [self.panelNavigationController presentModalViewController:navController animated:YES];

			break;
		}
		case 1:
            if (alertView.tag == 30){
                NSString *path = nil;
                NSError *error = NULL;
                NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"http\\S+writing.php" options:NSRegularExpressionCaseInsensitive error:&error];
                NSString *msg = [alertView message];
                NSRange rng = [regex rangeOfFirstMatchInString:msg options:0 range:NSMakeRange(0, [msg length])];
                
                if (rng.location == NSNotFound) {
                    path = self.blog.url;
                    if (![path hasPrefix:@"http"]) {
                        path = [NSString stringWithFormat:@"http://%@", path];
                    } else if ([self.blog isWPcom] && [path rangeOfString:@"wordpress.com"].location == NSNotFound) {
                        path = [self.blog.xmlrpc stringByReplacingOccurrencesOfString:@"xmlrpc.php" withString:@""];
                    }
                    path = [path stringByReplacingOccurrencesOfString:@"xmlrpc.php" withString:@""];
                    path = [path stringByAppendingFormat:@"/wp-admin/options-writing.php"];
                    
                } else {
                    path = [msg substringWithRange:rng];
                }
                
                WPWebViewController *webViewController;
                if ( IS_IPAD ) {
                    webViewController = [[WPWebViewController alloc] initWithNibName:@"WPWebViewController-iPad" bundle:nil];
                } else {
                    webViewController = [[WPWebViewController alloc] initWithNibName:@"WPWebViewController" bundle:nil];
                }
                webViewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismissModal:)];
                [webViewController setUrl:[NSURL URLWithString:path]];
                [webViewController setUsername:self.blog.username];
                [webViewController setPassword:[self.blog fetchPassword]];
                [webViewController setWpLoginURL:[NSURL URLWithString:self.blog.loginURL]];
                webViewController.shouldScrollToBottom = YES;
                // Probably should be modal.
                UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:webViewController];
                if (IS_IPAD) {
                    navController.modalPresentationStyle = UIModalPresentationFormSheet;
                    navController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
                }
                [self.panelNavigationController presentModalViewController:navController animated:YES];
            }
			break;
		default:
			break;
	}
}

#pragma mark - SettingsViewControllerDelegate

- (void)controllerDidDismiss:(UIViewController *)controller cancelled:(BOOL)cancelled {
    if (editSiteViewController == controller) {
        didPromptForCredentials = cancelled;
        editSiteViewController = nil;
    }
}

#pragma mark - Private Methods

- (void)configureNoResultsView {
    if (![self isViewLoaded]) return;
    
    if (self.resultsController && [[_resultsController fetchedObjects] count] == 0 && !self.isSyncing) {
        // Show no results view.

        NSString *ttl = NSLocalizedString(@"No %@ yet", @"A string format. The '%@' will be replaced by the relevant type of object, posts, pages or comments.");
        ttl = [NSString stringWithFormat:ttl, [self.title lowercaseString]];

        NSString *msg = @"";
		if ([self userCanCreateEntity]) {
            msg = NSLocalizedString(@"Why not create one?", @"A call to action to create a post or page.");
        }
        self.noResultsView = [WPInfoView WPInfoViewWithTitle:ttl
                                                     message:msg
                                                cancelButton:nil];
        
        [self.tableView addSubview:self.noResultsView];
    } else {
        [self.noResultsView removeFromSuperview];
    }

}

- (void)hideRefreshHeader {
    [_refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:self.tableView];
    if ([self isViewLoaded] && self.view.window && didTriggerRefresh) {
        [SoundUtil playRollupSound];
    }
    didTriggerRefresh = NO;
}

- (void)dismissModal:(id)sender {
    [self dismissModalViewControllerAnimated:YES];
}

- (void)simulatePullToRefresh {
    if(!_refreshHeaderView) return;
    
    CGPoint offset = self.tableView.contentOffset;
    offset.y = - 65.0f;
    [self.tableView setContentOffset:offset];
    [_refreshHeaderView egoRefreshScrollViewDidEndDragging:self.tableView];
}

- (void)syncItemsWithUserInteraction:(BOOL)userInteraction {
    if ([self isSyncing]) {
        return;
    }
    if (![ReachabilityUtils isInternetReachable]) {
        [ReachabilityUtils showAlertNoInternetConnection];
        [self performSelector:@selector(hideRefreshHeader) withObject:nil afterDelay:0.1];
        return;
    }

    _isSyncing = YES;
    [self syncItemsWithUserInteraction:userInteraction success:^{
        [self hideRefreshHeader];
        _isSyncing = NO;
        [self configureNoResultsView];
    } failure:^(NSError *error) {
        [_refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:self.tableView];
        _isSyncing = NO;
        if (self.blog) {
            if (error.code == 405) {
                // FIXME: this looks like "Enable XML-RPC" which is going away
                // If it's not, don't rely on whatever the error message is if we are showing custom actions like 'Enable Now'
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Couldn't sync", @"")
                                                                    message:[error localizedDescription]
                                                                   delegate:self
                                                          cancelButtonTitle:NSLocalizedString(@"Need Help?", @"")
                                                          otherButtonTitles:NSLocalizedString(@"Enable Now", @""), nil];

                alertView.tag = 30;
                [alertView show];

            } else if (error.code == 403 && editSiteViewController == nil) {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Couldn't Connect", @"")
                                                                    message:NSLocalizedString(@"The username or password stored in the app may be out of date. Please re-enter your password in the settings and try again.", @"")
                                                                   delegate:nil
                                                          cancelButtonTitle:nil
                                                          otherButtonTitles:NSLocalizedString(@"OK", @""), nil];
                [alertView show];

                // bad login/pass combination
                editSiteViewController = [[EditSiteViewController alloc] initWithNibName:nil bundle:nil];
                editSiteViewController.blog = self.blog;
                editSiteViewController.isCancellable = YES;
                editSiteViewController.delegate = self;
                UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:editSiteViewController];

                if(IS_IPAD == YES) {
                    navController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
                    navController.modalPresentationStyle = UIModalPresentationFormSheet;
                }

                [self.panelNavigationController presentModalViewController:navController animated:YES];
            }
        } else {
            // For non-blog tables (notifications), just show the error for now
            [WPError showAlertWithError:error];
        }
    }];
}

#pragma mark - Swipe gestures

- (void)enableSwipeGestureRecognizer {
    [self disableSwipeGestureRecognizer]; // Disable any existing gesturerecognizers before initing new ones to avoid leaks.
    
    _leftSwipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeLeft:)];
    _leftSwipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.tableView addGestureRecognizer:_leftSwipeGestureRecognizer];

    _rightSwipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRight:)];
    _rightSwipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
    [self.tableView addGestureRecognizer:_rightSwipeGestureRecognizer];
}

- (void)disableSwipeGestureRecognizer {
    if (_leftSwipeGestureRecognizer) {
        [self.tableView removeGestureRecognizer:_leftSwipeGestureRecognizer];
        _leftSwipeGestureRecognizer = nil;
    }

    if (_rightSwipeGestureRecognizer) {
        [self.tableView removeGestureRecognizer:_rightSwipeGestureRecognizer];
        _rightSwipeGestureRecognizer = nil;
    }
}

- (void)removeSwipeView:(BOOL)animated {
    if (!self.swipeActionsEnabled || !_swipeCell || (self.swipeCell.frame.origin.x == 0 && self.swipeView.superview == nil)) return;
    
    if (animated)
    {
        _animatingRemovalOfModerationSwipeView = YES;
        [UIView animateWithDuration:0.2
                         animations:^{
                             if (_swipeDirection == UISwipeGestureRecognizerDirectionRight)
                             {
                                 self.swipeView.frame = CGRectMake(-self.swipeView.frame.size.width + 5.0,self.swipeView.frame.origin.y, self.swipeView.frame.size.width, self.swipeView.frame.size.height);
                                 self.swipeCell.frame = CGRectMake(5.0, self.swipeCell.frame.origin.y, self.swipeCell.frame.size.width, self.swipeCell.frame.size.height);
                             }
                             else
                             {
                                 self.swipeView.frame = CGRectMake(self.swipeView.frame.size.width - 5.0,self.swipeView.frame.origin.y,self.swipeView.frame.size.width, self.swipeView.frame.size.height);
                                 self.swipeCell.frame = CGRectMake(-5.0, self.swipeCell.frame.origin.y, self.swipeCell.frame.size.width, self.swipeCell.frame.size.height);
                             }
                         }
                         completion:^(BOOL finished) {
                             [UIView animateWithDuration:0.1
                                              animations:^{
                                                  if (_swipeDirection == UISwipeGestureRecognizerDirectionRight)
                                                  {
                                                      self.swipeView.frame = CGRectMake(-self.swipeView.frame.size.width + 10.0,self.swipeView.frame.origin.y,self.swipeView.frame.size.width, self.swipeView.frame.size.height);
                                                      self.swipeCell.frame = CGRectMake(10.0, self.swipeCell.frame.origin.y, self.swipeCell.frame.size.width, self.swipeCell.frame.size.height);
                                                  }
                                                  else
                                                  {
                                                      self.swipeView.frame = CGRectMake(self.swipeView.frame.size.width - 10.0,self.swipeView.frame.origin.y,self.swipeView.frame.size.width, self.swipeView.frame.size.height);
                                                      self.swipeCell.frame = CGRectMake(-10.0, self.swipeCell.frame.origin.y, self.swipeCell.frame.size.width, self.swipeCell.frame.size.height);
                                                  }
                                              } completion:^(BOOL finished) {
                                                  [UIView animateWithDuration:0.1
                                                                   animations:^{
                                                                       if (_swipeDirection == UISwipeGestureRecognizerDirectionRight)
                                                                       {
                                                                           self.swipeView.frame = CGRectMake(-self.swipeView.frame.size.width ,self.swipeView.frame.origin.y,self.swipeView.frame.size.width, self.swipeView.frame.size.height);
                                                                           self.swipeCell.frame = CGRectMake(0, self.swipeCell.frame.origin.y, self.swipeCell.frame.size.width, self.swipeCell.frame.size.height);
                                                                       }
                                                                       else
                                                                       {
                                                                           self.swipeView.frame = CGRectMake(self.swipeView.frame.size.width ,self.swipeView.frame.origin.y,self.swipeView.frame.size.width, self.swipeView.frame.size.height);
                                                                           self.swipeCell.frame = CGRectMake(0, self.swipeCell.frame.origin.y, self.swipeCell.frame.size.width, self.swipeCell.frame.size.height);
                                                                       }
                                                                   }
                                                                   completion:^(BOOL finished) {
                                                                       _animatingRemovalOfModerationSwipeView = NO;
                                                                       self.swipeCell = nil;
                                                                       [_swipeView removeFromSuperview];
                                                                        _swipeView = nil;
                                                                   }];
                                              }];
                         }];
    }
    else
    {
        [self.swipeView removeFromSuperview];
         _swipeView = nil;
        self.swipeCell.frame = CGRectMake(0,self.swipeCell.frame.origin.y,self.swipeCell.frame.size.width, self.swipeCell.frame.size.height);
        self.swipeCell = nil;
    }
}

- (void)swipe:(UISwipeGestureRecognizer *)recognizer direction:(UISwipeGestureRecognizerDirection)direction
{
    if (!self.swipeActionsEnabled) {
        return;
    }
    if (recognizer && recognizer.state == UIGestureRecognizerStateEnded)
    {
        if (_animatingRemovalOfModerationSwipeView) return;
        
        CGPoint location = [recognizer locationInView:self.tableView];
        NSIndexPath* indexPath = [self.tableView indexPathForRowAtPoint:location];
        UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:indexPath];
        
        if (cell.frame.origin.x != 0)
        {
            [self removeSwipeView:YES];
            return;
        }
        [self removeSwipeView:NO];
        
        if (cell != self.swipeCell)
        {
            [self configureSwipeView:self.swipeView forIndexPath:indexPath];
            
            [self.tableView addSubview:self.swipeView];
            self.swipeCell = cell;
            CGRect cellFrame = cell.frame;
            _swipeDirection = direction;
            self.swipeView.frame = CGRectMake(direction == UISwipeGestureRecognizerDirectionRight ? -cellFrame.size.width : cellFrame.size.width, cellFrame.origin.y, cellFrame.size.width, cellFrame.size.height);
            
            [UIView animateWithDuration:0.2 animations:^{
                self.swipeView.frame = CGRectMake(0, cellFrame.origin.y, cellFrame.size.width, cellFrame.size.height);
                cell.frame = CGRectMake(direction == UISwipeGestureRecognizerDirectionRight ? cellFrame.size.width : -cellFrame.size.width, cellFrame.origin.y, cellFrame.size.width, cellFrame.size.height);
            }];
        }
    }
}

- (void)swipeLeft:(UISwipeGestureRecognizer *)recognizer
{
    [self swipe:recognizer direction:UISwipeGestureRecognizerDirectionLeft];
}

- (void)swipeRight:(UISwipeGestureRecognizer *)recognizer
{
    [self swipe:recognizer direction:UISwipeGestureRecognizerDirectionRight];
}

#pragma mark - Infinite scrolling

- (void)enableInfiniteScrolling {
    if (_activityFooter == nil) {
        CGRect rect = CGRectMake(145.0, 10.0, 30.0, 30.0);
        _activityFooter = [[UIActivityIndicatorView alloc] initWithFrame:rect];
        _activityFooter.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
        _activityFooter.hidesWhenStopped = YES;
        _activityFooter.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        [_activityFooter stopAnimating];
    }
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, 50.0)];
    footerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [footerView addSubview:_activityFooter];
    self.tableView.tableFooterView = footerView;
}

- (void)disableInfiniteScrolling {
    self.tableView.tableFooterView = nil;
    _activityFooter = nil;
}

#pragma mark - Subclass methods

- (BOOL)userCanCreateEntity {
	return NO;
}

#define AssertSubclassMethod() NSAssert(false, @"You must override %@ in a subclass", NSStringFromSelector(_cmd))

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wreturn-type"

#define AssertNoBlogSubclassMethod() NSAssert(self.blog, @"You must override %@ in a subclass if there is no blog", NSStringFromSelector(_cmd))

- (NSString *)entityName {
    AssertSubclassMethod();
}

- (NSDate *)lastSyncDate {
    AssertSubclassMethod();
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    AssertSubclassMethod();
}

- (void)syncItemsWithUserInteraction:(BOOL)userInteraction success:(void (^)())success failure:(void (^)(NSError *))failure {
    AssertSubclassMethod();
}

- (BOOL)isSyncing {
    return _isSyncing;
}

#pragma clang diagnostic pop

- (NSFetchRequest *)fetchRequest {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:[self entityName] inManagedObjectContext:self.blog.managedObjectContext]];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"blog == %@", self.blog]];

    return fetchRequest;
}

- (NSString *)sectionNameKeyPath {
    return nil;
}

- (UITableViewCell *)newCell {
    // To comply with apple ownership and naming conventions, returned cell should have a retain count > 0, so retain the dequeued cell.
    NSString *cellIdentifier = [NSString stringWithFormat:@"_WPTable_%@_Cell", [self entityName]];
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    return cell;
}

- (BOOL)hasMoreContent {
    return NO;
}

- (void)loadMoreWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure {
    AssertSubclassMethod();
}

@end
