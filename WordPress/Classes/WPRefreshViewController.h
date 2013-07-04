//
//  WPRefreshViewController.h
//  WordPress
//
//  Created by Eric J on 4/19/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WPRefreshViewController : UIViewController<UITableViewDataSource, UITableViewDelegate> {
	BOOL didPromptForCredentials;
	BOOL _isSyncing;
}

@property (nonatomic) BOOL infiniteScrollEnabled;
@property (nonatomic, strong) UITableView *tableView;

- (BOOL)isSyncing;
- (BOOL)hasMoreContent;
- (void)syncWithUserInteraction:(BOOL)userInteraction;
- (void)loadMoreWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure;
- (void)handleKeyboardDidShow:(NSNotification *)notification;
- (void)handleKeyboardWillHide:(NSNotification *)notification;

@end
