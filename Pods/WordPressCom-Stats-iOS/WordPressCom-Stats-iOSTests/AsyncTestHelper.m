#import "AsyncTestHelper.h"

dispatch_semaphore_t ATHSemaphore;
const NSTimeInterval AsyncTestCaseDefaultTimeout = 10;
int ddLogLevel = LOG_LEVEL_INFO;