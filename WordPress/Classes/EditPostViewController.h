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

/**
 The value of the @"opened_by" property attached to the "Editor Opened"
 stats event. This will let us see how many users are actually using the
 new post button on the tab bar.
 */
@property (nonatomic, strong) NSString *editorOpenedBy;

@end
