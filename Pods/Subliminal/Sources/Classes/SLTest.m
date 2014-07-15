//
//  SLTest.m
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

#import "SLTest.h"
#import "SLTest+Internal.h"

#import "SLLogger.h"
#import "SLElement.h"

#import <objc/runtime.h>
#import <objc/message.h>


// All exceptions thrown by SLTest must have names beginning with this prefix
// so that `-[SLTest exceptionByAddingFileInfo:]` can determine whether to attach
// call site information to exceptions.
static NSString *const SLTestExceptionNamePrefix       = @"SLTest";

NSString *const SLTestAssertionFailedException  = @"SLTestCaseAssertionFailedException";

const NSTimeInterval SLWaitUntilTrueRetryDelay = 0.25;


@implementation SLTest {
    NSString *_lastKnownFilename;
    int _lastKnownLineNumber;
}

+ (NSSet *)allTests {
    NSMutableSet *tests = [[NSMutableSet alloc] init];
    
    int numClasses = objc_getClassList(NULL, 0);
    if (numClasses > 0) {
        Class *classes = (Class *)malloc(sizeof(Class) * numClasses);
        objc_getClassList(classes, numClasses);
        
        for (int i = 0; i < numClasses; i++) {
            Class klass = classes[i];
            Class metaClass = object_getClass(klass);
            // Class methods are defined on the metaclass
            if (class_respondsToSelector(metaClass, @selector(isSubclassOfClass:)) &&
                [klass isSubclassOfClass:[SLTest class]]) {
                [tests addObject:klass];
            }
        }
        
        free(classes);
    }
    
    return tests;
}

+ (Class)testNamed:(NSString *)name {
    NSParameterAssert(name);
    
    Class klass = NSClassFromString(name);
    // perhaps the test is focused
    if (!klass) klass = NSClassFromString([SLTestFocusPrefix stringByAppendingString:name]);
    if (!klass) klass = NSClassFromString([[SLTestFocusPrefix capitalizedString] stringByAppendingString:name]);
    
    BOOL classIsTestClass = (class_respondsToSelector(object_getClass(klass), @selector(isSubclassOfClass:)) &&
                             [klass isSubclassOfClass:[SLTest class]]);
    return (classIsTestClass ? klass : nil);
}

+ (BOOL)isAbstract {
    return ![[self testCases] count];
}

+ (BOOL)isFocused {    
    for (NSString *testCaseName in [self focusedTestCases]) {
        // pass the unfocused selector, as focus is temporary and shouldn't require modifying the test infrastructure
        SEL unfocusedTestCaseSelector = NSSelectorFromString([self unfocusedTestCaseName:testCaseName]);
        if ([self testCaseWithSelectorSupportsCurrentPlatform:unfocusedTestCaseSelector]) return YES;
    }
    return NO;
}

+ (BOOL)supportsCurrentPlatform {
    // examine whether this test or any of its superclasses are annotated
    // the "nearest" annotation determines support ("nearest" like with method overrides)
    BOOL testSupportsCurrentDevice = YES;
    UIUserInterfaceIdiom userInterfaceIdiom = [[UIDevice currentDevice] userInterfaceIdiom];
    Class testClass = self;
    while (testClass != [SLTest class]) {
        NSString *testName = NSStringFromClass(testClass);
        if ([testName hasSuffix:@"_iPad"]) {
            testSupportsCurrentDevice = (userInterfaceIdiom == UIUserInterfaceIdiomPad);
            break;
        } else if ([testName hasSuffix:@"_iPhone"]) {
            testSupportsCurrentDevice = (userInterfaceIdiom == UIUserInterfaceIdiomPhone);
            break;
        }
        testClass = [testClass superclass];
    }

    return testSupportsCurrentDevice;
}

+ (NSUInteger)runGroup {
    return 1;
}

- (void)setUpTest {
    // nothing to do here
}

- (void)tearDownTest {
    // nothing to do here
}

- (void)setUpTestCaseWithSelector:(SEL)testCaseSelector {
    // nothing to do here
}

- (void)tearDownTestCaseWithSelector:(SEL)testCaseSelector {
    // nothing to do here
}

