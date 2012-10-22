//
//  Category.h
//  WordPress
//
//  Created by Jorge Bernal on 10/29/10.
//  Copyright 2010 WordPress. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "Blog.h"
#import "WordPressAppDelegate.h"

@interface Category : NSManagedObject {

}
@property (nonatomic, strong) NSNumber *categoryID;
@property (nonatomic, strong) NSString *categoryName;
@property (nonatomic, strong) NSNumber *parentID;
@property (nonatomic, strong) NSMutableSet *posts;
@property (nonatomic, strong) Blog *blog;

+ (BOOL)existsName:(NSString *)name forBlog:(Blog *)blog withParentId:(NSNumber *)parentId;
+ (Category *)findWithBlog:(Blog *)blog andCategoryID:(NSNumber *)categoryID;
// Takes the NSDictionary from a XMLRPC call and creates or updates a post
+ (Category *)createOrReplaceFromDictionary:(NSDictionary *)categoryInfo forBlog:(Blog *)blog;
+ (void)createCategory:(NSString *)name parent:(Category *)parent forBlog:(Blog *)blog success:(void (^)(Category *category))success failure:(void (^)(NSError *error))failure;

@end
