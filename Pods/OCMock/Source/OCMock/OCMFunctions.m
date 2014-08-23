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
#import "OCMFunctions.h"
#import "OCMLocation.h"
#import "OCClassMockObject.h"
#import "OCPartialMockObject.h"


#pragma mark  Known private API

@interface NSException(OCMKnownExceptionMethods)
+ (NSException *)failureInFile:(NSString *)file atLine:(int)line withDescription:(NSString *)formatString, ...;
@end

@interface NSObject(OCMKnownTestCaseMethods)
- (void)recordFailureWithDescription:(NSString *)description inFile:(NSString *)file atLine:(NSUInteger)line expected:(BOOL)expected;
- (void)failWithException:(NSException *)exception;
@end


#pragma mark  Functions related to ObjC type system

BOOL OCMIsObjectType(const char *objCType)
{
    objCType = OCMTypeWithoutQualifiers(objCType);

    if(strcmp(objCType, @encode(id)) == 0)
        return YES;

    // if the returnType is a typedef to an object, it has the form ^{OriginClass=#}
    NSString *regexString = @"^\\^\\{(.*)=#.*\\}";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexString options:0 error:NULL];
    NSString *type = [NSString stringWithCString:objCType encoding:NSASCIIStringEncoding];
    if([regex numberOfMatchesInString:type options:0 range:NSMakeRange(0, type.length)] > 0)
        return YES;

    return NO;
}


const char *OCMTypeWithoutQualifiers(const char *objCType)
{
    while(strchr("rnNoORV", objCType[0]) != NULL)
        objCType += 1;
    return objCType;
}


#pragma mark  Creating classes

Class OCMCreateSubclass(Class class, void *ref)
{
    double timestamp = [NSDate timeIntervalSinceReferenceDate];
    const char *className = [[NSString stringWithFormat:@"%@-%p-%f", NSStringFromClass(class), ref, timestamp] UTF8String];
    Class subclass = objc_allocateClassPair(class, className, 0);
    objc_registerClassPair(subclass);
    return subclass;
}

#pragma mark  Directly manipulating the isa pointer (look away)

void OCMSetIsa(id object, Class class)
{
    *((Class *)object) = class;
}

Class OCMGetIsa(id object)
{
    return *((Class *)object);
}


#pragma mark  Alias for renaming real methods

NSString *OCMRealMethodAliasPrefix = @"ocmock_replaced_";


BOOL OCMIsAliasSelector(SEL selector)
{
    return [NSStringFromSelector(selector) hasPrefix:OCMRealMethodAliasPrefix];
}

SEL OCMAliasForOriginalSelector(SEL selector)
{
    NSString *string = NSStringFromSelector(selector);
    return NSSelectorFromString([OCMRealMethodAliasPrefix stringByAppendingString:string]);

}

SEL OCMOriginalSelectorForAlias(SEL selector)
{
    if(!OCMIsAliasSelector(selector))
        [NSException raise:NSInvalidArgumentException format:@"Not an alias selector; found %@", NSStringFromSelector(selector)];
    NSString *string = NSStringFromSelector(selector);
    return NSSelectorFromString([string substringFromIndex:[OCMRealMethodAliasPrefix length]]);
}

#pragma mark  Wrappers around associative references

NSString *OCMClassMethodMockObjectKey = @"OCMClassMethodMockObjectKey";

void OCMSetAssociatedMockForClass(OCClassMockObject *mock, Class aClass)
{
    if((mock != nil) && (objc_getAssociatedObject(aClass, OCMClassMethodMockObjectKey) != nil))
        [NSException raise:NSInternalInconsistencyException format:@"Another mock is already associated with class %@", NSStringFromClass(aClass)];
    objc_setAssociatedObject(aClass, OCMClassMethodMockObjectKey, mock, OBJC_ASSOCIATION_ASSIGN);
}

OCClassMockObject *OCMGetAssociatedMockForClass(Class aClass, BOOL includeSuperclasses)
{
    OCClassMockObject *mock = nil;
    do
    {
        mock = objc_getAssociatedObject(aClass, OCMClassMethodMockObjectKey);
        aClass = class_getSuperclass(aClass);
    }
    while((mock == nil) && (aClass != nil) && includeSuperclasses);
    return mock;
}

NSString *OCMPartialMockObjectKey = @"OCMPartialMockObjectKey";

void OCMSetAssociatedMockForObject(OCClassMockObject *mock, id anObject)
{
    if((mock != nil) && (objc_getAssociatedObject(anObject, OCMPartialMockObjectKey) != nil))
        [NSException raise:NSInternalInconsistencyException format:@"Another mock is already associated with object %@", anObject];
    objc_setAssociatedObject(anObject, OCMPartialMockObjectKey, mock, OBJC_ASSOCIATION_ASSIGN);
}

OCPartialMockObject *OCMGetAssociatedMockForObject(id anObject)
{
    return objc_getAssociatedObject(anObject, OCMPartialMockObjectKey);
}


#pragma mark  Functions related to IDE error reporting

void OCMReportFailure(OCMLocation *loc, NSString *description)
{
    id testCase = [loc testCase];
    if((testCase != nil) && [testCase respondsToSelector:@selector(recordFailureWithDescription:inFile:atLine:expected:)])
    {
        [testCase recordFailureWithDescription:description inFile:[loc file] atLine:[loc line] expected:NO];
    }
    else if((testCase != nil) && [testCase respondsToSelector:@selector(failWithException:)])
    {
        NSException *exception = nil;
        if([NSException instancesRespondToSelector:@selector(failureInFile:atLine:withDescription:)])
        {
            exception = [NSException failureInFile:[loc file] atLine:(int)[loc line] withDescription:description];
        }
        else
        {
            NSString *reason = [NSString stringWithFormat:@"%@:%lu %@", [loc file], (unsigned long)[loc line], description];
            exception = [NSException exceptionWithName:@"OCMockTestFailure" reason:reason userInfo:nil];
        }
        [testCase failWithException:exception];
    }
    else if(loc != nil)
    {
        NSLog(@"%@:%lu %@", [loc file], (unsigned long)[loc line], description);
        NSString *reason = [NSString stringWithFormat:@"%@:%lu %@", [loc file], (unsigned long)[loc line], description];
        [[NSException exceptionWithName:@"OCMockTestFailure" reason:reason userInfo:nil] raise];

    }
    else
    {
        NSLog(@"%@", description);
        [[NSException exceptionWithName:@"OCMockTestFailure" reason:description userInfo:nil] raise];
    }

}
