//
//  BlogTabViewController.m
//  WordPress
//
//  Created by Gareth Townsend on 26/06/09.
//  Copyright 2009 Clear Interactive. All rights reserved.
//

#import "BlogTabViewController.h"
#import "PostsListController.h"
#import "PagesViewController.h"
#import "CommentsListController.h"
#import "PagesAndCommentsNotSupported.h"

#import "WPNavigationLeftButtonView.h"
#import "BlogDataManager.h"
#import "Reachability.h"
#import "UIViewController+WPAnimation.h"
#import "WordPressAppDelegate.h"



@implementation BlogTabViewController

@synthesize viewControllers;

@synthesize tabBar;
@synthesize postsTabBarItem;
@synthesize pagesTabBarItem;
@synthesize commentsTabBarItem;

@synthesize selectedViewController;


 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
       
        // Custom initialization
        PostsListController *postsListController = [[PostsListController alloc] init];
        PagesViewController *pagesViewController = [[PagesViewController alloc] init];
        CommentsListController *commentsListController = [[CommentsListController alloc] initWithNibName:@"CommentsListController" bundle:nil];
        PagesAndCommentsNotSupported *pagesAndCommentsNotSupported = [[PagesAndCommentsNotSupported alloc] initWithNibName:@"PagesAndCommentsNotSupported" bundle:nil];
        
        NSArray *array = [[NSArray alloc] initWithObjects:postsListController, pagesViewController, commentsListController, pagesAndCommentsNotSupported, nil];
        self.viewControllers = array;
        [array release];
        
        [self.view addSubview:postsListController.view];
        [postsListController viewWillAppear:YES];

        [self.view bringSubviewToFront:self.tabBar];
        self.selectedViewController = postsListController;
        
        self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose
                                                                                                target:postsListController
                                                                                                action:@selector(showAddPostView)] autorelease];
        
        [postsListController release];
        [pagesViewController release];
        [commentsListController release];
        [pagesAndCommentsNotSupported release];
    }
    return self;
}


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    tabBar.selectedItem = postsTabBarItem;
    
    WPNavigationLeftButtonView *myview = [WPNavigationLeftButtonView createCopyOfView];  
    [myview setTarget:self withAction:@selector(goToHome:)];
    [myview setTitle:@"Blogs"];
    UIBarButtonItem *barButton  = [[UIBarButtonItem alloc] initWithCustomView:myview];
    self.navigationItem.leftBarButtonItem = barButton;
    [barButton release];
    [myview release];
        
    [super viewDidLoad];
}

- (void)goToHome:(id)sender {
    [[BlogDataManager sharedDataManager] resetCurrentBlog];
	[self popTransition:self.navigationController.view];
}


/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
    
}

//- (void)goToHome:(id)sender {
//    [[BlogDataManager sharedDataManager] resetCurrentBlog];
//	[self popTransition:self.navigationController.view];
//}

- (void)dealloc {
    [viewControllers release];
    
    [tabBar release];
    [postsTabBarItem release];
    [pagesTabBarItem release];
    [commentsTabBarItem release];
    
    [selectedViewController release];
    
    [super dealloc];
}

#pragma mark -
#pragma mark Tab Bar Delegate Methods

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item {
    if (item == postsTabBarItem) {
        
        UIViewController *postsListController = [viewControllers objectAtIndex:0];
        [self.selectedViewController.view removeFromSuperview];
        [self.view addSubview:postsListController.view];
        [postsListController viewWillAppear:NO];
        [self.view bringSubviewToFront:self.tabBar];
        self.selectedViewController = postsListController;
        
        self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose
                                                                                                target:postsListController
                                                                                                action:@selector(showAddPostView)] autorelease];
        
    }
    else if ((item == pagesTabBarItem) && [[[[BlogDataManager sharedDataManager] currentBlog] valueForKey:kSupportsPagesAndComments] boolValue]) {
        UIViewController *pagesViewController = [viewControllers objectAtIndex:1];        
        [self.selectedViewController.view removeFromSuperview];
        [self.view addSubview:pagesViewController.view];
        [pagesViewController viewWillAppear:NO];
        [self.view bringSubviewToFront:self.tabBar];
        self.selectedViewController = pagesViewController;
        
        self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose
                                                                                                target:pagesViewController
                                                                                                action:@selector(showAddNewPage)] autorelease];
    }
    else if ((item == commentsTabBarItem) && [[[[BlogDataManager sharedDataManager] currentBlog] valueForKey:kSupportsPagesAndComments] boolValue]) {
        UIViewController *commentsListController = [viewControllers objectAtIndex:2];        
        [self.selectedViewController.view removeFromSuperview];
        [self.view addSubview:commentsListController.view];
        [commentsListController viewWillAppear:NO];
        [self.view bringSubviewToFront:self.tabBar];
        self.selectedViewController = commentsListController;
        
        self.navigationItem.rightBarButtonItem = nil;
    }
    else {
        UIViewController *pagesAndCommentsNotSupported = [viewControllers objectAtIndex:3];        
        [self.selectedViewController.view removeFromSuperview];
        [self.view addSubview:pagesAndCommentsNotSupported.view];
        [pagesAndCommentsNotSupported viewWillAppear:NO];
        [self.view bringSubviewToFront:self.tabBar];
        self.selectedViewController = pagesAndCommentsNotSupported;
        
        self.navigationItem.rightBarButtonItem = nil;
    }
    
}


@end
