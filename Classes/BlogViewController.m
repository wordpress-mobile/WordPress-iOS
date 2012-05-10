//
//  BlogViewController.m
//  WordPress
//
//  Created by Josh Bassett on 8/07/09.
//

#import "BlogViewController.h"
#import "WordPressAppDelegate.h"
#import "NSString+XMLExtensions.h" 

@implementation BlogViewController

@synthesize tabBarController, blog, selectedIndex;

- (void)viewDidLoad {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [super viewDidLoad];

    commentsItem.title = NSLocalizedString(@"Comments", @"");
    postsItem.title = NSLocalizedString(@"Posts", @"");
    pagesItem.title = NSLocalizedString(@"Pages", @"");
    statsItem.title = NSLocalizedString(@"Stats", @"");

    postsViewController.blog = self.blog;
    pagesViewController.blog = self.blog;
    commentsViewController.blog = self.blog;
	//uncomment me to add stats back
	statsTableViewController.blog = self.blog;
	
    tabBarController.view.frame = self.view.bounds;
    [self.view addSubview:tabBarController.view];
	
	if ([blog valueForKey:@"blogName"] != nil)
		self.title = [blog valueForKey:@"blogName"];
	else
       self.title = [blog hostURL];
	
	if (DeviceIsPad() == NO) {
		self.navigationItem.rightBarButtonItem = commentsViewController.editButtonItem;
	}
    tabBarController.selectedIndex = self.selectedIndex;
    [self tabBarController:tabBarController didSelectViewController:tabBarController.selectedViewController];
}

- (void)viewWillAppear:(BOOL)animated {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [super viewWillAppear:animated];
    
	if (DeviceIsPad() == YES) {
		[self restoreState];
	} else {
		[tabBarController.selectedViewController viewWillAppear:animated];
	}
}

- (void)viewDidUnload {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
	self.selectedIndex = tabBarController.selectedIndex;
    [commentsItem release]; commentsItem = nil;
    [postsItem release]; postsItem = nil;
    [pagesItem release]; pagesItem = nil;
    [statsItem release]; statsItem = nil;
	[super viewDidUnload];
}

- (void) viewWillDisappear:(BOOL)animated{
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
	[super viewWillDisappear:animated];
	[commentsViewController viewWillDisappear:animated];
	[postsViewController viewWillDisappear:animated];
	[pagesViewController viewWillDisappear:animated];
	//uncomment me to add stats back
	[statsTableViewController viewWillDisappear:animated];
}

- (void)dealloc {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[tabBarController release], tabBarController = nil;
    [postsViewController release]; postsViewController = nil;
    [pagesViewController release]; pagesViewController = nil;
    [commentsViewController release]; commentsViewController = nil;
    [statsTableViewController release]; statsTableViewController = nil;
    [splitViewController release]; splitViewController = nil;
    self.blog = nil;
	
    [super dealloc];
}

- (void)showCommentWithId:(NSNumber *)commentId {
    [self view]; // Force XIB outlet load
    [self.tabBarController setSelectedViewController:commentsViewController];
    [self configureCommentsTab];
    commentsViewController.wantedCommentId = commentId;
}

#pragma mark -
#pragma mark UITabBarControllerDelegate Methods

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
    return YES;
}

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
	self.navigationItem.titleView = nil;
	self.navigationItem.rightBarButtonItem = nil;
	if (viewController == postsViewController) {
		[[NSUserDefaults standardUserDefaults] setValue:@"Posts" forKey:@"WPSelectedContentType"];
		self.navigationItem.rightBarButtonItem = postsViewController.composeButtonItem;
	} 
	else if (viewController == pagesViewController) {
		[[NSUserDefaults standardUserDefaults] setValue:@"Pages" forKey:@"WPSelectedContentType"];
		self.navigationItem.rightBarButtonItem = pagesViewController.composeButtonItem;
	} 
	else if (viewController == commentsViewController) {
		[self configureCommentsTab];
	}
	else if (viewController == statsTableViewController) {
		[[NSUserDefaults standardUserDefaults] setValue:@"Stats" forKey:@"WPSelectedContentType"];
	}
	
    [viewController viewWillAppear:NO];
}

