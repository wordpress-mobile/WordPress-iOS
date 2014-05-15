//---------------------------------------------------------------------------------------
//  $Id$
//  Copyright (c) 2013 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import <OCMock/OCMock.h>
#import "OCMockObjectPartialMocksTests.h"
#import <objc/runtime.h>

#if TARGET_OS_IPHONE
#define NSRect CGRect
#define NSZeroRect CGRectZero
#define NSMakeRect CGRectMake
#define valueWithRect valueWithCGRect
#endif

#pragma mark   Helper classes

@interface TestClassWithSimpleMethod : NSObject
- (NSString *)foo;
@end

@implementation TestClassWithSimpleMethod

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

- (void)setMethodInt:(int)anInt
{
	methodInt = anInt;
}

@end



@implementation OCMockObjectPartialMocksTests

#pragma mark   Tests for stubbing with partial mocks

- (void)testStubsMethodsOnPartialMock
{
	TestClassWithSimpleMethod *object = [[[TestClassWithSimpleMethod alloc] init] autorelease];
	id mock = [OCMockObject partialMockForObject:object];
	[[[mock stub] andReturn:@"hi"] foo];
	STAssertEqualObjects(@"hi", [mock foo], @"Should have returned stubbed value");
}

//- (void)testStubsMethodsOnPartialMockForTollFreeBridgedClasses
//{
//	mock = [OCMockObject partialMockForObject:[NSString stringWithString:@"hello"]];
//	[[[mock stub] andReturn:@"hi"] uppercaseString];
//	STAssertEqualObjects(@"hi", [mock uppercaseString], @"Should have returned stubbed value");
//}

- (void)testForwardsUnstubbedMethodsCallsToRealObjectOnPartialMock
{
	TestClassWithSimpleMethod *object = [[[TestClassWithSimpleMethod alloc] init] autorelease];
	id mock = [OCMockObject partialMockForObject:object];
	STAssertEqualObjects(@"Foo", [mock foo], @"Should have returned value from real object.");
}

//- (void)testForwardsUnstubbedMethodsCallsToRealObjectOnPartialMockForTollFreeBridgedClasses
//{
//	mock = [OCMockObject partialMockForObject:[NSString stringWithString:@"hello2"]];
//	STAssertEqualObjects(@"HELLO2", [mock uppercaseString], @"Should have returned value from real object.");
//}

- (void)testStubsMethodOnRealObjectReference
{
	TestClassWithSimpleMethod *realObject = [[[TestClassWithSimpleMethod alloc] init] autorelease];
	id mock = [OCMockObject partialMockForObject:realObject];
	[[[mock stub] andReturn:@"TestFoo"] foo];
	STAssertEqualObjects(@"TestFoo", [realObject foo], @"Should have stubbed method.");
}

- (void)testCallsToSelfInRealObjectAreShadowedByPartialMock
{
	TestClassThatCallsSelf *realObject = [[[TestClassThatCallsSelf alloc] init] autorelease];
	id mock = [OCMockObject partialMockForObject:realObject];
	[[[mock stub] andReturn:@"FooFoo"] method2];
	STAssertEqualObjects(@"FooFoo", [mock method1], @"Should have called through to stubbed method.");
}

- (void)testCallsToSelfInRealObjectStructReturnAreShadowedByPartialMock
{
	TestClassThatCallsSelf *realObject = [[[TestClassThatCallsSelf alloc] init] autorelease];
	id mock = [OCMockObject partialMockForObject:realObject];
    [[[mock stub] andReturnValue:OCMOCK_VALUE(NSZeroRect)] methodRect2];
	STAssertEquals(NSZeroRect, [mock methodRect1], @"Should have called through to stubbed method.");
}


- (void)testPartialMockClassOverrideReportsOriginalClass
{
	TestClassThatCallsSelf *realObject = [[[TestClassThatCallsSelf alloc] init] autorelease];
	Class origClass = [realObject class];
	id mock = [OCMockObject partialMockForObject:realObject];
	STAssertEqualObjects([realObject class], origClass, @"Override of -class method did not work");
	STAssertEqualObjects([mock class], origClass, @"Mock proxy -class method did not work");
	STAssertFalse(origClass == object_getClass(realObject), @"Subclassing did not work");
	[mock stopMocking];
	STAssertEqualObjects([realObject class], origClass, @"Classes different after stopMocking");
	STAssertEqualObjects(object_getClass(realObject), origClass, @"Classes different after stopMocking");
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	numKVOCallbacks++;
}

#pragma mark   Tests for KVO interaction with mocks

/* Starting KVO observations on an already-mocked object generally should work. */
- (void)testAddingKVOObserverOnPartialMock
{
	static char *MyContext;
	TestClassThatCallsSelf *realObject = [[[TestClassThatCallsSelf alloc] init] autorelease];
	Class origClass = [realObject class];

	id mock = [OCMockObject partialMockForObject:realObject];
	Class ourSubclass = object_getClass(realObject);

	[realObject addObserver:self forKeyPath:@"methodInt" options:NSKeyValueObservingOptionNew context:MyContext];
	Class kvoClass = object_getClass(realObject);

	/* KVO additionally overrides the -class method, but they return the superclass of their special
	   subclass, which in this case is the special mock subclass */
	STAssertEqualObjects([realObject class], ourSubclass, @"KVO override of class did not return our subclass");
	STAssertFalse(ourSubclass == kvoClass, @"KVO with subclass did not work");

	[realObject setMethodInt:45];
	STAssertEquals(numKVOCallbacks, 1, @"did not get subclass KVO notification");
	[mock setMethodInt:47];
	STAssertEquals(numKVOCallbacks, 2, @"did not get mock KVO notification");

	[realObject removeObserver:self forKeyPath:@"methodInt" context:MyContext];
	STAssertEqualObjects([realObject class], origClass, @"Classes different after stopKVO");
	STAssertEqualObjects(object_getClass(realObject), ourSubclass, @"Classes different after stopKVO");

	[mock stopMocking];
	STAssertEqualObjects([realObject class], origClass, @"Classes different after stopMocking");
	STAssertEqualObjects(object_getClass(realObject), origClass, @"Classes different after stopMocking");
}

