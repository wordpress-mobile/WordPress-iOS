//
//  EditPostTableViewController.h
//  WordPress
//
//  Created by ? on ?
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AbstractPost;

@interface EditPostViewController : UITableViewController

- (id)initWithPost:(AbstractPost *)post;
- (id)initWithDraftForLastUsedBlog;

@end
