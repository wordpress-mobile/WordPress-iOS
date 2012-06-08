//
//  WPTableViewController.h
//  WordPress
//
//  Created by Brad Angelcyk on 5/22/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Blog.h"

@interface WPTableViewController : UITableViewController
@property (nonatomic,retain) Blog *blog;
- (id)initWithBlog:(Blog *)blog;
@end
