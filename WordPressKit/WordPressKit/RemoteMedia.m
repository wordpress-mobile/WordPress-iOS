#import "RemoteMedia.h"
#import <objc/runtime.h>

@implementation RemoteMedia

- (NSString *)debugDescription {
    NSDictionary *properties = [self debugProperties];
    return [NSString stringWithFormat:@"<%@: %p> (%@)", NSStringFromClass([self class]), self, properties];
}

- (NSDictionary *)debugProperties {
    unsigned int propertyCount;
    objc_property_t *properties = class_copyPropertyList([RemoteMedia class], &propertyCount);
    NSMutableDictionary *debugProperties = [NSMutableDictionary dictionaryWithCapacity:propertyCount];
    for (int i = 0; i < propertyCount; i++)
    {
        // Add property name to array
        objc_property_t property = properties[i];
        const char *propertyName = property_getName(property);
        id value = [self valueForKey:@(propertyName)];
        if (value == nil) {
            value = [NSNull null];
        }
        [debugProperties setObject:value forKey:@(propertyName)];
    }
    free(properties);
    return [NSDictionary dictionaryWithDictionary:debugProperties];
}

@end