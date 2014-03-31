/*
 * CategoryServiceRemote.h
 *
 * Copyright (c) 2014 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import <Foundation/Foundation.h>

@class Blog;

@interface CategoryServiceRemote : NSObject

- (void)createCategoryWithName:(NSString *)name
              parentCategoryID:(NSNumber *)parentCategoryID
                       forBlog:(Blog *)blog
                       success:(void (^)(NSNumber *categoryID))success
                       failure:(void (^)(NSError *error))failure;
@end
