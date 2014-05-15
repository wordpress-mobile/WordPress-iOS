//---------------------------------------------------------------------------------------
//  $Id$
//  Copyright (c) 2004-2010 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import <OCMock/OCMock.h>
#import "OCMockObjectTests.h"


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
	STAssertThrows([mock uppercaseString], @"Should have raised an exception.");
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

#if NS_BLOCKS_AVAILABLE

- (void)testAcceptsStubbedMethodWithBlockArgument
{
	mock = [OCMockObject mockForClass:[NSArray class]];
	[[mock stub] indexesOfObjectsPassingTest:[OCMArg any]];
	[mock indexesOfObjectsPassingTest:^(id obj, NSUInteger idx, BOOL *stop) { return YES; }];
}


- (void)testAcceptsStubbedMethodWithBlockConstraint
{
	[[mock stub] hasSuffix:[OCMArg checkWithBlock:^(id value) { return [value isEqualToString:@"foo"]; }]];

	STAssertNoThrow([mock hasSuffix:@"foo"], @"Should not have thrown a exception");
	STAssertThrows([mock hasSuffix:@"bar"], @"Should have thrown a exception");
}

#endif

- (void)testAcceptsStubbedMethodWithNilArgument
{
	[[mock stub] hasSuffix:nil];
	[mock hasSuffix:nil];
}

- (void)testRaisesExceptionWhenMethodWithWrongArgumentIsCalled
{
	[[mock stub] hasSuffix:@"foo"];
	STAssertThrows([mock hasSuffix:@"xyz"], @"Should have raised an exception.");
}


- (void)testAcceptsStubbedMethodWithScalarArgument
{
	[[mock stub] stringByPaddingToLength:20 withString:@"foo" startingAtIndex:5];
	[mock stringByPaddingToLength:20 withString:@"foo" startingAtIndex:5];
}

- (void)testRaisesExceptionWhenMethodWithOneWrongScalarArgumentIsCalled
{
	[[mock stub] stringByPaddingToLength:20 withString:@"foo" startingAtIndex:5];
	STAssertThrows([mock stringByPaddingToLength:20 withString:@"foo" startingAtIndex:3], @"Should have raised an exception.");
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
    STAssertThrows([mock doWithSelector:@selector(allValues)],nil);
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

	STAssertTrue([mock writeToFile:@"foo" atomically:YES encoding:NSMacOSRomanStringEncoding error:&error], nil);
}

- (void)testRaisesExceptionWhenMethodWithWrongPointerArgumentIsCalled
{
	NSString *string;
	NSString *anotherString;
	NSArray *array;

	[[mock stub] completePathIntoString:&string caseSensitive:YES matchesIntoArray:&array filterTypes:[OCMArg any]];

	STAssertThrows([mock completePathIntoString:&anotherString caseSensitive:YES matchesIntoArray:&array filterTypes:[OCMArg any]], nil);
}

- (void)testAcceptsStubbedMethodWithAnyPointerArgument
{
    [[[mock stub] andReturn:@"foo"] initWithCharacters:[OCMArg anyPointer] length:3];

    unichar characters[] = { 'b', 'a', 'r' };
    id result = [mock initWithCharacters:characters length:3];

    STAssertEqualObjects(@"foo", result, @"Should have mocked method.");
}


- (void)testAcceptsStubbedMethodWithAnyObjectRefArgument
{
    NSError *error;
    [[[mock stub] andReturnValue:@YES] writeToFile:[OCMArg any] atomically:YES encoding:NSMacOSRomanStringEncoding error:[OCMArg anyObjectRef]];

    STAssertTrue([mock writeToFile:@"foo" atomically:YES encoding:NSMacOSRomanStringEncoding error:&error], nil);
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
	STAssertThrows([mock appendBytes:"bar" length:3], @"Should have raised an exception.");
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
	STAssertThrows([mock initWithContentsOfFile:@"foo.txt" encoding:NSASCIIStringEncoding error:&error2], @"Should have raised.");
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
	STAssertThrows([mock substringWithRange:otherRange], @"Should have raised an exception.");
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
	STAssertThrows([mock stringByAppendingString:@"foo"], @"Should have raised an exception.");
}

