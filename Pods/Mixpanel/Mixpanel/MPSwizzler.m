//
//  MPSwizzler.m
//  HelloMixpanel
//
//  Created by Alex Hofsteede on 1/5/14.
//  Copyright (c) 2014 Mixpanel. All rights reserved.
//

#import <objc/runtime.h>
#import "MPSwizzler.h"

#define MIN_ARGS 2
#define MAX_ARGS 3

@interface MPSwizzle : NSObject

@property (nonatomic, assign) Class class;
@property (nonatomic, assign) SEL selector;
@property (nonatomic, assign) IMP originalMethod;
@property (nonatomic, assign) uint numArgs;
@property (nonatomic, copy) NSMapTable *blocks;

- (id)initWithBlock:(swizzleBlock)aBlock
              named:(NSString *)aName
           forClass:(Class)aClass
           selector:(SEL)aSelector
     originalMethod:(IMP)aMethod
        withNumArgs:(uint)numArgs;

@end

static NSMapTable *swizzles;

static void mp_swizzledMethod_2(id self, SEL _cmd)
{
    Method aMethod = class_getInstanceMethod([self class], _cmd);
    MPSwizzle *swizzle = (MPSwizzle *)[swizzles objectForKey:MAPTABLE_ID(aMethod)];
    if (swizzle) {
        ((void(*)(id, SEL))swizzle.originalMethod)(self, _cmd);

        NSEnumerator *blocks = [swizzle.blocks objectEnumerator];
        swizzleBlock block;
        while((block = [blocks nextObject])) {
            block(self, _cmd);
        }
    }
}

static void mp_swizzledMethod_3(id self, SEL _cmd, id arg)
{
    Method aMethod = class_getInstanceMethod([self class], _cmd);
    MPSwizzle *swizzle = (MPSwizzle *)[swizzles objectForKey:MAPTABLE_ID(aMethod)];
    if (swizzle) {
        ((void(*)(id, SEL, id))swizzle.originalMethod)(self, _cmd, arg);

        NSEnumerator *blocks = [swizzle.blocks objectEnumerator];
        swizzleBlock block;
        while((block = [blocks nextObject])) {
            block(self, _cmd);
        }
    }
}

static void (*mp_swizzledMethods[MAX_ARGS - MIN_ARGS + 1])() = {mp_swizzledMethod_2, mp_swizzledMethod_3};

@implementation MPSwizzler

+ (void)load
{
    swizzles = [NSMapTable mapTableWithKeyOptions:(NSPointerFunctionsOpaqueMemory | NSPointerFunctionsOpaquePersonality)
                                     valueOptions:(NSPointerFunctionsStrongMemory | NSPointerFunctionsObjectPointerPersonality)];
}

+ (void)printSwizzles
{
    NSEnumerator *en = [swizzles objectEnumerator];
    MPSwizzle *swizzle;
    while((swizzle = (MPSwizzle *)[en nextObject])) {
        NSLog(@"%@", swizzle);
    }
}

+ (MPSwizzle *)swizzleForMethod:(Method)aMethod
{
    return (MPSwizzle *)[swizzles objectForKey:MAPTABLE_ID(aMethod)];
}

+ (void)removeSwizzleForMethod:(Method)aMethod
{
    [swizzles removeObjectForKey:MAPTABLE_ID(aMethod)];
}

+ (void)setSwizzle:(MPSwizzle *)swizzle forMethod:(Method)aMethod
{
    [swizzles setObject:swizzle forKey:MAPTABLE_ID(aMethod)];
}

+ (BOOL)isLocallyDefinedMethod:(Method)aMethod onClass:(Class)aClass
{
    uint count;
    BOOL isLocal = NO;
    Method *methods = class_copyMethodList(aClass, &count);
    for (NSUInteger i = 0; i < count; i++) {
        if (aMethod == methods[i]) {
            isLocal = YES;
            break;
        }
    }
    free(methods);
    return isLocal;
}

