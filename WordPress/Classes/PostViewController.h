//
//  PostViewController.h
//  WordPress
//
//  Created by Eric Johnson on 2/25/14.
//  Copyright (c) 2014 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AbstractPost;

@interface PostViewController : UIViewController

/*
 Initialize the detail with the specified post.
 @param post The post to display.
 */
- (id)initWithPost:(AbstractPost *)post;

@end
