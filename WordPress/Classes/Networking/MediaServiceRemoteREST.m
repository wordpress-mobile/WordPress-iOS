#import "MediaServiceRemoteREST.h"
#import "WordPressComApi.h"
#import "Blog.h"

@interface MediaServiceRemoteREST ()
@property (nonatomic) WordPressComApi *api;
@end

@implementation MediaServiceRemoteREST

- (id)initWithApi:(WordPressComApi *)api {
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
    NSString *apiPath = [NSString stringWithFormat:@"sites/%@/media/new", blog.dotComID];
    NSMutableURLRequest *request = [self.api.requestSerializer multipartFormRequestWithMethod:@"POST" URLString:[[NSURL URLWithString:apiPath relativeToURL:self.api.baseURL] absoluteString] parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        NSURL *url = [[NSURL alloc] initFileURLWithPath:path];
        [formData appendPartWithFileURL:url name:@"media[]" fileName:filename mimeType:type error:nil];
    } error:nil];
    AFHTTPRequestOperation *operation = [self.api HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            NSDictionary *response = (NSDictionary *)responseObject;
            NSDictionary *media = [[response arrayForKey:@"media"] firstObject];
            NSNumber *mediaID = [media numberForKey:@"id"];
            NSString *url = [media stringForKey:@"link"];
            success(mediaID, url);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];

    return operation;
}

@end
