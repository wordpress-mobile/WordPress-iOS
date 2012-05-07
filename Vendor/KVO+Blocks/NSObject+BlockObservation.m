//
//  NSObject+BlockObservation.h
//  Version 1.0
//
//  Andy Matuschak
//  andy@andymatuschak.org
//  Public domain because I love you. Let me know how you use it.
//

#import "NSObject+BlockObservation.h"
#import <dispatch/dispatch.h>
#import <objc/runtime.h>

@interface AMObserverTrampoline : NSObject
{
    __weak id observee;
    NSString *keyPath;
    AMBlockTask task;
    NSOperationQueue *queue;
    dispatch_once_t cancellationPredicate;
}

- (AMObserverTrampoline *)initObservingObject:(id)obj keyPath:(NSString *)keyPath onQueue:(NSOperationQueue *)queue task:(AMBlockTask)task;
- (void)cancelObservation;
@end

@implementation AMObserverTrampoline

static NSString *AMObserverTrampolineContext = @"AMObserverTrampolineContext";

- (AMObserverTrampoline *)initObservingObject:(id)obj keyPath:(NSString *)newKeyPath onQueue:(NSOperationQueue *)newQueue task:(AMBlockTask)newTask
{
    if (!(self = [super init])) return nil;
    task = [newTask copy];
    keyPath = [newKeyPath copy];
    queue = [newQueue retain];
    observee = obj;
    cancellationPredicate = 0;
    [observee addObserver:self forKeyPath:keyPath options:0 context:AMObserverTrampolineContext];   
    return self;
}

- (void)observeValueForKeyPath:(NSString *)aKeyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == AMObserverTrampolineContext)
    {
        if (queue)
            [queue addOperationWithBlock:^{ task(object, change); }];
        else
            task(object, change);
    }
}

- (void)cancelObservation
{
    dispatch_once(&cancellationPredicate, ^{
        [observee removeObserver:self forKeyPath:keyPath];
        observee = nil;
    });
}

- (void)dealloc
{
    [self cancelObservation];
    [task release];
    [keyPath release];
    [queue release];
    [super dealloc];
}

@end

static NSString *AMObserverMapKey = @"org.andymatuschak.observerMap";
static dispatch_queue_t AMObserverMutationQueue = NULL;

static dispatch_queue_t AMObserverMutationQueueCreatingIfNecessary()
{
    static dispatch_once_t queueCreationPredicate = 0;
    dispatch_once(&queueCreationPredicate, ^{
        AMObserverMutationQueue = dispatch_queue_create("org.andymatuschak.observerMutationQueue", 0);
    });
    return AMObserverMutationQueue;
}

@implementation NSObject (AMBlockObservation)

- (AMBlockToken *)addObserverForKeyPath:(NSString *)keyPath task:(AMBlockTask)task
{
    return [self addObserverForKeyPath:keyPath onQueue:nil task:task];
}

- (AMBlockToken *)addObserverForKeyPath:(NSString *)keyPath onQueue:(NSOperationQueue *)queue task:(AMBlockTask)task
{
    AMBlockToken *token = [[NSProcessInfo processInfo] globallyUniqueString];
    dispatch_sync(AMObserverMutationQueueCreatingIfNecessary(), ^{
        NSMutableDictionary *dict = objc_getAssociatedObject(self, AMObserverMapKey);
        if (!dict)
        {
            dict = [[NSMutableDictionary alloc] init];
            objc_setAssociatedObject(self, AMObserverMapKey, dict, OBJC_ASSOCIATION_RETAIN);
            [dict release];
        }
        AMObserverTrampoline *trampoline = [[AMObserverTrampoline alloc] initObservingObject:self keyPath:keyPath onQueue:queue task:task];
        [dict setObject:trampoline forKey:token];
        [trampoline release];
    });
    return token;
}

- (void)removeObserverWithBlockToken:(AMBlockToken *)token
{
    dispatch_sync(AMObserverMutationQueueCreatingIfNecessary(), ^{
        NSMutableDictionary *observationDictionary = objc_getAssociatedObject(self, AMObserverMapKey);
        AMObserverTrampoline *trampoline = [observationDictionary objectForKey:token];
        if (!trampoline)
        {
            NSLog(@"[NSObject(AMBlockObservation) removeObserverWithBlockToken]: Ignoring attempt to remove non-existent observer on %@ for token %@.", self, token);
            return;
        }
        [trampoline cancelObservation];
        [observationDictionary removeObjectForKey:token];
        
        // Due to a bug in the obj-c runtime, this dictionary does not get cleaned up on release when running without GC.
        if ([observationDictionary count] == 0)
            objc_setAssociatedObject(self, AMObserverMapKey, nil, OBJC_ASSOCIATION_RETAIN);
    });
}

@end
