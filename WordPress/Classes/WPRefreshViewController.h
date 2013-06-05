//
//  WPRefreshViewController.h
//  WordPress
//
//  Created by Eric J on 4/19/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EGORefreshTableHeaderView.h"

@interface WPRefreshViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, EGORefreshTableHeaderDelegate> {
	EGORefreshTableHeaderView *_refreshHeaderView;
	BOOL didPlayPullSound;
    BOOL didTriggerRefresh;
	BOOL didPromptForCredentials;
	BOOL _isSyncing;
}

@property (nonatomic, strong) UITableView *tableView;

- (void)doBeforeDealloc;
- (void)simulatePullToRefresh;
- (void)hideRefreshHeader;
- (BOOL)isSyncing;
- (void)syncWithUserInteraction:(BOOL)userInteraction;

@end
