//
//  SLSwitch.m
//  Subliminal
//
//  Created by Justin Mutter on 2013-09-13.
//  Copyright (c) 2013 Inkling. All rights reserved.
//

#import "SLSwitch.h"
#import "SLUIAElement+Subclassing.h"

@implementation SLSwitch

- (BOOL)matchesObject:(NSObject *)object {
    return ([super matchesObject:object] && [object isKindOfClass:[UISwitch class]]);
}

- (BOOL)isOn
{
    return [[self value] boolValue];
}

- (void)setOn:(BOOL)on
{
    NSString *valueString = on ? @"true" : @"false";
    [self waitUntilTappable:NO thenSendMessage:@"setValue(%@)", valueString];
}

@end