+ (void)swizzleSelector:(SEL)aSelector onClass:(Class)aClass withBlock:(swizzleBlock)aBlock named:(NSString *)aName
{
    Method aMethod = class_getInstanceMethod(aClass, aSelector);
    if (aMethod) {
        uint numArgs = method_getNumberOfArguments(aMethod);
        if (numArgs >= MIN_ARGS && numArgs <= MAX_ARGS) {

            BOOL isLocal = [self isLocallyDefinedMethod:aMethod onClass:aClass];
            IMP swizzledMethod = (IMP)mp_swizzledMethods[numArgs - 2];
            MPSwizzle *swizzle = [self swizzleForMethod:aMethod];

            if (isLocal) {
                if (!swizzle) {
                    IMP originalMethod = method_getImplementation(aMethod);

                    // Replace the local implementation of this method with the swizzled one
                    method_setImplementation(aMethod,swizzledMethod);

                    // Create and add the swizzle
                    swizzle = [[MPSwizzle alloc] initWithBlock:aBlock named:aName forClass:aClass selector:aSelector originalMethod:originalMethod withNumArgs:numArgs];
                    [self setSwizzle:swizzle forMethod:aMethod];

                } else {
                    [swizzle.blocks setObject:aBlock forKey:aName];
                }
            } else {
                IMP originalMethod = swizzle ? swizzle.originalMethod : method_getImplementation(aMethod);

                // Add the swizzle as a new local method on the class.
                if (!class_addMethod(aClass, aSelector, swizzledMethod, method_getTypeEncoding(aMethod))) {
                    [NSException raise:@"SwizzleException" format:@"Could not add swizzled for %@::%@, even though it didn't already exist locally", NSStringFromClass(aClass), NSStringFromSelector(aSelector)];
                }
                // Now re-get the Method, it should be the one we just added.
                Method newMethod = class_getInstanceMethod(aClass, aSelector);
                if (aMethod == newMethod) {
                    [NSException raise:@"SwizzleException" format:@"Newly added method for %@::%@ was the same as the old method", NSStringFromClass(aClass), NSStringFromSelector(aSelector)];
                }

                MPSwizzle *newSwizzle = [[MPSwizzle alloc] initWithBlock:aBlock named:aName forClass:aClass selector:aSelector originalMethod:originalMethod withNumArgs:numArgs];
                [self setSwizzle:newSwizzle forMethod:newMethod];
            }
        } else {
            [NSException raise:@"SwizzleException" format:@"Cannot swizzle method with %d args", numArgs];
        }
    } else {
        [NSException raise:@"SwizzleException" format:@"Cannot find method for %@ on %@", NSStringFromSelector(aSelector), NSStringFromClass(aClass)];
    }
}

+ (void)unswizzleSelector:(SEL)aSelector onClass:(Class)aClass
{
    Method aMethod = class_getInstanceMethod(aClass, aSelector);
    MPSwizzle *swizzle = [self swizzleForMethod:aMethod];
    if (swizzle) {
        method_setImplementation(aMethod, swizzle.originalMethod);
        [self removeSwizzleForMethod:aMethod];
    }
}

/*
 Remove the named swizzle from the given class/selector. If aName is nil, remove all
 swizzles for this class/selector
*/
+ (void)unswizzleSelector:(SEL)aSelector onClass:(Class)aClass named:(NSString *)aName
{
    Method aMethod = class_getInstanceMethod(aClass, aSelector);
    MPSwizzle *swizzle = [self swizzleForMethod:aMethod];
    if (swizzle) {
        if (aName) {
            [swizzle.blocks removeObjectForKey:aName];
        }
        if (!aName || [swizzle.blocks count] == 0) {
            method_setImplementation(aMethod, swizzle.originalMethod);
            [self removeSwizzleForMethod:aMethod];
        }
    }
}

@end


@implementation MPSwizzle

- (id)init
{
    if ((self = [super init])) {
        self.blocks = [NSMapTable mapTableWithKeyOptions:(NSPointerFunctionsStrongMemory | NSPointerFunctionsObjectPersonality)
                                            valueOptions:(NSPointerFunctionsStrongMemory | NSPointerFunctionsObjectPointerPersonality)];
    }
    return self;
}

- (id)initWithBlock:(swizzleBlock)aBlock
              named:(NSString *)aName
           forClass:(Class)aClass
           selector:(SEL)aSelector
     originalMethod:(IMP)aMethod
        withNumArgs:(uint)numArgs
{
    if ((self = [self init])) {
        self.class = aClass;
        self.selector = aSelector;
        self.numArgs = numArgs;
        self.originalMethod = aMethod;
        [self.blocks setObject:aBlock forKey:aName];
    }
    return self;
}

- (NSString *)description
{
    NSString *descriptors = @"";
    NSString *key;
    NSEnumerator *keys = [self.blocks keyEnumerator];
    while ((key = [keys nextObject])) {
        descriptors = [descriptors stringByAppendingFormat:@"\t%@ : %@\n", key, [self.blocks objectForKey:key]];
    }
    return [NSString stringWithFormat:@"Swizzle on %@::%@ [\n%@]", NSStringFromClass(self.class), NSStringFromSelector(self.selector), descriptors];
}

@end
