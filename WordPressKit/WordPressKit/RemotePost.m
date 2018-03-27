#import "RemotePost.h"
#import <objc/runtime.h>

NSString * const PostStatusDraft = @"draft";
NSString * const PostStatusPending = @"pending";
NSString * const PostStatusPrivate = @"private";
NSString * const PostStatusPublish = @"publish";
NSString * const PostStatusScheduled = @"future";
NSString * const PostStatusTrash = @"trash";
NSString * const PostStatusDeleted = @"deleted"; // Returned by wpcom REST API when a post is permanently deleted.

@implementation RemotePost

- (id)initWithSiteID:(NSNumber *)siteID status:(NSString *)status title:(NSString *)title content:(NSString *)content
{
    self = [super init];
    if (self) {
        _siteID = siteID;
        _status = status;
        _title = title;
        _content = content;
    }
    return self;
}

- (NSString *)debugDescription {
    NSDictionary *properties = [self debugProperties];
    return [NSString stringWithFormat:@"<%@: %p> (%@)", NSStringFromClass([self class]), self, properties];
}

- (NSDictionary *)debugProperties {
    unsigned int propertyCount;
    objc_property_t *properties = class_copyPropertyList([RemotePost class], &propertyCount);
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
