//
// Copyright (c) 2014 Mixpanel. All rights reserved.

#import <libkern/OSAtomic.h>
#import "MPSequenceGenerator.h"


@implementation MPSequenceGenerator

{
    int32_t _value;
}

- (id)init
{
    return [self initWithInitialValue:0];
}

- (id)initWithInitialValue:(int32_t)initialValue
{
    self = [super init];
    if (self) {
        _value = initialValue;
    }

    return self;
}

- (int32_t)nextValue
{
    return OSAtomicAdd32(1, &_value);
}

@end
