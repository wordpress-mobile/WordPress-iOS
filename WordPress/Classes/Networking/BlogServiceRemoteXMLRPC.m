#import "BlogServiceRemoteXMLRPC.h"
#import <WordPressApi.h>
#import "Blog.h"

@interface BlogServiceRemoteXMLRPC ()

@property (nonatomic, strong) WPXMLRPCClient *api;

@end

@implementation BlogServiceRemoteXMLRPC

- (id)initWithApi:(WPXMLRPCClient *)api
{
    self = [super init];
    if (self) {
        _api = api;
    }

    return self;
}

- (void)checkMultiAuthorForBlog:(Blog *)blog
                        success:(void(^)(BOOL isMultiAuthor))success
                        failure:(void (^)(NSError *error))failure
{
    NSParameterAssert(blog != nil);
    NSDictionary *filter = @{@"who":@"authors"};
    NSArray *parameters = [blog getXMLRPCArgsWithExtra:filter];
    [self.api callMethod:@"wp.getUsers"
              parameters:parameters
                 success:^(AFHTTPRequestOperation *operation, id responseObject) {
                     if (success) {
                         NSArray *response = (NSArray *)responseObject;
                         BOOL isMultiAuthor = [response count] > 1;
                         success(isMultiAuthor);
                     }
                 } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                     if (failure) {
                         failure(error);
                     }
                 }];
}

- (void)syncOptionsForBlog:(Blog *)blog success:(OptionsHandler)success failure:(void (^)(NSError *))failure
{
    WPXMLRPCRequestOperation *operation = [self operationForOptionsWithBlog:blog success:success failure:failure];
    [blog.api enqueueXMLRPCRequestOperation:operation];
}

- (void)syncPostFormatsForBlog:(Blog *)blog success:(PostFormatsHandler)success failure:(void (^)(NSError *))failure
{
    WPXMLRPCRequestOperation *operation = [self operationForPostFormatsWithBlog:blog success:success failure:failure];
    [blog.api enqueueXMLRPCRequestOperation:operation];
}

- (WPXMLRPCRequestOperation *)operationForOptionsWithBlog:(Blog *)blog
                                                  success:(OptionsHandler)success
                                                  failure:(void (^)(NSError *error))failure
{
    NSArray *parameters = [blog getXMLRPCArgsWithExtra:nil];
    WPXMLRPCRequest *request = [self.api XMLRPCRequestWithMethod:@"wp.getOptions" parameters:parameters];
    WPXMLRPCRequestOperation *operation = [self.api XMLRPCRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSAssert([responseObject isKindOfClass:[NSDictionary class]], @"Response should be a dictionary.");

        if (success) {
            success(responseObject);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogError(@"Error syncing options: %@", error);

        if (failure) {
            failure(error);
        }
    }];

    return operation;
}

- (WPXMLRPCRequestOperation *)operationForPostFormatsWithBlog:(Blog *)blog 
                                                      success:(PostFormatsHandler)success
                                                      failure:(void (^)(NSError *error))failure
{
    NSDictionary *dict = @{@"show-supported": @"1"};
    NSArray *parameters = [blog getXMLRPCArgsWithExtra:dict];

    WPXMLRPCRequest *request = [self.api XMLRPCRequestWithMethod:@"wp.getPostFormats" parameters:parameters];
    WPXMLRPCRequestOperation *operation = [self.api XMLRPCRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSAssert([responseObject isKindOfClass:[NSDictionary class]], @"Response should be a dictionary.");

        NSDictionary *postFormats = responseObject;
        NSDictionary *respDict = responseObject;
        if ([postFormats objectForKey:@"supported"]) {
            NSMutableArray *supportedKeys;
            if ([[postFormats objectForKey:@"supported"] isKindOfClass:[NSArray class]]) {
                supportedKeys = [NSMutableArray arrayWithArray:[postFormats objectForKey:@"supported"]];
            } else if ([[postFormats objectForKey:@"supported"] isKindOfClass:[NSDictionary class]]) {
                supportedKeys = [NSMutableArray arrayWithArray:[[postFormats objectForKey:@"supported"] allValues]];
            }
            
            // Standard isn't included in the list of supported formats? Maybe it will be one day?
            if (![supportedKeys containsObject:@"standard"]) {
                [supportedKeys addObject:@"standard"];
            }

            NSDictionary *allFormats = [postFormats objectForKey:@"all"];
            NSMutableArray *supportedValues = [NSMutableArray array];
            for (NSString *key in supportedKeys) {
                [supportedValues addObject:[allFormats objectForKey:key]];
            }
            respDict = [NSDictionary dictionaryWithObjects:supportedValues forKeys:supportedKeys];
        }

        if (success) {
            success(respDict);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogError(@"Error syncing post formats (%@): %@", operation.request.URL, error);

        if (failure) {
            failure(error);
        }
    }];

    return operation;
}

@end
