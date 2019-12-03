#import "PostServiceOptions.h"

@implementation PostServiceSyncOptions

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.meta = @"autosave";
    }
    return self;
}

@end
