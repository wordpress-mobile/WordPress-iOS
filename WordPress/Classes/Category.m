//
//  Category.m
//  WordPress
//
//  Created by Jorge Bernal on 10/29/10.
//  Copyright 2010 WordPress. All rights reserved.
//

#import "Category.h"
#import "ContextManager.h"

@interface Category(PrivateMethods)
+ (Category *)newCategoryForBlog:(Blog *)blog;
@end

@implementation Category
@dynamic categoryID, categoryName, parentID, posts;
@dynamic blog;


@end
