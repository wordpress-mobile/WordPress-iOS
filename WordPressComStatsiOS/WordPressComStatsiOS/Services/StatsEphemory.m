#import "StatsEphemory.h"

@interface EphemoryContainer : NSObject

@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) id data;

@end

@implementation EphemoryContainer

@end

@interface StatsEphemory ()

@property (nonatomic, strong) NSMutableDictionary *cache;
@property (nonatomic, assign, readwrite) NSTimeInterval expiryInterval;

@end

@implementation StatsEphemory

- (instancetype)init
{
    self = [super init];
    if (self) {
        _cache = [NSMutableDictionary new];
        _expiryInterval = NSTimeIntervalSince1970;
    }
    return self;
}


- (instancetype)initWithExpiryInterval:(NSTimeInterval)expiryInterval
{
    self = [self init];
    if (self) {
        _expiryInterval = expiryInterval;
    }
    return self;
}


- (id)objectForKey:(id)key
{
    NSParameterAssert(key != nil);

    EphemoryContainer *container = [self.cache objectForKey:key];
    
    // Only return data when the expiration hasn't passed
    if (fabs([container.date timeIntervalSinceNow]) <= self.expiryInterval) {
        return container.data;
    }

    return nil;
}


- (void)setObject:(id)obj forKey:(id)key
{
    NSParameterAssert(obj != nil);
    NSParameterAssert(key != nil);
    
    EphemoryContainer *container = [EphemoryContainer new];
    container.date = [NSDate date];
    container.data = obj;
    
    [self.cache setObject:container forKey:key];
}


- (void)removeObjectForKey:(id)key
{
    NSParameterAssert(key != nil);
    
    [self.cache removeObjectForKey:key];
}

- (void)removeAllObjectsExceptObjectForKey:(id)key
{
    NSParameterAssert(key != nil);

    for (id existingKey in self.cache.allKeys) {
        if ([existingKey isEqual:key]) {
            continue;
        }
        
        [self.cache removeObjectForKey:existingKey];
    }
}

- (void)removeAllObjects
{
    [self.cache removeAllObjects];
}

@end
