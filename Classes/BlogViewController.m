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

@synthesize tabBarController;

- (void)viewDidLoad {
    [super viewDidLoad];
	
    self.view = tabBarController.view;

    BlogDataManager *dm = [BlogDataManager sharedDataManager];
    self.title =[NSString decodeXMLCharactersIn:[[dm currentBlog] valueForKey:@"blogName"]] ;
	
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
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshBlogs:) name:@"DraftsUpdated" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshBlogs:) name:@"BlogsRefreshNotification" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshBlogs:) name:@"PagesUpdated" object:nil];
	
	[postsViewController addObserver:self forKeyPath:@"selectedIndexPath" options:NSKeyValueObservingOptionNew context:nil];
	[pagesViewController addObserver:self forKeyPath:@"selectedIndexPath" options:NSKeyValueObservingOptionNew context:nil];
	[commentsViewController addObserver:self forKeyPath:@"selectedIndexPath" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)viewWillAppear:(BOOL)animated {
	if (DeviceIsPad() == YES) {
		[self restoreState];
	}
	else {
		[tabBarController.selectedViewController viewWillAppear:animated];
	}
	
    [super viewWillAppear:animated];
    [[WordPressAppDelegate sharedWordPressApp] storeCurrentBlog];
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[postsViewController removeObserver:self forKeyPath:@"selectedIndexPath"];
	[pagesViewController removeObserver:self forKeyPath:@"selectedIndexPath"];
	[commentsViewController removeObserver:self forKeyPath:@"selectedIndexPath"];
	
	[tabBarController release], tabBarController = nil;
	
    [super dealloc];
}

#pragma mark -
#pragma mark Navigation Methods

- (void)goToHome:(id)sender {
    [[WordPressAppDelegate sharedWordPressApp] resetCurrentBlogInUserDefaults];
    [self popTransition:self.navigationController.view];
}

#pragma mark -
#pragma mark UITabBarControllerDelegate Methods

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
    BlogDataManager *dm = [BlogDataManager sharedDataManager];

    if (viewController == pagesViewController || viewController == commentsViewController) {
        // Enable pages and comments tabs only if they are supported.
        return [[[dm currentBlog] valueForKey:kSupportsPagesAndComments] boolValue];
    } else {
        return YES;
    }
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

- (void)reselect
{
if ([tabBarController.selectedViewController respondsToSelector:@selector(reselect)])
	[tabBarController.selectedViewController performSelector:@selector(reselect)];
}

#pragma mark State saving

- (void)saveState;
{
	NSString *vcName;
	NSIndexPath *indexPath;
	if (commentsViewController.selectedIndexPath) {
		vcName = @"Comments";
		indexPath = commentsViewController.selectedIndexPath;
	}
	else if	(postsViewController.selectedIndexPath) {
		vcName = @"Posts";
		indexPath = postsViewController.selectedIndexPath;
	}
	else if	(pagesViewController.selectedIndexPath) {
		vcName = @"Pages";
		indexPath = pagesViewController.selectedIndexPath;
	}
	
	if((vcName != nil) && (indexPath != nil)) {
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
	}
		
	// show the view controller
	if (selectedViewController) {
		self.tabBarController.selectedViewController = selectedViewController;
		[self tabBarController:self.tabBarController didSelectViewController:selectedViewController];
	}
	
	stateRestored = YES;
}

@end
