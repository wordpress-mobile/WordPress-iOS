//
//  ReaderUsersBlogsViewController.h
//  WordPress
//
//  Created by Eric J on 6/6/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Blog;

@protocol ReaderUsersBlogsDelegate <NSObject>
- (void)userDidSelectBlog:(Blog *)blog;
@end

@interface ReaderUsersBlogsViewController : UIViewController
@property (nonatomic, weak) id<ReaderUsersBlogsDelegate>delegate;
@end