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

    self.view = tabBarController.view;

    self.title =[NSString decodeXMLCharactersIn:[blog valueForKey:@"blogName"]];
	
	if (DeviceIsPad() == NO) {
	#if defined __IPHONE_3_0
		[commentsViewController viewWillAppear:NO];
	#else if defined __IPHONE_2_0 
		tabBarController.selectedIndex = 0;
	#endif
		
		[commentsViewController setIndexForCurrentPost:-2];
		[commentsViewController refreshCommentsList];
		
		self.navigationItem.rightBarButtonItem = commentsViewController.editButtonItem;
		self.navigationItem.titleView = commentsViewController.segmentedControl;
	}
	
    postsViewController.blog = self.blog;
    pagesViewController.blog = self.blog;
    commentsViewController.blog = self.blog;
    
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshBlogs:) name:@"DraftsUpdated" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshBlogs:) name:@"BlogsRefreshNotification" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshBlogs:) name:@"PagesUpdated" object:nil];
	
	[postsViewController addObserver:self forKeyPath:@"selectedIndexPath" options:NSKeyValueObservingOptionNew context:nil];
	[pagesViewController addObserver:self forKeyPath:@"selectedIndexPath" options:NSKeyValueObservingOptionNew context:nil];
	[commentsViewController addObserver:self forKeyPath:@"selectedIndexPath" options:NSKeyValueObservingOptionNew context:nil];
	//[statsTableViewController addObserver:self forKeyPath:@"selectedIndexPath" options:NSKeyValueObservingOptionNew context:nil];
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

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[postsViewController removeObserver:self forKeyPath:@"selectedIndexPath"];
	[pagesViewController removeObserver:self forKeyPath:@"selectedIndexPath"];
	[commentsViewController removeObserver:self forKeyPath:@"selectedIndexPath"];	
	//[statsTableViewController removeObserver:self forKeyPath:@"selectedIndexPath"];
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
		self.navigationItem.rightBarButtonItem = postsViewController.newButtonItem;
	} 
	else if (viewController == pagesViewController) {
		self.navigationItem.rightBarButtonItem = pagesViewController.newButtonItem;
	} 
	else if (viewController == commentsViewController) {
		[commentsViewController setIndexForCurrentPost:-2];
		self.navigationItem.rightBarButtonItem = commentsViewController.editButtonItem;
		self.navigationItem.titleView = commentsViewController.segmentedControl;
	}
//	else if (viewController == statsTableViewController) {
//		self.navigationItem.rightBarButtonItem = statsTableViewController.refreshButtonItem;
//	}
	
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

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context;
{
	if ([keyPath isEqual:@"selectedIndexPath"]) {
		id new = [change objectForKey:NSKeyValueChangeNewKey];
		if (!new || new == [NSNull null])
			return;
		
		if (object != postsViewController) postsViewController.selectedIndexPath = nil;
		if (object != pagesViewController) pagesViewController.selectedIndexPath = nil;
		if (object != commentsViewController) commentsViewController.selectedIndexPath = nil;
	}
}

- (void)reselect {
	if ([tabBarController.selectedViewController respondsToSelector:@selector(reselect)])
		[tabBarController.selectedViewController performSelector:@selector(reselect)];
}

#pragma mark State saving

- (void)saveState;
{
	NSString *vcName = @"";
	NSIndexPath *indexPath = [NSIndexPath indexPathWithIndex:0];
	BOOL hasVCName = NO;
	BOOL hasIndexPath = NO;
	if (commentsViewController.selectedIndexPath) {
		vcName = @"Comments";
		indexPath = commentsViewController.selectedIndexPath;
		hasVCName = YES;
		hasIndexPath = YES;
	}
	else if	(postsViewController.selectedIndexPath) {
		vcName = @"Posts";
		indexPath = postsViewController.selectedIndexPath;
		hasVCName = YES;
		hasIndexPath = YES;
	}
	else if	(pagesViewController.selectedIndexPath) {
		vcName = @"Pages";
		indexPath = pagesViewController.selectedIndexPath;
		hasVCName = YES;
		hasIndexPath = YES;
	}
//	else if	(statsTableViewController.selectedIndexPath) {
//		vcName = @"Statss";
//		indexPath = statsTableViewController.selectedIndexPath;
//		hasVCName = YES;
//		hasIndexPath = YES;
//	}
	
	if((hasVCName == YES) && (hasIndexPath == YES)) {
		[[NSUserDefaults standardUserDefaults] setObject:vcName forKey:@"WPSelectedContentType"];
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
//		else if	([vcName isEqual:@"Stats"]) {
//			selectedViewController = statsTableViewController;
//			statsTableViewController.selectedIndexPath = selectedIndexPath;
//		}
	}
		
	// show the view controller
	if (selectedViewController) {
		self.tabBarController.selectedViewController = selectedViewController;
		[self tabBarController:self.tabBarController didSelectViewController:selectedViewController];
	}
	
	stateRestored = YES;
}

@end
