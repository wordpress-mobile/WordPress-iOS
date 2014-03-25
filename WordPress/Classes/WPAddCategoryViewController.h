//
//  WPAddCategoryViewController.h
//  WordPress
//
//  Created by ganeshr on 07/24/08
//  Copyright (c) 2014 WordPress. All rights reserved.
//
#import <UIKit/UIKit.h>

@class Post;

@interface WPAddCategoryViewController : UITableViewController

- (id)initWithPost:(Post *)post;

@end
