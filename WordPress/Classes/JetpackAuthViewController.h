//
//  JetpackAuthViewController.h
//  WordPress
//
//  Created by Jorge Bernal on 2/11/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Blog;

@interface JetpackAuthViewController : UITableViewController
- (id)initWithBlog:(Blog *)blog;
@end
