/*
 *  Copyright (c) 2009-2014 Erik Doernenburg and contributors
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

#import "NSObject+OCMAdditions.h"
#import "NSMethodSignature+OCMAdditions.h"
#import <objc/runtime.h>

@implementation NSObject(OCMAdditions)

+ (IMP)instanceMethodForwarderForSelector:(SEL)aSelector
{
    // use NSSelectorFromString and not @selector to avoid warning
    SEL selectorWithNoImplementation = NSSelectorFromString(@"methodWhichMustNotExist::::");

#ifndef __arm64__
    NSMethodSignature *sig = [self instanceMethodSignatureForSelector:aSelector];
    if([sig usesSpecialStructureReturn])
        return class_getMethodImplementation_stret(self, selectorWithNoImplementation);
#endif
    
    return class_getMethodImplementation(self, selectorWithNoImplementation);
}


+ (void)enumerateMethodsInClass:(Class)aClass usingBlock:(void (^)(SEL selector))aBlock
{
    for(Class cls = aClass; cls != nil; cls = class_getSuperclass(cls))
    {
        Method *methodList = class_copyMethodList(cls, NULL);
        if(methodList == NULL)
            continue;
        for(Method *mPtr = methodList; *mPtr != NULL; mPtr++)
        {
            SEL selector = method_getName(*mPtr);
            aBlock(selector);
        }
        free(methodList);
    }
}

@end
