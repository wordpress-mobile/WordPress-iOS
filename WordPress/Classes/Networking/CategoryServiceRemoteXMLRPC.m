#import "CategoryServiceRemoteXMLRPC.h"
#import "Blog.h"
#import "RemoteCategory.h"
#import <NSString+Util.h>

@interface CategoryServiceRemoteXMLRPC ()
@property (nonatomic, strong) WPXMLRPCClient *api;
@end

@implementation CategoryServiceRemoteXMLRPC

- (instancetype)initWithApi:(WPXMLRPCClient *)api
{
    self = [super init];
    if (self) {
        _api = api;
    }

    return self;
}

- (void)createCategory:(RemoteCategory *)category
               forBlog:(Blog *)blog
               success:(void (^)(RemoteCategory *))success
               failure:(void (^)(NSError *))failure
{
    NSDictionary *extraParameters = @{
                                      @"name" : category.name ?: [NSNull null],
                                      @"parent_id" : category.parentID ?: @0,
                                      @"taxonomy" : @"category",
                                      };
    NSArray *parameters = [blog getXMLRPCArgsWithExtra:extraParameters];


    [self.api callMethod:@"wp.newTerm"
              parameters:parameters
                 success:^(AFHTTPRequestOperation *operation, id responseObject) {
                     NSAssert([responseObject isKindOfClass:[NSString class]], @"wp.newTerm response should be a string");
                     if (![responseObject respondsToSelector:@selector(numericValue)]) {
                         NSString *errorMessage = @"Invalid response to wp.newTerm";
                         NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: errorMessage };
                         NSError *error = [NSError errorWithDomain:NSStringFromClass([self class]) code:0 userInfo:userInfo];
                         DDLogError(@"%@: %@", errorMessage, responseObject);
                         if (failure) {
                             failure(error);
                         }
                         return;
                     }
                     RemoteCategory *newCategory = [RemoteCategory new];
                     NSString *categoryID = (NSString *)responseObject;
                     newCategory.categoryID = [categoryID numericValue];
                     if (success) {
                         success(newCategory);
                     }
                 } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                     if (failure) {
                         failure(error);
                     }
                 }];
}

@end
