//
//  MPABTestDesignerTweakResponseMessage.m
//  HelloMixpanel
//
//  Created by Alex Hofsteede on 7/5/14.
//  Copyright (c) 2014 Mixpanel. All rights reserved.
//

#import "MPABTestDesignerTweakResponseMessage.h"

@implementation MPABTestDesignerTweakResponseMessage

+ (instancetype)message
{
    return [[self alloc] initWithType:@"tweak_response"];
}

- (void)setStatus:(NSString *)status
{
    [self setPayloadObject:status forKey:@"status"];
}

- (NSString *)status
{
    return [self payloadObjectForKey:@"status"];
}

@end
