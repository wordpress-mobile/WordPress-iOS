//
//  SLTestController+AppHooks.m
//  Subliminal
//
//  For details and documentation:
//  http://github.com/inkling/Subliminal
//
//  Copyright 2013-2014 Inkling Systems, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "SLTestController+AppHooks.h"
#import "SLMainThreadRef.h"

#import <objc/runtime.h>
#import <objc/message.h>


static const NSTimeInterval kTargetLookupTimeout = 5.0;
static const NSTimeInterval kTargetLookupRetryDelay = 0.25;
NSString *const SLAppActionTargetDoesNotExistException = @"SLAppActionTargetDoesNotExistException";

@implementation SLTestController (AppHooks)

+ (id)actionTargetMapKeyForAction:(SEL)action {
    return NSStringFromSelector(action);
}

// even though the SLTestController is a singleton,
// these really should be instance variables rather than statics
- (NSMutableDictionary *)actionTargetMap {
    static const void *const kActionTargetMapKey = &kActionTargetMapKey;
    NSMutableDictionary *actionTargetMap = objc_getAssociatedObject(self, kActionTargetMapKey);
    if (!actionTargetMap) {
        // actionTargetMap initialization must be thread-safe
        // but we only take the lock if we need to
        @synchronized(self) {
            // check again to make sure that the map is nil
            // (in case we're a second thread that got inside the if above)
            actionTargetMap = objc_getAssociatedObject(self, kActionTargetMapKey);
            if (!actionTargetMap) {
                actionTargetMap = [[NSMutableDictionary alloc] init];
                objc_setAssociatedObject(self, kActionTargetMapKey, actionTargetMap, OBJC_ASSOCIATION_RETAIN);
            }
        }
    }
    return actionTargetMap;
}

- (dispatch_queue_t)actionTargetMapQueue {
    static const void *const kActionTargetMapQueueKey = &kActionTargetMapQueueKey;
    NSValue *actionTargetMapQueueValue = objc_getAssociatedObject(self, kActionTargetMapQueueKey);
    if (!actionTargetMapQueueValue) {
        // actionTargetMapQueue initialization must be thread-safe
        // but we only take the lock if we need to
        @synchronized(self) {
            // check again to make sure that the queue is nil
            // (in case we're a second thread that got inside the if above)
            actionTargetMapQueueValue = objc_getAssociatedObject(self, kActionTargetMapQueueKey);
            if (!actionTargetMapQueueValue) {
                NSString *queueName = [NSString stringWithFormat:@"com.inkling.subliminal.SLTestController+AppHooks-%p.actionTargetMapQueue", self];
                dispatch_queue_t actionTargetMapQueue = dispatch_queue_create([queueName UTF8String], DISPATCH_QUEUE_SERIAL);
                // target the actionTargetMapQueue at the main thread
                // so that we may safely access SLMainThreadRefs' targets from the queue
                dispatch_set_target_queue(actionTargetMapQueue, dispatch_get_main_queue());
                
                actionTargetMapQueueValue = [NSValue value:&actionTargetMapQueue withObjCType:@encode(typeof(actionTargetMapQueue))];
                objc_setAssociatedObject(self, kActionTargetMapQueueKey, actionTargetMapQueueValue, OBJC_ASSOCIATION_RETAIN);
            }
        }
    }
    dispatch_queue_t actionTargetMapQueue;
    [actionTargetMapQueueValue getValue:&actionTargetMapQueue];
    return actionTargetMapQueue;
}

- (void)registerTarget:(id)target forAction:(SEL)action {
    // sanity check
    NSAssert([target respondsToSelector:action], @"Target %@ does not respond to action: %@", target, NSStringFromSelector(action));

    // assert that action is of the proper format
    // we can't actually enforce that id-type arguments/return values conform to NSCopying, but oh well
    NSMethodSignature *actionSignature = [target methodSignatureForSelector:action];

    // Suppress a warning when Subliminal is built with assertions disabled
    // (i.e. by Cocoapods, in Release: https://github.com/CocoaPods/Xcodeproj/pull/53 )
    const char *__unused actionReturnType = [actionSignature methodReturnType];
    NSAssert(strcmp(actionReturnType, @encode(void)) == 0 ||
             strcmp(actionReturnType, @encode(id<NSCopying>)) == 0, @"The action must return a value of either type void or id<NSCopying>.");

    NSUInteger numberOfArguments = [actionSignature numberOfArguments];
    // note that there are always at least two arguments, for self and _cmd
    NSAssert(numberOfArguments < 4, @"The action must identify a method which takes zero or one argument.");
    if (numberOfArguments == 3) {
        NSAssert(strcmp([actionSignature getArgumentTypeAtIndex:2], @encode(id<NSCopying>)) == 0,
                 @"If the action takes an argument, that argument must be of type id<NSCopying>.");
    }

    // register target
    id mapKey = [[self class] actionTargetMapKeyForAction:action];
    dispatch_async([self actionTargetMapQueue], ^{
        SLMainThreadRef *targetRef = [self actionTargetMap][mapKey];
        if ([targetRef target] != target) {
            targetRef = [SLMainThreadRef refWithTarget:target];
            [self actionTargetMap][mapKey] = targetRef;
        }
    });
}