- (void)testRaisesExceptionWhenDifferentMockArgumentIsPassed
{
	id expectedArg = [OCMockObject mockForClass:[NSString class]];
	id otherArg = [OCMockObject mockForClass:[NSString class]];
	[[mock stub] stringByAppendingString:otherArg];
	STAssertThrows([mock stringByAppendingString:expectedArg], @"Should have raised an exception.");
}


- (void)testAcceptsStubbedMethodWithAnyNonObjectArgument
{
    [[[mock stub] ignoringNonObjectArgs] rangeOfString:@"foo" options:0];
    [mock rangeOfString:@"foo" options:NSRegularExpressionSearch];
}

- (void)testRaisesExceptionWhenMethodWithMixedArgumentsIsCalledWithWrongObjectArgument
{
    [[[mock stub] ignoringNonObjectArgs] rangeOfString:@"foo" options:0];
    STAssertThrows([mock rangeOfString:@"bar" options:NSRegularExpressionSearch], @"Should have raised an exception.");
}


// --------------------------------------------------------------------------------------
//	returning values from stubbed methods
// --------------------------------------------------------------------------------------

- (void)testReturnsStubbedReturnValue
{
	[[[mock stub] andReturn:@"megamock"] lowercaseString];
	id returnValue = [mock lowercaseString];

	STAssertEqualObjects(@"megamock", returnValue, @"Should have returned stubbed value.");
}

- (void)testReturnsStubbedIntReturnValue
{
	[[[mock stub] andReturnValue:@42] intValue];
	int returnValue = [mock intValue];

	STAssertEquals(42, returnValue, @"Should have returned stubbed value.");
}

- (void)testRaisesWhenBoxedValueTypesDoNotMatch
{
	[[[mock stub] andReturnValue:@42.0] intValue];

	STAssertThrows([mock intValue], @"Should have raised an exception.");
}

- (void)testReturnsStubbedNilReturnValue
{
	[[[mock stub] andReturn:nil] uppercaseString];

	id returnValue = [mock uppercaseString];

	STAssertNil(returnValue, @"Should have returned stubbed value, which is nil.");
}


// --------------------------------------------------------------------------------------
//	beyond stubbing: raising exceptions, posting notifications, etc.
// --------------------------------------------------------------------------------------

- (void)testRaisesExceptionWhenAskedTo
{
	NSException *exception = [NSException exceptionWithName:@"TestException" reason:@"test" userInfo:nil];
	[[[mock expect] andThrow:exception] lowercaseString];

	STAssertThrows([mock lowercaseString], @"Should have raised an exception.");
}

- (void)testPostsNotificationWhenAskedTo
{
	NotificationRecorderForTesting *observer = [[[NotificationRecorderForTesting alloc] init] autorelease];
	[[NSNotificationCenter defaultCenter] addObserver:observer selector:@selector(receiveNotification:) name:TestNotification object:nil];

	NSNotification *notification = [NSNotification notificationWithName:TestNotification object:self];
	[[[mock stub] andPost:notification] lowercaseString];

	[mock lowercaseString];

	STAssertNotNil(observer->notification, @"Should have sent a notification.");
	STAssertEqualObjects(TestNotification, [observer->notification name], @"Name should match posted one.");
	STAssertEqualObjects(self, [observer->notification object], @"Object should match posted one.");
}

- (void)testPostsNotificationInAdditionToReturningValue
{
	NotificationRecorderForTesting *observer = [[[NotificationRecorderForTesting alloc] init] autorelease];
	[[NSNotificationCenter defaultCenter] addObserver:observer selector:@selector(receiveNotification:) name:TestNotification object:nil];

	NSNotification *notification = [NSNotification notificationWithName:TestNotification object:self];
	[[[[mock stub] andReturn:@"foo"] andPost:notification] lowercaseString];

	STAssertEqualObjects(@"foo", [mock lowercaseString], @"Should have returned stubbed value.");
	STAssertNotNil(observer->notification, @"Should have sent a notification.");
}


