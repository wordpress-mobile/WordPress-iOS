/*
 *  Copyright (c) 2013-2014 Erik Doernenburg and contributors
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
#import <objc/runtime.h>

#if TARGET_OS_IPHONE
#define NSRect CGRect
#define NSZeroRect CGRectZero
#define NSMakeRect CGRectMake
#define valueWithRect valueWithCGRect
#endif

#pragma mark   Helper classes

@interface TestClassWithSimpleMethod : NSObject
+ (NSUInteger)initializeCallCount;
- (NSString *)foo;
@end

@implementation TestClassWithSimpleMethod

static NSUInteger initializeCallCount = 0;

+ (void)initialize
{
    initializeCallCount += 1;
}

+ (NSUInteger)initializeCallCount
{
    return initializeCallCount;
}

- (NSString *)foo
{
    return @"Foo";
}

@end


@interface TestClassThatCallsSelf : NSObject
{
    int methodInt;
}

- (NSString *)method1;
- (NSString *)method2;
- (NSRect)methodRect1;
- (NSRect)methodRect2;
- (int)methodInt;
- (void)methodVoid;
- (void)setMethodInt:(int)anInt;
@end

@implementation TestClassThatCallsSelf

- (NSString *)method1
{
	id retVal = [self method2];
	return retVal;
}

- (NSString *)method2
{
	return @"Foo";
}


- (NSRect)methodRect1
{
	NSRect retVal = [self methodRect2];
	return retVal;
}

- (NSRect)methodRect2
{
	return NSMakeRect(10, 10, 10, 10);
}

- (int)methodInt
{
	return methodInt;
}

- (void)methodVoid
{
}

- (void)setMethodInt:(int)anInt
{
	methodInt = anInt;
}

@end


@interface NSObject(OCMCategoryForTesting)

- (NSString *)categoryMethod;

@end

@implementation NSObject(OCMCategoryForTesting)

- (NSString *)categoryMethod
{
    return @"Foo-Category";
}

@end




@interface OCMockObjectPartialMocksTests : XCTestCase
{
    int numKVOCallbacks;
}

@end


@implementation OCMockObjectPartialMocksTests

#pragma mark   Tests for stubbing with partial mocks

- (void)testStubsMethodsOnPartialMock
{
	TestClassWithSimpleMethod *object = [[TestClassWithSimpleMethod alloc] init];
	id mock = [OCMockObject partialMockForObject:object];
	[[[mock stub] andReturn:@"hi"] foo];
	XCTAssertEqualObjects(@"hi", [mock foo], @"Should have returned stubbed value");
}

- (void)testForwardsUnstubbedMethodsCallsToRealObjectOnPartialMock
{
	TestClassWithSimpleMethod *object = [[TestClassWithSimpleMethod alloc] init];
	id mock = [OCMockObject partialMockForObject:object];
	XCTAssertEqualObjects(@"Foo", [mock foo], @"Should have returned value from real object.");
}

//- (void)testForwardsUnstubbedMethodsCallsToRealObjectOnPartialMockForTollFreeBridgedClasses
//{
//	mock = [OCMockObject partialMockForObject:[NSString stringWithString:@"hello2"]];
//	STAssertEqualObjects(@"HELLO2", [mock uppercaseString], @"Should have returned value from real object.");
//}

- (void)testStubsMethodOnRealObjectReference
{
	TestClassWithSimpleMethod *realObject = [[TestClassWithSimpleMethod alloc] init];
	id mock = [OCMockObject partialMockForObject:realObject];
	[[[mock stub] andReturn:@"TestFoo"] foo];
	XCTAssertEqualObjects(@"TestFoo", [realObject foo], @"Should have stubbed method.");
}

- (void)testCallsToSelfInRealObjectAreShadowedByPartialMock
{
	TestClassThatCallsSelf *realObject = [[TestClassThatCallsSelf alloc] init];
	id mock = [OCMockObject partialMockForObject:realObject];
	[[[mock stub] andReturn:@"FooFoo"] method2];
	XCTAssertEqualObjects(@"FooFoo", [mock method1], @"Should have called through to stubbed method.");
}

- (void)testCallsToSelfInRealObjectStructReturnAreShadowedByPartialMock
{
	TestClassThatCallsSelf *realObject = [[TestClassThatCallsSelf alloc] init];
	id mock = [OCMockObject partialMockForObject:realObject];
    [[[mock stub] andReturnValue:OCMOCK_VALUE(NSZeroRect)] methodRect2];
#if TARGET_OS_IPHONE
#define NSEqualRects CGRectEqualToRect
#endif
    XCTAssertTrue(NSEqualRects(NSZeroRect, [mock methodRect1]), @"Should have called through to stubbed method.");
}

- (void)testInvocationsOfNSObjectCategoryMethodsCanBeStubbed
{
    TestClassThatCallsSelf *realObject = [[TestClassThatCallsSelf alloc] init];
   	id mock = [OCMockObject partialMockForObject:realObject];
    [[[mock stub] andReturn:@"stubbed"] categoryMethod];
    XCTAssertEqualObjects(@"stubbed", [realObject categoryMethod], @"Should have stubbed NSObject's method");
}


#pragma mark   Tests for behaviour when setting up partial mocks

- (void)testPartialMockClassOverrideReportsOriginalClass
{
	TestClassThatCallsSelf *realObject = [[TestClassThatCallsSelf alloc] init];
	Class origClass = [realObject class];
	id mock = [OCMockObject partialMockForObject:realObject];
	XCTAssertEqualObjects([realObject class], origClass, @"Override of -class method did not work");
	XCTAssertEqualObjects([mock class], origClass, @"Mock proxy -class method did not work");
	XCTAssertFalse(origClass == object_getClass(realObject), @"Subclassing did not work");
	[mock stopMocking];
	XCTAssertEqualObjects([realObject class], origClass, @"Classes different after stopMocking");
	XCTAssertEqualObjects(object_getClass(realObject), origClass, @"Classes different after stopMocking");
}

- (void)testInitializeIsNotCalledOnMockedClass
{
    NSUInteger countBefore = [TestClassWithSimpleMethod initializeCallCount];

    TestClassWithSimpleMethod *object = [[TestClassWithSimpleMethod alloc] init];
    id mock = [OCMockObject partialMockForObject:object];
    [[[mock expect] andForwardToRealObject] foo];
    [object foo];

    NSUInteger countAfter = [TestClassWithSimpleMethod initializeCallCount];

    XCTAssertEqual(countBefore, countAfter, @"Creating a mock should not have resulted in call to +initialize");
}

- (void)testRefusesToCreateTwoPartialMocksForTheSameObject
{
    id object = [[TestClassThatCallsSelf alloc] init];

    id partialMock1 = [OCMockObject partialMockForObject:object];

    XCTAssertNotNil(partialMock1, @"Should have created first partial mock.");
    XCTAssertThrows([OCMockObject partialMockForObject:object], @"Should not have allowed creation of second partial mock");
}

- (void)testRefusesToCreatePartialMockForTollFreeBridgedClasses
{
    id object = (id)CFBridgingRelease(CFStringCreateWithCString(kCFAllocatorDefault, "foo", kCFStringEncodingASCII));
    XCTAssertThrowsSpecificNamed([OCMockObject partialMockForObject:object],
                                 NSException,
                                 NSInvalidArgumentException,
                                 @"should throw NSInvalidArgumentException exception");
}

#if TARGET_RT_64_BIT

- (void)testRefusesToCreatePartialMockForTaggedPointers
{
    NSDate *object = [NSDate dateWithTimeIntervalSince1970:0];
    XCTAssertThrowsSpecificNamed([OCMockObject partialMockForObject:object],
                                 NSException,
                                 NSInvalidArgumentException,
                                 @"should throw NSInvalidArgumentException exception");
}

#endif


#pragma mark   Tests for KVO interaction with mocks

/* Starting KVO observations on an already-mocked object generally should work. */
- (void)testAddingKVOObserverOnPartialMock
{
	static char *MyContext;
	TestClassThatCallsSelf *realObject = [[TestClassThatCallsSelf alloc] init];
	Class origClass = [realObject class];

	id mock = [OCMockObject partialMockForObject:realObject];
	Class ourSubclass = object_getClass(realObject);

	[realObject addObserver:self forKeyPath:@"methodInt" options:NSKeyValueObservingOptionNew context:MyContext];
	Class kvoClass = object_getClass(realObject);

	/* KVO additionally overrides the -class method, but they return the superclass of their special
	   subclass, which in this case is the special mock subclass */
	XCTAssertEqualObjects([realObject class], ourSubclass, @"KVO override of class did not return our subclass");
	XCTAssertFalse(ourSubclass == kvoClass, @"KVO with subclass did not work");

	[realObject setMethodInt:45];
	XCTAssertEqual(numKVOCallbacks, 1, @"did not get subclass KVO notification");
	[mock setMethodInt:47];
	XCTAssertEqual(numKVOCallbacks, 2, @"did not get mock KVO notification");

	[realObject removeObserver:self forKeyPath:@"methodInt" context:MyContext];
	XCTAssertEqualObjects([realObject class], origClass, @"Classes different after stopKVO");
	XCTAssertEqualObjects(object_getClass(realObject), ourSubclass, @"Classes different after stopKVO");

	[mock stopMocking];
	XCTAssertEqualObjects([realObject class], origClass, @"Classes different after stopMocking");
	XCTAssertEqualObjects(object_getClass(realObject), origClass, @"Classes different after stopMocking");
}

