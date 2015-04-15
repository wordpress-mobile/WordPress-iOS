#import "RemotePostStatus.h"

@implementation RemotePostStatus

- (NSString *)debugDescription {
    NSDictionary *properties = @{
                                 @"name": self.name,
                                 @"label": self.label,
                                 };
    return [NSString stringWithFormat:@"<%@: %p> (%@)", NSStringFromClass([self class]), self, properties];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p> %@[%@]", NSStringFromClass([self class]), self, self.name, self.label];
}

@end
