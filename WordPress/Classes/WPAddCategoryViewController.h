//
//  WPAddCategoryViewController.h
//  WordPress
//
//  Created by ? on ?
//  Copyright (c) 2014 WordPress. All rights reserved.
//
#import <UIKit/UIKit.h>

extern NSString *const NewCategoryCreatedAndUpdatedInBlogNotification;

@class Blog;

@interface WPAddCategoryViewController : UITableViewController

- (id)initWithBlog:(Blog *)blog;

@end
