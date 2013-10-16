//
//  ReaderUsersBlogsViewController.h
//  WordPress
//
//  Created by Eric J on 6/6/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ReaderUsersBlogsDelegate;

@interface ReaderUsersBlogsViewController : UIViewController

@property (nonatomic, weak) id<ReaderUsersBlogsDelegate>delegate;

+ (id)presentAsModalWithDelegate:(id<ReaderUsersBlogsDelegate>)delegate;

@end

@protocol ReaderUsersBlogsDelegate <NSObject>

- (void)userDidSelectBlog:(NSDictionary *)blog;

@end
