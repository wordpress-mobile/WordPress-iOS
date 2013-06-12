//
//  ReaderPostsViewController.m
//  WordPress
//
//  Created by Eric J on 3/21/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "ReaderPostsViewController.h"
#import "ReaderPostTableViewCell.h"
#import "ReaderTopicsViewController.h"
#import "ReaderPostDetailViewController.h"
#import "ReaderPost.h"
#import "WordPressComApi.h"
#import "WordPressAppDelegate.h"
#import "PanelNavigationConstants.h"
#import "SFHFKeychainUtils.h"
#import "NSString+XMLExtensions.h"
#import "ReaderReblogFormView.h"
#import "WPFriendFinderViewController.h"
#import "WPFriendFinderNudgeView.h"

NSString *const ReaderLastSyncDateKey = @"ReaderLastSyncDate";
NSString *const WPReaderViewControllerDisplayedNativeFriendFinder = @"DisplayedNativeFriendFinder";

@interface ReaderPostsViewController ()<ReaderTopicsDelegate, ReaderTextFormDelegate>

@property (nonatomic, strong) NSArray *rowHeights;
@property (nonatomic, strong) NSFetchedResultsController *resultsController;
@property (nonatomic, strong) ReaderReblogFormView *readerReblogFormView;
@property (nonatomic) BOOL isShowingReblogForm;
@property (nonatomic) BOOL isShowingKeyboard;
@property (nonatomic) BOOL shouldShowKeyboard;
@property (nonatomic, strong) WPFriendFinderNudgeView *friendFinderNudgeView;
@property (nonatomic, strong) UIBarButtonItem *titleButton;

- (NSDictionary *)currentTopic;
- (void)updateRowHeightsForWidth:(CGFloat)width;
- (void)fetchBlogsAndPrimaryBlog;
- (void)handleReblogButtonTapped:(id)sender;

@end

@implementation ReaderPostsViewController

@synthesize rowHeights;

#pragma mark - Life Cycle methods

- (void)doBeforeDealloc {
	[super doBeforeDealloc];
	_resultsController.delegate = nil;
}


- (id)init {
	self = [super init];
	if (self) {
		// This is a convenient place to check for the user's blogs and primary blog for reblogging.
		[self fetchBlogsAndPrimaryBlog];
	}
	return self;
}


- (void)viewDidLoad {
	[super viewDidLoad];
	
	self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
	
	UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, 10.0f)];
	paddingView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	paddingView.backgroundColor = [UIColor colorWithHexString:@"efefef"];
	self.tableView.tableHeaderView = paddingView;
	
	
	// Topics button
	UIBarButtonItem *button = nil;
    if (IS_IPHONE && [[UIButton class] respondsToSelector:@selector(appearance)]) {
		
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
    
    if (IS_IPHONE) {
        [self.navigationItem setRightBarButtonItem:button animated:YES];
    } else {
        self.titleButton = [[UIBarButtonItem alloc] initWithTitle:[self.currentTopic objectForKey:@"title"]
                                                       style:UIBarButtonItemStylePlain
                                                      target:self
                                                      action:@selector(handleTopicsButtonTapped:)];
        
        UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                                                                                target:nil
                                                                                action:nil];
        spacer.width = 8.0f;
        self.toolbarItems = [NSArray arrayWithObjects:button, spacer, self.titleButton, nil];
    }
    
	
	CGRect frame = CGRectMake(0.0f, self.view.bounds.size.height, self.view.bounds.size.width, [ReaderReblogFormView desiredHeight]);
	self.readerReblogFormView = [[ReaderReblogFormView alloc] initWithFrame:frame];
	_readerReblogFormView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
	_readerReblogFormView.navigationItem = self.navigationItem;
	_readerReblogFormView.delegate = self;
	
	// Compute row heights now for smoother scrolling later.
	[self updateRowHeightsForWidth:self.tableView.frame.size.width];
}


- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
    if (IS_IPAD)
        [self.panelNavigationController setToolbarHidden:NO forViewController:self animated:NO];
    
    [self performSelector:@selector(showFriendFinderNudgeView:) withObject:self afterDelay:3.0];
    
	self.panelNavigationController.delegate = self;
	
	NSDictionary *dict = [self currentTopic];
	NSString *title = [[dict objectForKey:@"title"] capitalizedString];
	self.title = NSLocalizedString(title, @"");
	[self updateRowHeightsForWidth:self.tableView.frame.size.width];
}


- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
	
    self.panelNavigationController.delegate = nil;
}


- (void)viewDidUnload {
	[super viewDidUnload];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
	
	[self updateRowHeightsForWidth:width];
}


#pragma mark - Instance Methods

- (NSDictionary *)currentTopic {
	NSDictionary *topic = [[NSUserDefaults standardUserDefaults] dictionaryForKey:ReaderCurrentTopicKey];
	if(!topic) {
		topic = [[ReaderPost readerEndpoints] objectAtIndex:0];
	}
	return topic;
}


- (void)updateRowHeightsForWidth:(CGFloat)width {
	self.rowHeights = [ReaderPostTableViewCell cellHeightsForPosts:self.resultsController.fetchedObjects
															 width:width
														tableStyle:UITableViewStylePlain
														 cellStyle:UITableViewCellStyleDefault
												   reuseIdentifier:@"ReaderPostCell"];

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
		[self showReblogForm:YES];
		
		return;
	}
	
	// if showing form && same cell as before, dismiss the form.
	if([selectedPath compare:path] == NSOrderedSame) {
		[self hideReblogForm:YES];
	} else {
		[self.tableView selectRowAtIndexPath:path animated:NO scrollPosition:UITableViewScrollPositionNone];
	}
}


- (void)showReblogForm:(BOOL)animated {

	if (_readerReblogFormView.superview == nil) {
		CGRect frame = CGRectMake(0.0f, self.view.bounds.size.height, self.view.bounds.size.width, [ReaderReblogFormView desiredHeight]);
		_readerReblogFormView.frame = frame;
		[self.view addSubview:_readerReblogFormView];
	}
	
	NSIndexPath *path = [self.tableView indexPathForSelectedRow];
	_readerReblogFormView.post = (ReaderPost *)[self.resultsController objectAtIndexPath:path];
	
	if (_isShowingReblogForm) {
		[_readerReblogFormView.textView becomeFirstResponder];
		return;
	}
	
	self.isShowingReblogForm = YES;
	CGRect formFrame = _readerReblogFormView.frame;
	CGRect tableFrame = self.tableView.frame;
	tableFrame.size.height = self.view.bounds.size.height - formFrame.size.height;
	formFrame.origin.y = tableFrame.origin.y + tableFrame.size.height;
	
	self.tableView.frame = tableFrame;
	_readerReblogFormView.frame = formFrame;
	[_readerReblogFormView.textView becomeFirstResponder];
}


- (void)hideReblogForm:(BOOL)animated {
	if(!_isShowingReblogForm) {
		return;
	}
	
	[self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:NO];
	
	CGRect formFrame = _readerReblogFormView.frame;
	CGRect tableFrame = self.tableView.frame;
	tableFrame.size.height = self.view.bounds.size.height;
	formFrame.origin.y = tableFrame.origin.y + tableFrame.size.height;
	
	if (!animated) {
		self.tableView.frame = tableFrame;
		_readerReblogFormView.frame = formFrame;
		self.isShowingReblogForm = NO;
		return;
	}

	[UIView animateWithDuration:0.3 animations:^{
		self.tableView.frame = tableFrame;
		_readerReblogFormView.frame = formFrame;
	} completion:^(BOOL finished) {
		self.isShowingReblogForm = NO;

		// Remove the view so we don't glympse it on the iPad when rotating
		[_readerReblogFormView removeFromSuperview];
	}];
}


