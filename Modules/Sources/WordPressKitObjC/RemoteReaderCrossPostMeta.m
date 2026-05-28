#import "RemoteReaderCrossPostMeta.h"

@implementation RemoteReaderCrossPostMeta

- (instancetype)init {
    self = [super init];
    if (self) {
        _postID = @0;
        _siteID = @0;
        _siteURL = @"";
        _postURL = @"";
        _commentURL = @"";
    }
    return self;
}

@end
