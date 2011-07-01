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

@synthesize tabBarController, blog, selectedViewController;

- (void)viewDidLoad {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [super viewDidLoad];
    [FlurryAPI logEvent:@"Blog"];

    commentsItem.title = NSLocalizedString(@"Comments", @"");
    postsItem.title = NSLocalizedString(@"Posts", @"");
    pagesItem.title = NSLocalizedString(@"Pages", @"");
    statsItem.title = NSLocalizedString(@"Stats", @"");

    postsViewController.blog = self.blog;
    pagesViewController.blog = self.blog;
    commentsViewController.blog = self.blog;
	//uncomment me to add stats back
	statsTableViewController.blog = self.blog;
	
    self.view = tabBarController.view;
	
	if ([blog valueForKey:@"blogName"] != nil)
		self.title = [blog valueForKey:@"blogName"];
	else
		self.title = NSLocalizedString(@"Blog", @"");
	
	if (DeviceIsPad() == NO) {
		self.navigationItem.rightBarButtonItem = commentsViewController.editButtonItem;
	}
	if (self.selectedViewController) {
		tabBarController.selectedViewController = self.selectedViewController;
	}
	else {
		tabBarController.selectedViewController = postsViewController;
	}
    [self tabBarController:tabBarController didSelectViewController:tabBarController.selectedViewController];
	    
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshBlogs:) name:@"DraftsUpdated" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshBlogs:) name:@"BlogsRefreshNotification" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshBlogs:) name:@"PagesUpdated" object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [super viewWillAppear:animated];
	
	if (DeviceIsPad() == YES) {
		[self restoreState];
	}
	else {
		[tabBarController.selectedViewController viewWillAppear:animated];
	}	
}

- (void)viewDidUnload {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
	self.selectedViewController = tabBarController.selectedViewController;
    commentsItem = nil;
    postsItem = nil;
    pagesItem = nil;
    statsItem = nil;
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
    [splitViewController release]; splitViewController = nil;
    self.selectedViewController = nil;
    self.blog = nil;
	
    [super dealloc];
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
		self.navigationItem.rightBarButtonItem = postsViewController.newButtonItem;
	} 
	else if (viewController == pagesViewController) {
		[[NSUserDefaults standardUserDefaults] setValue:@"Pages" forKey:@"WPSelectedContentType"];
		self.navigationItem.rightBarButtonItem = pagesViewController.newButtonItem;
	} 
	else if (viewController == commentsViewController) {
		[self configureCommentsTab];
	}
	//uncomment me to add stats back
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
	self.selectedViewController = postsViewController;
	if (vcName) {
		int section = [[NSUserDefaults standardUserDefaults] integerForKey:@"WPSelectedIndexPathSection"];
		int row = [[NSUserDefaults standardUserDefaults] integerForKey:@"WPSelectedIndexPathRow"];
		NSIndexPath *selectedIndexPath = [NSIndexPath indexPathForRow:row inSection:section];
		if ([vcName isEqual:@"Comments"]) {
			self.selectedViewController = commentsViewController;
			commentsViewController.selectedIndexPath = selectedIndexPath;
		}
		else if	([vcName isEqual:@"Posts"]) {
			self.selectedViewController = postsViewController;
			postsViewController.selectedIndexPath = selectedIndexPath;
		}
		else if	([vcName isEqual:@"Pages"]) {
			self.selectedViewController = pagesViewController;
			pagesViewController.selectedIndexPath = selectedIndexPath;
		}
		//uncomment me to add stats back
		else if	([vcName isEqual:@"Stats"]) {
			self.selectedViewController = statsTableViewController;
		}
	}
		
	// show the view controller
	if (self.selectedViewController) {
		self.tabBarController.selectedViewController = self.selectedViewController;
		[self tabBarController:self.tabBarController didSelectViewController:self.selectedViewController];
	}
	stateRestored = YES;
}

@end
