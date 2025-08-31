#import "RemotePostTag.h"

@implementation RemotePostTag

- (NSString *)debugDescription
{
    NSDictionary *properties = @{
                                 @"ID": self.tagID,
                                 @"name": self.name
                                 };
    return [NSString stringWithFormat:@"<%@: %p> (%@)", NSStringFromClass([self class]), self, properties];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p> %@[%@]", NSStringFromClass([self class]), self, self.name, self.tagID];
}

@end
