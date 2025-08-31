#import <Foundation/Foundation.h>

@interface NSMutableDictionary (Helpers)
- (void)setValueIfNotNil:(id)value forKey:(NSString *)key;
@end
