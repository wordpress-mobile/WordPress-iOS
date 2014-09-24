/**
 Copyright (c) 2014-present, Facebook, Inc.
 All rights reserved.

 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>
#import "MPTweak.h"

@class MPTweak;

/**
  @abstract The global store for tweaks.
 */
@interface MPTweakStore : NSObject

/**
  @abstract Creates or returns the shared global store.
 */
+ (instancetype)sharedInstance;

/**
  @abstract The tweak categories in the store.
 */
@property (nonatomic, copy, readonly) NSArray *tweaks;

/**
  @abstract Finds a tweak by name.
  @param name The name of the tweak to find.
  @return The tweak if found, nil otherwise.
 */
- (MPTweak *)tweakWithName:(NSString *)name;

/**
  @abstract Registers a tweak with the store.
  @param tweak The tweak to register.
 */
- (void)addTweak:(MPTweak *)tweak;

/**
  @abstract Removes a tweak from the store.
  @param tweak The tweak to remove.
 */
- (void)removeTweak:(MPTweak *)tweak;

/**
  @abstract Resets all tweaks in the store.
 */
- (void)reset;

@end
