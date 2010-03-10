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

@end
