//
//  AsyncTestHelper.h
//  WordPress
//
//  Created by Jorge Bernal on 2/12/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SenTestingKit/SenTestingKit.h>

extern dispatch_semaphore_t ATHSemaphore;
extern const NSTimeInterval AsyncTestCaseDefaultTimeout;

#define ATHStart() do {\
    ATHSemaphore = dispatch_semaphore_create(0);\
} while (0)

#define ATHNotify() do {\
    dispatch_semaphore_signal(ATHSemaphore);\
} while (0)

#define ATHWait() do {\
    BOOL timedOut;\
    NSDate *timeoutDate = [NSDate dateWithTimeIntervalSinceNow:AsyncTestCaseDefaultTimeout];\
    long lockStatus = 0;\
    while ((lockStatus = dispatch_semaphore_wait(ATHSemaphore, DISPATCH_TIME_NOW)) && [timeoutDate compare:[NSDate date]] == NSOrderedDescending)\
    [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode\
                             beforeDate:[NSDate dateWithTimeIntervalSinceNow:AsyncTestCaseDefaultTimeout]];\
    timedOut = (lockStatus != 0);\
    STAssertFalse(timedOut, @"Lock timed out");\
} while (0)

#define ATHNeverCalled(timeout) do {\
    BOOL timedOut;\
    NSDate *timeoutDate = [NSDate dateWithTimeIntervalSinceNow:timeout];\
    long lockStatus = 0;\
    while ((lockStatus = dispatch_semaphore_wait(ATHSemaphore, DISPATCH_TIME_NOW)) && [timeoutDate compare:[NSDate date]] == NSOrderedDescending)\
    [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode\
                             beforeDate:[NSDate dateWithTimeIntervalSinceNow:timeout]];\
    timedOut = (lockStatus != 0);\
    STAssertTrue(timedOut, @"Lock timed out");\
} while (0)

#define ATHEnd() do {\
    ATHWait(); \
    dispatch_release(ATHSemaphore);\
} while (0)

#define ATHEndNeverCalled(timeout) do {\
    ATHNeverCalled(timeout); \
    dispatch_release(ATHSemaphore);\
} while (0)