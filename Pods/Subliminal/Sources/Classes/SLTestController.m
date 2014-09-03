//
//  SLTestController.m
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

#import "SLTestController.h"
#import "SLTestController+Internal.h"

#import "SLLogger.h"
#import "SLTest.h"
#import "SLTest+Internal.h"
#import "SLTerminal.h"
#import "SLElement.h"
#import "SLAlert.h"
#import "SLDevice.h"

#import "SLStringUtilities.h"

#import <objc/runtime.h>


const unsigned int SLTestControllerRandomSeed = UINT_MAX;

static NSUncaughtExceptionHandler *appsUncaughtExceptionHandler = NULL;
static const NSTimeInterval kDefaultTimeout = 5.0;


@interface SLTestController () <UIAlertViewDelegate>

@end


/// Uncaught exceptions are logged to Subliminal for visibility.
static void SLUncaughtExceptionHandler(NSException *exception)
{
    if ([NSThread isMainThread]) {
        // We need to wait for UIAutomation, but we can't block the main thread,
        // so we spin the run loop instead.
        __block BOOL hasLogged = NO;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            [[SLLogger sharedLogger] logUncaughtException:exception];
            hasLogged = YES;
        });
        while (!hasLogged) {
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.25]];
        }
    } else {
        [[SLLogger sharedLogger] logUncaughtException:exception];
    }

    if (appsUncaughtExceptionHandler) {
        appsUncaughtExceptionHandler(exception);
    }
}


@implementation SLTestController {
    dispatch_queue_t _runQueue;
    unsigned int _runSeed;
    BOOL _runningWithFocus, _runningWithPredeterminedSeed;
    NSArray *_testsToRun;
    NSUInteger _numTestsExecuted, _numTestsFailed;
    void(^_completionBlock)(void);

    dispatch_semaphore_t _startTestingSemaphore;
    BOOL _shouldWaitToStartTesting;
}

+ (void)initialize {
    // initialize shared test controller, to prevent an SLTestController
    // from being manually initialized prior to +sharedTestController being invoked,
    // bypassing the assert at the top of -init
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
    [SLTestController sharedTestController];
#pragma clang diagnostic pop
}

// To use a preprocessor macro throughout this file, we'd have to specially build Subliminal
// when unit testing, e.g. using a "Unit Testing" build configuration
+ (BOOL)isBeingUnitTested {
    static BOOL isBeingUnitTested = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        isBeingUnitTested = (getenv("SL_UNIT_TESTING") != NULL);
    });
    return isBeingUnitTested;
}

static SLTestController *__sharedController = nil;
+ (instancetype)sharedTestController {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __sharedController = [[SLTestController alloc] init];
    });
    return __sharedController;
}

/// Produces a portable seed for `random()`, as suggested by
/// http://eternallyconfuzzled.com/arts/jsw_art_rand.aspx
unsigned int time_seed(){
    static time_t previousNow;
    time_t now = time ( 0 );
    if ([SLTestController isBeingUnitTested] && (now <= previousNow)) {
        // when unit testing, this function may be called repeatedly within the temporal resolution of `time`;
        // we adjust `now` to get different seeds
        now = previousNow + 1;
    }
    previousNow = now;

    unsigned char *p = (unsigned char *)&now;
    unsigned int seed = 0;
    size_t i;
    for (i = 0; i < sizeof now; i++) {
        seed = seed * ( UCHAR_MAX + 2U ) + p[i];
    }
    
    return seed;
}

/// a condensed version of the `uniform_deviate` function
/// also from http://eternallyconfuzzled.com/arts/jsw_art_rand.aspx
u_int32_t random_uniform(u_int32_t upperBound) {
    return ( random() / ( RAND_MAX + 1.0 ) ) * upperBound;
}

