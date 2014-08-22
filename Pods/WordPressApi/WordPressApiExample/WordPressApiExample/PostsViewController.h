//
//  PostsViewController.h
//  WordPressApiExample
//
//  Created by Jorge Bernal on 12/20/11.
//  Copyright (c) 2011 Automattic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WordPressBaseApi.h"

@interface PostsViewController : UITableViewController
@property (readonly, nonatomic, retain) id<WordPressBaseApi> api;

- (IBAction)refreshPosts:(id)sender;
- (void)publishPostWithTitle:(NSString *)title content:(NSString *)content image:(UIImage *)image;
@end