- (NSString *)valueForString:(NSString *)aString andMask:(NSStringCompareOptions)mask
{
	return [NSString stringWithFormat:@"[%@, %ld]", aString, (long)mask];
}

- (void)testCallsAlternativeMethodAndPassesOriginalArgumentsAndReturnsValue
{
	[[[mock stub] andCall:@selector(valueForString:andMask:) onObject:self] commonPrefixWithString:@"FOO" options:NSCaseInsensitiveSearch];

	NSString *returnValue = [mock commonPrefixWithString:@"FOO" options:NSCaseInsensitiveSearch];

	STAssertEqualObjects(@"[FOO, 1]", returnValue, @"Should have passed and returned invocation.");
}

#if NS_BLOCKS_AVAILABLE

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

	STAssertEqualObjects(@"MOCK foo", [mock stringByAppendingString:@"foo"], @"Should have called block.");
	STAssertEqualObjects(@"MOCK bar", [mock stringByAppendingString:@"bar"], @"Should have called block.");
}

#endif

- (void)testThrowsWhenTryingToUseForwardToRealObjectOnNonPartialMock
{
	STAssertThrows([[[mock expect] andForwardToRealObject] name], @"Should have raised and exception.");
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

	STAssertNoThrow([mock verify], @"An unexpected exception was thrown");
	STAssertEqualObjects(expectedName, actualName, @"The two string objects should be equal");
	STAssertEqualObjects(expectedArray, actualArray, @"The two array objects should be equal");
}


- (void)testReturnsValuesInNonObjectPassByReferenceArguments
{
    mock = [OCMockObject mockForClass:[TestClassWithIntPointerMethod class]];
    [[mock stub] returnValueInPointer:[OCMArg setToValue:@1234]];

    int actualValue = 0;
    [mock returnValueInPointer:&actualValue];

    STAssertEquals(1234, actualValue, @"Should have returned value via pass by ref argument.");

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

	STAssertEqualObjects(@"Objective-C", returnValue, @"Should have returned stubbed value.");
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

	STAssertThrows([mock verify], @"Should have raised an exception.");
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

	STAssertEqualObjects(@"foo", [mock lowercaseString], @"Should have returned first stubbed value");
	STAssertEqualObjects(@"bar", [mock lowercaseString], @"Should have returned seconds stubbed value");

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
    dispatch_async(dispatch_queue_create("mockqueue", nil), ^{
        [NSThread sleepForTimeInterval:0.1];
        [mock lowercaseString];
    });
    
	[[mock expect] lowercaseString];
	STAssertThrows([mock verify], @"Should have raised an exception because method was not called in time.");
}

- (void)testFailsVerifyExpectedMethodsWithDelay
{
	[[mock expect] lowercaseString];
	STAssertThrows([mock verifyWithDelay:0.1], @"Should have raised an exception because method was not called.");
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
	STAssertThrows([mock verifyWithDelay:0.1], @"Should have raised an exception because method was not called.");
}

// --------------------------------------------------------------------------------------
//	ordered expectations
// --------------------------------------------------------------------------------------

- (void)testAcceptsExpectedMethodsInRecordedSequenceWhenOrderMatters
{
	[mock setExpectationOrderMatters:YES];

	[[mock expect] lowercaseString];
	[[mock expect] uppercaseString];

	STAssertNoThrow([mock lowercaseString], @"Should have accepted expected method in sequence.");
	STAssertNoThrow([mock uppercaseString], @"Should have accepted expected method in sequence.");
}

- (void)testRaisesExceptionWhenSequenceIsWrongAndOrderMatters
{
	[mock setExpectationOrderMatters:YES];

	[[mock expect] lowercaseString];
	[[mock expect] uppercaseString];

	STAssertThrows([mock uppercaseString], @"Should have complained about wrong sequence.");
}


// --------------------------------------------------------------------------------------
//	nice mocks don't complain about unknown methods, unless told to
// --------------------------------------------------------------------------------------

