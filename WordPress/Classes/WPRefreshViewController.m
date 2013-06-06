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
	CGFloat keyboardOffset;
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
	
	self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
	_tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	_tableView.dataSource = self;
	_tableView.delegate = self;
	[self.view addSubview:_tableView];
	
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
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardDidShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
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
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
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


- (void)handleKeyboardDidShow:(NSNotification *)notification {
	CGRect frame = self.view.frame;
	CGRect startFrame = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
	CGRect endFrame = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
	
	CGPoint point = [self.view.window convertPoint:CGPointMake(0.0f, frame.size.height) fromView:self.view];
	keyboardOffset = startFrame.origin.y - point.y;
	
	point = [self.view.window convertPoint:endFrame.origin toView:self.view];
	frame.size.height = point.y;
	
	// TODO: There is a bug with rotation that we need to sort out :/
	[UIView animateWithDuration:0.3 animations:^{
		self.view.frame = frame;
	}];
}


- (void)handleKeyboardWillHide:(NSNotification *)notification {
	CGRect frame = self.view.frame;
	CGRect keyFrame = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
	
	CGPoint point = keyFrame.origin;
	point.y -= keyboardOffset;
	
	point = [self.view.window convertPoint:point toView:self.view];
	frame.size.height = point.y;
	
	[UIView animateWithDuration:0.3 animations:^{
		self.view.frame = frame;
	}];
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
