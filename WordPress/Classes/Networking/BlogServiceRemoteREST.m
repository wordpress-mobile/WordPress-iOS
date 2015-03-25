#import "BlogServiceRemoteREST.h"
#import <WordPressComApi.h>
#import "Blog.h"
#import "NSDate+WordPressJSON.h"

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

- (void)syncOptionsForBlog:(Blog *)blog
                   success:(OptionsHandler)success
                   failure:(void (^)(NSError *))failure
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

- (void)syncPostFormatsForBlog:(Blog *)blog
                       success:(PostFormatsHandler)success
                       failure:(void (^)(NSError *))failure
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

- (void)syncMediaLibraryForBlog:(Blog *)blog
                        success:(MediaLibraryHandler)success
                        failure:(void (^)(NSError *))failure
{
#warning write networking code for REST
    NSParameterAssert(blog != nil);
    NSParameterAssert(blog.dotComID != nil);
    NSString *path = [self pathForMediaLibraryWithBlog:blog];
    [self.api GET:path
       parameters:nil // @{ @"number" : @9999 } must be <= 100; defaults to 20
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              //NSInteger mediaCount = [responseObject[@"found"] integerValue];
              NSArray *mediaItems = responseObject[@"media"];
              //NSDictionary *meta = responseObject[@"meta"];
              NSArray *media = [self mapMediaLibraryFromResponse:mediaItems];
              if (success) {
                  success(media);
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

- (NSString *)pathForMediaLibraryWithBlog:(Blog *)blog
{
    return [NSString stringWithFormat:@"sites/%@/media", blog.dotComID];
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
                                    @"gmt_offset"
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

- (NSArray *)mapMediaLibraryFromResponse:(id)response
{
    if ([response isKindOfClass:[NSArray class]] && [response count]) {
        NSMutableArray *mediaLibrary = [NSMutableArray array];
        
        for (NSDictionary *json in response) {
            NSMutableDictionary *medium = [NSMutableDictionary dictionary];
            
            // map to XMLRPC format expected by Media -updateFromDictionary
            medium[@"date_created_gmt"] = [NSDate dateWithWordPressComJSONString:json[@"date"]] ?: @"";
            NSDictionary *mappings = @{
                @"link" : @"URL",
                @"attachment_id" : @"ID",
                @"title" : @"title",
                @"caption" : @"caption",
                @"description" : @"description",
            };
            for (NSString *key in mappings) {
                medium[key] = json[mappings[key]] ?: @"";
            }
            NSMutableDictionary *metadata = [NSMutableDictionary dictionary];
            NSArray *keys = @[@"width", @"height", @"file"];
            for (NSString *key in keys) {
                metadata[key] = json[key] ?: @"";
            }
            medium[@"metadata"] = metadata;

            [mediaLibrary addObject:medium];
        }
        return [NSMutableArray arrayWithArray:mediaLibrary];
    } else {
        return @[];
    }
}

@end
