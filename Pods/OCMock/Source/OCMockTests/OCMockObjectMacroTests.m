/*
 *  Copyright (c) 2014 Erik Doernenburg and contributors
 *
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License. You may obtain
 *  a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 *  WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
 *  License for the specific language governing permissions and limitations
 *  under the License.
 */

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>


@protocol TestProtocolForMacroTesting
- (NSString *)stringValue;
@end

@interface TestClassForMacroTesting : NSObject <TestProtocolForMacroTesting>

@end

@implementation TestClassForMacroTesting

- (NSString *)stringValue
{
    return @"FOO";
}

@end


// implemented in OCMockObjectClassMethodMockingTests

@interface TestClassWithClassMethods : NSObject
+ (NSString *)foo;
+ (NSString *)bar;
- (NSString *)bar;
@end



@interface OCMockObjectMacroTests : XCTestCase
{
    BOOL        shouldCaptureFailure;
    NSString    *reportedDescription;
    NSString    *reportedFile;
    NSUInteger  reportedLine;
}

@end


@implementation OCMockObjectMacroTests

- (void)recordFailureWithDescription:(NSString *)description inFile:(NSString *)file atLine:(NSUInteger)line expected:(BOOL)expected
{
    if(shouldCaptureFailure)
    {
        reportedDescription = description;
        reportedFile = file;
        reportedLine = line;
    }
    else
    {
        [super recordFailureWithDescription:description inFile:file atLine:line expected:expected];
    }
}


- (void)testReportsVerifyFailureWithCorrectLocation
{
    id mock = OCMClassMock([NSString class]);
    
    [[mock expect] lowercaseString];
    
    shouldCaptureFailure = YES;
    OCMVerifyAll(mock); const char *expectedFile = __FILE__; int expectedLine = __LINE__;
    shouldCaptureFailure = NO;
    
    XCTAssertNotNil(reportedDescription, @"Should have recorded a failure with description.");
    XCTAssertEqualObjects([NSString stringWithUTF8String:expectedFile], reportedFile, @"Should have reported correct file.");
    XCTAssertEqual(expectedLine, (int)reportedLine, @"Should have reported correct line");
}

- (void)testReportsIgnoredExceptionsAtVerifyLocation
{
    id mock = OCMClassMock([NSString class]);
    
    [[mock reject] lowercaseString];

    @try
    {
        [mock lowercaseString];
    }
    @catch (NSException *exception)
    {
        // ignore; the mock will rethrow this in verify
    }

    shouldCaptureFailure = YES;
    OCMVerifyAll(mock); const char *expectedFile = __FILE__; int expectedLine = __LINE__;
    shouldCaptureFailure = NO;
    
    XCTAssertTrue([reportedDescription rangeOfString:@"ignored"].location != NSNotFound, @"Should have reported ignored exceptions.");
    XCTAssertEqualObjects([NSString stringWithUTF8String:expectedFile], reportedFile, @"Should have reported correct file.");
    XCTAssertEqual(expectedLine, (int)reportedLine, @"Should have reported correct line");
}

- (void)testReportsVerifyWithDelayFailureWithCorrectLocation
{
    id mock = OCMClassMock([NSString class]);

    [[mock expect] lowercaseString];

    shouldCaptureFailure = YES;
    OCMVerifyAllWithDelay(mock, 0.05); const char *expectedFile = __FILE__; int expectedLine = __LINE__;
    shouldCaptureFailure = NO;

    XCTAssertNotNil(reportedDescription, @"Should have recorded a failure with description.");
    XCTAssertEqualObjects([NSString stringWithUTF8String:expectedFile], reportedFile, @"Should have reported correct file.");
    XCTAssertEqual(expectedLine, (int)reportedLine, @"Should have reported correct line");
}


