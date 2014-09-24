//
// Copyright (c) 2014 Mixpanel. All rights reserved.

#import "MPABTestDesignerChangeResponseMessage.h"


@implementation MPABTestDesignerChangeResponseMessage

+ (instancetype)message
{
    return [[self alloc] initWithType:@"change_response"];
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
