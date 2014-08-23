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

#import <objc/runtime.h>
#import <OCMock/OCMockRecorder.h>
#import "OCClassMockObject.h"
#import "OCMInvocationMatcher.h"
#import "OCMReturnValueProvider.h"
#import "OCMBoxedReturnValueProvider.h"
#import "OCMExceptionReturnValueProvider.h"
#import "OCMIndirectReturnValueProvider.h"
#import "OCMNotificationPoster.h"
#import "OCMBlockCaller.h"
#import "OCMRealObjectForwarder.h"
#import "OCMFunctions.h"

@interface NSObject(HCMatcherDummy)
- (BOOL)matches:(id)item;
@end

#pragma mark  -


@implementation OCMockRecorder

#pragma mark  Initialisers, description, accessors, etc.

- (id)initWithMockObject:(OCMockObject *)aMockObject
{
	mockObject = aMockObject;
    invocationMatcher = [[OCMInvocationMatcher alloc] init];
	invocationHandlers = [[NSMutableArray alloc] init];
	return self;
}

- (void)dealloc
{
    [invocationMatcher release];
	[invocationHandlers release];
	[super dealloc];
}

- (NSString *)description
{
    return [invocationMatcher description];
}

- (OCMInvocationMatcher *)invocationMatcher
{
    return invocationMatcher;
}

- (NSArray *)invocationHandlers
{
    return invocationHandlers;
}


#pragma mark  Recording invocation handlers

- (void)addInvocationHandler:(id)aHandler
{
    [invocationHandlers addObject:aHandler];
}

- (id)andReturn:(id)anObject
{
	[self addInvocationHandler:[[[OCMReturnValueProvider alloc] initWithValue:anObject] autorelease]];
	return self;
}

- (id)andReturnValue:(NSValue *)aValue
{
	[self addInvocationHandler:[[[OCMBoxedReturnValueProvider alloc] initWithValue:aValue] autorelease]];
	return self;
}

- (id)andThrow:(NSException *)anException
{
	[self addInvocationHandler:[[[OCMExceptionReturnValueProvider alloc] initWithValue:anException] autorelease]];
	return self;
}

- (id)andPost:(NSNotification *)aNotification
{
	[self addInvocationHandler:[[[OCMNotificationPoster alloc] initWithNotification:aNotification] autorelease]];
	return self;
}

- (id)andCall:(SEL)selector onObject:(id)anObject
{
	[self addInvocationHandler:[[[OCMIndirectReturnValueProvider alloc] initWithProvider:anObject andSelector:selector] autorelease]];
	return self;
}

- (id)andDo:(void (^)(NSInvocation *))aBlock 
{
	[self addInvocationHandler:[[[OCMBlockCaller alloc] initWithCallBlock:aBlock] autorelease]];
	return self;
}

- (id)andForwardToRealObject
{
    [self addInvocationHandler:[[[OCMRealObjectForwarder alloc] init] autorelease]];
    return self;
}


#pragma mark  Modifying the matcher

- (id)classMethod
{
    // should we handle the case where this is called with a mock that isn't a class mock?
    [invocationMatcher setRecordedAsClassMethod:YES];
    return self;
}

- (id)ignoringNonObjectArgs
{
    [invocationMatcher setIgnoreNonObjectArgs:YES];
    return self;
}


#pragma mark  Recording the actual invocation

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    if([invocationMatcher recordedAsClassMethod])
        return [[(OCClassMockObject *)mockObject mockedClass] methodSignatureForSelector:aSelector];
    
    NSMethodSignature *signature = [mockObject methodSignatureForSelector:aSelector];
    if(signature == nil)
    {
        // if we're a working with a class mock and there is a class method, auto-switch
        if(([object_getClass(mockObject) isSubclassOfClass:[OCClassMockObject class]]) &&
           ([[(OCClassMockObject *)mockObject mockedClass] respondsToSelector:aSelector]))
        {
            [self classMethod];
            signature = [self methodSignatureForSelector:aSelector];
        }
    }
    return signature;
}

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
    if([invocationMatcher recordedAsClassMethod])
        [mockObject prepareForMockingClassMethod:[anInvocation selector]];
    else
        [mockObject prepareForMockingMethod:[anInvocation selector]];
//	if(recordedInvocation != nil)
//		[NSException raise:NSInternalInconsistencyException format:@"Recorder received two methods to record."];
	[anInvocation setTarget:nil];
    [invocationMatcher setInvocation:anInvocation];
}

- (void)doesNotRecognizeSelector:(SEL)aSelector
{
    [NSException raise:NSInvalidArgumentException format:@"%@: cannot stub or expect method '%@' because no such method exists in the mocked class.", mockObject, NSStringFromSelector(aSelector)];
}


@end


@implementation OCMockRecorder(Properties)

@dynamic _andReturn;

- (OCMockRecorder *(^)(NSValue *))_andReturn
{
    id (^theBlock)(id) = ^ (NSValue *aValue)
    {
        if(OCMIsObjectType([aValue objCType]))
        {
            NSValue *objValue = nil;
            [aValue getValue:&objValue];
            return [self andReturn:objValue];
        }
        else
        {
            return [self andReturnValue:aValue];
        }
    };
    return [[theBlock copy] autorelease];
}


@dynamic _andThrow;

- (OCMockRecorder *(^)(NSException *))_andThrow
{
    id (^theBlock)(id) = ^ (NSException * anException)
    {
        return [self andThrow:anException];
    };
    return [[theBlock copy] autorelease];
}


@dynamic _andPost;

- (OCMockRecorder *(^)(NSNotification *))_andPost
{
    id (^theBlock)(id) = ^ (NSNotification * aNotification)
    {
        return [self andPost:aNotification];
    };
    return [[theBlock copy] autorelease];
}


@dynamic _andCall;

- (OCMockRecorder *(^)(id, SEL))_andCall
{
    id (^theBlock)(id, SEL) = ^ (id anObject, SEL aSelector)
    {
        return [self andCall:aSelector onObject:anObject];
    };
    return [[theBlock copy] autorelease];
}


@dynamic _andDo;

- (OCMockRecorder *(^)(void (^)(NSInvocation *)))_andDo
{
    id (^theBlock)(void (^)(NSInvocation *)) = ^ (void (^ blockToCall)(NSInvocation *))
    {
        return [self andDo:blockToCall];
    };
    return [[theBlock copy] autorelease];
}


@dynamic _andForwardToRealObject;

- (OCMockRecorder *(^)(void))_andForwardToRealObject
{
    id (^theBlock)(void) = ^ (void)
    {
        return [self andForwardToRealObject];
    };
    return [[theBlock copy] autorelease];
}


@end
