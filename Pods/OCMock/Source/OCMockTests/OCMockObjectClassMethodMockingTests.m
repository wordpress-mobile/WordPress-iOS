//---------------------------------------------------------------------------------------
//  $Id$
//  Copyright (c) 2013 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import <OCMock/OCMock.h>
#import "OCClassMockObject.h"
#import "OCPartialMockObject.h"
#import "OCMockObjectClassMethodMockingTests.h"

#pragma mark   Helper classes

@interface TestClassWithClassMethods : NSObject
+ (NSString *)foo;
+ (NSString *)bar;
- (NSString *)bar;
@end

@implementation TestClassWithClassMethods

+ (NSString *)foo
{
    return @"Foo-ClassMethod";
}

+ (NSString *)bar
{
    return @"Bar-ClassMethod";
}

- (NSString *)bar
{
    return @"Bar";
}

@end


@interface TestSubclassWithClassMethods : TestClassWithClassMethods

@end

@implementation TestSubclassWithClassMethods

@end



@implementation OCMockObjectClassMethodMockingTests

#pragma mark   Tests stubbing class methods

- (void)testCanStubClassMethod
{
    id mock = [OCMockObject mockForClass:[TestClassWithClassMethods class]];

    [[[[mock stub] classMethod] andReturn:@"mocked"] foo];
    
    STAssertEqualObjects(@"mocked", [TestClassWithClassMethods foo], @"Should have stubbed class method.");
}

- (void)testCanExpectTheSameClassMethodMoreThanOnce
{
    id mock = [OCMockObject mockForClass:[TestClassWithClassMethods class]];
    [[[[mock expect] classMethod] andReturn:@"mocked-foo"] foo];
    [[[[mock expect] classMethod] andReturn:@"mocked-foo2"] foo];

    STAssertEqualObjects(@"mocked-foo", [TestClassWithClassMethods foo], @"Should have stubbed class method 'foo'.");
    STAssertEqualObjects(@"mocked-foo2", [TestClassWithClassMethods foo], @"Should have stubbed class method 'foo2'.");
}

- (void)testClassReceivesMethodsAfterStopWasCalled
{
    id mock = [OCMockObject mockForClass:[TestClassWithClassMethods class]];
    
    [[[[mock stub] classMethod] andReturn:@"mocked"] foo];
    [mock stopMocking];
    
    STAssertEqualObjects(@"Foo-ClassMethod", [TestClassWithClassMethods foo], @"Should not have stubbed class method.");
}

- (void)testClassReceivesMethodAgainWhenExpectedCallOccurred
{
    id mock = [OCMockObject mockForClass:[TestClassWithClassMethods class]];

   	[[[[mock expect] classMethod] andReturn:@"mocked"] foo];
   	
    STAssertEqualObjects(@"mocked", [TestClassWithClassMethods foo], @"Should have stubbed method.");
   	STAssertEqualObjects(@"Foo-ClassMethod", [TestClassWithClassMethods foo], @"Should have 'unstubbed' method.");
}

- (void)testCanStubClassMethodFromMockForSubclass
{
    id subclassMock = [OCMockObject mockForClass:[TestSubclassWithClassMethods class]];

    [[[[subclassMock stub] classMethod] andReturn:@"mocked-subclass"] foo];
    STAssertEqualObjects(@"mocked-subclass", [TestSubclassWithClassMethods foo], @"Should have stubbed method.");
    STAssertEqualObjects(@"Foo-ClassMethod", [TestClassWithClassMethods foo], @"Should not have stubbed method in superclass.");
}

- (void)testSuperclassReceivesMethodsAfterStopWasCalled
{
    id mock = [OCMockObject mockForClass:[TestSubclassWithClassMethods class]];

    [[[[mock stub] classMethod] andReturn:@"mocked"] foo];
    [mock stopMocking];

    STAssertEqualObjects(@"Foo-ClassMethod", [TestSubclassWithClassMethods foo], @"Should not have stubbed class method.");
}

