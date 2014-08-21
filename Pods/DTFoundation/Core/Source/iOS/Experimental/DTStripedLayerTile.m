//
//  DTStripedLayerTile.m
//  DTFoundation
//
//  Created by Oliver Drobnik on 01.03.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "DTStripedLayerTile.h"

@implementation DTStripedLayerTile

- (id)init
{
    self = [super init];
    
    if (self)
    {
        // disable interpolation on contents property to avoid cross fade on image contents
        NSMutableDictionary *newActions = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                           [NSNull null], @"contents",
                                           nil];
        self.actions = newActions;
    }
    
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@ index=%d width=%@>", NSStringFromClass([self class]), _index, NSStringFromCGRect(self.frame)];
}


// disable all implicit animations
- (id < CAAction >)actionForKey:(NSString *)key
{
    return nil;
}

@end
