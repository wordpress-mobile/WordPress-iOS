//
//  ReaderPostsViewController.h
//  WordPress
//
//  Created by Eric J on 3/21/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WPTableViewController.h"
#import "ReaderPostView.h"

extern NSString * const ReaderTopicDidChangeNotification;

@interface ReaderPostsViewController : WPTableViewController<WPContentViewDelegate>

@end
