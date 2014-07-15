//
//  SLMainThreadRef.m
//  Subliminal
//
//  For details and documentation:
//  http://github.com/inkling/Subliminal
//
//  Copyright 2013-2014 Inkling Systems, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "SLMainThreadRef.h"

@implementation SLMainThreadRef {
    id __weak _target;
}

+ (instancetype)refWithTarget:(id)target {
    return [[self alloc] initWithTarget:target];
}

- (instancetype)initWithTarget:(id)target {
    self = [super init];
    if (self) {
        _target = target;
    }
    return self;
}

- (id)target {
    NSAssert([NSThread isMainThread],
             @"An SLMainThreadRef's target may only be accessed from the main thread.");
    return _target;
}

- (NSString *)description {
    // we intentionally allow for "(null)" to be formatted into the string
    // if the target's been released
    return [NSString stringWithFormat:@"%@: %@", NSStringFromClass([self class]), _target];
}

@end
