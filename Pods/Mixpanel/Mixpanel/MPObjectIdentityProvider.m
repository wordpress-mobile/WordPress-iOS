//
// Copyright (c) 2014 Mixpanel. All rights reserved.

#import "MPObjectIdentityProvider.h"
#import "MPSequenceGenerator.h"


@implementation MPObjectIdentityProvider

{
    NSMapTable *_objectToIdentifierMap;
    MPSequenceGenerator *_sequenceGenerator;
}

- (id)init
{
    self = [super init];
    if (self) {
        _objectToIdentifierMap = [NSMapTable weakToStrongObjectsMapTable];
        _sequenceGenerator = [[MPSequenceGenerator alloc] init];
    }

    return self;
}

- (NSString *)identifierForObject:(id)object
{
    NSString *identifier = [_objectToIdentifierMap objectForKey:object];
    if (identifier == nil) {
        identifier = [NSString stringWithFormat:@"$%" PRIi32, [_sequenceGenerator nextValue]];
        [_objectToIdentifierMap setObject:identifier forKey:object];
    }

    return identifier;
}

@end
