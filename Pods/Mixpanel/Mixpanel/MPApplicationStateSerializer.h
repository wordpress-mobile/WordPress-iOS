//
// Copyright (c) 2014 Mixpanel. All rights reserved.

#import <Foundation/Foundation.h>

@class MPObjectSerializerConfig;
@class MPObjectIdentityProvider;

@interface MPApplicationStateSerializer : NSObject

- (id)initWithApplication:(UIApplication *)application configuration:(MPObjectSerializerConfig *)configuration objectIdentityProvider:(MPObjectIdentityProvider *)objectIdentityProvider;

- (UIImage *)screenshotImageForWindowAtIndex:(NSUInteger)index;

- (NSDictionary *)objectHierarchyForWindowAtIndex:(NSUInteger)index;

@end
