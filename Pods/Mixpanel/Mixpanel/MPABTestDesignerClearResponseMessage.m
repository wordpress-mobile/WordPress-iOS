//
//  MPABTestDesignerClearResponseMessage.m
//  HelloMixpanel
//
//  Created by Alex Hofsteede on 3/7/14.
//  Copyright (c) 2014 Mixpanel. All rights reserved.
//

#import "MPABTestDesignerClearResponseMessage.h"

@implementation MPABTestDesignerClearResponseMessage

+ (instancetype)message
{
    return [[self alloc] initWithType:@"clear_response"];
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
