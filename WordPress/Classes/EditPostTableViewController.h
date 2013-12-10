//
//  EditPostTableViewController.h
//  WordPress
//
//  Created by Eric on 12/5/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AbstractPost;

@interface EditPostTableViewController : UITableViewController

- (id)initWithPost:(AbstractPost *)post;
- (id)initWithDraftForLastUsedBlog;

@end
