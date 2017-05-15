#import <Foundation/Foundation.h>

/*!
    @class      StatsEphemory
    @brief      A lightweight container for NSCache.
    @discussion Encapsulates an NSCache instance with an additional parameter for expiration time interval.
 
                This class' name is a portmanteua of Ephemeral and Memory.
*/
@interface StatsEphemory : NSObject

@property (nonatomic, assign, readonly) NSTimeInterval expiryInterval;

- (instancetype)initWithExpiryInterval:(NSTimeInterval)expiryInterval;

- (id)objectForKey:(id)key;
- (void)setObject:(id)obj forKey:(id)key;
- (void)removeObjectForKey:(id)key;
- (void)removeAllObjects;
- (void)removeAllObjectsExceptObjectForKey:(id)key;

@end
