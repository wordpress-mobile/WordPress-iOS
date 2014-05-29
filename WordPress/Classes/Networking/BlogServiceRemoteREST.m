#import "BlogServiceRemoteREST.h"
#import <WordPressComApi.h>

@interface BlogServiceRemoteREST ()

@property (nonatomic) WordPressComApi *api;

@end

@implementation BlogServiceRemoteREST

- (id)initWithApi:(WordPressComApi *)api {
    self = [super init];
    if (self) {
        _api = api;
    }
    return self;
}

@end
