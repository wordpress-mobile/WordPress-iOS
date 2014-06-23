#import "AccountServiceRemote.h"
#import <WordPressApi/WordPressApi.h>

@implementation RemoteBlog
- (NSString *)debugDescription {
    NSDictionary *properties = @{
                                 @"ID": self.ID,
                                 @"title": self.title,
                                 @"url": self.url,
                                 @"xmlrpc": self.xmlrpc,
                                 };
    return [NSString stringWithFormat:@"<%@: %p> (%@)", NSStringFromClass([self class]), self, properties];
}
@end