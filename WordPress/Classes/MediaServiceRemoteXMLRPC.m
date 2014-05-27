#import "MediaServiceRemoteXMLRPC.h"

#import "Blog.h"
#import <WordPressApi/WPXMLRPCClient.h>

@interface MediaServiceRemoteXMLRPC ()
@property (nonatomic) WPXMLRPCClient *api;
@end

@implementation MediaServiceRemoteXMLRPC

- (id)initWithApi:(WPXMLRPCClient *)api
{
    self = [super init];
    if (self) {
        _api = api;
    }

    return self;
}

- (AFHTTPRequestOperation *)operationToUploadFile:(NSString *)path
                                           ofType:(NSString *)type
                                     withFilename:(NSString *)filename
                                           toBlog:(Blog *)blog
                                          success:(void (^)(NSNumber *mediaID, NSString *url))success
                                          failure:(void (^)(NSError *))failure {
    NSDictionary *data = @{
                           @"name": filename,
                           @"type": type,
                           @"bits": [NSInputStream inputStreamWithFileAtPath:path],
                           };
    NSArray *parameters = [blog getXMLRPCArgsWithExtra:data];
    NSURLRequest *request = [self.api requestWithMethod:@"wp.uploadFile" parameters:parameters];
    AFHTTPRequestOperation *operation = [self.api HTTPRequestOperationWithRequest:request
                                                                          success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                                                              NSDictionary *response = (NSDictionary *)responseObject;

                                                                              if (![response isKindOfClass:[NSDictionary class]]) {
                                                                                  NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadServerResponse userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"The server returned an empty response. This usually means you need to increase the memory limit for your site.", @"")}];
                                                                                  if (failure) {
                                                                                      failure(error);
                                                                                  }
                                                                                  return;
                                                                              }

                                                                              NSNumber *ID = [response numberForKey:@"id"];
                                                                              NSString *url = [response stringForKey:@"url"];

                                                                              if (success) {
                                                                                  success(ID, url);
                                                                              }
                                                                          } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                                                              if (failure) {
                                                                                  failure(error);
                                                                              }
                                                                          }];
    return operation;
}

@end
