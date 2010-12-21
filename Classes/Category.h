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
@property (nonatomic, retain) NSString *categoryId;
@property (nonatomic, retain) NSString *categoryName;
@property (nonatomic, retain) NSString *desc;
@property (nonatomic, retain) NSString *htmlUrl;
@property (nonatomic, retain) NSString *parentId;
@property (nonatomic, retain) NSString *rssUrl;
@property (nonatomic, retain) NSArray *posts;
@property (nonatomic, retain) NSString *blogId;

+ (BOOL)existsName:(NSString *)name forBlogId:(NSString *)blogId withParentId:(NSString *)parentId;
@end
