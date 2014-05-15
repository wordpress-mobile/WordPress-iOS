//---------------------------------------------------------------------------------------
//  $Id$
//  Copyright (c) 2013 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import "OCMockObjectForwardingTargetTests.h"
#import <OCMock/OCMock.h>
#import <objc/runtime.h>

#pragma mark   Helper classes

@interface InternalObject : NSObject
{
    NSString *_name;
}
@property (nonatomic, strong) NSString *name;
@end

@interface PublicObject : NSObject
{
    InternalObject *_internal;
};
@property (nonatomic, strong) NSString *name;
@end

@implementation InternalObject

@synthesize name = _name;

- (void)dealloc
{
    [_name release];
    [super dealloc];
}

@end


@implementation PublicObject

@dynamic name;

- (instancetype)initWithInternal:(InternalObject *)internal
{
    self = [super init];
    if (!self)
        return self;

    _internal = internal;
    return self;
}

- (instancetype)init
{
    return [self initWithInternal:[[InternalObject alloc] init]];
}

- (void)dealloc
{
    [_internal release];
    [super dealloc];
}

- (id)forwardingTargetForSelector:(SEL)selector
{
    if (selector == @selector(name) ||
        selector == @selector(setName:))
        return _internal;
    return [super forwardingTargetForSelector:selector];
}

+ (NSMethodSignature *)instanceMethodSignatureForSelector:(SEL)selector
{
    NSMethodSignature *signature = [super instanceMethodSignatureForSelector:selector];
    if (signature)
        return signature;
    else
        return [InternalObject instanceMethodSignatureForSelector:selector];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector
{
    NSMethodSignature *signature = [super methodSignatureForSelector:selector];
    if (signature)
        return signature;

    return [[self forwardingTargetForSelector:selector] methodSignatureForSelector:selector];
}

- (BOOL)respondsToSelector:(SEL)selector
{
    if ([super respondsToSelector:selector])
        return YES;

    return [[self forwardingTargetForSelector:selector] respondsToSelector:selector];
}

+ (BOOL)instancesRespondToSelector:(SEL)selector
{
    if (class_respondsToSelector(self, selector))
        return YES;

    return [InternalObject instancesRespondToSelector:selector];
}

- (id)valueForUndefinedKey:(NSString *)key
{
    return [_internal valueForKey:key];
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
    [_internal setValue:value forKey:key];
}

@end


#pragma mark    Tests


@implementation OCMockForwardingTargetTests

- (void)testNameShouldForwardToInternal
{
    InternalObject *internal = [[InternalObject alloc] init];
    internal.name = @"Internal Object";
    PublicObject *public = [[PublicObject alloc] initWithInternal:internal];
    STAssertEqualObjects(@"Internal Object", public.name, nil);
}

- (void)testStubsMethodImplementation
{
    PublicObject *public = [[PublicObject alloc] init];
    id mock = [OCMockObject partialMockForObject:public];

    [[[mock stub] andReturn:@"FOO"] name];
    STAssertEqualObjects(@"FOO", [mock name], nil);
}

@end
