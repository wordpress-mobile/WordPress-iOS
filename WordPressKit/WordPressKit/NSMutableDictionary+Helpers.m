#import "NSMutableDictionary+Helpers.h"

@implementation NSMutableDictionary (Helpers)
- (void)setValueIfNotNil:(id)value forKey:(NSString *)key
{
    if (value != nil) {
        self[key] = value;
    }
}
@end
