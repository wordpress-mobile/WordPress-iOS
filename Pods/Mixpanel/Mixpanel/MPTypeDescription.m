//
// Copyright (c) 2014 Mixpanel. All rights reserved.

#import "MPTypeDescription.h"


@implementation MPTypeDescription

- (id)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if (self) {
        _name = [dictionary[@"name"] copy];
    }

    return self;
}

@end
