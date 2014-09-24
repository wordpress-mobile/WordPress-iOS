/**
 Copyright (c) 2014-present, Facebook, Inc.
 All rights reserved.

 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import "MPTweak.h"

@implementation MPTweak {
  NSHashTable *_observers;
}

- (instancetype)initWithName:(NSString *)name andEncoding:(NSString *)encoding
{
  if ((self = [super init])) {
    _name = name;
    _encoding = encoding;
      _currentValue = nil;
      _defaultValue = nil;
      _minimumValue = nil;
      _maximumValue = nil;
  }
  return self;
}

- (void)setCurrentValue:(MPTweakValue)currentValue
{
  if (_minimumValue != nil && currentValue != nil && [_minimumValue compare:currentValue] == NSOrderedDescending) {
    currentValue = _minimumValue;
  }

  if (_maximumValue != nil && currentValue != nil && [_maximumValue compare:currentValue] == NSOrderedAscending) {
    currentValue = _maximumValue;
  }

  if (_currentValue != currentValue) {
    _currentValue = currentValue;
    for (id<MPTweakObserver> observer in [_observers setRepresentation]) {
      [observer tweakDidChange:self];
    }
  }
}

- (void)addObserver:(id<MPTweakObserver>)observer
{
  if (_observers == nil) {
    _observers = [NSHashTable weakObjectsHashTable];
  }

  NSAssert(observer != nil, @"observer is required");
  [_observers addObject:observer];
}

- (void)removeObserver:(id<MPTweakObserver>)observer
{
  NSAssert(observer != nil, @"observer is required");
  [_observers removeObject:observer];
}

@end
