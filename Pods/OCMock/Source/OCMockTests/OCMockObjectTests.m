/*
 *  Copyright (c) 2004-2014 Erik Doernenburg and contributors
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


// --------------------------------------------------------------------------------------
//	Helper classes and protocols for testing
// --------------------------------------------------------------------------------------

@interface TestClassWithSelectorMethod : NSObject

- (void)doWithSelector:(SEL)aSelector;

@end

@implementation TestClassWithSelectorMethod

- (void)doWithSelector:(SEL)aSelector
{
}

@end


@interface TestClassWithTypeQualifierMethod : NSObject

- (void)aSpecialMethod:(byref in void *)someArg;

@end

@implementation TestClassWithTypeQualifierMethod

- (void)aSpecialMethod:(byref in void *)someArg
{
}

@end


@interface TestClassWithIntPointerMethod : NSObject

- (void)returnValueInPointer:(int *)ptr;

@end

@implementation TestClassWithIntPointerMethod

- (void)returnValueInPointer:(int *)ptr
{
    *ptr = 555;
}

@end


@interface NotificationRecorderForTesting : NSObject
{
	@public
	NSNotification *notification;
}

@end

@implementation NotificationRecorderForTesting

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[notification release];
	[super dealloc];
}

- (void)receiveNotification:(NSNotification *)aNotification
{
	notification = [aNotification retain];
}

@end

static NSString *TestNotification = @"TestNotification";


@interface OCMockObjectTests : XCTestCase
{
	id mock;
}

@end


// --------------------------------------------------------------------------------------
//  setup
// --------------------------------------------------------------------------------------


@implementation OCMockObjectTests

- (void)setUp
{
	mock = [OCMockObject mockForClass:[NSString class]];
}


// --------------------------------------------------------------------------------------
//	accepting stubbed methods / rejecting methods not stubbed
// --------------------------------------------------------------------------------------

- (void)testAcceptsStubbedMethod
{
	[[mock stub] lowercaseString];
	[mock lowercaseString];
}

- (void)testRaisesExceptionWhenUnknownMethodIsCalled
{
	[[mock stub] lowercaseString];
	XCTAssertThrows([mock uppercaseString], @"Should have raised an exception.");
}


- (void)testAcceptsStubbedMethodWithSpecificArgument
{
	[[mock stub] hasSuffix:@"foo"];
	[mock hasSuffix:@"foo"];
}


- (void)testAcceptsStubbedMethodWithConstraint
{
	[[mock stub] hasSuffix:[OCMArg any]];
	[mock hasSuffix:@"foo"];
	[mock hasSuffix:@"bar"];
}

- (void)testAcceptsStubbedMethodWithBlockArgument
{
	mock = [OCMockObject mockForClass:[NSArray class]];
	[[mock stub] indexesOfObjectsPassingTest:[OCMArg any]];
	[mock indexesOfObjectsPassingTest:^(id obj, NSUInteger idx, BOOL *stop) { return YES; }];
}


- (void)testAcceptsStubbedMethodWithBlockConstraint
{
	[[mock stub] hasSuffix:[OCMArg checkWithBlock:^(id value) { return [value isEqualToString:@"foo"]; }]];

	XCTAssertNoThrow([mock hasSuffix:@"foo"], @"Should not have thrown a exception");
	XCTAssertThrows([mock hasSuffix:@"bar"], @"Should have thrown a exception");
}


- (void)testAcceptsStubbedMethodWithNilArgument
{
	[[mock stub] hasSuffix:nil];
	[mock hasSuffix:nil];
}

- (void)testRaisesExceptionWhenMethodWithWrongArgumentIsCalled
{
	[[mock stub] hasSuffix:@"foo"];
	XCTAssertThrows([mock hasSuffix:@"xyz"], @"Should have raised an exception.");
}


- (void)testAcceptsStubbedMethodWithScalarArgument
{
	[[mock stub] stringByPaddingToLength:20 withString:@"foo" startingAtIndex:5];
	[mock stringByPaddingToLength:20 withString:@"foo" startingAtIndex:5];
}

- (void)testRaisesExceptionWhenMethodWithOneWrongScalarArgumentIsCalled
{
	[[mock stub] stringByPaddingToLength:20 withString:@"foo" startingAtIndex:5];
	XCTAssertThrows([mock stringByPaddingToLength:20 withString:@"foo" startingAtIndex:3], @"Should have raised an exception.");
}


- (void)testAcceptsStubbedMethodWithSelectorArgument
{
    mock = [OCMockObject mockForClass:[TestClassWithSelectorMethod class]];
    [[mock stub] doWithSelector:@selector(allKeys)];
    [mock doWithSelector:@selector(allKeys)];
}

- (void)testRaisesExceptionWhenMethodWithWrongSelectorArgumentIsCalled
{
    mock = [OCMockObject mockForClass:[TestClassWithSelectorMethod class]];
    [[mock stub] doWithSelector:@selector(allKeys)];
    XCTAssertThrows([mock doWithSelector:@selector(allValues)]);
}

- (void)testAcceptsStubbedMethodWithAnySelectorArgument
{
    mock = [OCMockObject mockForClass:[TestClassWithSelectorMethod class]];
    [[mock stub] doWithSelector:[OCMArg anySelector]];
    [mock doWithSelector:@selector(allKeys)];
}


- (void)testAcceptsStubbedMethodWithPointerArgument
{
	NSError *error;
	[[[mock stub] andReturnValue:@YES] writeToFile:[OCMArg any] atomically:YES encoding:NSMacOSRomanStringEncoding error:&error];

	XCTAssertTrue([mock writeToFile:@"foo" atomically:YES encoding:NSMacOSRomanStringEncoding error:&error]);
}

- (void)testRaisesExceptionWhenMethodWithWrongPointerArgumentIsCalled
{
	NSString *string;
	NSString *anotherString;
	NSArray *array;

	[[mock stub] completePathIntoString:&string caseSensitive:YES matchesIntoArray:&array filterTypes:[OCMArg any]];

	XCTAssertThrows([mock completePathIntoString:&anotherString caseSensitive:YES matchesIntoArray:&array filterTypes:[OCMArg any]]);
}

- (void)testAcceptsStubbedMethodWithAnyPointerArgument
{
    [[[mock stub] andReturn:@"foo"] initWithCharacters:[OCMArg anyPointer] length:3];

    unichar characters[] = { 'b', 'a', 'r' };
    id result = [mock initWithCharacters:characters length:3];

    XCTAssertEqualObjects(@"foo", result, @"Should have mocked method.");
}


- (void)testAcceptsStubbedMethodWithAnyObjectRefArgument
{
    NSError *error;
    [[[mock stub] andReturnValue:@YES] writeToFile:[OCMArg any] atomically:YES encoding:NSMacOSRomanStringEncoding error:[OCMArg anyObjectRef]];

    XCTAssertTrue([mock writeToFile:@"foo" atomically:YES encoding:NSMacOSRomanStringEncoding error:&error]);
}

- (void)testAcceptsStubbedMethodWithVoidPointerArgument
{
	mock = [OCMockObject mockForClass:[NSMutableData class]];
	[[mock stub] appendBytes:NULL length:0];
	[mock appendBytes:NULL length:0];
}


- (void)testRaisesExceptionWhenMethodWithWrongVoidPointerArgumentIsCalled
{
	mock = [OCMockObject mockForClass:[NSMutableData class]];
	[[mock stub] appendBytes:"foo" length:3];
	XCTAssertThrows([mock appendBytes:"bar" length:3], @"Should have raised an exception.");
}


- (void)testAcceptsStubbedMethodWithPointerPointerArgument
{
	NSError *error = nil;
	[[mock stub] initWithContentsOfFile:@"foo.txt" encoding:NSASCIIStringEncoding error:&error];
	[mock initWithContentsOfFile:@"foo.txt" encoding:NSASCIIStringEncoding error:&error];
}


- (void)testRaisesExceptionWhenMethodWithWrongPointerPointerArgumentIsCalled
{
	NSError *error = nil, *error2;
	[[mock stub] initWithContentsOfFile:@"foo.txt" encoding:NSASCIIStringEncoding error:&error];
	XCTAssertThrows([mock initWithContentsOfFile:@"foo.txt" encoding:NSASCIIStringEncoding error:&error2], @"Should have raised.");
}


- (void)testAcceptsStubbedMethodWithStructArgument
{
    NSRange range = NSMakeRange(0,20);
	[[mock stub] substringWithRange:range];
	[mock substringWithRange:range];
}


- (void)testRaisesExceptionWhenMethodWithWrongStructArgumentIsCalled
{
    NSRange range = NSMakeRange(0,20);
    NSRange otherRange = NSMakeRange(0,10);
	[[mock stub] substringWithRange:range];
	XCTAssertThrows([mock substringWithRange:otherRange], @"Should have raised an exception.");
}


- (void)testCanPassMocksAsArguments
{
	id mockArg = [OCMockObject mockForClass:[NSString class]];
	[[mock stub] stringByAppendingString:[OCMArg any]];
	[mock stringByAppendingString:mockArg];
}

- (void)testCanStubWithMockArguments
{
	id mockArg = [OCMockObject mockForClass:[NSString class]];
	[[mock stub] stringByAppendingString:mockArg];
	[mock stringByAppendingString:mockArg];
}

- (void)testRaisesExceptionWhenStubbedMockArgIsNotUsed
{
	id mockArg = [OCMockObject mockForClass:[NSString class]];
	[[mock stub] stringByAppendingString:mockArg];
	XCTAssertThrows([mock stringByAppendingString:@"foo"], @"Should have raised an exception.");
}

- (void)testRaisesExceptionWhenDifferentMockArgumentIsPassed
{
	id expectedArg = [OCMockObject mockForClass:[NSString class]];
	id otherArg = [OCMockObject mockForClass:[NSString class]];
	[[mock stub] stringByAppendingString:otherArg];
	XCTAssertThrows([mock stringByAppendingString:expectedArg], @"Should have raised an exception.");
}


- (void)testAcceptsStubbedMethodWithAnyNonObjectArgument
{
    [[[mock stub] ignoringNonObjectArgs] rangeOfString:@"foo" options:0];
    [mock rangeOfString:@"foo" options:NSRegularExpressionSearch];
}

- (void)testRaisesExceptionWhenMethodWithMixedArgumentsIsCalledWithWrongObjectArgument
{
    [[[mock stub] ignoringNonObjectArgs] rangeOfString:@"foo" options:0];
    XCTAssertThrows([mock rangeOfString:@"bar" options:NSRegularExpressionSearch], @"Should have raised an exception.");
}


// --------------------------------------------------------------------------------------
//	returning values from stubbed methods
// --------------------------------------------------------------------------------------

- (void)testReturnsStubbedReturnValue
{
	[[[mock stub] andReturn:@"megamock"] lowercaseString];
	id returnValue = [mock lowercaseString];

	XCTAssertEqualObjects(@"megamock", returnValue, @"Should have returned stubbed value.");
}

- (void)testReturnsStubbedIntReturnValue
{
	[[[mock stub] andReturnValue:@42] intValue];
	int returnValue = [mock intValue];

	XCTAssertEqual(42, returnValue, @"Should have returned stubbed value.");
}

- (void)testRaisesWhenBoxedValueTypesDoNotMatch
{
	[[[mock stub] andReturnValue:@42.0] intValue];

	XCTAssertThrows([mock intValue], @"Should have raised an exception.");
}

- (void)testReturnsStubbedNilReturnValue
{
	[[[mock stub] andReturn:nil] uppercaseString];

	id returnValue = [mock uppercaseString];

	XCTAssertNil(returnValue, @"Should have returned stubbed value, which is nil.");
}


// --------------------------------------------------------------------------------------
//	beyond stubbing: raising exceptions, posting notifications, etc.
// --------------------------------------------------------------------------------------

- (void)testRaisesExceptionWhenAskedTo
{
	NSException *exception = [NSException exceptionWithName:@"TestException" reason:@"test" userInfo:nil];
	[[[mock expect] andThrow:exception] lowercaseString];

	XCTAssertThrows([mock lowercaseString], @"Should have raised an exception.");
}

- (void)testPostsNotificationWhenAskedTo
{
	NotificationRecorderForTesting *observer = [[[NotificationRecorderForTesting alloc] init] autorelease];
	[[NSNotificationCenter defaultCenter] addObserver:observer selector:@selector(receiveNotification:) name:TestNotification object:nil];

	NSNotification *notification = [NSNotification notificationWithName:TestNotification object:self];
	[[[mock stub] andPost:notification] lowercaseString];

	[mock lowercaseString];

	XCTAssertNotNil(observer->notification, @"Should have sent a notification.");
	XCTAssertEqualObjects(TestNotification, [observer->notification name], @"Name should match posted one.");
	XCTAssertEqualObjects(self, [observer->notification object], @"Object should match posted one.");
}

- (void)testPostsNotificationInAdditionToReturningValue
{
	NotificationRecorderForTesting *observer = [[[NotificationRecorderForTesting alloc] init] autorelease];
	[[NSNotificationCenter defaultCenter] addObserver:observer selector:@selector(receiveNotification:) name:TestNotification object:nil];

	NSNotification *notification = [NSNotification notificationWithName:TestNotification object:self];
	[[[[mock stub] andReturn:@"foo"] andPost:notification] lowercaseString];

	XCTAssertEqualObjects(@"foo", [mock lowercaseString], @"Should have returned stubbed value.");
	XCTAssertNotNil(observer->notification, @"Should have sent a notification.");
}


- (NSString *)valueForString:(NSString *)aString andMask:(NSStringCompareOptions)mask
{
	return [NSString stringWithFormat:@"[%@, %ld]", aString, (long)mask];
}

- (void)testCallsAlternativeMethodAndPassesOriginalArgumentsAndReturnsValue
{
	[[[mock stub] andCall:@selector(valueForString:andMask:) onObject:self] commonPrefixWithString:@"FOO" options:NSCaseInsensitiveSearch];

	NSString *returnValue = [mock commonPrefixWithString:@"FOO" options:NSCaseInsensitiveSearch];

	XCTAssertEqualObjects(@"[FOO, 1]", returnValue, @"Should have passed and returned invocation.");
}


- (void)testCallsBlockWhichCanSetUpReturnValue
{
	void (^theBlock)(NSInvocation *) = ^(NSInvocation *invocation)
		{
			NSString *value;
			[invocation getArgument:&value atIndex:2];
			value = [NSString stringWithFormat:@"MOCK %@", value];
			[invocation setReturnValue:&value];
		};

	[[[mock stub] andDo:theBlock] stringByAppendingString:[OCMArg any]];

	XCTAssertEqualObjects(@"MOCK foo", [mock stringByAppendingString:@"foo"], @"Should have called block.");
	XCTAssertEqualObjects(@"MOCK bar", [mock stringByAppendingString:@"bar"], @"Should have called block.");
}

- (void)testHandlesNilPassedAsBlock
{
    [[[mock stub] andDo:nil] stringByAppendingString:[OCMArg any]];

    XCTAssertNoThrow([mock stringByAppendingString:@"foo"], @"Should have done nothing.");
    XCTAssertNil([mock stringByAppendingString:@"foo"], @"Should have returned default value.");
}


- (void)testThrowsWhenTryingToUseForwardToRealObjectOnNonPartialMock
{
	XCTAssertThrows([[[mock expect] andForwardToRealObject] name], @"Should have raised and exception.");
}


// --------------------------------------------------------------------------------------
//	returning values in pass-by-reference arguments
// --------------------------------------------------------------------------------------

- (void)testReturnsValuesInPassByReferenceArguments
{
	NSString *expectedName = @"Test";
	NSArray *expectedArray = [NSArray array];

	[[mock expect] completePathIntoString:[OCMArg setTo:expectedName] caseSensitive:YES
						 matchesIntoArray:[OCMArg setTo:expectedArray] filterTypes:[OCMArg any]];

	NSString *actualName = nil;
	NSArray *actualArray = nil;
	[mock completePathIntoString:&actualName caseSensitive:YES matchesIntoArray:&actualArray filterTypes:nil];

	XCTAssertNoThrow([mock verify], @"An unexpected exception was thrown");
	XCTAssertEqualObjects(expectedName, actualName, @"The two string objects should be equal");
	XCTAssertEqualObjects(expectedArray, actualArray, @"The two array objects should be equal");
}


- (void)testReturnsValuesInNonObjectPassByReferenceArguments
{
    mock = [OCMockObject mockForClass:[TestClassWithIntPointerMethod class]];
    [[mock stub] returnValueInPointer:[OCMArg setToValue:@1234]];

    int actualValue = 0;
    [mock returnValueInPointer:&actualValue];

    XCTAssertEqual(1234, actualValue, @"Should have returned value via pass by ref argument.");

}


// --------------------------------------------------------------------------------------
//	accepting expected methods
// --------------------------------------------------------------------------------------

- (void)testAcceptsExpectedMethod
{
	[[mock expect] lowercaseString];
	[mock lowercaseString];
}


- (void)testAcceptsExpectedMethodAndReturnsValue
{
	[[[mock expect] andReturn:@"Objective-C"] lowercaseString];
	id returnValue = [mock lowercaseString];

	XCTAssertEqualObjects(@"Objective-C", returnValue, @"Should have returned stubbed value.");
}


- (void)testAcceptsExpectedMethodsInRecordedSequence
{
	[[mock expect] lowercaseString];
	[[mock expect] uppercaseString];

	[mock lowercaseString];
	[mock uppercaseString];
}


- (void)testAcceptsExpectedMethodsInDifferentSequence
{
	[[mock expect] lowercaseString];
	[[mock expect] uppercaseString];

	[mock uppercaseString];
	[mock lowercaseString];
}


// --------------------------------------------------------------------------------------
//	verifying expected methods
// --------------------------------------------------------------------------------------

- (void)testAcceptsAndVerifiesExpectedMethods
{
	[[mock expect] lowercaseString];
	[[mock expect] uppercaseString];

	[mock lowercaseString];
	[mock uppercaseString];

	[mock verify];
}


- (void)testRaisesExceptionOnVerifyWhenNotAllExpectedMethodsWereCalled
{
	[[mock expect] lowercaseString];
	[[mock expect] uppercaseString];

	[mock lowercaseString];

	XCTAssertThrows([mock verify], @"Should have raised an exception.");
}

- (void)testAcceptsAndVerifiesTwoExpectedInvocationsOfSameMethod
{
	[[mock expect] lowercaseString];
	[[mock expect] lowercaseString];

	[mock lowercaseString];
	[mock lowercaseString];

	[mock verify];
}


- (void)testAcceptsAndVerifiesTwoExpectedInvocationsOfSameMethodAndReturnsCorrespondingValues
{
	[[[mock expect] andReturn:@"foo"] lowercaseString];
	[[[mock expect] andReturn:@"bar"] lowercaseString];

	XCTAssertEqualObjects(@"foo", [mock lowercaseString], @"Should have returned first stubbed value");
	XCTAssertEqualObjects(@"bar", [mock lowercaseString], @"Should have returned seconds stubbed value");

	[mock verify];
}

- (void)testReturnsStubbedValuesIndependentOfExpectations
{
	[[mock stub] hasSuffix:@"foo"];
	[[mock expect] hasSuffix:@"bar"];

	[mock hasSuffix:@"foo"];
	[mock hasSuffix:@"bar"];
	[mock hasSuffix:@"foo"]; // Since it's a stub, shouldn't matter how many times we call this

	[mock verify];
}

-(void)testAcceptsAndVerifiesMethodsWithSelectorArgument
{
	[[mock expect] performSelector:@selector(lowercaseString)];
	[mock performSelector:@selector(lowercaseString)];
	[mock verify];
}


// --------------------------------------------------------------------------------------
//	verify with delay
// --------------------------------------------------------------------------------------

- (void)testAcceptsAndVerifiesExpectedMethodsWithDelay
{
	[[mock expect] lowercaseString];
	[[mock expect] uppercaseString];
    
	[mock lowercaseString];
	[mock uppercaseString];
    
	[mock verifyWithDelay:1];
}

- (void)testAcceptsAndVerifiesExpectedMethodsWithDelayBlock
{
    dispatch_async(dispatch_queue_create("mockqueue", nil), ^{
        [NSThread sleepForTimeInterval:0.1];
        [mock lowercaseString];
    });
    
	[[mock expect] lowercaseString];
	[mock verifyWithDelay:1];
}

- (void)testFailsVerifyExpectedMethodsWithoutDelay
{
    [mock retain];
    dispatch_async(dispatch_queue_create("mockqueue", nil), ^{
        [NSThread sleepForTimeInterval:0.1];
        [mock lowercaseString];
        [mock release];
    });
    
	[[mock expect] lowercaseString];
	XCTAssertThrows([mock verify], @"Should have raised an exception because method was not called in time.");
}

- (void)testFailsVerifyExpectedMethodsWithDelay
{
	[[mock expect] lowercaseString];
	XCTAssertThrows([mock verifyWithDelay:0.1], @"Should have raised an exception because method was not called.");
}

- (void)testAcceptsAndVerifiesExpectedMethodsWithDelayBlockTimeout
{
    [mock retain];
    
    dispatch_async(dispatch_queue_create("mockqueue", nil), ^{
        [NSThread sleepForTimeInterval:1];
        [mock lowercaseString];
        [mock release];
    });
    
	[[mock expect] lowercaseString];
	XCTAssertThrows([mock verifyWithDelay:0.1], @"Should have raised an exception because method was not called.");
}

// --------------------------------------------------------------------------------------
//	ordered expectations
// --------------------------------------------------------------------------------------

- (void)testAcceptsExpectedMethodsInRecordedSequenceWhenOrderMatters
{
	[mock setExpectationOrderMatters:YES];

	[[mock expect] lowercaseString];
	[[mock expect] uppercaseString];

	XCTAssertNoThrow([mock lowercaseString], @"Should have accepted expected method in sequence.");
	XCTAssertNoThrow([mock uppercaseString], @"Should have accepted expected method in sequence.");
}

- (void)testRaisesExceptionWhenSequenceIsWrongAndOrderMatters
{
	[mock setExpectationOrderMatters:YES];

	[[mock expect] lowercaseString];
	[[mock expect] uppercaseString];

	XCTAssertThrows([mock uppercaseString], @"Should have complained about wrong sequence.");
}


// --------------------------------------------------------------------------------------
//	nice mocks don't complain about unknown methods, unless told to
// --------------------------------------------------------------------------------------

- (void)testReturnsDefaultValueWhenUnknownMethodIsCalledOnNiceClassMock
{
	mock = [OCMockObject niceMockForClass:[NSString class]];
	XCTAssertNil([mock lowercaseString], @"Should return nil on unexpected method call (for nice mock).");
	[mock verify];
}

- (void)testRaisesAnExceptionWhenAnExpectedMethodIsNotCalledOnNiceClassMock
{
	mock = [OCMockObject niceMockForClass:[NSString class]];
	[[[mock expect] andReturn:@"HELLO!"] uppercaseString];
	XCTAssertThrows([mock verify], @"Should have raised an exception because method was not called.");
}

- (void)testThrowsWhenRejectedMethodIsCalledOnNiceMock
{
    mock = [OCMockObject niceMockForClass:[NSString class]];

    [[mock reject] uppercaseString];
    XCTAssertThrows([mock uppercaseString], @"Should have complained about rejected method being called.");
}


// --------------------------------------------------------------------------------------
//	mocks should honour the NSObject contract, etc.
// --------------------------------------------------------------------------------------

- (void)testRespondsToValidSelector
{
	XCTAssertTrue([mock respondsToSelector:@selector(lowercaseString)]);
}

- (void)testDoesNotRespondToInvalidSelector
{
    // We use a selector that's not implemented by the mock, which is an NSString
	XCTAssertFalse([mock respondsToSelector:@selector(arrayWithArray:)]);
}

- (void)testCanStubValueForKeyMethod
{
	id returnValue;

	mock = [OCMockObject mockForClass:[NSObject class]];
	[[[mock stub] andReturn:@"SomeValue"] valueForKey:@"SomeKey"];

	returnValue = [mock valueForKey:@"SomeKey"];

	XCTAssertEqualObjects(@"SomeValue", returnValue, @"Should have returned value that was set up.");
}

- (void)testForwardsIsKindOfClass
{
    XCTAssertTrue([mock isKindOfClass:[NSString class]], @"Should have pretended to be the mocked class.");
}

- (void)testWorksWithTypeQualifiers
{
    id myMock = [OCMockObject mockForClass:[TestClassWithTypeQualifierMethod class]];

    XCTAssertNoThrow([[myMock expect] aSpecialMethod:"foo"], @"Should not complain about method with type qualifiers.");
    XCTAssertNoThrow([myMock aSpecialMethod:"foo"], @"Should not complain about method with type qualifiers.");
}

- (void)testAdjustsRetainCountWhenStubbingMethodsThatCreateObjects
{
    NSString *objectToReturn = [NSString stringWithFormat:@"This is not a %@.", @"string constant"];
    [[[mock stub] andReturn:objectToReturn] mutableCopy];

    NSUInteger retainCountBefore = [objectToReturn retainCount];
    id returnedObject = [mock mutableCopy];
    [returnedObject release]; // the expectation is that we have to call release after a copy
    NSUInteger retainCountAfter = [objectToReturn retainCount];

    XCTAssertEqualObjects(objectToReturn, returnedObject, @"Should not stubbed copy method");
    XCTAssertEqual(retainCountBefore, retainCountAfter, @"Should have incremented retain count in copy stub.");
}


// --------------------------------------------------------------------------------------
//  some internal tests
// --------------------------------------------------------------------------------------

- (void)testReRaisesFailFastExceptionsOnVerify
{
	@try
	{
		[mock lowercaseString];
	}
	@catch(NSException *exception)
	{
		// expected
	}
	XCTAssertThrows([mock verify], @"Should have reraised the exception.");
}

- (void)testReRaisesRejectExceptionsOnVerify
{
	mock = [OCMockObject niceMockForClass:[NSString class]];
	[[mock reject] uppercaseString];
	@try
	{
		[mock uppercaseString];
	}
	@catch(NSException *exception)
	{
		// expected
	}
	XCTAssertThrows([mock verify], @"Should have reraised the exception.");
}


- (void)testCanCreateExpectationsAfterInvocations
{
	[[mock expect] lowercaseString];
	[mock lowercaseString];
	[mock expect];
}


- (void)testMockShouldNotRaiseWhenDescribing
{
    mock = [OCMockObject mockForClass:[NSObject class]];

    XCTAssertNoThrow(NSLog(@"Testing description handling dummy methods... %@ %@ %@ %@ %@",
                          @{@"foo": mock},
                          @[mock],
                          [NSSet setWithObject:mock],
                          [mock description],
                          mock),
                    @"asking for the description of a mock shouldn't cause a test to fail.");
}

- (void)testPartialMockShouldNotRaiseWhenDescribing
{
    mock = [OCMockObject partialMockForObject:[[NSObject alloc] init]];
    
    XCTAssertNoThrow(NSLog(@"Testing description handling dummy methods... %@ %@ %@ %@ %@",
                          @{@"bar": mock},
                          @[mock],
                          [NSSet setWithObject:mock],
                          [mock description],
                          mock),
                    @"asking for the description of a mock shouldn't cause a test to fail.");
    [mock stopMocking];
}


@end
