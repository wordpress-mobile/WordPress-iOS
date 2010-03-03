//
//  WordPressSplitViewController.h
//  WordPress
//
//  Created by Jonathan Wight on 03/02/10.
//  Copyright 2010 toxicsoftware.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WordPressSplitViewController : UISplitViewController <UISplitViewControllerDelegate> {
	UIPopoverController *currentPopoverController;
}

@property (readonly, nonatomic, retain) UINavigationController *masterNavigationController;
@property (readonly, nonatomic, retain) UINavigationController *detailNavigationController;

@property (readwrite, nonatomic, retain) UIPopoverController *currentPopoverController;

@end
