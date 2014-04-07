#import "NSMutableDictionary+Helpers.h"

@implementation NSMutableDictionary (Helpers)
- (void)setValueIfNotNil:(id)value forKey:(NSString *)key {
    if (value != nil) {
        [self setValue:value forKey:key];
    }
}
@end
