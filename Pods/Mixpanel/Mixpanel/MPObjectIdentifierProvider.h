//
// Copyright (c) 2014 Mixpanel. All rights reserved.

#import <Foundation/Foundation.h>

@protocol MPObjectIdentifierProvider <NSObject>
- (NSString *)identifierForObject:(id)object;

@end
