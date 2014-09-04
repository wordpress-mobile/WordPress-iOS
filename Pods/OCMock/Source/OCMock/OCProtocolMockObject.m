/*
 *  Copyright (c) 2005-2014 Erik Doernenburg and contributors
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
#import "NSMethodSignature+OCMAdditions.h"
#import "OCProtocolMockObject.h"

@implementation OCProtocolMockObject

#pragma mark  Initialisers, description, accessors, etc.

- (id)initWithProtocol:(Protocol *)aProtocol
{
	[super init];
	mockedProtocol = aProtocol;
	return self;
}

- (NSString *)description
{
    const char* name = protocol_getName(mockedProtocol);
    return [NSString stringWithFormat:@"OCMockObject(%s)", name];
}

#pragma mark  Proxy API

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
	struct objc_method_description methodDescription = protocol_getMethodDescription(mockedProtocol, aSelector, YES, YES);
    if(methodDescription.name == NULL) 
	{
        methodDescription = protocol_getMethodDescription(mockedProtocol, aSelector, NO, YES);
    }
    if(methodDescription.name == NULL) 
	{
        return nil;
    }
	return [NSMethodSignature signatureWithObjCTypes:methodDescription.types];
}

- (BOOL)conformsToProtocol:(Protocol *)aProtocol
{
    return protocol_conformsToProtocol(mockedProtocol, aProtocol);
}

- (BOOL)respondsToSelector:(SEL)selector
{
    return ([self methodSignatureForSelector:selector] != nil);
}

@end
