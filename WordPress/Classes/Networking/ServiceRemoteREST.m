#import "ServiceRemoteREST.h"
#import "WordPressComApi.h"

@interface ServiceRemoteREST ()
@end

@implementation ServiceRemoteREST

- (id)initWithApi:(WordPressComApi *)api {
    
    NSParameterAssert([api isKindOfClass:[WordPressComApi class]]);
    
    self = [super init];
    if (self) {
        _api = api;
    }
    return self;
}
@end