+ (NSArray *)testsToRun:(NSSet *)tests usingSeed:(inout unsigned int *)seed withFocus:(BOOL *)withFocus {
    NSMutableArray *testsToRun = [[NSMutableArray alloc] initWithCapacity:[tests count]];

    // identify run groups
    NSMutableDictionary *runGroups = [[NSMutableDictionary alloc] init];
    for (Class test in tests) {
        NSNumber *groupNumber = @([test runGroup]);
        NSMutableArray *group = runGroups[groupNumber];
        if (!group) {
            group = [[NSMutableArray alloc] init];
            runGroups[groupNumber] = group;
        }
        [group addObject:test];
    }

    // add the tests of each group to the array to run,
    // sorted by group number, but randomized within each group
    unsigned int seedSpecified = seed ? *seed : SLTestControllerRandomSeed;
    unsigned int seedUsed = (seedSpecified == SLTestControllerRandomSeed) ? time_seed() : seedSpecified;
    if (seed) *seed = seedUsed;
    srandom(seedUsed);

    for (NSNumber *groupNumber in [[runGroups allKeys] sortedArrayUsingSelector:@selector(compare:)]) {
        NSMutableArray *group = runGroups[groupNumber];

        // sort the group to produce a consistent basis for randomization
        [group sortUsingComparator:^NSComparisonResult(Class test1, Class test2) {
            // make sure to strip the focus prefix if present
            NSString *test1Name = [NSStringFromClass(test1) lowercaseString];
            if ([test1Name hasPrefix:SLTestFocusPrefix]) {
                test1Name = [test1Name substringFromIndex:[SLTestFocusPrefix length]];
            }
            NSString *test2Name = [NSStringFromClass(test2) lowercaseString];
            if ([test2Name hasPrefix:SLTestFocusPrefix]) {
                test2Name = [test2Name substringFromIndex:[SLTestFocusPrefix length]];
            }
            return [test1Name compare:test2Name];
        }];

        // randomize the group
        NSAssert([group count] <= (uint32_t)-1, @"The cast below is unsafe.");
        // http://en.wikipedia.org/wiki/Fisher–Yates_shuffle
        for (NSUInteger i = [group count] - 1; i > 0; --i) {
            [group exchangeObjectAtIndex:i withObjectAtIndex:random_uniform((u_int32_t)(i + 1))];
        }

        [testsToRun addObjectsFromArray:group];
    }

    // now filter the tests to run: only run tests that are concrete...
    [testsToRun filterUsingPredicate:[NSPredicate predicateWithFormat:@"isAbstract == NO"]];

    // ...that support the current platform...
    [testsToRun filterUsingPredicate:[NSPredicate predicateWithFormat:@"supportsCurrentPlatform == YES"]];

    // ...and that are focused (if any remaining are focused)
    NSMutableArray *focusedTests = [testsToRun mutableCopy];
    [focusedTests filterUsingPredicate:[NSPredicate predicateWithFormat:@"isFocused == YES"]];
    BOOL runningWithFocus = ([focusedTests count] > 0);
    if (runningWithFocus) {
        testsToRun = focusedTests;
    }
    if (withFocus) *withFocus = runningWithFocus;

    return [testsToRun copy];
}

- (id)init {
    NSAssert(!__sharedController, @"SLTestController should not be initialized manually. Use +sharedTestController instead.");
    
    self = [super init];
    if (self) {
        NSString *runQueueName = [NSString stringWithFormat:@"com.inkling.subliminal.SLTestController-%p.runQueue", self];
        _runQueue = dispatch_queue_create([runQueueName UTF8String], DISPATCH_QUEUE_SERIAL);
        _runSeed = SLTestControllerRandomSeed;
        _defaultTimeout = kDefaultTimeout;
        _startTestingSemaphore = dispatch_semaphore_create(0);
    }
    return self;
}

- (void)dealloc {
    dispatch_release(_runQueue);
    dispatch_release(_startTestingSemaphore);
}

- (BOOL)shouldWaitToStartTesting {
    return _shouldWaitToStartTesting;
}

- (void)setShouldWaitToStartTesting:(BOOL)shouldWaitToStartTesting {
    if (shouldWaitToStartTesting != _shouldWaitToStartTesting) {
        _shouldWaitToStartTesting = shouldWaitToStartTesting;
    }
}