/* Mocking a class which already has KVO observations does not work, but does not crash. */
- (void)testPartialMockOnKVOObserved
{
	static char *MyContext;
	TestClassThatCallsSelf *realObject = [[[TestClassThatCallsSelf alloc] init] autorelease];
	Class origClass = [realObject class];
    
	[realObject addObserver:self forKeyPath:@"methodInt" options:NSKeyValueObservingOptionNew context:MyContext];
	Class kvoClass = object_getClass(realObject);

	id mock = [OCMockObject partialMockForObject:realObject];
	Class ourSubclass = object_getClass(realObject);
    
	STAssertEqualObjects([realObject class], origClass, @"We did not preserve the original [self class]");
	STAssertFalse(ourSubclass == kvoClass, @"KVO with subclass did not work");
    
	/* Due to the way we replace the object's class, the KVO class gets overwritten and
	   KVO notifications stop functioning.  If we did not do this, the presence of the mock
	   subclass would cause KVO to crash, at least without further tinkering. */
	[realObject setMethodInt:45];
//	STAssertEquals(numKVOCallbacks, 1, @"did not get subclass KVO notification");
	STAssertEquals(numKVOCallbacks, 0, @"got subclass KVO notification");
	[mock setMethodInt:47];
//	STAssertEquals(numKVOCallbacks, 2, @"did not get mock KVO notification");
	STAssertEquals(numKVOCallbacks, 0, @"got mock KVO notification");

	[mock stopMocking];
	STAssertEqualObjects([realObject class], origClass, @"Classes different after stopMocking");
//	STAssertEqualObjects(object_getClass(realObject), kvoClass, @"KVO class different after stopMocking");
	STAssertEqualObjects(object_getClass(realObject), origClass, @"class different after stopMocking");

	[realObject removeObserver:self forKeyPath:@"methodInt" context:MyContext];
	STAssertEqualObjects([realObject class], origClass, @"Classes different after stopKVO");
	STAssertEqualObjects(object_getClass(realObject), origClass, @"Classes different after stopKVO");
}

#pragma mark   Tests for end of stubbing with partial mocks

- (void)testReturnsToRealImplementationWhenExpectedCallOccurred
{
    TestClassWithSimpleMethod *realObject = [[[TestClassWithSimpleMethod alloc] init] autorelease];
   	id mock = [OCMockObject partialMockForObject:realObject];
   	[[[mock expect] andReturn:@"TestFoo"] foo];
   	STAssertEqualObjects(@"TestFoo", [realObject foo], @"Should have stubbed method.");
   	STAssertEqualObjects(@"Foo", [realObject foo], @"Should have 'unstubbed' method.");
}

- (void)testRestoresObjectWhenStopped
{
	TestClassWithSimpleMethod *realObject = [[[TestClassWithSimpleMethod alloc] init] autorelease];
	id mock = [OCMockObject partialMockForObject:realObject];
	[[[mock stub] andReturn:@"TestFoo"] foo];
	STAssertEqualObjects(@"TestFoo", [realObject foo], @"Should have stubbed method.");
	STAssertEqualObjects(@"TestFoo", [realObject foo], @"Should have stubbed method.");
	[mock stopMocking];
	STAssertEqualObjects(@"Foo", [realObject foo], @"Should have 'unstubbed' method.");
}


#pragma mark   Tests for explicit forward to real object with partial mocks

- (void)testForwardsToRealObjectWhenSetUpAndCalledOnMock
{
	TestClassWithSimpleMethod *realObject = [[[TestClassWithSimpleMethod alloc] init] autorelease];
	id mock = [OCMockObject partialMockForObject:realObject];
    
	[[[mock expect] andForwardToRealObject] foo];
	STAssertEquals(@"Foo", [mock foo], @"Should have called method on real object.");
    
	[mock verify];
}

- (void)testForwardsToRealObjectWhenSetUpAndCalledOnRealObject
{
	TestClassWithSimpleMethod *realObject = [[[TestClassWithSimpleMethod alloc] init] autorelease];
	id mock = [OCMockObject partialMockForObject:realObject];
	
	[[[mock expect] andForwardToRealObject] foo];
	STAssertEquals(@"Foo", [realObject foo], @"Should have called method on real object.");
	
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
	TestClassThatCallsSelf *foo = [[[TestClassThatCallsSelf alloc] init] autorelease];
	id mock = [OCMockObject partialMockForObject:foo];
	[[[mock stub] andCall:@selector(differentMethodInDifferentClass) onObject:self] method1];
	STAssertEqualObjects(@"swizzled!", [foo method1], @"Should have returned value from different method");
}


- (void)aMethodWithVoidReturn
{
}

- (void)testMethodSwizzlingWorksForVoidReturns
{
	TestClassThatCallsSelf *foo = [[[TestClassThatCallsSelf alloc] init] autorelease];
	id mock = [OCMockObject partialMockForObject:foo];
	[[[mock stub] andCall:@selector(aMethodWithVoidReturn) onObject:self] method1];
	STAssertNoThrow([foo method1], @"Should have worked.");
}


@end