- (void)configureCommentsTab {
	[[NSUserDefaults standardUserDefaults] setValue:@"Comments" forKey:@"WPSelectedContentType"];
	[commentsViewController setIndexForCurrentPost:-2];
	//force commentViewController to nil, fixes trac #754
	commentsViewController.commentViewController = nil;
	self.navigationItem.rightBarButtonItem = commentsViewController.editButtonItem;
}

#pragma mark KVO callbacks

- (void)refreshBlogs:(NSNotification *)notification {
	UIViewController *viewController = tabBarController.selectedViewController;
	if (viewController == postsViewController) {
		[postsViewController.tableView reloadData];
	}
	else if (viewController == pagesViewController) {
		[pagesViewController.tableView reloadData];
	}
}

- (void)reselect {
	if ([tabBarController.selectedViewController respondsToSelector:@selector(reselect)])
		[tabBarController.selectedViewController performSelector:@selector(reselect)];
}

#pragma mark State saving

- (void)saveState;
{
	NSIndexPath *indexPath = [NSIndexPath indexPathWithIndex:0];
	BOOL hasIndexPath = NO;
	NSString *vcName = [[NSUserDefaults standardUserDefaults] objectForKey:@"WPSelectedContentType"];
	if ([vcName isEqual:@"Comments"]) {
		indexPath = commentsViewController.selectedIndexPath;
		hasIndexPath = YES;
	}
	else if	([vcName isEqual:@"Posts"]) {
		indexPath = postsViewController.selectedIndexPath;
		hasIndexPath = YES;
	}
	else if	([vcName isEqual:@"Pages"]) {
		indexPath = pagesViewController.selectedIndexPath;
		hasIndexPath = YES;
	}
	
	if (hasIndexPath == YES) {
		[[NSUserDefaults standardUserDefaults] setInteger:indexPath.section forKey:@"WPSelectedIndexPathSection"];
		[[NSUserDefaults standardUserDefaults] setInteger:indexPath.row forKey:@"WPSelectedIndexPathRow"];
	}
}

- (void)restoreState;
{
	if (stateRestored) {
		[tabBarController.selectedViewController viewWillAppear:YES];
		return;
	}
	
	NSString *vcName = [[NSUserDefaults standardUserDefaults] objectForKey:@"WPSelectedContentType"];
	self.selectedIndex = 0;
	if (vcName) {
		int section = [[NSUserDefaults standardUserDefaults] integerForKey:@"WPSelectedIndexPathSection"];
		int row = [[NSUserDefaults standardUserDefaults] integerForKey:@"WPSelectedIndexPathRow"];
		NSIndexPath *selectedIndexPath = [NSIndexPath indexPathForRow:row inSection:section];
		if ([vcName isEqual:@"Comments"]) {
			self.selectedIndex = 2;
			commentsViewController.selectedIndexPath = selectedIndexPath;
		}
		else if	([vcName isEqual:@"Posts"]) {
			self.selectedIndex = 0;
			postsViewController.selectedIndexPath = selectedIndexPath;
		}
		else if	([vcName isEqual:@"Pages"]) {
			self.selectedIndex = 1;
			pagesViewController.selectedIndexPath = selectedIndexPath;
		}
		//uncomment me to add stats back
		else if	([vcName isEqual:@"Stats"]) {
			self.selectedIndex = 3;
		}
	}
		
	// show the view controller
	if (self.selectedIndex) {
		self.tabBarController.selectedIndex = self.selectedIndex;
		[self tabBarController:self.tabBarController didSelectViewController:self.tabBarController.selectedViewController];
	}
	stateRestored = YES;
}

@end