// In certain environments like Travis, `instruments` intermittently hangs.
// When this occurs, it seems that the simulator is also in an inconsistent state
// such that it can't be rotated, web pages don't load, etc.
// If we detect that we are running in such an environment,
// abort so that the test runner can relaunch.
//
// Don't try to do this when unit testing; it shouldn't be necessary
// and communication with UIAutomation is disabled anyway.
#if TARGET_IPHONE_SIMULATOR
- (void)abortIfSimulatorIsInconsistent {
    if ([SLTestController isBeingUnitTested]) return;
    
    const UIDeviceOrientation testOrientation = UIDeviceOrientationPortrait;

    [[SLDevice currentDevice] setOrientation:testOrientation];
    BOOL simulatorIsConsistent = ([UIDevice currentDevice].orientation == testOrientation);
    if (!simulatorIsConsistent) {
        [[SLLogger sharedLogger] logError:@"Please relaunch the tests: the simulator is in an inconsistent state. This run will now abort."];
        abort();
    }
}
#endif

// Having the Accessibility Inspector enabled while tests are running
// can cause problems with touch handling and/or prevent UIAutomation's alert
// handler from being called.
//
// The Accessibility Inspector shouldn't affect unit tests, though (and the
// user directory path will be different in unit tests than when the application is running).
- (void)warnIfAccessibilityInspectorIsEnabled {
#if TARGET_IPHONE_SIMULATOR
    if ([SLTestController isBeingUnitTested]) return;

    // We detect if the Inspector is enabled by examining the simulator's Accessibility preferences
    // 1. get into the simulator's app support directory by fetching the sandboxed Library's path
    NSString *userDirectoryPath = [(NSURL *)[[[NSFileManager defaultManager] URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask] lastObject] path];

    // 2. get out of our application directory, back to the root support directory for this system version
    NSString *plistRootPath = [userDirectoryPath substringToIndex:([userDirectoryPath rangeOfString:@"Applications"].location)];
    
    // 3. locate, relative to here, the Accessibility preferences
    NSString *relativePlistPath = @"Library/Preferences/com.apple.Accessibility.plist";
    NSString *plistPath = [plistRootPath stringByAppendingPathComponent:relativePlistPath];

    // 4. Check whether the Inspector is enabled
    NSDictionary *accessibilityPreferences = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    if ([accessibilityPreferences[@"AXInspectorEnabled"] boolValue]) {
        [[SLLogger sharedLogger] logWarning:@"The Accessibility Inspector is enabled. Tests may not run as expected."];
    }
#endif
}

- (void)_beginTesting {
    appsUncaughtExceptionHandler = NSGetUncaughtExceptionHandler();
    NSSetUncaughtExceptionHandler(&SLUncaughtExceptionHandler);

    SLLog(@"Tests are starting up... ");

#if TARGET_IPHONE_SIMULATOR
    [self abortIfSimulatorIsInconsistent];
#endif

    // we use a local element resolution timeout
    // and suppress UIAutomation's timeout, to better control the timing of the tests
    [SLUIAElement setDefaultTimeout:_defaultTimeout];
    [[SLTerminal sharedTerminal] evalWithFormat:@"UIATarget.localTarget().setTimeout(0);"];

    [SLAlertHandler loadUIAAlertHandling];

#if DEBUG
    if (self.shouldWaitToStartTesting) {
        static NSString *const kWaitToStartTestingAlertTitle = @"Waiting to start testing...";

        SLAlert *waitToStartTestingAlert = [SLAlert alertWithTitle:kWaitToStartTestingAlertTitle];
        [SLAlertHandler addHandler:[waitToStartTestingAlert dismissByUser]];

        dispatch_async(dispatch_get_main_queue(), ^{
            [[[UIAlertView alloc] initWithTitle:kWaitToStartTestingAlertTitle
                                        message:@"You can attach the debugger now."
                                       delegate:self
                              cancelButtonTitle:@"Continue"
                              otherButtonTitles:nil] show];
        });
        dispatch_semaphore_wait(_startTestingSemaphore, DISPATCH_TIME_FOREVER);
    }
#endif

    if (_runningWithPredeterminedSeed) {
        SLLog(@"Running tests in order as predetermined by seed %u.", _runSeed);
    }
    if (_runningWithFocus) {
        SLLog(@"Focusing on test cases in specific tests: %@.", [_testsToRun componentsJoinedByString:@","]);
    }

    [self warnIfAccessibilityInspectorIsEnabled];

    [[SLLogger sharedLogger] logTestingStart];
}

