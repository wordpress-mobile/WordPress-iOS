//
//  FlippingViewController.h
//  WordPress
//
//  Created by Devin Chalmers on 3/5/10.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface FlippingViewController : UIViewController {
	UIViewController *frontViewController;
	UIViewController *backViewController;
	
	BOOL showingFront;
}

@property (nonatomic, retain) UIViewController *frontViewController;
@property (nonatomic, retain) UIViewController *backViewController;

@property (nonatomic, assign) BOOL showingFront;

- (void)setShowingFront:(BOOL)newShowingFront animated:(BOOL)animated;

@end
