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

@end
