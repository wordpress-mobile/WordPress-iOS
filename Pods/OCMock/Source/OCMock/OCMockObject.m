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

#import <OCMock/OCMockObject.h>
#import "OCClassMockObject.h"
#import "OCProtocolMockObject.h"
#import "OCPartialMockObject.h"
#import "OCObserverMockObject.h"
#import <OCMock/OCMockRecorder.h>
#import <OCMock/OCMLocation.h>
#import "NSInvocation+OCMAdditions.h"
#import "OCMInvocationMatcher.h"
#import "OCMMacroState.h"
#import "OCMFunctions.h"
#import "OCMVerifier.h"


@implementation OCMockObject

#pragma mark  Class initialisation

+ (void)initialize
{
	if([[NSInvocation class] instanceMethodSignatureForSelector:@selector(getArgumentAtIndexAsObject:)] == NULL)
		[NSException raise:NSInternalInconsistencyException format:@"** Expected method not present; the method getArgumentAtIndexAsObject: is not implemented by NSInvocation. If you see this exception it is likely that you are using the static library version of OCMock and your project is not configured correctly to load categories from static libraries. Did you forget to add the -ObjC linker flag?"];
}


#pragma mark  Factory methods

+ (id)mockForClass:(Class)aClass
{
	return [[[OCClassMockObject alloc] initWithClass:aClass] autorelease];
}

+ (id)mockForProtocol:(Protocol *)aProtocol
{
	return [[[OCProtocolMockObject alloc] initWithProtocol:aProtocol] autorelease];
}

+ (id)partialMockForObject:(NSObject *)anObject
{
	return [[[OCPartialMockObject alloc] initWithObject:anObject] autorelease];
}


+ (id)niceMockForClass:(Class)aClass
{
	return [self _makeNice:[self mockForClass:aClass]];
}

+ (id)niceMockForProtocol:(Protocol *)aProtocol
{
	return [self _makeNice:[self mockForProtocol:aProtocol]];
}


+ (id)_makeNice:(OCMockObject *)mock
{
	mock->isNice = YES;
	return mock;
}


+ (id)observerMock
{
	return [[[OCObserverMockObject alloc] init] autorelease];
}


#pragma mark  Initialisers, description, accessors, etc.

- (id)init
{
	// no [super init], we're inheriting from NSProxy
	expectationOrderMatters = NO;
	recorders = [[NSMutableArray alloc] init];
	expectations = [[NSMutableArray alloc] init];
	rejections = [[NSMutableArray alloc] init];
	exceptions = [[NSMutableArray alloc] init];
    invocations = [[NSMutableArray alloc] init];
    return self;
}

- (void)dealloc
{
	[recorders release];
	[expectations release];
	[rejections	release];
	[exceptions release];
	[invocations release];
	[super dealloc];
}

- (NSString *)description
{
	return @"OCMockObject";
}


- (void)setExpectationOrderMatters:(BOOL)flag
{
    expectationOrderMatters = flag;
}


#pragma mark  Public API

- (id)stub
{
    OCMockRecorder *recorder = [[[OCMockRecorder alloc] initWithMockObject:self] autorelease];
	[recorders addObject:recorder];
	return recorder;
}


- (id)expect
{
	OCMockRecorder *recorder = [self stub];
	[expectations addObject:recorder];
	return recorder;
}


- (id)reject
{
	OCMockRecorder *recorder = [self stub];
	[rejections addObject:recorder];
	return recorder;
}


- (id)verify
{
    return [self verifyAtLocation:nil];
}

- (id)verifyAtLocation:(OCMLocation *)location
{
	if([expectations count] == 1)
	{
        NSString *description = [NSString stringWithFormat:@"%@: expected method was not invoked: %@",
         [self description], [[expectations objectAtIndex:0] description]];
        OCMReportFailure(location, description);
	}
	else if([expectations count] > 0)
	{
		NSString *description = [NSString stringWithFormat:@"%@: %@ expected methods were not invoked: %@",
         [self description], @([expectations count]), [self _recorderDescriptions:YES]];
        OCMReportFailure(location, description);
	}
	if([exceptions count] > 0)
	{
        NSString *description = [NSString stringWithFormat:@"%@: %@ (This is a strict mock failure that was ignored when it actually occured.)",
         [self description], [[exceptions objectAtIndex:0] description]];
        OCMReportFailure(location, description);
	}

    return [[[OCMVerifier alloc] initWithMockObject:self] autorelease];
}


- (void)verifyWithDelay:(NSTimeInterval)delay
{
    [self verifyWithDelay:delay atLocation:nil];
}

- (void)verifyWithDelay:(NSTimeInterval)delay atLocation:(OCMLocation *)location
{
    NSTimeInterval step = 0.01;
    while(delay > 0)
    {
        if([expectations count] == 0)
            break;
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:step]];
        delay -= step;
        step *= 2;
    }
    [self verifyAtLocation:location];
}

