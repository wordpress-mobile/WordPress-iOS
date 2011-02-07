//
//  BlogViewController.m
//  WordPress
//
//  Created by Josh Bassett on 8/07/09.
//

#import "BlogViewController.h"

#import "BlogDataManager.h"
#import "UIViewController+WPAnimation.h"
#import "WPNavigationLeftButtonView.h"
#import "WordPressAppDelegate.h"
#import "NSString+XMLExtensions.h" 

@implementation BlogViewController

@synthesize tabBarController, blog;

- (void)viewDidLoad {
    [super viewDidLoad];
    [FlurryAPI logEvent:@"Blog"];

    postsViewController.blog = self.blog;
    pagesViewController.blog = self.blog;
    commentsViewController.blog = self.blog;
	statsTableViewController.blog = self.blog;
	
    self.view = tabBarController.view;
	
	if ([blog valueForKey:@"blogName"] != nil)
		self.title = [NSString decodeXMLCharactersIn:[blog valueForKey:@"blogName"]];
	else
		self.title = @"Blog";
	
	if (DeviceIsPad() == NO) {
		tabBarController.selectedIndex = 0;

		self.navigationItem.rightBarButtonItem = commentsViewController.editButtonItem;
		self.navigationItem.titleView = commentsViewController.segmentedControl;
	}
	    
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshBlogs:) name:@"DraftsUpdated" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshBlogs:) name:@"BlogsRefreshNotification" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshBlogs:) name:@"PagesUpdated" object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	
	if (DeviceIsPad() == YES) {
		[self restoreState];
	}
	else {
		[tabBarController.selectedViewController viewWillAppear:animated];
	}	
}

- (void) viewWillDisappear:(BOOL)animated{
	[super viewWillDisappear:animated];
	[commentsViewController viewWillDisappear:animated];
	[postsViewController viewWillDisappear:animated];
	[pagesViewController viewWillDisappear:animated];
	[statsTableViewController viewWillDisappear:animated];
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[tabBarController release], tabBarController = nil;
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
		[[NSUserDefaults standardUserDefaults] setValue:@"Comments" forKey:@"WPSelectedContentType"];
		[commentsViewController setIndexForCurrentPost:-2];
		self.navigationItem.rightBarButtonItem = commentsViewController.editButtonItem;
		self.navigationItem.titleView = commentsViewController.segmentedControl;
	}
	else if (viewController == statsTableViewController) {
		[[NSUserDefaults standardUserDefaults] setValue:@"Stats" forKey:@"WPSelectedContentType"];
	}
	
	[viewController viewWillAppear:NO];
}

#pragma mark KVO callbacks

- (void)refreshBlogs:(NSNotification *)notification {
	// should probably let each VC take care of these on their own,
	// but that would probably also entail cleaning up the BlogDataManager
	// notifications et al.
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
	if (stateRestored) return;
	
	NSString *vcName = [[NSUserDefaults standardUserDefaults] objectForKey:@"WPSelectedContentType"];
	UIViewController *selectedViewController = postsViewController;
	if (vcName) {
		int section = [[NSUserDefaults standardUserDefaults] integerForKey:@"WPSelectedIndexPathSection"];
		int row = [[NSUserDefaults standardUserDefaults] integerForKey:@"WPSelectedIndexPathRow"];
		NSIndexPath *selectedIndexPath = [NSIndexPath indexPathForRow:row inSection:section];
		if ([vcName isEqual:@"Comments"]) {
			selectedViewController = commentsViewController;
			commentsViewController.selectedIndexPath = selectedIndexPath;
		}
		else if	([vcName isEqual:@"Posts"]) {
			selectedViewController = postsViewController;
			postsViewController.selectedIndexPath = selectedIndexPath;
		}
		else if	([vcName isEqual:@"Pages"]) {
			selectedViewController = pagesViewController;
			pagesViewController.selectedIndexPath = selectedIndexPath;
		}
		else if	([vcName isEqual:@"Stats"]) {
			selectedViewController = statsTableViewController;
		}
	}
		
	// show the view controller
	if (selectedViewController) {
		self.tabBarController.selectedViewController = selectedViewController;
		[self tabBarController:self.tabBarController didSelectViewController:selectedViewController];
	}
	
	stateRestored = YES;
}

@end