- (void)testSetsUpStubsForCorrectMethods
{
    id mock = OCMStrictClassMock([NSString class]);

    OCMStub([mock uppercaseString]).andReturn(@"TEST_STRING");

    XCTAssertEqualObjects(@"TEST_STRING", [mock uppercaseString], @"Should have returned stubbed value");
    XCTAssertThrows([mock lowercaseString]);
}

- (void)testSetsUpStubsWithNonObjectReturnValues
{
    id mock = OCMStrictClassMock([NSString class]);

    OCMStub([mock boolValue]).andReturn(YES);

    XCTAssertEqual(YES, [mock boolValue], @"Should have returned stubbed value");
}

- (void)testSetsUpStubsWithStructureReturnValues
{
    id mock = OCMStrictClassMock([NSString class]);

    NSRange expected = NSMakeRange(123, 456);
    OCMStub([mock rangeOfString:[OCMArg any]]).andReturn(expected);

    NSRange actual = [mock rangeOfString:@"substring"];
    XCTAssertEqual((NSUInteger)123, actual.location, @"Should have returned stubbed value");
    XCTAssertEqual((NSUInteger)456, actual.length, @"Should have returned stubbed value");
}

- (void)testSetsUpStubReturningNilForIdReturnType
{
    id mock = OCMClassMock([NSString class]);

    OCMStub([mock lowercaseString]).andReturn(nil);

    XCTAssertNil([mock lowercaseString], @"Should have returned stubbed value");
}

- (void)testSetsUpExceptionThrowing
{
    id mock = OCMClassMock([NSString class]);

    OCMStub([mock uppercaseString]).andThrow([NSException exceptionWithName:@"TestException" reason:@"Testing" userInfo:nil]);

    XCTAssertThrowsSpecificNamed([mock uppercaseString], NSException, @"TestException", @"Should have thrown correct exception");
}

- (void)testSetsUpNotificationPostingAndNotificationObserving
{
    id mock = OCMProtocolMock(@protocol(TestProtocolForMacroTesting));

    NSNotification *n = [NSNotification notificationWithName:@"TestNotification" object:nil];

    id observer = OCMObserverMock();
    [[NSNotificationCenter defaultCenter] addMockObserver:observer name:[n name] object:nil];
    OCMExpect([observer notificationWithName:[n name] object:[OCMArg any]]);

    OCMStub([mock stringValue]).andPost(n);

    [mock stringValue];

    OCMVerifyAll(observer);
}

- (void)testSetsUpSubstituteCall
{
    id mock = OCMStrictProtocolMock(@protocol(TestProtocolForMacroTesting));

    OCMStub([mock stringValue]).andCall(self, @selector(stringValueForTesting));

    XCTAssertEqualObjects([mock stringValue], @"TEST_STRING_FROM_TESTCASE", @"Should have called method from test case");
}

- (NSString *)stringValueForTesting
{
    return @"TEST_STRING_FROM_TESTCASE";
}


- (void)testCanChainPropertyBasedActions
{
    id mock = OCMPartialMock([[TestClassForMacroTesting alloc] init]);

    __block BOOL didCallBlock = NO;
    void (^theBlock)(NSInvocation *) = ^(NSInvocation *invocation)
    {
        didCallBlock = YES;
    };

    OCMStub([mock stringValue]).andDo(theBlock).andForwardToRealObject();

    NSString *actual = [mock stringValue];

    XCTAssertTrue(didCallBlock, @"Should have called block");
    XCTAssertEqualObjects(@"FOO", actual, @"Should have forwarded invocation");
}


- (void)testCanUseVariablesInInvocationSpec
{
    id mock = OCMStrictClassMock([NSString class]);

    NSString *expected = @"foo";
    OCMStub([mock rangeOfString:expected]).andReturn(NSMakeRange(0, 3));

    XCTAssertThrows([mock rangeOfString:@"bar"], @"Should not have accepted invocation with non-matching arg.");
}