+ (NSSet *)testCases {
    static const void *const kTestCasesKey = &kTestCasesKey;
    NSSet *testCases = objc_getAssociatedObject(self, kTestCasesKey);
    if (!testCases) {
        static NSString *const kTestCaseNamePrefix = @"test";

        NSMutableSet *selectorStrings = [NSMutableSet set];
        Class testClass = self;
        while (testClass != [SLTest class]) {
            unsigned int methodCount;
            Method *methods = class_copyMethodList(testClass, &methodCount);
            for (unsigned int i = 0; i < methodCount; i++) {
                Method method = methods[i];
                SEL selector = method_getName(method);
                char *methodReturnType = method_copyReturnType(method);
                NSString *selectorString = NSStringFromSelector(selector);

                // ignore the focus prefix for the purposes of aggregating all the test cases
                NSString *unfocusedTestCaseName = [self unfocusedTestCaseName:selectorString];

                if ([unfocusedTestCaseName hasPrefix:kTestCaseNamePrefix] &&
                    methodReturnType && strlen(methodReturnType) > 0 && methodReturnType[0] == 'v' &&
                    ![selectorString hasSuffix:@":"]) {
                    // make sure to add the actual selector name including focus
                    [selectorStrings addObject:selectorString];
                }
                
                if (methodReturnType) free(methodReturnType);
            }
            if (methods) free(methods);
            testClass = [testClass superclass];
        }

        objc_setAssociatedObject(self, kTestCasesKey, selectorStrings, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        testCases = selectorStrings;
    }
    return testCases;
}

+ (NSSet *)focusedTestCases {
    static const void *const kFocusedTestCasesKey = &kFocusedTestCasesKey;
    NSSet *focusedTestCases = objc_getAssociatedObject(self, kFocusedTestCasesKey);
    if (!focusedTestCases) {
        NSSet *testCases = [self testCases];

        // if any test cases are prefixed, only those test cases are focused
        focusedTestCases = [testCases filteredSetUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSString *testCase, NSDictionary *bindings) {
            return [[testCase lowercaseString] hasPrefix:SLTestFocusPrefix];
        }]];

        // otherwise, if our class' name (or the name of any superclass) is prefixed,
        // all test cases are focused
        if (![focusedTestCases count]) {
            BOOL classIsFocused = NO;
            Class testClass = self;
            while (testClass != [SLTest class]) {
                if ([[NSStringFromClass(testClass) lowercaseString] hasPrefix:SLTestFocusPrefix]) {
                    classIsFocused = YES;
                    break;
                }
                testClass = [testClass superclass];
            }
            if (classIsFocused) {
                focusedTestCases = [testCases copy];
            }
        }
        
        objc_setAssociatedObject(self, kFocusedTestCasesKey, focusedTestCases, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return focusedTestCases;
}

+ (NSSet *)testCasesToRun {
    NSSet *baseTestCases = (([self isFocused]) ? [self focusedTestCases] : [self testCases]);
    return [baseTestCases filteredSetUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        // pass the unfocused selector, as focus is temporary and shouldn't require modifying the test infrastructure
        SEL unfocusedTestCaseSelector = NSSelectorFromString([self unfocusedTestCaseName:evaluatedObject]);
        return [self testCaseWithSelectorSupportsCurrentPlatform:unfocusedTestCaseSelector];
    }]];
}

+ (NSString *)unfocusedTestCaseName:(NSString *)testCase {
    NSRange rangeOfFocusPrefix = [testCase rangeOfString:SLTestFocusPrefix];
    if (rangeOfFocusPrefix.location == 0) {
        testCase = [testCase substringFromIndex:NSMaxRange(rangeOfFocusPrefix)];
    }
    return testCase;
}

+ (BOOL)testCaseWithSelectorSupportsCurrentPlatform:(SEL)testCaseSelector {
    NSString *testCaseName = NSStringFromSelector(testCaseSelector);
    
    UIUserInterfaceIdiom userInterfaceIdiom = [[UIDevice currentDevice] userInterfaceIdiom];
    if ([testCaseName hasSuffix:@"_iPad"]) return (userInterfaceIdiom == UIUserInterfaceIdiomPad);
    if ([testCaseName hasSuffix:@"_iPhone"]) return (userInterfaceIdiom == UIUserInterfaceIdiomPhone);
    return YES;
 }

