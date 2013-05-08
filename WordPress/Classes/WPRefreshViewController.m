//
//  WPRefreshViewController.m
//  WordPress
//
//  Created by Eric J on 4/19/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "WPRefreshViewController.h"
#import "SoundUtil.h"
#import "WordPressAppDelegate.h"

@interface WPRefreshViewController ()
@end

NSTimeInterval const WPRefreshViewControllerRefreshTimeout = 300; // 5 minutes

@implementation WPRefreshViewController {
	CGPoint savedScrollOffset;
}


#pragma mark - LifeCycle Methods

- (void)dealloc {
	[self doBeforeDealloc];
}

- (void)doBeforeDealloc {
    if([self.tableView observationInfo]) {
        [self.tableView removeObserver:self forKeyPath:@"contentOffset"];
	}
}

- (void)viewDidLoad {
    [super viewDidLoad];

	if (_refreshHeaderView == nil) {
		_refreshHeaderView = [[EGORefreshTableHeaderView alloc] initWithFrame:CGRectMake(0.0f, 0.0f - self.tableView.bounds.size.height, self.view.frame.size.width, self.tableView.bounds.size.height)];
		_refreshHeaderView.delegate = self;
		[self.tableView addSubview:_refreshHeaderView];
    }
	
	[self.tableView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];
    
	//  update the last update date
	[_refreshHeaderView refreshLastUpdatedDate];
}


- (void)viewDidUnload {
	if([self.tableView observationInfo]) {
        [self.tableView removeObserver:self forKeyPath:@"contentOffset"];
    }
	
	[super viewDidUnload];
	
	_refreshHeaderView = nil;
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    CGSize contentSize = self.tableView.contentSize;
    if(contentSize.height > savedScrollOffset.y) {
        [self.tableView scrollRectToVisible:CGRectMake(savedScrollOffset.x, savedScrollOffset.y, 0.0f, 0.0f) animated:NO];
    } else {
        [self.tableView scrollRectToVisible:CGRectMake(0.0f, contentSize.height, 0.0f, 0.0f) animated:NO];
    }
}


- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	
	WordPressAppDelegate *appDelegate = [WordPressAppDelegate sharedWordPressApplicationDelegate];
    if( appDelegate.connectionAvailable == NO ) return; //do not start auto-sync if connection is down
	
    // Don't try to refresh if we just canceled editing credentials
    if (didPromptForCredentials) {
        return;
    }
    NSDate *lastSynced = [self lastSyncDate];
    if (lastSynced == nil || ABS([lastSynced timeIntervalSinceNow]) > WPRefreshViewControllerRefreshTimeout) {
        // If table is at the original scroll position, simulate a pull to refresh
        if (self.tableView.contentOffset.y == 0.0f) {
            [self simulatePullToRefresh];
        } else {
			// Otherwise, just update in the background
            [self syncWithUserInteraction:NO];
        }
    }
}


- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (IS_IPHONE) {
        savedScrollOffset = self.tableView.contentOffset;
    }
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return [super shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}


#pragma mark - Instance Methods

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
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


#pragma mark - Sync methods

- (void)hideRefreshHeader {
    [_refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:self.tableView];
    if ([self isViewLoaded] && self.view.window && didTriggerRefresh) {
        [SoundUtil playRollupSound];
    }
    didTriggerRefresh = NO;
}


- (void)simulatePullToRefresh {
    if(!_refreshHeaderView) return;
    
    CGPoint offset = self.tableView.contentOffset;
    offset.y = - 65.0f;
    [self.tableView setContentOffset:offset];
    [_refreshHeaderView egoRefreshScrollViewDidEndDragging:self.tableView];
}


- (BOOL)isSyncing {
    return _isSyncing;
}


- (NSDate *)lastSyncDate {
	// Should be overridden
	return nil;
}


- (void)syncWithUserInteraction:(BOOL)userInteraction {
	// should be overridden
}


#pragma mark - EGORefreshTableHeaderDelegate Methods

- (void)egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView *)view {
    didTriggerRefresh = YES;
	[self syncWithUserInteraction:YES];
}


- (BOOL)egoRefreshTableHeaderDataSourceIsLoading:(EGORefreshTableHeaderView *)view {
	return [self isSyncing]; // should return if data source model is reloading
}


- (NSDate*)egoRefreshTableHeaderDataSourceLastUpdated:(EGORefreshTableHeaderView *)view {
	return [self lastSyncDate]; // should return date data source was last changed
}


#pragma mark -
#pragma mark UIScrollViewDelegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	if (!self.editing)
        [_refreshHeaderView egoRefreshScrollViewDidScroll:scrollView];
}


- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
	if (!self.editing)
		[_refreshHeaderView egoRefreshScrollViewDidEndDragging:scrollView];
}


- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (self.panelNavigationController) {
        [self.panelNavigationController viewControllerWantsToBeFullyVisible:self];
    }
}


@end
