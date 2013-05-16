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

NSString *const ReaderLastSyncDateKey = @"ReaderLastSyncDate";

@interface ReaderPostsViewController ()<ReaderTopicsDelegate>

@property (nonatomic, strong) NSArray *rowHeights;
@property (nonatomic, strong) NSFetchedResultsController *resultsController;

- (NSDictionary *)currentTopic;
- (void)updateRowHeightsForWidth:(CGFloat)width;

@end

@implementation ReaderPostsViewController

@synthesize rowHeights;

#pragma mark - Life Cycle methods

- (void)doBeforeDealloc {
	[super doBeforeDealloc];
	_resultsController.delegate = nil;
}


- (void)viewDidLoad {
	[super viewDidLoad];
	
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
        self.toolbarItems = [NSArray arrayWithObjects:button, nil];
    }
    
	// Compute row heights now for smoother scrolling later.
	[self updateRowHeightsForWidth:self.tableView.frame.size.width];
	
}


- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	self.panelNavigationController.delegate = self;
	
	NSDictionary *dict = [self currentTopic];
	NSString *title = [dict objectForKey:@"title"];
	self.title = NSLocalizedString(title, @"");

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
    }
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	cell.accessoryType = UITableViewCellAccessoryNone;
	
	ReaderPost *post = (ReaderPost *)[self.resultsController objectAtIndexPath:indexPath];
	[cell configureCell:post];
	
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	ReaderPost *post = [self.resultsController.fetchedObjects objectAtIndex:indexPath.row];
	
	ReaderPostDetailViewController *controller = [[ReaderPostDetailViewController alloc] initWithPost:post];
	
	[self.panelNavigationController pushViewController:controller animated:YES];
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
	[self updateRowHeightsForWidth:self.tableView.frame.size.width];
    [self.tableView reloadData];
    if ( [WordPressAppDelegate sharedWordPressApplicationDelegate].connectionAvailable == YES && [self.resultsController.fetchedObjects count] == 0 && ![self isSyncing] ) {
        [self simulatePullToRefresh];
    }
}


@end
