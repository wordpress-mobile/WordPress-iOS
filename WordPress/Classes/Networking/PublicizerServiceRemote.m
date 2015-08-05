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
                  NSString *rawJSON = operation.responseString;
                  NSArray *publicizers = [self remotePublicizersWithJSONDictionary:responseObject[@"services"] fromRawJSON:rawJSON];
                  success(publicizers);
              }
          } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              if (failure) {
                  failure(error);
              }
          }];
}

- (NSArray *)remotePublicizersWithJSONDictionary:(NSDictionary *)jsonDictionary fromRawJSON:(NSString *)rawJSON
{
    NSMutableArray *publicizers = [NSMutableArray arrayWithCapacity:jsonDictionary.count];
    for (NSString *key in jsonDictionary) {
        // Presentation order is the JSON dictionary key order
        NSInteger location = [rawJSON rangeOfString:key].location;
        [publicizers addObject:[self remotePublicizer:key withJSONDictionary:jsonDictionary[key] andLocation:location]];
    }
    NSArray *sortedArray = [publicizers sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"location" ascending:TRUE]]];
    return sortedArray;
}

- (RemotePublicizer *)remotePublicizer:(NSString *)service
                    withJSONDictionary:(NSDictionary *)jsonPublicizer
                        andLocation:(NSInteger)location
{
    RemotePublicizer *publicizer = [RemotePublicizer new];
    publicizer.service = service;
    publicizer.label = jsonPublicizer[@"label"];
    publicizer.detail = jsonPublicizer[@"description"];
    publicizer.icon = jsonPublicizer[@"icon"];
    publicizer.connect = jsonPublicizer[@"connect"];
    publicizer.location = @(location);
    return publicizer;
}

@end