/* Mocking a class which already has KVO observations does not work, but does not crash. */
- (void)testPartialMockOnKVOObserved
{
	static char *MyContext;
	TestClassThatCallsSelf *realObject = [[TestClassThatCallsSelf alloc] init];
	Class origClass = [realObject class];
    
	[realObject addObserver:self forKeyPath:@"methodInt" options:NSKeyValueObservingOptionNew context:MyContext];
	Class kvoClass = object_getClass(realObject);

	id mock = [OCMockObject partialMockForObject:realObject];
	Class ourSubclass = object_getClass(realObject);
    
	XCTAssertEqualObjects([realObject class], origClass, @"We did not preserve the original [self class]");
	XCTAssertFalse(ourSubclass == kvoClass, @"KVO with subclass did not work");
    
	/* Due to the way we replace the object's class, the KVO class gets overwritten and
	   KVO notifications stop functioning.  If we did not do this, the presence of the mock
	   subclass would cause KVO to crash, at least without further tinkering. */
	[realObject setMethodInt:45];
//	STAssertEquals(numKVOCallbacks, 1, @"did not get subclass KVO notification");
	XCTAssertEqual(numKVOCallbacks, 0, @"got subclass KVO notification");
	[mock setMethodInt:47];
//	STAssertEquals(numKVOCallbacks, 2, @"did not get mock KVO notification");
	XCTAssertEqual(numKVOCallbacks, 0, @"got mock KVO notification");

	[mock stopMocking];
	XCTAssertEqualObjects([realObject class], origClass, @"Classes different after stopMocking");
//	STAssertEqualObjects(object_getClass(realObject), kvoClass, @"KVO class different after stopMocking");
	XCTAssertEqualObjects(object_getClass(realObject), origClass, @"class different after stopMocking");

	[realObject removeObserver:self forKeyPath:@"methodInt" context:MyContext];
	XCTAssertEqualObjects([realObject class], origClass, @"Classes different after stopKVO");
	XCTAssertEqualObjects(object_getClass(realObject), origClass, @"Classes different after stopKVO");
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	numKVOCallbacks++;
}


