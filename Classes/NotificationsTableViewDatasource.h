//
//  NotificationsTableViewDatasource.h
//  WordPress
//
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WordPressComApi.h"
#import "EGORefreshTableHeaderView.h"

@protocol NotificationsTableViewDatasourceDelegate;

@interface NotificationsTableViewDatasource : NSObject <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) WordPressComApi *user;
@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet id <NotificationsTableViewDatasourceDelegate> delegate;
@property (readonly, getter = isRefreshing) BOOL refreshing;
@property (readonly, nonatomic, strong) NSDate *lastRefreshDate;

- (id)initWithUser:(WordPressApi *)user;
- (void)refreshNotifications;
@end

@protocol NotificationsTableViewDatasourceDelegate <NSObject>

- (void)notificationsWillRefresh:(NotificationsTableViewDatasource *)notifiationsDataSource;
- (void)notificationsDidFinishRefreshing:(NotificationsTableViewDatasource *)notifcationsDataSource withError:(NSError *)error;

@end