- (BOOL)runAndReportNumExecuted:(NSUInteger *)numCasesExecuted
                         failed:(NSUInteger *)numCasesFailed
             failedUnexpectedly:(NSUInteger *)numCasesFailedUnexpectedly {
    NSUInteger numberOfCasesExecuted = 0, numberOfCasesFailed = 0, numberOfCasesFailedUnexpectedly = 0;

    BOOL testDidFailInSetUpOrTearDown = NO;
    @try {
        [self setUpTest];
    }
    @catch (NSException *exception) {
        [[SLLogger sharedLogger] logException:[self exceptionByAddingFileInfo:exception]
                                     expected:[[self class] exceptionWasExpected:exception]];
        testDidFailInSetUpOrTearDown = YES;
    }

    // if setUpTest failed, skip the test cases
    if (!testDidFailInSetUpOrTearDown) {
        NSString *test = NSStringFromClass([self class]);
        for (NSString *testCaseName in [[self class] testCasesToRun]) {
            @autoreleasepool {
                // all logs below use the focused name, so that the logs are consistent
                // with what's actually running
                [[SLLogger sharedLogger] logTest:test caseStart:testCaseName];

                // but pass the unfocused selector to setUp/tearDown methods,
                // because focus is temporary and shouldn't require modifying the test infrastructure
                SEL unfocusedTestCaseSelector = NSSelectorFromString([[self class] unfocusedTestCaseName:testCaseName]);

                // clear call site information, so at the least it won't be reused between test cases
                // (though we can't guarantee it won't be reused within a test case)
                [self clearLastKnownCallSite];

                BOOL caseFailed = NO, failureWasExpected = NO;
                @try {
                    [self setUpTestCaseWithSelector:unfocusedTestCaseSelector];
                }
                @catch (NSException *exception) {
                    caseFailed = YES;
                    failureWasExpected = [[self class] exceptionWasExpected:exception];
                    [[SLLogger sharedLogger] logException:[self exceptionByAddingFileInfo:exception]
                                                 expected:failureWasExpected];
                }

                // Only execute the test case if set-up succeeded.
                if (!caseFailed) {
                    @try {
                        // We use objc_msgSend so that Clang won't complain about performSelector leaks
                        // Make sure to send the actual test case selector
                        ((void(*)(id, SEL))objc_msgSend)(self, NSSelectorFromString(testCaseName));
                    }
                    @catch (NSException *exception) {
                        caseFailed = YES;
                        failureWasExpected = [[self class] exceptionWasExpected:exception];
                        [[SLLogger sharedLogger] logException:[self exceptionByAddingFileInfo:exception]
                                                     expected:failureWasExpected];
                    }
                }

                // Still perform tear-down even if set-up failed.
                // If the app is in an inconsistent state, then tear-down should fail.
                @try {
                    [self tearDownTestCaseWithSelector:unfocusedTestCaseSelector];
                }
                @catch (NSException *exception) {
                    BOOL caseHadFailed = caseFailed;
                    caseFailed = YES;
                    // don't override `failureWasExpected` if we had already failed
                    BOOL exceptionWasExpected = [[self class] exceptionWasExpected:exception];
                    if (!caseHadFailed) failureWasExpected = exceptionWasExpected;
                    [[SLLogger sharedLogger] logException:[self exceptionByAddingFileInfo:exception]
                                                 expected:exceptionWasExpected];
                }

                if (caseFailed) {
                    [[SLLogger sharedLogger] logTest:test caseFail:testCaseName expected:failureWasExpected];
                    numberOfCasesFailed++;
                    if (!failureWasExpected) numberOfCasesFailedUnexpectedly++;
                } else {
                    [[SLLogger sharedLogger] logTest:test casePass:testCaseName];
                }
                numberOfCasesExecuted++;
            }
        }
    }

    // still perform tearDownTest even if setUpTest failed
    @try {
        [self tearDownTest];
    }
    @catch (NSException *exception) {
        [[SLLogger sharedLogger] logException:[self exceptionByAddingFileInfo:exception]
                                     expected:[[self class] exceptionWasExpected:exception]];
        testDidFailInSetUpOrTearDown = YES;
    }

    if (numCasesExecuted) *numCasesExecuted = numberOfCasesExecuted;
    if (numCasesFailed) *numCasesFailed = numberOfCasesFailed;
    if (numCasesFailedUnexpectedly) *numCasesFailedUnexpectedly = numberOfCasesFailedUnexpectedly;

    return !testDidFailInSetUpOrTearDown;
}

- (void)wait:(NSTimeInterval)interval {
    [NSThread sleepForTimeInterval:interval];
}

- (void)recordLastKnownFile:(const char *)filename line:(int)lineNumber {
    _lastKnownFilename = [@(filename) lastPathComponent];
    _lastKnownLineNumber = lineNumber;
}

- (void)clearLastKnownCallSite {
    _lastKnownFilename = nil;
    _lastKnownLineNumber = 0;
}

- (NSException *)exceptionByAddingFileInfo:(NSException *)exception {
    // Only use the call site information if we have information
    // and if the exception was thrown by `SLTest` or `SLUIAElement`,
    // where the information was likely to have been recorded by an assertion or UIAElement macro.
    // Otherwise it is likely stale.
    if (_lastKnownFilename &&
        ([[exception name] hasPrefix:SLTestExceptionNamePrefix] ||
         [[exception name] hasPrefix:SLUIAElementExceptionNamePrefix])) {
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:[exception userInfo]];
        userInfo[SLLoggerExceptionFilenameKey] = _lastKnownFilename;
        userInfo[SLLoggerExceptionLineNumberKey] = @(_lastKnownLineNumber);

        exception = [NSException exceptionWithName:[exception name] reason:[exception reason] userInfo:userInfo];
    }

    // Regardless of whether we used it or not,
    // call site info is now stale
    [self clearLastKnownCallSite];

    return exception;
}

+ (BOOL)exceptionWasExpected:(NSException *)exception {
    return [[exception name] isEqualToString:SLTestAssertionFailedException];
}

@end

