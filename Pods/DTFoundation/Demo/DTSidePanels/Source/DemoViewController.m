//
//  DemoViewController.m
//  DTFoundation
//
//  Created by Oliver Drobnik on 15.05.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "DemoViewController.h"

@implementation DemoViewController

#pragma mark - Appearance Notifications

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	DTLogInfo(@"%@ %s animated:%d", self, __PRETTY_FUNCTION__, animated);
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	DTLogInfo(@"%@ %s animated:%d", self, __PRETTY_FUNCTION__, animated);
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	DTLogInfo(@"%@ %s animated:%d", self, __PRETTY_FUNCTION__, animated);
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
	DTLogInfo(@"%@ %s animated:%d", self, __PRETTY_FUNCTION__, animated);
}

- (void)willMoveToParentViewController:(UIViewController *)parent
{
	[super willMoveToParentViewController:parent];
	DTLogInfo(@"%@ %s", self, __PRETTY_FUNCTION__);
}

- (void)didMoveToParentViewController:(UIViewController *)parent
{
	[super didMoveToParentViewController:parent];
	DTLogInfo(@"%@ %s", self, __PRETTY_FUNCTION__);
}

@end
