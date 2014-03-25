//
//  PageSettingsViewController.m
//  WordPress
//
//  Created by Eric Johnson on 2/11/14.
//  Copyright (c) 2014 WordPress. All rights reserved.
//

#import "PageSettingsViewController.h"
#import "PostSettingsViewController_Internal.h"

@interface PageSettingsViewController ()

@end

@implementation PageSettingsViewController

- (id)initWithPost:(AbstractPost *)aPost {
    self = [super initWithPost:aPost];
    if (self) {
        self.statsPrefix = @"Page Detail";
    }
    return self;
}

- (void)addPostPropertiesObserver {
    // noop
    // No need to observe properties for page settings
}

- (void)removePostPropertiesObserver {
    // noop
    // No need to observe properties for page settings
}


- (void)configureSections {
    self.sections = [NSMutableArray array];
    [self.sections addObject:[NSNumber numberWithInteger:PostSettingsSectionMeta]];
}

@end
