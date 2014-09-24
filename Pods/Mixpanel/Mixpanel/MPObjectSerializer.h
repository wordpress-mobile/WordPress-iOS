//
// Copyright (c) 2014 Mixpanel. All rights reserved.

#import <Foundation/Foundation.h>

@class MPClassDescription;
@class MPObjectSerializerContext;
@class MPObjectSerializerConfig;
@class MPObjectIdentityProvider;

@interface MPObjectSerializer : NSObject

/*!
 @param     An array of MPClassDescription instances.
 */
- (id)initWithConfiguration:(MPObjectSerializerConfig *)configuration objectIdentityProvider:(MPObjectIdentityProvider *)objectIdentityProvider;

- (NSDictionary *)serializedObjectsWithRootObject:(id)rootObject;

@end
