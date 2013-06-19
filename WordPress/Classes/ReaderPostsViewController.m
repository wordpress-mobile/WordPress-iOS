//
//  ReaderPostsViewController.m
//  WordPress
//
//  Created by Eric J on 3/21/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <DTCoreText/DTCoreText.h>
#import "ReaderPostsViewController.h"
#import "ReaderPostTableViewCell.h"
#import "ReaderTopicsViewController.h"
#import "ReaderPostDetailViewController.h"
#import "ReaderPost.h"
#import "WordPressComApi.h"
#import "WordPressAppDelegate.h"
#import "PanelNavigationConstants.h"
#import "NSString+XMLExtensions.h"
#import "ReaderReblogFormView.h"
#import "WPFriendFinderViewController.h"
#import "WPFriendFinderNudgeView.h"
#import "WPAccount.h"

NSInteger const ReaderPostsToSync = 40;
NSString *const ReaderLastSyncDateKey = @"ReaderLastSyncDate";
NSString *const WPReaderViewControllerDisplayedNativeFriendFinder = @"DisplayedNativeFriendFinder";

@interface ReaderPostsViewController ()<ReaderTopicsDelegate, ReaderTextFormDelegate> {
	BOOL _hasMoreContent;
	BOOL _loadingMore;
}

@property (nonatomic, strong) NSFetchedResultsController *resultsController;
@property (nonatomic, strong) ReaderReblogFormView *readerReblogFormView;
@property (nonatomic, strong) WPFriendFinderNudgeView *friendFinderNudgeView;
@property (nonatomic, strong) UIBarButtonItem *titleButton;
@property (nonatomic, strong) UINavigationBar *navBar;
@property (nonatomic) BOOL isShowingReblogForm;

- (NSDictionary *)currentTopic;
- (void)configureTableHeader;
- (void)fetchBlogsAndPrimaryBlog;
- (void)handleReblogButtonTapped:(id)sender;
- (void)showReblogForm;
- (void)hideReblogForm;
- (void)onSyncSuccess:(AFHTTPRequestOperation *)operation response:(id)responseObject;
- (void)onSyncFailure:(AFHTTPRequestOperation *)operation error:(NSError *)error;

@end

@implementation ReaderPostsViewController

#pragma mark - Life Cycle methods

- (void)dealloc {
	_resultsController.delegate = nil;
}


- (id)init {
	self = [super init];
	if (self) {
		// This is a convenient place to check for the user's blogs and primary blog for reblogging.
		_hasMoreContent = YES;
		[self fetchBlogsAndPrimaryBlog];
	}
	return self;
}


- (void)viewDidLoad {
	[super viewDidLoad];
	
	self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
	
	[self configureTableHeader];
	
	// Topics button
	UIBarButtonItem *button = nil;
    if ([[UIButton class] respondsToSelector:@selector(appearance)]) {
		
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [btn setImage:[UIImage imageNamed:@"navbar_read"] forState:UIControlStateNormal];
        
		UIImage *backgroundImage = [[UIImage imageNamed:@"navbar_button_bg"] stretchableImageWithLeftCapWidth:4 topCapHeight:0];
        [btn setBackgroundImage:backgroundImage forState:UIControlStateNormal];
		
        backgroundImage = [[UIImage imageNamed:@"navbar_button_bg_active"] stretchableImageWithLeftCapWidth:4 topCapHeight:0];
        [btn setBackgroundImage:backgroundImage forState:UIControlStateHighlighted];
        
        btn.frame = CGRectMake(0.0f, 0.0f, 44.0f, 30.0f);
		
        [btn addTarget:self action:@selector(handleTopicsButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        button = [[UIBarButtonItem alloc] initWithCustomView:btn];
		
    } else {
        button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemBookmarks
                                                               target:self
                                                               action:@selector(handleTopicsButtonTapped:)];
    }
	
    [button setAccessibilityLabel:NSLocalizedString(@"Topics", @"")];
    
    if ([button respondsToSelector:@selector(setTintColor:)]) {
        UIColor *color = [UIColor UIColorFromHex:0x464646];
        button.tintColor = color;
    }
    
	[self.navigationItem setRightBarButtonItem:button animated:YES];
    if (IS_IPAD) {

		self.navBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, 44.0f)];
		_navBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		[_navBar pushNavigationItem:self.navigationItem animated:NO];
		[self.view addSubview:_navBar];

		CGRect frame = self.tableView.frame;
		frame.origin.y = 44.0f;
		frame.size.height -= 44.0f;
		self.tableView.frame = frame;
    }
	
	CGRect frame = CGRectMake(0.0f, self.view.bounds.size.height, self.view.bounds.size.width, [ReaderReblogFormView desiredHeight]);
	self.readerReblogFormView = [[ReaderReblogFormView alloc] initWithFrame:frame];
	_readerReblogFormView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
	_readerReblogFormView.navigationItem = self.navigationItem;
	_readerReblogFormView.delegate = self;
	
	if (_isShowingReblogForm) {
		[self showReblogForm];
	}
	
}


- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
    [self performSelector:@selector(showFriendFinderNudgeView:) withObject:self afterDelay:3.0];
    
	self.panelNavigationController.delegate = self;
	
	NSDictionary *dict = [self currentTopic];
	NSString *title = [[dict objectForKey:@"title"] capitalizedString];
	self.title = NSLocalizedString(title, @"");
}


- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
	
    self.panelNavigationController.delegate = nil;
}


- (void)viewDidUnload {
	[super viewDidUnload];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	self.readerReblogFormView = nil;
	self.friendFinderNudgeView = nil;
	self.titleButton = nil;
	self.navBar = nil;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return [super shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}


- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	[super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
	
	CGFloat width;
	// The new width should be the window
	if (IS_IPAD) {
		width = IPAD_DETAIL_WIDTH;
	} else {
		CGRect frame = self.view.window.frame;
		width = UIInterfaceOrientationIsLandscape(toInterfaceOrientation) ? frame.size.height : frame.size.width;
	}
}


#pragma mark - Instance Methods

- (NSDictionary *)currentTopic {
	NSDictionary *topic = [[NSUserDefaults standardUserDefaults] dictionaryForKey:ReaderCurrentTopicKey];
	if(!topic) {
		topic = [[ReaderPost readerEndpoints] objectAtIndex:0];
	}
	return topic;
}


- (void)configureTableHeader {
	if ([self.resultsController.fetchedObjects count] == 0) {
		self.tableView.tableHeaderView = nil;
		return;
	}
	
	if (self.tableView.tableHeaderView != nil) {
		return;
	}
	
	UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, 10.0f)];
	paddingView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	paddingView.backgroundColor = [UIColor colorWithHexString:@"efefef"];
	self.tableView.tableHeaderView = paddingView;
}

- (void)handleTopicsButtonTapped:(id)sender {
	ReaderTopicsViewController *controller = [[ReaderTopicsViewController alloc] initWithStyle:UITableViewStyleGrouped];
	controller.delegate = self;
	
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
    if (IS_IPAD) {
        navController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
		navController.modalPresentationStyle = UIModalPresentationFormSheet;
    }
	
    [self presentModalViewController:navController animated:YES];
}


- (void)handleReblogButtonTapped:(id)sender {
	// Locate the cell this originated from. 
	UIView *v = (UIView *)sender;
	while (![v isKindOfClass:[UITableViewCell class]]) {
		v = (UIView *)v.superview;
	}
	
	NSIndexPath *selectedPath = [self.tableView indexPathForSelectedRow];
	
	UITableViewCell *cell = (UITableViewCell *)v;
	NSIndexPath *path = [self.tableView indexPathForCell:cell];
	
	// if not showing form, show the form.
	if (!selectedPath) {
		[self.tableView selectRowAtIndexPath:path animated:NO scrollPosition:UITableViewScrollPositionNone];
		[self showReblogForm];
		return;
	}
	
	// if showing form && same cell as before, dismiss the form.
	if([selectedPath compare:path] == NSOrderedSame) {
		[self hideReblogForm];
	} else {
		[self.tableView selectRowAtIndexPath:path animated:NO scrollPosition:UITableViewScrollPositionNone];
	}
}


- (void)showReblogForm {
	if (_readerReblogFormView.superview != nil) {
		return;
	}
	
	NSIndexPath *path = [self.tableView indexPathForSelectedRow];
	_readerReblogFormView.post = (ReaderPost *)[self.resultsController objectAtIndexPath:path];
	
	CGFloat reblogHeight = [ReaderReblogFormView desiredHeight];
	CGRect tableFrame = self.tableView.frame;
	tableFrame.size.height = self.tableView.frame.size.height - reblogHeight;
	self.tableView.frame = tableFrame;
	
	CGFloat y = tableFrame.origin.y + tableFrame.size.height;
	_readerReblogFormView.frame = CGRectMake(0.0f, y, self.view.bounds.size.width, reblogHeight);
	[self.view addSubview:_readerReblogFormView];
	self.isShowingReblogForm = YES;
	[_readerReblogFormView.textView becomeFirstResponder];
}


