//
//  NSPipe+Utilities.m
//  subliminal-instrument
//
//  For details and documentation:
//  http://github.com/inkling/Subliminal
//
//  Copyright 2014 Inkling Systems, Inc.
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

#import "NSPipe+Utilities.h"

#import <objc/runtime.h>

static const void *kReadObserverKey = &kReadObserverKey;
static const void *kWaitingForDataKey = &kWaitingForDataKey;
static const void *kAvailableDataKey = &kAvailableDataKey;

@implementation NSPipe (Utilities)

- (NSData *)availableData {
    return objc_getAssociatedObject(self, kAvailableDataKey);
}

- (void)beginReadingInBackground {
    id dataObserver = objc_getAssociatedObject(self, kReadObserverKey);
    if (dataObserver) return;

    NSFileHandle *readHandle = [self fileHandleForReading];

    __typeof(self) __weak weakSelf = self;
    dataObserver = [[NSNotificationCenter defaultCenter] addObserverForName:NSFileHandleReadToEndOfFileCompletionNotification object:readHandle queue:nil usingBlock:^(NSNotification *note) {
        [[NSNotificationCenter defaultCenter] removeObserver:dataObserver];

        __typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf) {
            @synchronized(strongSelf) {
                objc_setAssociatedObject(strongSelf, kReadObserverKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                objc_setAssociatedObject(strongSelf, kAvailableDataKey, [note userInfo][NSFileHandleNotificationDataItem], OBJC_ASSOCIATION_RETAIN_NONATOMIC);

                // let `-finishReading` exit if it's waiting
                if (objc_getAssociatedObject(strongSelf, kWaitingForDataKey)) CFRunLoopStop(CFRunLoopGetCurrent());
            }
        }
    }];
    objc_setAssociatedObject(self, kReadObserverKey, dataObserver, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    [readHandle readToEndOfFileInBackgroundAndNotify];
}

- (void)finishReading {
    @synchronized(self) {
        // if we haven't already finished reading, signal EOF
        if (objc_getAssociatedObject(self, kReadObserverKey)) {
            [[self fileHandleForWriting] closeFile];

            // run until our read handle finishes reading
            objc_setAssociatedObject(self, kWaitingForDataKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            CFRunLoopRun();
        }
    }
}

@end
