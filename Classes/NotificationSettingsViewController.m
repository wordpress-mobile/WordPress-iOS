//
//  NotificationSettingsViewController.m
//  WordPress
//
//  Created by Dan Roundhill on 12/10/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import "NotificationSettingsViewController.h"
#import "SFHFKeychainUtils.h"
#import "AFXMLRPCClient.h"
#import "EGORefreshTableHeaderView.h"
#import "WordPressAppDelegate.h"

@interface NotificationSettingsViewController () <EGORefreshTableHeaderDelegate>

@property (nonatomic, strong) EGORefreshTableHeaderView *refreshHeaderView;
@property (readwrite, nonatomic, strong) NSDate *lastRefreshDate;
@property (readwrite, getter = isRefreshing) BOOL refreshing;

@end

@implementation NotificationSettingsViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.backgroundView = nil;
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"settings_bg"]];
    self.title = NSLocalizedString(@"Notifications", @"");
    
    CGRect refreshFrame = self.tableView.bounds;
    refreshFrame.origin.y = -refreshFrame.size.height;
    self.refreshHeaderView = [[EGORefreshTableHeaderView alloc] initWithFrame:refreshFrame];
    self.refreshHeaderView.delegate = self;
    
    [self.tableView addSubview:self.refreshHeaderView];
    
    _notificationPreferences = [[[NSUserDefaults standardUserDefaults] objectForKey:@"notification_preferences"] mutableCopy];
    if (_notificationPreferences) {
        _notificationPrefArray = [_notificationPreferences allKeys];
    } else {
        // Trigger a refresh to download the notification settings
        CGPoint offset = self.tableView.contentOffset;
        offset.y = - 65.0f;
        [self.tableView setContentOffset:offset];
        [self.refreshHeaderView egoRefreshScrollViewDidEndDragging:self.tableView];
    }
}

- (void)getNotificationSettings {
    NSString *token = [[NSUserDefaults standardUserDefaults] objectForKey:@"apnsDeviceToken"];
    
    NSString *authURL = kNotificationAuthURL;
    NSError *error = nil;
	if([[NSUserDefaults standardUserDefaults] objectForKey:@"wpcom_username_preference"] == nil) return;
    NSString *username = [[NSUserDefaults standardUserDefaults] objectForKey:@"wpcom_username_preference"];
    NSString *password = [SFHFKeychainUtils getPasswordForUsername:username
                                                    andServiceName:@"WordPress.com"
                                                             error:&error];

    AFXMLRPCClient *api = [[AFXMLRPCClient alloc] initWithXMLRPCEndpoint:[NSURL URLWithString:authURL]];
    //Update supported notifications dictionary
    [api callMethod:@"wpcom.get_mobile_push_notification_settings"
         parameters:[NSArray arrayWithObjects:username, password, token, nil]
            success:^(AFHTTPRequestOperation *operation, id responseObject) {
                NSDictionary *supportedNotifications = (NSDictionary *)responseObject;
                [[NSUserDefaults standardUserDefaults] setObject:supportedNotifications forKey:@"notification_preferences"];
                [self notificationsDidFinishRefreshingWithError:nil];
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                [self notificationsDidFinishRefreshingWithError:error];
    }];
    
}

