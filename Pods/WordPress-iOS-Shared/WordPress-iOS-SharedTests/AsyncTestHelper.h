#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>

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
    XCTAssertFalse(timedOut, @"Lock timed out");\
} while (0)

#define ATHNeverCalled(timeout) do {\
    BOOL timedOut;\
    NSDate *timeoutDate = [NSDate dateWithTimeIntervalSinceNow:timeout];\
    long lockStatus = 0;\
    while ((lockStatus = dispatch_semaphore_wait(ATHSemaphore, DISPATCH_TIME_NOW)) && [timeoutDate compare:[NSDate date]] == NSOrderedDescending)\
    [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode\
                             beforeDate:[NSDate dateWithTimeIntervalSinceNow:timeout]];\
    timedOut = (lockStatus != 0);\
    XCTAssertTrue(timedOut, @"Lock timed out");\
} while (0)

#define ATHEnd() do {\
    ATHWait(); \
    ATHSemaphore = nil;\
} while (0)

#define ATHEndNeverCalled(timeout) do {\
    ATHNeverCalled(timeout); \
    ATHSemaphore = nil;\
} while (0)