- (void)testCanReplaceSameMethodInSubclassAfterSuperclassMockWasStopped
{
    id superclassMock = [OCMockObject mockForClass:[TestClassWithClassMethods class]];
    id subclassMock = [OCMockObject mockForClass:[TestSubclassWithClassMethods class]];

    [[[[superclassMock stub] classMethod] andReturn:@"mocked-superclass"] foo];
    [superclassMock stopMocking];

    [[[[subclassMock stub] classMethod] andReturn:@"mocked-subclass"] foo];
    STAssertEqualObjects(@"mocked-subclass", [TestSubclassWithClassMethods foo], @"Should have stubbed method");
}

- (void)testCanReplaceSameMethodInSuperclassAfterSubclassMockWasStopped
{
    id superclassMock = [OCMockObject mockForClass:[TestClassWithClassMethods class]];
    id subclassMock = [OCMockObject mockForClass:[TestSubclassWithClassMethods class]];

    [[[[subclassMock stub] classMethod] andReturn:@"mocked-subclass"] foo];
    [subclassMock stopMocking];

    [[[[superclassMock stub] classMethod] andReturn:@"mocked-superclass"] foo];
    STAssertEqualObjects(@"mocked-superclass", [TestClassWithClassMethods foo], @"Should have stubbed method");
}

// The following test does not verify behaviour; it shows a problem. It only passes when run in
// isolation because otherwise the other tests cause the problem that this test demonstrates.

- (void)_ignore_testShowThatStubbingSuperclassMethodInSubclassLeavesImplementationInSubclass
{
    // stage 1: stub in superclass affects both superclass and subclass
    id superclassMock = [OCMockObject mockForClass:[TestClassWithClassMethods class]];
    [[[[superclassMock stub] classMethod] andReturn:@"mocked-superclass"] foo];
    STAssertEqualObjects(@"mocked-superclass", [TestClassWithClassMethods foo], @"Should have stubbed method");
    STAssertEqualObjects(@"mocked-superclass", [TestSubclassWithClassMethods foo], @"Should have stubbed method");
    [superclassMock stopMocking];

    // stage 2: stub in subclass affects only subclass
    id subclassMock = [OCMockObject mockForClass:[TestSubclassWithClassMethods class]];
    [[[[subclassMock stub] classMethod] andReturn:@"mocked-subclass"] foo];
    STAssertEqualObjects(@"Foo-ClassMethod", [TestClassWithClassMethods foo], @"Should NOT have stubbed method");
    STAssertEqualObjects(@"mocked-subclass", [TestSubclassWithClassMethods foo], @"Should have stubbed method");
    [subclassMock stopMocking];

    // stage 3: should be like stage 1, but it isn't (see last assert)
    // This is because the subclass mock can't remove the method added to the subclass in stage 2
    // and instead has to point the method in the subclass to the real implementation.
    id superclassMock2 = [OCMockObject mockForClass:[TestClassWithClassMethods class]];
    [[[[superclassMock2 stub] classMethod] andReturn:@"mocked-superclass"] foo];
    STAssertEqualObjects(@"mocked-superclass", [TestClassWithClassMethods foo], @"Should have stubbed method");
    STAssertEqualObjects(@"Foo-ClassMethod", [TestSubclassWithClassMethods foo], @"Should NOT have stubbed method");
}

- (void)testStubsOnlyClassMethodWhenInstanceMethodWithSameNameExists
{
    id mock = [OCMockObject mockForClass:[TestClassWithClassMethods class]];
    
    [[[[mock stub] classMethod] andReturn:@"mocked"] bar];
    
    STAssertEqualObjects(@"mocked", [TestClassWithClassMethods bar], @"Should have stubbed class method.");
    STAssertThrows([mock bar], @"Should not have stubbed instance method.");
}

- (void)testStubsClassMethodWhenNoInstanceMethodExistsWithName
{
    id mock = [OCMockObject mockForClass:[TestClassWithClassMethods class]];
    
    [[[mock stub] andReturn:@"mocked"] foo];
    
    STAssertEqualObjects(@"mocked", [TestClassWithClassMethods foo], @"Should have stubbed class method.");
}

