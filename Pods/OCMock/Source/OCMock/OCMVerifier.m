/*
 *  Copyright (c) 2014 Erik Doernenburg and contributors
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
#import "OCMVerifier.h"
#import "OCMockObject.h"
#import "OCMInvocationMatcher.h"
#import "OCClassMockObject.h"


@implementation OCMVerifier

- (id)initWithMockObject:(OCMockObject *)aMockObject
{
    // no super, we're inheriting from NSProxy
    mockObject = aMockObject;
    return self;
}

- (id)classMethod
{
    // should we handle the case where this is called with a mock that isn't a class mock?
    verifyAsClassMethod = YES;
    return self;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    if(verifyAsClassMethod)
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
    [anInvocation setTarget:nil];
    OCMInvocationMatcher *matcher = [[[OCMInvocationMatcher alloc] init] autorelease];
    [matcher setInvocation:anInvocation];
    [matcher setRecordedAsClassMethod:verifyAsClassMethod];
    [mockObject verifyInvocation:matcher];
}

- (void)doesNotRecognizeSelector:(SEL)aSelector
{
    [NSException raise:NSInvalidArgumentException format:@"%@: cannot stub or expect method '%@' because no such method exists in the mocked class.", mockObject, NSStringFromSelector(aSelector)];
}



@end