- (void)hideReblogForm {
	if(_readerReblogFormView.superview == nil) {
		return;
	}
	
	[self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:NO];
	
	CGRect tableFrame = self.tableView.frame;
	tableFrame.size.height = self.tableView.frame.size.height + _readerReblogFormView.frame.size.height;
	
	self.tableView.frame = tableFrame;
	[_readerReblogFormView removeFromSuperview];
	self.isShowingReblogForm = NO;
	[self.view endEditing:YES];
}


#pragma mark - ReaderTextForm Delegate Methods

- (void)readerTextFormDidSend:(ReaderTextFormView *)readerTextForm {
	[self hideReblogForm];
}


- (void)readerTextFormDidCancel:(ReaderTextFormView *)readerTextForm {
	[self hideReblogForm];
}


#pragma mark - UIScrollView Delegate Methods

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
	NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
	if (!selectedIndexPath) {
		return;
	}

	__block BOOL found = NO;
	[[self.tableView indexPathsForVisibleRows] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		NSIndexPath *objPath = (NSIndexPath *)obj;
		if ([objPath compare:selectedIndexPath] == NSOrderedSame) {
			found = YES;
		}
		*stop = YES;
	}];
	
	if (found) return;
	
	[self hideReblogForm];
}


#pragma mark - DetailView Delegate Methods

- (void)resetView {
	
}


#pragma mark - Sync methods

- (NSDate *)lastSyncDate {
	return (NSDate *)[[NSUserDefaults standardUserDefaults] objectForKey:ReaderLastSyncDateKey];
}


- (void)syncWithUserInteraction:(BOOL)userInteraction {	
	NSString *endpoint = [[self currentTopic] objectForKey:@"endpoint"];
	NSNumber *numberToSync = [NSNumber numberWithInteger:ReaderPostsToSync];
	NSDictionary *params = @{@"number":numberToSync, @"per_page":numberToSync};
	[ReaderPost getPostsFromEndpoint:endpoint
					  withParameters:params
							 success:^(AFHTTPRequestOperation *operation, id responseObject) {
								 [self onSyncSuccess:operation response:responseObject];
							 }
							 failure:^(AFHTTPRequestOperation *operation, NSError *error) {
								 [self onSyncFailure:operation error:error];
							 }];
}


- (void)loadMoreWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure {
	if ([self.resultsController.fetchedObjects count] == 0) {
		return;
	}
	
	if (_loadingMore) return;
	_loadingMore = YES;
	
	ReaderPost *post = self.resultsController.fetchedObjects.lastObject;
	NSNumber *numberToSync = [NSNumber numberWithInteger:ReaderPostsToSync];
	NSDictionary *params = @{@"before":[DateUtils isoStringFromDate:post.dateCreated], @"number":numberToSync, @"per_page":numberToSync};
	NSString *endpoint = [[self currentTopic] objectForKey:@"endpoint"];

	[ReaderPost getPostsFromEndpoint:endpoint
					  withParameters:params
							 success:^(AFHTTPRequestOperation *operation, id responseObject) {
								 [self onSyncSuccess:operation response:responseObject];
							 }
							 failure:^(AFHTTPRequestOperation *operation, NSError *error) {
								 [self onSyncFailure:operation error:error];
							 }];
}


- (BOOL)hasMoreContent {
	return _hasMoreContent;
}


