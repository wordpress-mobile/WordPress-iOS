#import "RemotePublicizer.h"

@implementation RemotePublicizer

- (NSString *)debugDescription {
    NSDictionary *properties = @{
                                 @"service": self.service,
                                 @"label": self.label,
                                 @"detail": self.detail,
                                 @"connect": self.connect,
                                 };
    return [NSString stringWithFormat:@"<%@: %p> (%@)", NSStringFromClass([self class]), self, properties];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p> %@[%@]", NSStringFromClass([self class]), self, self.service];
}

@end
