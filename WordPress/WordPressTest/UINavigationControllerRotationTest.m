//
//  UINavigationControllerRotationTest.m
//  WordPress
//
//  Created by Jorge Bernal on 4/15/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "UINavigationControllerRotationTest.h"
#import "UINavigationController+Rotation.h"

@implementation UINavigationControllerRotationTest

- (void)testSupportedInterfaceOrientations {
    UINavigationController *nav = [[UINavigationController alloc] init];
    if ([nav respondsToSelector:@selector(supportedInterfaceOrientations)]) {
        if (([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)) {
            STAssertEquals(nav.supportedInterfaceOrientations, UIInterfaceOrientationMaskAll, nil);
        } else {
            STAssertEquals(nav.supportedInterfaceOrientations, UIInterfaceOrientationMaskAllButUpsideDown, nil);
        }
    }
}

- (void)testShouldAutorotate {
    UINavigationController *nav = [[UINavigationController alloc] init];
    if (([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)) {
        STAssertTrue([nav shouldAutorotateToInterfaceOrientation:UIInterfaceOrientationPortraitUpsideDown], nil);
    } else {
        STAssertFalse([nav shouldAutorotateToInterfaceOrientation:UIInterfaceOrientationPortraitUpsideDown], nil);
    }
    STAssertTrue([nav shouldAutorotateToInterfaceOrientation:UIInterfaceOrientationPortrait], nil);
    STAssertTrue([nav shouldAutorotateToInterfaceOrientation:UIInterfaceOrientationLandscapeLeft], nil);
    STAssertTrue([nav shouldAutorotateToInterfaceOrientation:UIInterfaceOrientationLandscapeRight], nil);
}

@end
