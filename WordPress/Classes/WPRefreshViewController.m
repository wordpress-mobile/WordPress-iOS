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

@property (nonatomic, strong) UIActivityIndicatorView *activityFooter;

- (void)enableInfiniteScrolling;
- (void)disableInfiniteScrolling;

@end

NSTimeInterval const WPRefreshViewControllerRefreshTimeout = 300; // 5 minutes

@implementation WPRefreshViewController {
	CGPoint savedScrollOffset;
	CGFloat keyboardOffset;
	BOOL _infiniteScrollEnabled;
}

#pragma mark - LifeCycle Methods

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
	_tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	_tableView.dataSource = self;
	_tableView.delegate = self;
	[self.view addSubview:_tableView];
	
	if (self.infiniteScrollEnabled) {
        [self enableInfiniteScrolling];
    }
}


- (void)viewDidUnload {
	[super viewDidUnload];
	
	self.activityFooter = nil;
	self.tableView = nil;
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
		[self syncWithUserInteraction:NO];
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

- (void)handleKeyboardDidShow:(NSNotification *)notification {
	CGRect frame = self.view.frame;
	CGRect startFrame = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
	CGRect endFrame = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
	
	// Figure out the difference between the bottom of this view, and the top of the keyboard.
	// This should account for any toolbars.
	CGPoint point = [self.view.window convertPoint:startFrame.origin toView:self.view];
	keyboardOffset = point.y - (frame.origin.y + frame.size.height);
	
	// if we're upside down, we need to adjust the origin.
	if (endFrame.origin.x == 0 && endFrame.origin.y == 0) {
		endFrame.origin.y = endFrame.origin.x += MIN(endFrame.size.height, endFrame.size.width);
	}
	
	point = [self.view.window convertPoint:endFrame.origin toView:self.view];
	frame.size.height = point.y;
	
	[UIView animateWithDuration:0.3f delay:0.0f options:UIViewAnimationOptionBeginFromCurrentState animations:^{
		self.view.frame = frame;
	} completion:^(BOOL finished) {
		// BUG: When dismissing a modal view, and the keyboard is showing again, the animation can get clobbered in some cases.
		// When this happens the view is set to the dimensions of its wrapper view, hiding content that should be visible
		// above the keyboard.
		// For now use a fallback animation.
		if (CGRectEqualToRect(self.view.frame, frame) == false) {
			[UIView animateWithDuration:0.3 animations:^{
				self.view.frame = frame;
			}];
		}
	}];
}


- (void)handleKeyboardWillHide:(NSNotification *)notification {
	CGRect frame = self.view.frame;
	CGRect keyFrame = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];

	CGPoint point = [self.view.window convertPoint:keyFrame.origin toView:self.view];
	frame.size.height = point.y - (frame.origin.y + keyboardOffset);
	self.view.frame = frame;
}


#pragma mark - Sync methods

- (BOOL)isSyncing {
    return _isSyncing;
}


- (NSDate *)lastSyncDate {
	// Should be overridden
	return nil;
}


- (BOOL)hasMoreContent {
    return NO;
}


- (void)syncWithUserInteraction:(BOOL)userInteraction {
	// should be overridden
}


- (void)loadMoreWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure {
    // should be overridden
}


#pragma mark - Infinite Scrolling

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


- (void)enableInfiniteScrolling {
    if (_activityFooter == nil) {
        CGRect rect = CGRectMake(145.0f, 10.0f, 30.0f, 30.0f);
        _activityFooter = [[UIActivityIndicatorView alloc] initWithFrame:rect];
        _activityFooter.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
        _activityFooter.hidesWhenStopped = YES;
        _activityFooter.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        [_activityFooter stopAnimating];
    }
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 320.0f, 50.0f)];
    footerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [footerView addSubview:_activityFooter];
    self.tableView.tableFooterView = footerView;
}


- (void)disableInfiniteScrolling {
    self.tableView.tableFooterView = nil;
    _activityFooter = nil;
}


#pragma mark - UITableView Delegate Methods

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (IS_IPAD == YES) {
		cell.accessoryType = UITableViewCellAccessoryNone;
	}
	
    // Are we approaching the end of the table?
    if ((indexPath.section + 1 == [self numberOfSectionsInTableView:tableView]) &&
		(indexPath.row + 4 >= [self tableView:tableView numberOfRowsInSection:indexPath.section]) &&
		[self tableView:tableView numberOfRowsInSection:indexPath.section] > 10) {
        
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


#pragma mark -
#pragma mark UIScrollViewDelegate Methods

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (self.panelNavigationController) {
        [self.panelNavigationController viewControllerWantsToBeFullyVisible:self];
    }
}


@end
