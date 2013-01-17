//
//  NotificationsTableViewDatasource.m
//  WordPress
//
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import "NotificationsTableViewDatasource.h"
#import "NotificationsTableViewCell.h"
#import "Note.h"

@interface NotificationsTableViewDatasource ()
@property (nonatomic, strong) NSMutableArray *notes;
@property (readwrite, nonatomic, strong) NSDate *lastRefreshDate;
@property (readwrite, getter = isRefreshing) BOOL refreshing;
@end

@implementation NotificationsTableViewDatasource

- (id)initWithUser:(WordPressComApi *)user {
    if (self = [super init]) {
        self.user = user;
        // a page of notes is 9 by default
        self.notes = [[NSMutableArray alloc] initWithCapacity:9];
    }
    return self;
}

/*
 * Ask the user to check for new notifications
 * TODO: handle failure
 */
- (void)refreshNotifications {
    if (self.isRefreshing) {
        return;
    }
    [self.delegate notificationsWillRefresh:self];
    self.refreshing = YES;
    [self.user checkNotificationsSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        self.lastRefreshDate = [NSDate new];
        self.refreshing = NO;
        [self.delegate notificationsDidFinishRefreshing:self withError:nil];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        self.refreshing = NO;
        [self.delegate notificationsDidFinishRefreshing:self withError:error];
    }];
}

/*
 * For loading of additional notifications
 */
- (void)loadNotificationsAfterNote:(id)note {
    [self.user getNotificationsBefore:[note objectForKey:@"timestamp"] success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
    }];
}

- (void)setTableView:(UITableView *)tableView {
    if (tableView != _tableView) {
        _tableView.dataSource = nil;
        _tableView.delegate = nil;
        tableView.dataSource = self;
        tableView.delegate = self;
        _tableView = tableView;
//        [[self class] registerTableViewCells:tableView];
    }
}

//+ (void)registerTableViewCells:(UITableView *)tableView {
//    [tableView registerClass:[NotificationsTableViewCell class] forCellReuseIdentifier:NotificationsTableViewNoteCellIdentifier];
//}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.notes count];
}
//
//-  (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
//    NotificationsTableViewCell *cell = (NotificationsTableViewCell *)[tableView dequeueReusableCellWithIdentifier:NotificationsTableViewNoteCellIdentifier];
//    cell.note = [self.notes objectAtIndex:indexPath.row];
//    return cell;
//}
//
#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return 63.f;
    
}
 



@end
