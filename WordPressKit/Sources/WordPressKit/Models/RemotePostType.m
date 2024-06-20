#import "RemotePostType.h"

@implementation RemotePostType

- (NSString *)debugDescription
{
    NSDictionary *properties = @{
                                 @"name": self.name,
                                 @"label": self.label,
                                 @"apiQueryable": self.apiQueryable
                                 };
    return [NSString stringWithFormat:@"<%@: %p> (%@)", NSStringFromClass([self class]), self, properties];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p> %@[%@], apiQueryable=%@", NSStringFromClass([self class]), self, self.name, self.label, self.apiQueryable];
}

@end
