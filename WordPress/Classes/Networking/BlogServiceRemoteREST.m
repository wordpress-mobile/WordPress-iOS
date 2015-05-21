#import "BlogServiceRemoteREST.h"
#import <WordPressComApi.h>
#import "Blog.h"

@interface BlogServiceRemoteREST ()

@property (nonatomic) WordPressComApi *api;

@end

@implementation BlogServiceRemoteREST

- (id)initWithApi:(WordPressComApi *)api
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
    NSParameterAssert(blog.dotComID != nil);
    NSDictionary *parameters = @{@"authors_only":@(YES)};
    NSString *path = [NSString stringWithFormat:@"sites/%@/users", blog.dotComID];
    [self.api GET:path
       parameters:parameters
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              if (success) {
                  NSDictionary *response = (NSDictionary *)responseObject;
                  BOOL isMultiAuthor = [[response arrayForKey:@"users"] count] > 1;
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
    NSParameterAssert(blog != nil);
    NSParameterAssert(blog.dotComID != nil);
    NSString *path = [self pathForOptionsWithBlog:blog];
    [self.api GET:path
       parameters:nil
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              NSDictionary *response = (NSDictionary *)responseObject;
              NSDictionary *options = [self mapOptionsFromResponse:response];
              if (success) {
                  success(options);
              }
          } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              if (failure) {
                  failure(error);
              }
          }];
}

- (void)syncPostFormatsForBlog:(Blog *)blog success:(PostFormatsHandler)success failure:(void (^)(NSError *))failure
{
    NSParameterAssert(blog != nil);
    NSParameterAssert(blog.dotComID != nil);
    NSString *path = [self pathForPostFormatsWithBlog:blog];
    [self.api GET:path
       parameters:nil
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              NSDictionary *formats = [self mapPostFormatsFromResponse:responseObject[@"formats"]];
              if (success) {
                  success(formats);
              }
          } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              if (failure) {
                  failure(error);
              }
          }];
}

#pragma mark - API paths

- (NSString *)pathForOptionsWithBlog:(Blog *)blog
{
    return [NSString stringWithFormat:@"sites/%@", blog.dotComID];
}

- (NSString *)pathForPostFormatsWithBlog:(Blog *)blog
{
    return [NSString stringWithFormat:@"sites/%@/post-formats", blog.dotComID];
}

#pragma mark - Mapping methods

- (NSDictionary *)mapOptionsFromResponse:(NSDictionary *)response
{
    NSMutableDictionary *options = [NSMutableDictionary dictionary];
    options[@"home_url"] = response[@"URL"];
    // We'd be better off saving this as a BOOL property on Blog, but let's do what XML-RPC does for now
    options[@"blog_public"] = [[response numberForKey:@"is_private"] boolValue] ? @"-1" : @"0";
    if ([[response numberForKey:@"jetpack"] boolValue]) {
        options[@"jetpack_client_id"] = [response numberForKey:@"ID"];
    }
    if ( response[@"options"] ) {
        options[@"post_thumbnail"] = [response valueForKeyPath:@"options.featured_images_enabled"];
        NSArray *optionsDirectMapKeys = @[
                                    @"admin_url",
                                    @"login_url",
                                    @"image_default_link_type",
                                    @"software_version",
                                    @"videopress_enabled",
                                    @"timezone",
                                    @"gmt_offset",
                                    @"allowed_file_types",
                                    ];

        for (NSString *key in optionsDirectMapKeys) {
            NSString *sourceKeyPath = [NSString stringWithFormat:@"options.%@", key];
            options[key] = [response valueForKeyPath:sourceKeyPath];
        }
    } else {
        //valid default values
        options[@"software_version"] = @"3.6";
    }
    NSMutableDictionary *valueOptions = [NSMutableDictionary dictionaryWithCapacity:options.count];
    [options enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        valueOptions[key] = @{@"value": obj};
    }];

    return [NSDictionary dictionaryWithDictionary:valueOptions ];
}

- (NSDictionary *)mapPostFormatsFromResponse:(id)response
{
    if ([response isKindOfClass:[NSDictionary class]]) {
        return response;
    } else {
        return @{};
    }
}

@end
