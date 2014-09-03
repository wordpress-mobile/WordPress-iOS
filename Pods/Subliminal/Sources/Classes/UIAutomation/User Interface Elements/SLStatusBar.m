//
//  SLStatusBar.m
//  Subliminal
//
//  Created by Leon Jiang on 8/12/13.
//  Copyright (c) 2013 Inkling. All rights reserved.
//

#import "SLStatusBar.h"

@implementation SLStatusBar

+ (SLStatusBar *)statusBar {
    return [[self alloc] initWithUIARepresentation:@"UIATarget.localTarget().frontMostApp().statusBar()"];
}

@end
