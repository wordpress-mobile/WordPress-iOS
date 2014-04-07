/*
 * CategoryServiceRemote.m
 *
 * Copyright (c) 2014 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import "CategoryServiceLegacyRemote.h"
#import "Blog.h"

@implementation CategoryServiceLegacyRemote {
    WPXMLRPCClient *_xmlrpcClient;
    NSString *_username;
    NSString *_password;
}

- (id)initWithApi:(id)api username:(NSString *)username password:(NSString *)password {
    self = [super init];
    if (self) {
        _xmlrpcClient = api;
        _username = username;
        _password = password;
    }
    return self;
}

#pragma mark - CategoryServiceRemoteAPI

- (void)createCategoryWithName:(NSString *)name parentCategoryID:(NSNumber *)parentCategoryID siteID:(NSNumber *)siteID success:(void (^)(NSNumber *))success failure:(void (^)(NSError *))failure {
    NSArray *parameters = @[
                            siteID,
                            _username,
                            _password,
                            @{
                                @"name" : name ?: [NSNull null],
                                @"parent_id" : parentCategoryID ?: @0
                                },
                            ];

    [_xmlrpcClient callMethod:@"wp.newCategory"
                   parameters:parameters
                      success:^(AFHTTPRequestOperation *operation, id responseObject) {
                          NSNumber *categoryID = @([responseObject integerValue]);
                          int newID = [categoryID intValue];
                          if (newID > 0) {

                              if (success) {
                                  success(categoryID);
                              }
                          }
                      } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                          if (failure) {
                              failure(error);
                          }
                      }];
}

- (void)getCategoriesForSiteWithID:(NSNumber *)siteID success:(void (^)(NSArray *))success failure:(void (^)(NSError *))failure {
    NSArray *parameters = @[
                            siteID,
                            _username,
                            _password,
                            ];
    [_xmlrpcClient callMethod:@"wp.getCategories"
                   parameters:parameters
                      success:^(AFHTTPRequestOperation *operation, id responseObject) {
                          if (success) {
                              /*
                               Category response format:
                               {
                                   categoryId
                                   parentId
                                   description
                                   categoryDescription
                                   categoryName
                                   htmlUrl
                                   rssUrl
                               }
                               */
                              NSArray *receivedCategories = (NSArray *)responseObject;
                              if (![receivedCategories isKindOfClass:[NSArray class]]) {
                                  DDLogError(@"wp.getCategories returned an unexpected object type: %@", responseObject);
                                  receivedCategories = @[];
                              }
                              NSMutableArray *categories = [NSMutableArray arrayWithCapacity:[receivedCategories count]];
                              for (NSDictionary *receivedCategory in receivedCategories) {
                                  if (![receivedCategory isKindOfClass:[NSDictionary class]]) {
                                      DDLogError(@"wp.getCategories included an unexpected category type: %@", receivedCategory);
                                      continue;
                                  }
                                  NSDictionary *category = @{
                                                             CategoryServiceRemoteKeyID: [receivedCategory numberForKey:@"categoryId"],
                                                             CategoryServiceRemoteKeyName: [receivedCategory stringForKey:@"categoryName"],
                                                             CategoryServiceRemoteKeyParent: [receivedCategory numberForKey:@"parentId"],
                                                             };
                                  [categories addObject:category];
                              }
                              success([categories copy]);
                          }
                      } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                          if (failure) {
                              failure(error);
                          }
                      }];
}

@end