- (void)setNotificationSettings {
    NSString *token = [[NSUserDefaults standardUserDefaults] objectForKey:@"apnsDeviceToken"];
    // Build the dictionary to send in the API call
    NSMutableDictionary *updatedSettings = [[NSMutableDictionary alloc] init];
    for (int i = 0; i < [_notificationPrefArray count]; i++) {
        NSDictionary *updatedSetting = [_notificationPreferences objectForKey:[_notificationPrefArray objectAtIndex:i]];
        [updatedSettings setValue:[updatedSetting objectForKey:@"value"] forKey:[_notificationPrefArray objectAtIndex:i]];
    }
    
    if ([updatedSettings count] == 0)
        return;
    
    NSString *authURL = kNotificationAuthURL;
    NSError *error = nil;
	if([[NSUserDefaults standardUserDefaults] objectForKey:@"wpcom_username_preference"] == nil) return;
    NSString *username = [[NSUserDefaults standardUserDefaults] objectForKey:@"wpcom_username_preference"];
    NSString *password = [SFHFKeychainUtils getPasswordForUsername:username
                                                    andServiceName:@"WordPress.com"
                                                             error:&error];
    
    AFXMLRPCClient *api = [[AFXMLRPCClient alloc] initWithXMLRPCEndpoint:[NSURL URLWithString:authURL]];
    //Update supported notifications dictionary
    [api callMethod:@"wpcom.set_mobile_push_notification_settings"
         parameters:[NSArray arrayWithObjects:username, password, updatedSettings, token, nil]
            success:^(AFHTTPRequestOperation *operation, id responseObject) {
                // Hooray!
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Connection Error", @" Connection error title for alert prompt")
                                                                message:NSLocalizedString(@"Notification settings could not be saved due to a network error. Please try again later.", @"Network save error on notification settings view.")
                                                               delegate:nil
                                                      cancelButtonTitle:NSLocalizedString(@"OK", @"OK button label.")
                                                      otherButtonTitles:nil, nil];
                [alert show];
            }];
}

- (void)reloadNotificationSettings {
    _notificationPreferences = [[[NSUserDefaults standardUserDefaults] objectForKey:@"notification_preferences"] mutableCopy];
    if (_notificationPreferences) {
        _notificationPrefArray = [_notificationPreferences allKeys];
        [self.tableView reloadData];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    if (_notificationPrefArray)
        return 1;
    else
        return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [_notificationPrefArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"NotficationSettingsCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
        UISwitch *cellSwitch = [[UISwitch alloc] initWithFrame:CGRectZero]; // Frame is ignored.
        [cellSwitch addTarget:self action:@selector(notificationSettingChanged:) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = cellSwitch;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    UISwitch *cellSwitch = (UISwitch *)cell.accessoryView;
    cellSwitch.tag = indexPath.row;
   
    NSDictionary *notificationPreference = [_notificationPreferences objectForKey:[_notificationPrefArray objectAtIndex:indexPath.row]];
    
    cell.textLabel.text =  [notificationPreference objectForKey:@"desc"];
    cellSwitch.on = [[notificationPreference objectForKey:@"value"] boolValue];
    return cell;
}

- (void)notificationSettingChanged:(id)sender {
    UISwitch *cellSwitch = (UISwitch *)sender;
    
    NSMutableDictionary *updatedPreference = [[_notificationPreferences objectForKey:[_notificationPrefArray objectAtIndex:cellSwitch.tag]] mutableCopy];
    
    [updatedPreference setValue:[NSNumber numberWithBool:cellSwitch.on] forKey:@"value"];
        
    [_notificationPreferences setValue:updatedPreference forKey:[_notificationPrefArray objectAtIndex:cellSwitch.tag]];
    [[NSUserDefaults standardUserDefaults] setValue:_notificationPreferences forKey:@"notification_preferences"];
    
     [self setNotificationSettings];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return NSLocalizedString(@"Send notifications for:", @"");
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
}

#pragma mark - UIScrollViewDelegate

- (BOOL)egoRefreshTableHeaderDataSourceIsLoading:(EGORefreshTableHeaderView *)view {
    return self.isRefreshing;
}

- (NSDate *)egoRefreshTableHeaderDataSourceLastUpdated:(EGORefreshTableHeaderView *)view {
    return self.lastRefreshDate;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    [self.refreshHeaderView egoRefreshScrollViewDidScroll:scrollView];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    [self.refreshHeaderView egoRefreshScrollViewDidEndDragging:scrollView];
}

- (void)egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView *)view {
    [self getNotificationSettings];
}

- (void)notificationsDidFinishRefreshingWithError:(NSError *)error {
    [self.refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:self.tableView];
    if (!error) {
        [self reloadNotificationSettings];
    }
    else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Connection Error", @" Connection error title for alert prompt")
                                                        message:NSLocalizedString(@"Notification settings could not be loaded due to a network error. Please try again.", @"Network error on notification settings view.")
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"OK", @"OK button label.")
                                              otherButtonTitles:nil, nil];
        [alert show];
    }
}

@end
