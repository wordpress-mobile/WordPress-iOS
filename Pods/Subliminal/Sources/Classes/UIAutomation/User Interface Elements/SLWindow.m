//
//  SLWindow.m
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

#import "SLWindow.h"
#import "SLUIAElement+Subclassing.h"

@implementation SLWindow

+ (SLWindow *)mainWindow {
    return [self elementMatching:^BOOL(NSObject *obj) {
        return (obj == [[UIApplication sharedApplication] keyWindow]);
    } withDescription:@"Main Window"];
}

- (BOOL)matchesObject:(NSObject *)object {
    return [super matchesObject:object] && [object isKindOfClass:[UIWindow class]];
}

@end
