//
//  PSStackedView.h
//  PSStackedView
//
//  Created by Peter Steinberger on 7/14/11.
//  Copyright 2011 Peter Steinberger. All rights reserved.
//

#import "PSStackedViewDelegate.h"
#import "PSStackedViewController.h"
#import "PSSVContainerView.h"
#import "UIViewController+PSStackedView.h"

enum {
    PSSVLogLevelNothing,
    PSSVLogLevelError,    
    PSSVLogLevelInfo,
    PSSVLogLevelVerbose
}typedef PSSVLogLevel;

extern PSSVLogLevel kPSSVDebugLogLevel; // defaults to PSSVLogLevelError