- (void)testStubsCanDistinguishInstanceAndClassMethods
{
    id mock = [OCMockObject mockForClass:[TestClassWithClassMethods class]];
    
    [[[[mock stub] classMethod] andReturn:@"mocked-class"] bar];
    [[[mock stub] andReturn:@"mocked-instance"] bar];
    
    STAssertEqualObjects(@"mocked-class", [TestClassWithClassMethods bar], @"Should have stubbed class method.");
    STAssertEqualObjects(@"mocked-instance", [mock bar], @"Should have stubbed instance method.");
}

- (void)testRevertsAllStubbedMethodsOnDealloc
{
    id mock = [[OCClassMockObject alloc] initWithClass:[TestClassWithClassMethods class]];

    [[[[mock stub] classMethod] andReturn:@"mocked-foo"] foo];
    [[[[mock stub] classMethod] andReturn:@"mocked-bar"] bar];

    STAssertEqualObjects(@"mocked-foo", [TestClassWithClassMethods foo], @"Should have stubbed class method 'foo'.");
    STAssertEqualObjects(@"mocked-bar", [TestClassWithClassMethods bar], @"Should have stubbed class method 'bar'.");

    [mock release];

    STAssertEqualObjects(@"Foo-ClassMethod", [TestClassWithClassMethods foo], @"Should have 'unstubbed' class method 'foo'.");
    STAssertEqualObjects(@"Bar-ClassMethod", [TestClassWithClassMethods bar], @"Should have 'unstubbed' class method 'bar'.");
}

- (void)testRevertsAllStubbedMethodsOnPartialMockDealloc
{
    id mock = [[OCPartialMockObject alloc] initWithClass:[TestClassWithClassMethods class]];
    
    [[[[mock stub] classMethod] andReturn:@"mocked-foo"] foo];
    [[[[mock stub] classMethod] andReturn:@"mocked-bar"] bar];
    
    STAssertEqualObjects(@"mocked-foo", [TestClassWithClassMethods foo], @"Should have stubbed class method 'foo'.");
    STAssertEqualObjects(@"mocked-bar", [TestClassWithClassMethods bar], @"Should have stubbed class method 'bar'.");
    
    [mock release];
    
    STAssertEqualObjects(@"Foo-ClassMethod", [TestClassWithClassMethods foo], @"Should have 'unstubbed' class method 'foo'.");
    STAssertEqualObjects(@"Bar-ClassMethod", [TestClassWithClassMethods bar], @"Should have 'unstubbed' class method 'bar'.");
}

- (void)testForwardToRealObject
{
    NSString *classFooValue = [TestClassWithClassMethods foo];
    NSString *classBarValue = [TestClassWithClassMethods bar];
    id mock = [OCMockObject mockForClass:[TestClassWithClassMethods class]];

    [[[[mock expect] classMethod] andForwardToRealObject] foo];
    NSString *result = [TestClassWithClassMethods foo];
    STAssertEqualObjects(result, classFooValue, nil);
    STAssertNoThrow([mock verify], nil);
    
    [[[mock expect] andForwardToRealObject] foo];
    result = [TestClassWithClassMethods foo];
    STAssertEqualObjects(result, classFooValue, nil);
    STAssertNoThrow([mock verify], nil);

    [[[[mock expect] classMethod] andForwardToRealObject] bar];
    result = [TestClassWithClassMethods bar];
    STAssertEqualObjects(result, classBarValue, nil);
    STAssertNoThrow([mock verify], nil);
    
    [[[[mock expect] classMethod] andForwardToRealObject] bar];
    STAssertThrowsSpecificNamed([mock bar], NSException, NSInternalInconsistencyException, nil);

    [[[mock expect] andForwardToRealObject] bar];
    STAssertThrowsSpecificNamed([mock bar], NSException, NSInternalInconsistencyException, @"Did not get the exception saying andForwardToRealObject not supported");

    [[[mock expect] andForwardToRealObject] foo];
    STAssertThrows([mock foo], nil);
}


@end
