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
    self.title =[NSString decodeXMLCharactersIn:[[dm currentBlog] valueForKey:@"blogName"]] ;

    WPNavigationLeftButtonView *myview = [WPNavigationLeftButtonView createCopyOfView];
    [myview setTarget:self withAction:@selector(goToHome:)];
    [myview setTitle:@"Blogs"];
    UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithCustomView:myview];
    self.navigationItem.leftBarButtonItem = barButton;
    [barButton release];
    [myview release];

    [self initBackButton];

#if defined __IPHONE_3_0
	[dashboardViewController viewWillAppear:NO];
#else if defined __IPHONE_2_0 
    tabBarController.selectedIndex = 0;
#endif
    
    [commentsViewController setIndexForCurrentPost:-2];
    [commentsViewController refreshCommentsList];
}

- (void)viewWillAppear:(BOOL)animated {
    [tabBarController.selectedViewController viewWillAppear:animated];
    [super viewWillAppear:animated];
    [[WordPressAppDelegate sharedWordPressApp] storeCurrentBlog];
}

- (void)dealloc {
    [backButton release];
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
    backButton.title = viewController.tabBarItem.title;

    if (viewController == postsViewController) {
        self.navigationItem.rightBarButtonItem = postsViewController.newButtonItem;
    } else if (viewController == pagesViewController) {
        self.navigationItem.rightBarButtonItem = pagesViewController.newButtonItem;
    } else if (viewController == commentsViewController) {
        [commentsViewController setIndexForCurrentPost:-2];
        self.navigationItem.rightBarButtonItem = commentsViewController.editButtonItem;
    }
    else {
        self.navigationItem.rightBarButtonItem = nil;
    }
    
    [viewController viewWillAppear:NO];
}

@end
