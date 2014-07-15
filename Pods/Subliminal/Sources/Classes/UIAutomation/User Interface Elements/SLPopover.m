//
//  SLPopover.m
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

#import "SLPopover.h"
#import "SLUIAElement+Subclassing.h"

@implementation SLPopover

+ (instancetype)currentPopover {
    return [[SLPopover alloc] initWithUIARepresentation:@"UIATarget.localTarget().frontMostApp().mainWindow().popover()"];
}

- (void)dismiss {
    /*
     I don't know how to check whether dismissal requires tappability
     because I don't know how to make a popover not tappable: a popover
     is never both valid and hidden. But my inclination is to say
     that it doesn't require tappability, because a popover is dismissed
     by tapping _outside_ the popover.
     */
    [self waitUntilTappable:NO thenSendMessage:@"dismiss()"];

    // wait for the dismissal animation to finish
    [NSThread sleepForTimeInterval:0.5];
}

@end
