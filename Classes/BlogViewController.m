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


- (void)viewDidLoad {
    [super viewDidLoad];

    self.view = tabBarController.view;

    BlogDataManager *dm = [BlogDataManager sharedDataManager];
    self.title =[NSString decodeXMLCharactersIn:[[dm currentBlog] valueForKey:@"blogName"]] ;

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

- (void)viewWillAppear:(BOOL)animated {
    [tabBarController.selectedViewController viewWillAppear:animated];
    [super viewWillAppear:animated];
    [[WordPressAppDelegate sharedWordPressApp] storeCurrentBlog];
}

- (void)dealloc {
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

@end
