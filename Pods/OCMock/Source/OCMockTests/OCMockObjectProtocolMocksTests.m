//---------------------------------------------------------------------------------------
//  $Id$
//  Copyright (c) 2013 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import <OCMock/OCMock.h>
#import "OCMockObjectProtocolMocksTests.h"


// --------------------------------------------------------------------------------------
//	Helper classes and protocols for testing
// --------------------------------------------------------------------------------------

@protocol TestProtocol
- (int)primitiveValue;
@optional
- (id)objectValue;
@end

@interface InterfaceForTypedef : NSObject {
    int prop1;
    NSObject *prop2;
}
@end

@implementation InterfaceForTypedef
@end

typedef InterfaceForTypedef TypedefInterface;
typedef InterfaceForTypedef* PointerTypedefInterface;

@protocol ProtocolWithTypedefs
- (TypedefInterface*)typedefReturnValue1;
- (PointerTypedefInterface)typedefReturnValue2;
- (void)typedefParameter:(TypedefInterface*)parameter;
@end


// --------------------------------------------------------------------------------------
//	Tests
// --------------------------------------------------------------------------------------

@implementation OCMockObjectProtocolMocksTests

- (void)testCanMockFormalProtocol
{
    id mock = [OCMockObject mockForProtocol:@protocol(NSLocking)];
    [[mock expect] lock];

    [mock lock];

    [mock verify];
}

- (void)testSetsCorrectNameForProtocolMockObjects
{
    id mock = [OCMockObject mockForProtocol:@protocol(NSLocking)];
    STAssertEqualObjects(@"OCMockObject[NSLocking]", [mock description], @"Should have returned correct description.");
}

- (void)testRaisesWhenUnknownMethodIsCalledOnProtocol
{
    id mock = [OCMockObject mockForProtocol:@protocol(NSLocking)];
    STAssertThrows([mock lowercaseString], @"Should have raised an exception.");
}

- (void)testConformsToMockedProtocol
{
    id mock = [OCMockObject mockForProtocol:@protocol(NSLocking)];
    STAssertTrue([mock conformsToProtocol:@protocol(NSLocking)], nil);
}

- (void)testRespondsToValidProtocolRequiredSelector
{
    id mock = [OCMockObject mockForProtocol:@protocol(TestProtocol)];
    STAssertTrue([mock respondsToSelector:@selector(primitiveValue)], nil);
}

- (void)testRespondsToValidProtocolOptionalSelector
{
    id mock = [OCMockObject mockForProtocol:@protocol(TestProtocol)];
    STAssertTrue([mock respondsToSelector:@selector(objectValue)], nil);
}

- (void)testDoesNotRespondToInvalidProtocolSelector
{
    id mock = [OCMockObject mockForProtocol:@protocol(TestProtocol)];
    STAssertFalse([mock respondsToSelector:@selector(fooBar)], nil);
}

- (void)testWithTypedefReturnType {
    id mock = [OCMockObject mockForProtocol:@protocol(ProtocolWithTypedefs)];
    STAssertNoThrow([[[mock stub] andReturn:[TypedefInterface new]] typedefReturnValue1], @"Should accept a typedefed return-type");
    STAssertNoThrow([mock typedefReturnValue1], nil);
}

- (void)testWithTypedefPointerReturnType {
    id mock = [OCMockObject mockForProtocol:@protocol(ProtocolWithTypedefs)];
    STAssertNoThrow([[[mock stub] andReturn:[TypedefInterface new]] typedefReturnValue2], @"Should accept a typedefed return-type");
    STAssertNoThrow([mock typedefReturnValue2], nil);
}

- (void)testWithTypedefParameter {
    id mock = [OCMockObject mockForProtocol:@protocol(ProtocolWithTypedefs)];
    STAssertNoThrow([[mock stub] typedefParameter:nil], @"Should accept a typedefed parameter-type");
    STAssertNoThrow([mock typedefParameter:nil], nil);
}


- (void)testReturnDefaultValueWhenUnknownMethodIsCalledOnNiceProtocolMock
{
    id mock = [OCMockObject niceMockForProtocol:@protocol(TestProtocol)];
    STAssertTrue(0 == [mock primitiveValue], @"Should return 0 on unexpected method call (for nice mock).");
    [mock verify];
}

- (void)testRaisesAnExceptionWenAnExpectedMethodIsNotCalledOnNiceProtocolMock
{
    id mock = [OCMockObject niceMockForProtocol:@protocol(TestProtocol)];
    [[mock expect] primitiveValue];
    STAssertThrows([mock verify], @"Should have raised an exception because method was not called.");
}

@end