- (void)testReturnsDefaultValueWhenUnknownMethodIsCalledOnNiceClassMock
{
	mock = [OCMockObject niceMockForClass:[NSString class]];
	STAssertNil([mock lowercaseString], @"Should return nil on unexpected method call (for nice mock).");
	[mock verify];
}

- (void)testRaisesAnExceptionWhenAnExpectedMethodIsNotCalledOnNiceClassMock
{
	mock = [OCMockObject niceMockForClass:[NSString class]];
	[[[mock expect] andReturn:@"HELLO!"] uppercaseString];
	STAssertThrows([mock verify], @"Should have raised an exception because method was not called.");
}

- (void)testThrowsWhenRejectedMethodIsCalledOnNiceMock
{
    mock = [OCMockObject niceMockForClass:[NSString class]];

    [[mock reject] uppercaseString];
    STAssertThrows([mock uppercaseString], @"Should have complained about rejected method being called.");
}


// --------------------------------------------------------------------------------------
//	mocks should honour the NSObject contract, etc.
// --------------------------------------------------------------------------------------

- (void)testRespondsToValidSelector
{
	STAssertTrue([mock respondsToSelector:@selector(lowercaseString)], nil);
}

- (void)testDoesNotRespondToInvalidSelector
{
    // We use a selector that's not implemented by the mock, which is an NSString
	STAssertFalse([mock respondsToSelector:@selector(arrayWithArray:)], nil);
}

- (void)testCanStubValueForKeyMethod
{
	id returnValue;

	mock = [OCMockObject mockForClass:[NSObject class]];
	[[[mock stub] andReturn:@"SomeValue"] valueForKey:@"SomeKey"];

	returnValue = [mock valueForKey:@"SomeKey"];

	STAssertEqualObjects(@"SomeValue", returnValue, @"Should have returned value that was set up.");
}

- (void)testForwardsIsKindOfClass
{
    STAssertTrue([mock isKindOfClass:[NSString class]], @"Should have pretended to be the mocked class.");
}

- (void)testWorksWithTypeQualifiers
{
    id myMock = [OCMockObject mockForClass:[TestClassWithTypeQualifierMethod class]];

    STAssertNoThrow([[myMock expect] aSpecialMethod:"foo"], @"Should not complain about method with type qualifiers.");
    STAssertNoThrow([myMock aSpecialMethod:"foo"], @"Should not complain about method with type qualifiers.");
}

- (void)testAdjustsRetainCountWhenStubbingMethodsThatCreateObjects
{
    NSString *objectToReturn = [NSString stringWithFormat:@"This is not a %@.", @"string constant"];
    [[[mock stub] andReturn:objectToReturn] mutableCopy];

    NSUInteger retainCountBefore = [objectToReturn retainCount];
    id returnedObject = [mock mutableCopy];
    [returnedObject release]; // the expectation is that we have to call release after a copy
    NSUInteger retainCountAfter = [objectToReturn retainCount];

    STAssertEqualObjects(objectToReturn, returnedObject, @"Should not stubbed copy method");
    STAssertEquals(retainCountBefore, retainCountAfter, @"Should have incremented retain count in copy stub.");
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
	STAssertThrows([mock verify], @"Should have reraised the exception.");
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
	STAssertThrows([mock verify], @"Should have reraised the exception.");
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

    STAssertNoThrow(NSLog(@"Testing description handling dummy methods... %@ %@ %@ %@ %@",
                          @{@"foo": mock},
                          @[mock],
                          [NSSet setWithObject:mock],
                          [mock description],
                          mock),
                    @"asking for the description of a mock shouldn't cause a test to fail.");
}

- (void)testPartialMockShouldNotRaiseWhenDescribing
{
    mock = [OCMockObject partialMockForObject:@"foo"];
    
    STAssertNoThrow(NSLog(@"Testing description handling dummy methods... %@ %@ %@ %@ %@",
                          @{@"bar": mock},
                          @[mock],
                          [NSSet setWithObject:mock],
                          [mock description],
                          mock),
                    @"asking for the description of a mock shouldn't cause a test to fail.");
    [mock stopMocking];
}


@end
