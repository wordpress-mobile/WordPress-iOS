#import "Publicizer.h"

@implementation Publicizer

@dynamic service;
@dynamic label;
@dynamic detail;
@dynamic icon;
@dynamic connect;
@dynamic order;
@dynamic blog;

- (BOOL)isConnected
{
    for (NSDictionary *connection in self.blog.connections) {
        if ([connection[@"service"] isEqualToString:self.service]) {
            return true;
        }
    }
    return false;
}

@end