- (void)deregisterTarget:(id)target forAction:(SEL)action {
    // take care not to retain the target in the block
    // (this method may be called from the target's dealloc,
    // and our reference cannot at that point keep it alive,
    // but the release of that reference at block's close will cause a segfault)
    id __unsafe_unretained blockTarget = target;
    id mapKey = [[self class] actionTargetMapKeyForAction:action];
    dispatch_async([self actionTargetMapQueue], ^{
        // if the target is registered for the action, deregister it
        SLMainThreadRef *targetRef = [self actionTargetMap][mapKey];
        if ([targetRef target] == blockTarget) {
            [[self actionTargetMap] removeObjectForKey:mapKey];
        }
    });
}

- (void)deregisterTarget:(id)target {
    // take care not to retain the target in the block
    // (this method may be called from the target's dealloc,
    // and our reference cannot at that point keep it alive,
    // but the release of that reference at block's close will cause a segfault)
    id __unsafe_unretained blockTarget = target;
    dispatch_async([self actionTargetMapQueue], ^{
        // first pass to find the objects
        NSMutableArray *actionsForTarget = [NSMutableArray array];
        [[self actionTargetMap] enumerateKeysAndObjectsUsingBlock:^(id key, SLMainThreadRef *targetRef, BOOL *stop) {
            if ([targetRef target] == blockTarget) {
                [actionsForTarget addObject:key];
            }
        }];
        [[self actionTargetMap] removeObjectsForKeys:actionsForTarget];
    });
}

// The target lookup timeout is factored as a method
// so that the SLTestController+AppHooks tests can provide different values
// for different tests (using OCMock). It is not considered necessary or useful
// to expose it publicly for other purposes.
// Don't change the name of this method without updating the tests.
- (NSTimeInterval)targetLookupTimeout {
    return kTargetLookupTimeout;
}

- (id)sendAction:(SEL)action {
    NSAssert(![NSThread isMainThread], @"-sendAction: must not be called from the main thread.");

    __block id returnValue;
    
    // wait for a target to be registered, if necessary
    __block BOOL lookupDidSucceed = NO;
    id mapKey = [[self class] actionTargetMapKeyForAction:action];
    NSDate *startDate = [NSDate date];
    do {
        dispatch_sync([self actionTargetMapQueue], ^{
            SLMainThreadRef *targetRef = [self actionTargetMap][mapKey];
            id target = [targetRef target];
            
            if (!target) return;
            else lookupDidSucceed = YES;
            
            NSMethodSignature *actionSignature = [target methodSignatureForSelector:action];
            const char *actionReturnType = [actionSignature methodReturnType];
            if (strcmp(actionReturnType, @encode(void)) != 0) {
                // use objc_msgSend so that Clang won't complain about performSelector leaks
                returnValue = ((id(*)(id, SEL))objc_msgSend)(target, action);
            } else {
                ((void(*)(id, SEL))objc_msgSend)(target, action);
                returnValue = nil;
            }

            // return a copy, for thread safety
            // note: if actions return an object, that object is required to conform to NSCopying (see header)
            // no way for us to enforce that at compile-time, though
            returnValue = [returnValue copyWithZone:NULL];
        });
        if (lookupDidSucceed) break;
        [NSThread sleepForTimeInterval:kTargetLookupRetryDelay];
    } while ([[NSDate date] timeIntervalSinceDate:startDate] <= [self targetLookupTimeout]);
    
    if (!lookupDidSucceed) {
        [NSException raise:SLAppActionTargetDoesNotExistException
                    format:@"No target is currently registered for action %@. \
         (Either no target was ever registered, or a registered target has fallen out of scope.)",
         NSStringFromSelector(action)];
    }

    return returnValue;
}

- (id)sendAction:(SEL)action withObject:(id<NSCopying>)object {
    NSAssert(![NSThread isMainThread], @"-sendAction:withObject: must not be called from the main thread.");

    // pass a copy of the argument, for thread safety
    id arg = [object copyWithZone:NULL];
    __block id returnValue;

    // wait for a target to be registered, if necessary
    __block BOOL lookupDidSucceed = NO;
    id mapKey = [[self class] actionTargetMapKeyForAction:action];
    NSDate *startDate = [NSDate date];
    do {
        dispatch_sync([self actionTargetMapQueue], ^{
            SLMainThreadRef *targetRef = [self actionTargetMap][mapKey];
            id target = [targetRef target];

            if (!target) return;
            else lookupDidSucceed = YES;

            NSMethodSignature *actionSignature = [target methodSignatureForSelector:action];
            const char *actionReturnType = [actionSignature methodReturnType];
            if (strcmp(actionReturnType, @encode(void)) != 0) {
                // use objc_msgSend so that Clang won't complain about performSelector leaks
                returnValue = ((id(*)(id, SEL, id))objc_msgSend)(target, action, arg);
            } else {
                ((void(*)(id, SEL, id))objc_msgSend)(target, action, arg);
                returnValue = nil;
            }

            // return a copy, for thread safety
            // note: if actions return an object, that object is required to conform to NSCopying (see header)
            // no way for us to enforce that at compile-time, though
            returnValue = [returnValue copyWithZone:NULL];
        });
        if (lookupDidSucceed) break;
        [NSThread sleepForTimeInterval:kTargetLookupRetryDelay];
    } while ([[NSDate date] timeIntervalSinceDate:startDate] <= [self targetLookupTimeout]);

    if (!lookupDidSucceed) {
        [NSException raise:SLAppActionTargetDoesNotExistException
                    format:@"No target is currently registered for action %@. \
         (Either no target was ever registered, or a registered target has fallen out of scope.)",
         NSStringFromSelector(action)];
    }

    return returnValue;
}

@end