- (void)runTests:(NSSet *)tests withCompletionBlock:(void (^)())completionBlock {
    [self runTests:tests usingSeed:SLTestControllerRandomSeed withCompletionBlock:completionBlock];
}

- (void)runTests:(NSSet *)tests usingSeed:(unsigned int)seed withCompletionBlock:(void (^)())completionBlock {
    dispatch_async(_runQueue, ^{
        _completionBlock = completionBlock;

        _runningWithPredeterminedSeed = (seed != SLTestControllerRandomSeed);
        _runSeed = seed;
        _testsToRun = [[self class] testsToRun:tests usingSeed:&_runSeed withFocus:&_runningWithFocus];
        if (![_testsToRun count]) {
            SLLog(@"%@%@%@", @"There are no tests to run", (_runningWithFocus) ? @": no tests are focused" : @"", @".");
            [self _finishTesting];
            return;
        }

        [self _beginTesting];

        for (Class testClass in _testsToRun) {
            @autoreleasepool {
                SLTest *test = (SLTest *)[[testClass alloc] init];

                NSString *testName = NSStringFromClass(testClass);
                [[SLLogger sharedLogger] logTestStart:testName];

                NSUInteger numCasesExecuted = 0, numCasesFailed = 0, numCasesFailedUnexpectedly = 0;

                BOOL testDidFinish = [test runAndReportNumExecuted:&numCasesExecuted
                                                            failed:&numCasesFailed
                                                failedUnexpectedly:&numCasesFailedUnexpectedly];
                if (testDidFinish) {
                    [[SLLogger sharedLogger] logTestFinish:testName
                                      withNumCasesExecuted:numCasesExecuted
                                            numCasesFailed:numCasesFailed
                                numCasesFailedUnexpectedly:numCasesFailedUnexpectedly];
                    if (numCasesFailed > 0) _numTestsFailed++;
                } else {
                    [[SLLogger sharedLogger] logTestAbort:testName];
                    _numTestsFailed++;
                }
                _numTestsExecuted++;
            }
        }

        [self _finishTesting];
    });
}

- (void)_finishTesting {
    [[SLLogger sharedLogger] logTestingFinishWithNumTestsExecuted:_numTestsExecuted
                                                   numTestsFailed:_numTestsFailed];

    if (_numTestsFailed > 0) {
        SLLog(@"The run order may be reproduced using seed %u.", _runSeed);
    }
    if (_runningWithPredeterminedSeed) {
        [[SLLogger sharedLogger] logWarning:@"Tests were run in a predetermined order."];
    }
    if (_runningWithFocus) {
        [[SLLogger sharedLogger] logWarning:@"This was a focused run. Fewer test cases may have run than normal."];
    }

    if (_completionBlock) dispatch_sync(dispatch_get_main_queue(), _completionBlock);

    // NOTE: Everything below the next line will not execute when running
    // from the command line, because the UIAutomation script will terminate,
    // and then the app.
    //
    // When running with the Instruments GUI, the script will terminate,
    // but the app will remain open and Instruments will keep recording
    // --the developer must explicitly stop recording to terminate the app.
    [[SLTerminal sharedTerminal] shutDown];

    // clear controller state (important when testing Subliminal, when the controller will test repeatedly)
    _numTestsExecuted = 0;
    _numTestsFailed = 0;
    _runSeed = SLTestControllerRandomSeed;
    _runningWithFocus = NO;
    _runningWithPredeterminedSeed = NO;
    _testsToRun = nil;
    _completionBlock = nil;

    // deregister Subliminal's exception handler
    // this is important when unit testing Subliminal, so that successive Subliminal testing runs
    // don't treat Subliminal's handler as the app's handler,
    // which would cause Subliminal's handler to recurse (as it calls the app's handler)
    NSSetUncaughtExceptionHandler(appsUncaughtExceptionHandler);
}


#pragma mark - UIAlertView delegate methods

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    dispatch_semaphore_signal(_startTestingSemaphore);
}

@end