- (void)stopMocking
{
    // no-op for mock objects that are not class object or partial mocks
}


#pragma mark  Additional setup (called from recorder)

- (void)prepareForMockingClassMethod:(__unused SEL)aSelector
{
    // to be overridden by subclasses
}

- (void)prepareForMockingMethod:(__unused SEL)aSelector
{
    // to be overridden by subclasses
}


#pragma mark  Handling invocations

- (BOOL)handleSelector:(SEL)sel
{
    for (OCMockRecorder *recorder in recorders)
        if ([[recorder invocationMatcher] matchesSelector:sel])
            return YES;

    return NO;
}

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
    OCMMacroState *macroState = [OCMMacroState globalState];
    if(macroState != nil)
    {
        [macroState handleInvocation:anInvocation];
    }
    else
    {
        if([self handleInvocation:anInvocation] == NO)
            [self handleUnRecordedInvocation:anInvocation];
    }
}

- (BOOL)handleInvocation:(NSInvocation *)anInvocation
{
	OCMockRecorder *recorder = nil;
	unsigned int			   i;

    [invocations addObject:anInvocation];
	
	for(i = 0; i < [recorders count]; i++)
	{
		recorder = [recorders objectAtIndex:i];
		if([[recorder invocationMatcher] matchesInvocation:anInvocation])
			break;
	}
	
	if(i == [recorders count])
		return NO;
	
	if([rejections containsObject:recorder]) 
	{
		NSException *exception = [NSException exceptionWithName:NSInternalInconsistencyException reason:
								  [NSString stringWithFormat:@"%@: explicitly disallowed method invoked: %@", [self description], 
								   [anInvocation invocationDescription]] userInfo:nil];
		[exceptions addObject:exception];
		[exception raise];
	}

	if([expectations containsObject:recorder])
	{
		if(expectationOrderMatters && ([expectations objectAtIndex:0] != recorder))
		{
			[NSException raise:NSInternalInconsistencyException	format:@"%@: unexpected method invoked: %@\n\texpected:\t%@",  
			 [self description], [recorder description], [[expectations objectAtIndex:0] description]];
			
		}
		[[recorder retain] autorelease];
		[expectations removeObject:recorder];
		[recorders removeObjectAtIndex:i];
	}
	[[recorder invocationHandlers] makeObjectsPerformSelector:@selector(handleInvocation:) withObject:anInvocation];
	
	return YES;
}

- (void)handleUnRecordedInvocation:(NSInvocation *)anInvocation
{
	if(isNice == NO)
	{
		NSException *exception = [NSException exceptionWithName:NSInternalInconsistencyException reason:
								  [NSString stringWithFormat:@"%@: unexpected method invoked: %@ %@",  [self description], 
								   [anInvocation invocationDescription], [self _recorderDescriptions:NO]] userInfo:nil];
		[exceptions addObject:exception];
		[exception raise];
	}
}

- (void)doesNotRecognizeSelector:(SEL)aSelector
{
    OCMMacroState *macroState = [OCMMacroState globalState];
     if(macroState != nil)
     {
         // we can't do anything clever with the macro state because we must raise an exception here
         [NSException raise:NSInvalidArgumentException format:@"%@: Cannot stub/expect/verify method '%@' because no such method exists in the mocked class.", self, NSStringFromSelector(aSelector)];
     }
     else
     {
         [super doesNotRecognizeSelector:aSelector];
     }
}

#pragma mark  Verify After Run

- (void)verifyInvocation:(OCMInvocationMatcher *)matcher
{
    [self verifyInvocation:matcher atLocation:nil];
}

- (void)verifyInvocation:(OCMInvocationMatcher *)matcher atLocation:(OCMLocation *)location
{
    for(NSInvocation *invocation in invocations)
    {
        if([matcher matchesInvocation:invocation])
            return;
    }
    NSString *description = [NSString stringWithFormat:@"%@: Method %@ was not invoked.",
     [self description], [matcher description]];

    OCMReportFailure(location, description);
}


#pragma mark  Helper methods

- (NSString *)_recorderDescriptions:(BOOL)onlyExpectations
{
	NSMutableString *outputString = [NSMutableString string];
	
	OCMockRecorder *currentObject;
	NSEnumerator *recorderEnumerator = [recorders objectEnumerator];
	while((currentObject = [recorderEnumerator nextObject]) != nil)
	{
		NSString *prefix;
		
		if(onlyExpectations)
		{
			if(![expectations containsObject:currentObject])
				continue;
			prefix = @" ";
		}
		else
		{
			if ([expectations containsObject:currentObject])
				prefix = @"expected: ";
			else
				prefix = @"stubbed: ";
		}
		[outputString appendFormat:@"\n\t%@\t%@", prefix, [currentObject description]];
	}
	
	return outputString;
}


@end
