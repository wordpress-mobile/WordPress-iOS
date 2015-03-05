#import "RemotePostCategory.h"

@implementation RemotePostCategory

- (NSString *)debugDescription {
    NSDictionary *properties = @{
                                 @"ID": self.categoryID,
                                 @"name": self.name,
                                 @"parent": self.parentID,
                                 };
    return [NSString stringWithFormat:@"<%@: %p> (%@)", NSStringFromClass([self class]), self, properties];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p> %@[%@]", NSStringFromClass([self class]), self, self.name, self.categoryID];
}

@end
