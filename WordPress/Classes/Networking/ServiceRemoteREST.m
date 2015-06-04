#import "ServiceRemoteREST.h"
#import "WordPressComApi.h"

@interface ServiceRemoteREST ()
@end

@implementation ServiceRemoteREST

- (id)initWithApi:(WordPressComApi *)api {
    
    NSAssert([api isKindOfClass:[WordPressComApi class]],
             @"Expected api to be a valid WordPressComApi instance.");
    
    self = [super init];
    if (self) {
        _api = api;
    }
    return self;
}
@end
