//
//  FlurryAdDelegate.h
//  FlurryAnalytics
//
//  Created by chunhao on 3/2/10.
//  Copyright 2010 Flurry Inc. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol FlurryAdDelegate <NSObject>

@optional
/* 
 called after data is received
 */
- (void)dataAvailable;
/*
 called after data is determined to be unavailable
 */
- (void)dataUnavailable;
/*
 called before canvas displays
 code to pause app states can be set here
 */
- (void)canvasWillDisplay:(NSString *)hook;
/*
 called before canvas closes
 code to resume app states can be set here
 */
- (void)canvasWillClose;

@end