#pragma mark   Tests for end of stubbing with partial mocks

- (void)testReturnsToRealImplementationWhenExpectedCallOccurred
{
    TestClassWithSimpleMethod *realObject = [[TestClassWithSimpleMethod alloc] init];
   	id mock = [OCMockObject partialMockForObject:realObject];
   	[[[mock expect] andReturn:@"TestFoo"] foo];
   	XCTAssertEqualObjects(@"TestFoo", [realObject foo], @"Should have stubbed method.");
   	XCTAssertEqualObjects(@"Foo", [realObject foo], @"Should have 'unstubbed' method.");
}

- (void)testRestoresObjectWhenStopped
{
	TestClassWithSimpleMethod *realObject = [[TestClassWithSimpleMethod alloc] init];
	id mock = [OCMockObject partialMockForObject:realObject];
	[[[mock stub] andReturn:@"TestFoo"] foo];
	XCTAssertEqualObjects(@"TestFoo", [realObject foo], @"Should have stubbed method.");
	XCTAssertEqualObjects(@"TestFoo", [realObject foo], @"Should have stubbed method.");
	[mock stopMocking];
	XCTAssertEqualObjects(@"Foo", [realObject foo], @"Should have 'unstubbed' method.");
}


#pragma mark   Tests for explicit forward to real object with partial mocks

- (void)testForwardsToRealObjectWhenSetUpAndCalledOnMock
{
	TestClassWithSimpleMethod *realObject = [[TestClassWithSimpleMethod alloc] init];
	id mock = [OCMockObject partialMockForObject:realObject];
    
	[[[mock expect] andForwardToRealObject] foo];
	XCTAssertEqual(@"Foo", [mock foo], @"Should have called method on real object.");
    
	[mock verify];
}

- (void)testForwardsToRealObjectWhenSetUpAndCalledOnRealObject
{
	TestClassWithSimpleMethod *realObject = [[TestClassWithSimpleMethod alloc] init];
	id mock = [OCMockObject partialMockForObject:realObject];
	
	[[[mock expect] andForwardToRealObject] foo];
	XCTAssertEqual(@"Foo", [realObject foo], @"Should have called method on real object.");
	
	[mock verify];
}


#pragma mark   Tests for method swizzling with partial mocks

- (NSString *)differentMethodInDifferentClass
{
	return @"swizzled!";
}

- (void)testImplementsMethodSwizzling
{
	// using partial mocks and the indirect return value provider
	TestClassThatCallsSelf *foo = [[TestClassThatCallsSelf alloc] init];
	id mock = [OCMockObject partialMockForObject:foo];
	[[[mock stub] andCall:@selector(differentMethodInDifferentClass) onObject:self] method1];
	XCTAssertEqualObjects(@"swizzled!", [foo method1], @"Should have returned value from different method");
}


- (void)aMethodWithVoidReturn
{
}

- (void)testMethodSwizzlingWorksForVoidReturns
{
	TestClassThatCallsSelf *foo = [[TestClassThatCallsSelf alloc] init];
	id mock = [OCMockObject partialMockForObject:foo];
	[[[mock stub] andCall:@selector(aMethodWithVoidReturn) onObject:self] methodVoid];
	XCTAssertNoThrow([foo method1], @"Should have worked.");
}


@end
