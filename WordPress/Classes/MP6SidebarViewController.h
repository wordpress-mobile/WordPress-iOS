//
//  MP6SidebarViewController.h
//  WordPress
//
//  Created by Sendhil Panchadsaram on 8/12/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Post;
@interface MP6SidebarViewController : UIViewController

- (void)showCommentWithId:(NSNumber *)itemId blogId:(NSNumber *)blogId;
- (void)uploadQuickPhoto:(Post *)post;

@end
