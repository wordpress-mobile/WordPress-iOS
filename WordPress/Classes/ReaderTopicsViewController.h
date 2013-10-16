//
//  ReaderTopicsViewController.h
//  WordPress
//
//  Created by Eric J on 3/21/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ReaderTopicsDelegate <NSObject>

- (void)readerTopicChanged;

@end

@interface ReaderTopicsViewController : UITableViewController

@property (nonatomic, strong) id<ReaderTopicsDelegate>delegate;

@end
