#import "MenuPostServiceOptions.h"

@implementation MenuPostServiceSyncOptions

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.meta = @"autosave";
    }
    return self;
}

@end