- (void)testSetsUpExpectations
{
    id mock = OCMClassMock([TestClassForMacroTesting class]);

    OCMExpect([mock stringValue]).andReturn(@"TEST_STRING");

    XCTAssertThrows([mock verify], @"Should have complained about expected method not being invoked");

    XCTAssertEqual([mock stringValue], @"TEST_STRING", @"Should have stubbed method, too");
    XCTAssertNoThrow([mock verify], @"Should have accepted invocation as matching expectation");
}


- (void)testShouldNotReportErrorWhenMethodWasInvoked
{
    id mock = OCMClassMock([NSString class]);

    [mock lowercaseString];

    shouldCaptureFailure = YES;
    OCMVerify([mock lowercaseString]);
    shouldCaptureFailure = NO;

    XCTAssertNil(reportedDescription, @"Should not have recorded a failure.");
}

- (void)testShouldReportErrorWhenMethodWasNotInvoked
{
    id mock = OCMClassMock([NSString class]);

    [mock lowercaseString];

    shouldCaptureFailure = YES;
    OCMVerify([mock uppercaseString]); const char *expectedFile = __FILE__; int expectedLine = __LINE__;
    shouldCaptureFailure = NO;

    XCTAssertNotNil(reportedDescription, @"Should have recorded a failure with description.");
    XCTAssertEqualObjects([NSString stringWithUTF8String:expectedFile], reportedFile, @"Should have reported correct file.");
    XCTAssertEqual(expectedLine, (int)reportedLine, @"Should have reported correct line");
}

- (void)testShouldThrowDescriptiveExceptionWhenTryingToVerifyUnimplementedMethod
{
    id mock = OCMClassMock([NSString class]);

    // have not found a way to report the error; it seems we must throw an
    // exception to get out of the forwarding machinery
    XCTAssertThrowsSpecificNamed(OCMVerify([mock arrayByAddingObject:nil]),
                    NSException,
                    NSInvalidArgumentException,
                    @"should throw NSInvalidArgumentException exception");
}


- (void)testCanExplicitlySelectClassMethodForStubs
{
    id mock = OCMClassMock([TestClassWithClassMethods class]);

    OCMStub(ClassMethod([mock bar])).andReturn(@"mocked-class");
    OCMStub([mock bar]).andReturn(@"mocked-instance");

    XCTAssertEqualObjects(@"mocked-class", [TestClassWithClassMethods bar], @"Should have stubbed class method.");
    XCTAssertEqualObjects(@"mocked-instance", [mock bar], @"Should have stubbed instance method.");
}

- (void)testSelectsInstanceMethodForStubsWhenAmbiguous
{
    id mock = OCMClassMock([TestClassWithClassMethods class]);

    OCMStub([mock bar]).andReturn(@"mocked-instance");

    XCTAssertEqualObjects(@"mocked-instance", [mock bar], @"Should have stubbed instance method.");
}

- (void)testSelectsClassMethodForStubsWhenUnambiguous
{
    id mock = OCMClassMock([TestClassWithClassMethods class]);

    OCMStub([mock foo]).andReturn(@"mocked-class");

    XCTAssertEqualObjects(@"mocked-class", [TestClassWithClassMethods foo], @"Should have stubbed class method.");
}


- (void)testCanExplicitlySelectClassMethodForVerify
{
    id mock = OCMClassMock([TestClassWithClassMethods class]);

    [TestClassWithClassMethods bar];

    OCMVerify(ClassMethod([mock bar]));
}

- (void)testSelectsInstanceMethodForVerifyWhenAmbiguous
{
    id mock = OCMClassMock([TestClassWithClassMethods class]);

    [mock bar];

    OCMVerify([mock bar]);
}

- (void)testSelectsClassMethodForVerifyWhenUnambiguous
{
    id mock = OCMClassMock([TestClassWithClassMethods class]);

    [TestClassWithClassMethods foo];

    OCMVerify([mock foo]);
}


@end
