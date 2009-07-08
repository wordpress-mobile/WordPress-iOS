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

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.view = tabBarController.view;
    
    WPNavigationLeftButtonView *myview = [WPNavigationLeftButtonView createCopyOfView];  
    [myview setTarget:self withAction:@selector(goToHome:)];
    [myview setTitle:@"Blogs"];
    UIBarButtonItem *barButton  = [[UIBarButtonItem alloc] initWithCustomView:myview];
    self.navigationItem.leftBarButtonItem = barButton;
    [barButton release];
    [myview release];
	
	tabBarController.selectedIndex = 0;
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
		self.navigationItem.rightBarButtonItem = postsViewController.newButtonItem;
	} else if (viewController == pagesViewController) {
		self.navigationItem.rightBarButtonItem = pagesViewController.newButtonItem;
	} else if (viewController == commentsViewController) {
		self.navigationItem.rightBarButtonItem = commentsViewController.editButtonItem;
	} else {
		self.navigationItem.rightBarButtonItem = nil;
	}
}

@end