- (void)onSyncSuccess:(AFHTTPRequestOperation *)operation response:(id)responseObject {
	_loadingMore = NO;
	[self hideRefreshHeader];
	
	NSDictionary *resp = (NSDictionary *)responseObject;
	NSArray *postsArr = [resp arrayForKey:@"posts"];
	
	if (!postsArr) {
		_hasMoreContent = NO;
		return;
	}
	
	// if # of results is less than # requested then no more content.
	if ([postsArr count] < ReaderPostsToSync) {
		_hasMoreContent = NO;
	}
	
	NSString *endpoint = [[self currentTopic] objectForKey:@"endpoint"];
	[ReaderPost syncPostsFromEndpoint:endpoint
							withArray:postsArr
						  withContext:[[WordPressAppDelegate sharedWordPressApplicationDelegate] managedObjectContext]];
	
	[[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:ReaderLastSyncDateKey];
	[NSUserDefaults resetStandardUserDefaults];
	
	if (!_loadingMore) {
		NSTimeInterval interval = - (60 * 60 * 24 * 7); // 7 days.
		[ReaderPost deletePostsSynedEarlierThan:[NSDate dateWithTimeInterval:interval sinceDate:[NSDate date]] withContext:[[WordPressAppDelegate sharedWordPressApplicationDelegate] managedObjectContext]];
	}
	
	self.resultsController = nil;
	
	[self configureTableHeader];
	
	[self.tableView reloadData];
	

}


- (void)onSyncFailure:(AFHTTPRequestOperation *)operation error:(NSError *)error {
	[self hideRefreshHeader];
	// TODO: prompt about failure.
}


#pragma mark -
#pragma mark TableView Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return [[self.resultsController sections] count];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = nil;
    sectionInfo = [[self.resultsController sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    ReaderPostTableViewCell *cell = (ReaderPostTableViewCell *)[self tableView:tableView cellForRowAtIndexPath:indexPath];
	return [cell requiredRowHeightForWidth:self.tableView.bounds.size.width tableStyle:self.tableView.style];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellIdentifier = @"ReaderPostCell";
    ReaderPostTableViewCell *cell = (ReaderPostTableViewCell *)[self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[ReaderPostTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
		cell.parentController = self;
		[cell setReblogTarget:self action:@selector(handleReblogButtonTapped:)];
    }
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	cell.accessoryType = UITableViewCellAccessoryNone;
	
	ReaderPost *post = (ReaderPost *)[self.resultsController objectAtIndexPath:indexPath];
	[cell configureCell:post];
	
    return cell;
}


- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (_readerReblogFormView.superview != nil) {
		[self hideReblogForm];
		return nil;
	}
	
	UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
	if ([cell isSelected]) {
		_readerReblogFormView.post = nil;
		[tableView deselectRowAtIndexPath:indexPath animated:NO];
		[self hideReblogForm];
		return nil;
	}
	
	return indexPath;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	ReaderPost *post = [self.resultsController.fetchedObjects objectAtIndex:indexPath.row];
	
	ReaderPostDetailViewController *controller = [[ReaderPostDetailViewController alloc] initWithPost:post];
	[self.panelNavigationController pushViewController:controller fromViewController:self animated:YES];
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
	
	NSString *entityName = @"ReaderPost";
	NSManagedObjectContext *moc = [[WordPressAppDelegate sharedWordPressApplicationDelegate] managedObjectContext];
	
	NSString *endpoint = [[self currentTopic] objectForKey:@"endpoint"];
	
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:entityName inManagedObjectContext:moc]];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"(endpoint == %@)", endpoint]];
	
    NSSortDescriptor *sortDescriptorDate = [[NSSortDescriptor alloc] initWithKey:@"sortDate" ascending:NO];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptorDate, nil];
    [fetchRequest setSortDescriptors:sortDescriptors];
	
	_resultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                             managedObjectContext:moc
                                                               sectionNameKeyPath:nil
                                                                        cacheName:nil];
	
    NSError *error = nil;
    if (![_resultsController performFetch:&error]) {
        WPFLog(@"%@ couldn't fetch %@: %@", self, entityName, [error localizedDescription]);
        _resultsController = nil;
    }
    
    return _resultsController;
}


#pragma mark - ReaderTopicsDelegate Methods

- (void)readerTopicChanged {
	_hasMoreContent = YES;
	
	self.resultsController = nil;
    [self configureTableHeader];
	
    self.titleButton.title = [self.currentTopic objectForKey:@"title"];
    
    [self.tableView reloadData];
    if ( [WordPressAppDelegate sharedWordPressApplicationDelegate].connectionAvailable == YES && ![self isSyncing] ) {
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:ReaderLastSyncDateKey];
		[NSUserDefaults resetStandardUserDefaults];

        [self simulatePullToRefresh];
    }
	
	[self.tableView setContentOffset:CGPointZero animated:NO];
}


#pragma mark - Utility

