//
//  ModalPanelViewController.m
//  DTFoundation
//
//  Created by Oliver Drobnik on 5/24/13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "ModalPanelViewController.h"
#import "UIViewController+DTSidePanelController.h"

@implementation ModalPanelViewController

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

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	[super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
	DTLogInfo(@"%@ %s", self, __PRETTY_FUNCTION__);
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	[super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
	DTLogInfo(@"%@ %s", self, __PRETTY_FUNCTION__);
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	[super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
	DTLogInfo(@"%@ %s", self, __PRETTY_FUNCTION__);
}

#pragma mark - Actions

- (IBAction)switchChanged:(UISwitch *)sender
{
	DTLogInfo(@"%@", self.sidePanelController);
	
	self.allowClosing = sender.isOn;
}

@end
