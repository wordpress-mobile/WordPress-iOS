#import "PostStatusServiceRemoteREST.h"
#import "WordPressComApi.h"
#import "Blog.h"
#import "RemotePostStatus.h"

@interface PostStatusServiceRemoteREST ()

@property (nonatomic, strong) WordPressComApi *api;

@end

@implementation PostStatusServiceRemoteREST

- (instancetype)initWithApi:(WordPressComApi *)api
{
    self = [super init];
    if (self) {
        _api = api;
    }
    return self;
}

- (void)getStatusesForBlog:(Blog *)blog success:(void (^)(NSArray *))success failure:(void (^)(NSError *))failure
{
    // not supported
    if(failure) {
        failure(nil);
    }
}

@end
