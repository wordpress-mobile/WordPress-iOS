#import "PublicizerServiceRemote.h"
#import "WordPressComApi.h"
#import "RemotePublicizer.h"

@implementation PublicizerServiceRemote

- (void)getPublicizersWithSuccess:(void (^)(NSArray *publicizers))success
                          failure:(void (^)(NSError *error))failure
{
    static NSString* const path = @"meta/publicize/";
    [self.api GET:path
       parameters:nil
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              if (success) {
                  success([self remotePublicizersWithJSONDictionary:responseObject[@"services"]]);
              }
          } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              if (failure) {
                  failure(error);
              }
          }];
}

- (NSArray *)remotePublicizersWithJSONDictionary:(NSDictionary *)jsonDictionary
{
    NSMutableArray *publicizers = [NSMutableArray arrayWithCapacity:jsonDictionary.count];
    for (NSString *key in jsonDictionary) {
        [publicizers addObject:[self remotePublicizer:key withJSONDictionary:jsonDictionary[key]]];
    }
    return [NSArray arrayWithArray:publicizers];
}

- (RemotePublicizer *)remotePublicizer:(NSString *)service withJSONDictionary:(NSDictionary *)jsonPublicizer
{
    RemotePublicizer *publicizer = [RemotePublicizer new];
    publicizer.service = service;
    publicizer.label = jsonPublicizer[@"label"];
    publicizer.detail = jsonPublicizer[@"description"];
    publicizer.icon = jsonPublicizer[@"icon"];
    publicizer.connect = jsonPublicizer[@"connect"];
    return publicizer;
}

@end
