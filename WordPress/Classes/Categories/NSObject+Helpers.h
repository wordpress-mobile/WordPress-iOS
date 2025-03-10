#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (Helpers)

// FIXME: Currently duplicated in WordPressSharedObjC because it'll be used in WordPressData (which depends on WordPressSharedObjc)
// It's not convenient to replace all usages in the main targets at this time.
// They should progressively diminish as we move all the Core Data related code into WordPressData.
// At that point, we should be able to remove this method from the main target.
+ (NSString *)classNameWithoutNamespaces;

- (void)debounce:(SEL)selector afterDelay:(NSTimeInterval)timeInterval;
@end

NS_ASSUME_NONNULL_END
