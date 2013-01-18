//
//  WPReaderTopicsViewController.h
//  WordPress
//
//  Created by Beau Collins on 1/19/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import "WPWebAppViewController.h"

@class WPReaderTopicsViewController;

@protocol WPReaderTopicsViewControllerDelegate <NSObject>

- (void)topicsController:(WPReaderTopicsViewController *)topicsController didDismissSelectingTopic:(NSString *)topic withTitle:(NSString *)title;

@end

@interface WPReaderTopicsViewController : WPWebAppViewController

@property (nonatomic, weak) id<WPReaderTopicsViewControllerDelegate> delegate;

- (void)loadTopicsPage;
- (void)selectTopic:(NSString *)topic :(NSString *) title;
- (void)setSelectedTopic:(NSString *)topicId;
- (void)openFriendFinder;
- (NSString *)selectedTopicTitle;
@end

