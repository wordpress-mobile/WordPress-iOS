#import "RemoteBlog.h"

@implementation RemoteBlog
- (NSString *)description
{
    NSDictionary *properties = @{
                                 @"ID": self.ID,
                                 @"title": self.title,
                                 @"url": self.url,
                                 @"xmlrpc": self.xmlrpc,
                                 @"jetpack": self.jetpack ? @"YES" : @"NO",
                                 @"icon": self.icon ? self.icon : @""
                                 };
    return [NSString stringWithFormat:@"<%@: %p> (%@)", NSStringFromClass([self class]), self, properties];
}
@end