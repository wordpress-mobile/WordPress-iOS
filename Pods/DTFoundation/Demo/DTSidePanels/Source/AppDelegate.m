//
//  AppDelegate.m
//  DTSidePanelController
//
//  Created by Oliver Drobnik on 15.05.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "AppDelegate.h"

#import "DTSidePanelController.h"
#import "TableViewController.h"
#import "ModalPanelViewController.h"
#import "DemoViewController.h"
#import "LoggingNavigationController.h"

@interface AppDelegate () <DTSidePanelControllerDelegate>

@end

@implementation AppDelegate
{
	DTSidePanelController *_sidePanelController;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	
	// set up panel for left side
	UIViewController *leftVC = [[TableViewController alloc] init];
	leftVC.navigationItem.title = @"Left";
	LoggingNavigationController *leftNav = [[LoggingNavigationController alloc] initWithRootViewController:leftVC];
	
	// set up panel for right side
	ModalPanelViewController *rightVC = [[ModalPanelViewController alloc] initWithNibName:@"ModalPanelViewController" bundle:nil];
	rightVC.navigationItem.title = @"Right";
	LoggingNavigationController *rightNav = [[LoggingNavigationController alloc] initWithRootViewController:rightVC];
	
	// set up center panel
	UIViewController *centerVC = [[DemoViewController alloc] initWithNibName:@"DemoViewController" bundle:nil];
	centerVC.navigationItem.title = @"Center";
	
	// create a panel controller as root
	_sidePanelController = [[DTSidePanelController alloc] init];
    
    // create a left and right "Hamburger" icon on center VC's navigationItem
	UIImage *hamburgerIcon = [UIImage imageNamed:@"toolbar-icon-menu"];
	centerVC.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:hamburgerIcon style:UIBarButtonItemStyleBordered target:_sidePanelController action:@selector(toggleLeftPanel:)];
	centerVC.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:hamburgerIcon style:UIBarButtonItemStyleBordered target:_sidePanelController action:@selector(toggleRightPanel:)];
	LoggingNavigationController *centerNav = [[LoggingNavigationController alloc] initWithRootViewController:centerVC];
	
	// left panel has fixed width, right panel width is variable
	[_sidePanelController setWidth:200 forPanel:DTSidePanelControllerPanelLeft animated:NO];
	
	// set the panels on the controller
	_sidePanelController.leftPanelController = leftNav;
	_sidePanelController.centerPanelController = centerNav;
	_sidePanelController.rightPanelController = rightNav;
	_sidePanelController.sidePanelDelegate = self;

	self.window.rootViewController = _sidePanelController;
	[self.window makeKeyAndVisible];
	
	return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
	// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
	// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
	// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
	// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - DTSidePanelControllerDelegate

- (BOOL)sidePanelController:(DTSidePanelController *)sidePanelController shouldAllowClosingOfSidePanel:(DTSidePanelControllerPanel)sidePanel
{
	if (sidePanel == DTSidePanelControllerPanelRight)
	{
		UINavigationController *navController = (UINavigationController *)sidePanelController.rightPanelController;
		ModalPanelViewController *controller = (ModalPanelViewController *)[[navController viewControllers] objectAtIndex:0];
		
		return [controller allowClosing];
	}
	
	return YES;
}

@end
