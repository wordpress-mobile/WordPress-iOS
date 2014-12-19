#import "Notification.h"



#pragma mark ====================================================================================
#pragma mark NotificationBlock: Protected Methods
#pragma mark ====================================================================================

@interface NotificationBlock (Internals)

// Dynamic Attribute Cache: used internally by the Interface Extension, as an optimization.
- (void)setCacheValue:(id)value forKey:(NSString *)key;
- (id)cacheValueForKey:(NSString *)key;

@end