#pragma mark - ReaderTextForm Delegate Methods

- (void)readerTextFormDidSend:(ReaderTextFormView *)readerTextForm {
	
}


- (void)readerTextFormDidBeginEditing:(ReaderTextFormView *)readerTextForm {
	self.isShowingKeyboard = YES;
}


- (void)readerTextFormDidChange:(ReaderTextFormView *)readerTextForm {
	
}


- (void)readerTextFormDidEndEditing:(ReaderTextFormView *)readerTextForm {
	self.isShowingKeyboard = NO;
	
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
	
	[self hideReblogForm:YES];
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
	
	[ReaderPost getPostsFromEndpoint:endpoint
					  withParameters:nil
							 success:^(AFHTTPRequestOperation *operation, id responseObject) {
								 
								 NSDictionary *resp = (NSDictionary *)responseObject;
								 NSArray *postsArr = [resp objectForKey:@"posts"];
								 
								 [ReaderPost syncPostsFromEndpoint:endpoint
														 withArray:postsArr
													   withContext:[[WordPressAppDelegate sharedWordPressApplicationDelegate] managedObjectContext]];
								 
								 [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:ReaderLastSyncDateKey];
								 [NSUserDefaults resetStandardUserDefaults];
								 
								 NSTimeInterval interval = - (60 * 60 * 24 * 7); // 7 days.
								 [ReaderPost deletePostsSynedEarlierThan:[NSDate dateWithTimeInterval:interval sinceDate:[NSDate date]] withContext:[[WordPressAppDelegate sharedWordPressApplicationDelegate] managedObjectContext]];
								 
								 self.resultsController = nil;
								 [self updateRowHeightsForWidth:self.tableView.frame.size.width];
								 [self.tableView reloadData];
								 
								 [self hideRefreshHeader];
							 }
							 failure:^(AFHTTPRequestOperation *operation, NSError *error) {
								 [self hideRefreshHeader];
								 // TODO:
							 }];

}


- (void)loadMoreWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure {
	
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
	return [(NSNumber *)[self.rowHeights objectAtIndex:indexPath.row] floatValue];
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
	if (_isShowingKeyboard) {
		[self.view endEditing:YES];
		return nil;
	}
	
	UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
	if ([cell isSelected]) {
		_readerReblogFormView.post = nil;
		[tableView deselectRowAtIndexPath:indexPath animated:NO];
		[self hideReblogForm:YES];
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
	self.resultsController = nil;
    
    self.titleButton.title = [self.currentTopic objectForKey:@"title"];
    
	[self updateRowHeightsForWidth:self.tableView.frame.size.width];
    [self.tableView reloadData];
    if ( [WordPressAppDelegate sharedWordPressApplicationDelegate].connectionAvailable == YES && [self.resultsController.fetchedObjects count] == 0 && ![self isSyncing] ) {
        [self simulatePullToRefresh];
    }
}


#pragma mark - Utility

- (void)fetchBlogsAndPrimaryBlog {
	
	NSURL *xmlrpc;
    NSString *username, *password;
	NSError *error = nil;
	xmlrpc = [NSURL URLWithString:@"https://wordpress.com/xmlrpc.php"];
	username = [[NSUserDefaults standardUserDefaults] objectForKey:@"wpcom_username_preference"];
	password = [SFHFKeychainUtils getPasswordForUsername:username
										  andServiceName:@"WordPress.com"
												   error:&error];
	
    WPXMLRPCClient *api = [WPXMLRPCClient clientWithXMLRPCEndpoint:xmlrpc];
    [api callMethod:@"wp.getUsersBlogs"
         parameters:[NSArray arrayWithObjects:username, password, nil]
            success:^(AFHTTPRequestOperation *operation, id responseObject) {
                NSArray *usersBlogs = responseObject;
				
                if(usersBlogs.count > 0) {
					
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
