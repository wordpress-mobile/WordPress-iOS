/*
 * CategoryServiceRemote.m
 *
 * Copyright (c) 2014 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import "CategoryServiceRemote.h"
#import "Blog.h"

@implementation CategoryServiceRemote

- (void)createCategoryWithName:(NSString *)name parentCategoryID:(NSNumber *)parentCategoryID forBlog:(Blog *)blog success:(void (^)(NSNumber *))success failure:(void (^)(NSError *))failure {
    NSDictionary *parameters = @{ @"name" : name ?: [NSNull null],
                                  @"parent_id" : parentCategoryID ?: @0};
    
    // TODO - Get the API for a Blog without needing the Blog object
    [blog.api callMethod:@"wp.newCategory"
              parameters:[blog getXMLRPCArgsWithExtra:parameters]
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

@end
