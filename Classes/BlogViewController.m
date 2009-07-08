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


@implementation BlogViewController

- (void)initBackButton {
	backButton = [[UIBarButtonItem alloc] initWithTitle:@"Posts"
												  style:UIBarButtonItemStylePlain
												 target:self
												 action:nil];
	
	self.navigationItem.backBarButtonItem = backButton;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.view = tabBarController.view;
	
	BlogDataManager *dm = [BlogDataManager sharedDataManager];
	self.title = [[dm currentBlog] valueForKey:@"blogName"];
    
    WPNavigationLeftButtonView *myview = [WPNavigationLeftButtonView createCopyOfView];  
    [myview setTarget:self withAction:@selector(goToHome:)];
    [myview setTitle:@"Blogs"];
    UIBarButtonItem *barButton  = [[UIBarButtonItem alloc] initWithCustomView:myview];
    self.navigationItem.leftBarButtonItem = barButton;
    [barButton release];
    [myview release];
	
	[self initBackButton];
	
	tabBarController.selectedIndex = 0;
}

- (void)dealloc {
	[backButton release];
	[super dealloc];
}

- (void)viewWillAppear:(BOOL)animated {
	[tabBarController.selectedViewController viewWillAppear:animated];
	[super viewWillAppear:animated];
}

#pragma mark -
#pragma mark Navigation Methods

- (void)goToHome:(id)sender {
    [[BlogDataManager sharedDataManager] resetCurrentBlog];
	[self popTransition:self.navigationController.view];
}

#pragma mark -
#pragma mark UITabBarControllerDelegate Methods

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
	[viewController viewWillAppear:NO];
	
	if (viewController == postsViewController) {
		backButton.title = @"Posts";
		self.navigationItem.rightBarButtonItem = postsViewController.newButtonItem;
	} else if (viewController == pagesViewController) {
		backButton.title = @"Pages";
		self.navigationItem.rightBarButtonItem = pagesViewController.newButtonItem;
	} else if (viewController == commentsViewController) {
		backButton.title = @"Comments";
		self.navigationItem.rightBarButtonItem = commentsViewController.editButtonItem;
	} else {
		self.navigationItem.rightBarButtonItem = nil;
	}
}

@end
