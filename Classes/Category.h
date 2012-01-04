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
@property (nonatomic, retain) NSNumber *categoryID;
@property (nonatomic, retain) NSString *categoryName;
@property (nonatomic, retain) NSNumber *parentID;
@property (nonatomic, retain) NSMutableSet *posts;
@property (nonatomic, retain) Blog *blog;

+ (BOOL)existsName:(NSString *)name forBlog:(Blog *)blog withParentId:(NSNumber *)parentId;
+ (Category *)findWithBlog:(Blog *)blog andCategoryID:(NSNumber *)categoryID;
// Takes the NSDictionary from a XMLRPC call and creates or updates a post
+ (Category *)createOrReplaceFromDictionary:(NSDictionary *)categoryInfo forBlog:(Blog *)blog;
+ (void)createCategory:(NSString *)name parent:(Category *)parent forBlog:(Blog *)blog success:(void (^)(Category *category))success failure:(void (^)(NSError *error))failure;

@end
