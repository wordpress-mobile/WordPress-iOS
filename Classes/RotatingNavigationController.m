    //
//  RotatingNavigationController.m
//  WordPress
//
//  Created by Devin Chalmers on 3/5/10.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import "RotatingNavigationController.h"


@implementation RotatingNavigationController

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Overriden to allow any orientation.
    return YES;
}

- (CGSize)contentSizeForViewInPopover;
{
	CGSize childSize = self.visibleViewController.contentSizeForViewInPopover;
	if (childSize.height == 0) {
		childSize = CGSizeMake(320, 436);
	}
	return CGSizeMake(childSize.width, childSize.height + 44.0);
}

@end
