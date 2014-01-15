//
//  AsyncTestHelper.m
//  WordPress
//
//  Created by Jorge Bernal on 2/12/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "AsyncTestHelper.h"

dispatch_semaphore_t ATHSemaphore;
const NSTimeInterval AsyncTestCaseDefaultTimeout = 10;

@implementation AsyncTestHelper {
    dispatch_semaphore_t _semaphore;
}

- (id)init {
    self = [super init];
    if (self) {
        _semaphore = dispatch_semaphore_create(0);
    }
    return self;
}

- (void)notify {
    dispatch_semaphore_signal(_semaphore);
}

- (BOOL)wait {
    NSDate *timeoutDate = [NSDate dateWithTimeIntervalSinceNow:AsyncTestCaseDefaultTimeout];
    long lockStatus = 0;
    while ((lockStatus = dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_NOW)) && [timeoutDate compare:[NSDate date]] == NSOrderedDescending) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:AsyncTestCaseDefaultTimeout]];
    }

    return (lockStatus == 0);
}

@end