- (void)fetchBlogsAndPrimaryBlog {
	
	NSURL *xmlrpc;
    NSString *username, *password;
    WPAccount *account = [WPAccount defaultWordPressComAccount];
	xmlrpc = [NSURL URLWithString:@"https://wordpress.com/xmlrpc.php"];
	username = account.username;
	password = account.password;
	
    WPXMLRPCClient *api = [WPXMLRPCClient clientWithXMLRPCEndpoint:xmlrpc];
    [api callMethod:@"wp.getUsersBlogs"
         parameters:[NSArray arrayWithObjects:username, password, nil]
            success:^(AFHTTPRequestOperation *operation, id responseObject) {
                NSArray *usersBlogs = responseObject;
				
                if([usersBlogs count] > 0) {
					
                    [usersBlogs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                        NSString *title = [obj valueForKey:@"blogName"];
                        title = [title stringByDecodingXMLCharacters];
                        [obj setValue:title forKey:@"blogName"];
                    }];
                    
                }
				
				[[NSUserDefaults standardUserDefaults] setObject:usersBlogs forKey:@"wpcom_users_blogs"];
				
				if ([usersBlogs count] == 1) {
					NSDictionary *dict = [usersBlogs objectAtIndex:0];
					[[NSUserDefaults standardUserDefaults] setObject:[dict numberForKey:@"blogid"] forKey:@"wpcom_users_prefered_blog_id"];
					[NSUserDefaults resetStandardUserDefaults];
				} else if ([usersBlogs count] > 1) {
					
					[[WordPressComApi sharedApi] getPath:@"me"
											  parameters:nil
												 success:^(AFHTTPRequestOperation *operation, id responseObject) {
													 NSDictionary *dict = (NSDictionary *)responseObject;
													 NSNumber *primaryBlog = [dict objectForKey:@"primary_blog"];
													 [usersBlogs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
														 if ([primaryBlog isEqualToNumber:[obj numberForKey:@"blogid"]]) {
															 [[NSUserDefaults standardUserDefaults] setObject:[obj numberForKey:@"blogid"] forKey:@"wpcom_users_prefered_blog_id"];
															 [NSUserDefaults resetStandardUserDefaults];
															 *stop = YES;
														 }
													 }];
												 } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
													 // TODO: Handle Failure. Retry maybe?
												 }];
					
					
				}
				
			} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
				// Fail silently.
            }];

}


#pragma mark - Friend Finder Button

- (BOOL) shouldDisplayfriendFinderNudgeView {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return ![userDefaults boolForKey:WPReaderViewControllerDisplayedNativeFriendFinder] && self.friendFinderNudgeView == nil;
}


- (void) showFriendFinderNudgeView:(id)sender {
    if ([self shouldDisplayfriendFinderNudgeView]) {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        
        [userDefaults setBool:YES forKey:WPReaderViewControllerDisplayedNativeFriendFinder];
        [userDefaults synchronize];
        
        CGRect buttonFrame = CGRectMake(0,self.view.frame.size.height,self.view.frame.size.width, 0.f);
        WPFriendFinderNudgeView *nudgeView = [[WPFriendFinderNudgeView alloc] initWithFrame:buttonFrame];
        self.friendFinderNudgeView = nudgeView;
        self.friendFinderNudgeView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        [self.view addSubview:self.friendFinderNudgeView];
        
        buttonFrame = self.friendFinderNudgeView.frame;
        CGRect viewFrame = self.view.frame;
        buttonFrame.origin.y = viewFrame.size.height - buttonFrame.size.height + 1.f;
        
        [self.friendFinderNudgeView.cancelButton addTarget:self action:@selector(hideFriendFinderNudgeView:) forControlEvents:UIControlEventTouchUpInside];
        [self.friendFinderNudgeView.confirmButton addTarget:self action:@selector(openFriendFinder:) forControlEvents:UIControlEventTouchUpInside];
        
        [UIView animateWithDuration:0.2 animations:^{
            self.friendFinderNudgeView.frame = buttonFrame;
        }];
    }
}


- (void) hideFriendFinderNudgeView:(id)sender {
    if (self.friendFinderNudgeView == nil) {
        return;
    }
    
    CGRect buttonFrame = self.friendFinderNudgeView.frame;
    CGRect viewFrame = self.view.frame;
    buttonFrame.origin.y = viewFrame.size.height + 1.f;
    [UIView animateWithDuration:0.1 animations:^{
        self.friendFinderNudgeView.frame = buttonFrame;
    } completion:^(BOOL finished) {
        [self.friendFinderNudgeView removeFromSuperview];
        self.friendFinderNudgeView = nil;
    }];
}


- (void)openFriendFinder:(id)sender {
    [self hideFriendFinderNudgeView:sender];
    WPFriendFinderViewController *controller = [[WPFriendFinderViewController alloc] initWithNibName:@"WPReaderViewController" bundle:nil];
	
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
    if (IS_IPAD) {
        navController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
		navController.modalPresentationStyle = UIModalPresentationFormSheet;
    }
	
    [self presentModalViewController:navController animated:YES];
    
    [controller loadURL:kMobileReaderFFURL];
}

@end
