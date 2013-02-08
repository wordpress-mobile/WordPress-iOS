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
#import "WordPressComApi.h"
#import "NSString+XMLExtensions.h"

@interface NotificationSettingsViewController () <EGORefreshTableHeaderDelegate>

@property (nonatomic, strong) EGORefreshTableHeaderView *refreshHeaderView;
@property (readwrite, nonatomic, strong) NSDate *lastRefreshDate;
@property (readwrite, getter = isRefreshing) BOOL refreshing;

@end


@implementation NotificationSettingsViewController

BOOL hasChanges;
@synthesize showCloseButton;

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
    self.title = NSLocalizedString(@"Manage Notifications", @"");
    
    CGRect refreshFrame = self.tableView.bounds;
    refreshFrame.origin.y = -refreshFrame.size.height;
    self.refreshHeaderView = [[EGORefreshTableHeaderView alloc] initWithFrame:refreshFrame];
    self.refreshHeaderView.delegate = self;
    [self.tableView addSubview:self.refreshHeaderView];
    
    if(self.showCloseButton)
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", @"") style:UIBarButtonItemStyleBordered target:self action:@selector(dismiss)];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    hasChanges = NO;
    _notificationPreferences = [[[NSUserDefaults standardUserDefaults] objectForKey:@"notification_preferences"] mutableCopy];
    if (_notificationPreferences) {
        [self reloadNotificationSettings];
    } else {
        // Trigger a refresh to download the notification settings
        CGPoint offset = self.tableView.contentOffset;
        offset.y = - 65.0f;
        [self.tableView setContentOffset:offset];
        [self.refreshHeaderView egoRefreshScrollViewDidEndDragging:self.tableView];
    }
}

- (void)getNotificationSettings {
    [[WordPressComApi sharedApi] fetchNotificationSettings:^{
        [self notificationsDidFinishRefreshingWithError: nil];
    } failure:^(NSError *error) {
        [self notificationsDidFinishRefreshingWithError: error];
    }];
}

- (void)reloadNotificationSettings {
    _notificationPreferences = [[[NSUserDefaults standardUserDefaults] objectForKey:@"notification_preferences"] mutableCopy];
    if (_notificationPreferences) {
        _notificationPrefArray = [[_notificationPreferences allKeys] mutableCopy];
        if ([_notificationPrefArray indexOfObject:@"muted_blogs"] != NSNotFound) {
            [_notificationPrefArray removeObjectAtIndex:[_notificationPrefArray indexOfObject:@"muted_blogs"]];
            _mutedBlogsArray = [[[_notificationPreferences objectForKey:@"muted_blogs"] objectForKey:@"value"] mutableCopy];
        }
        [self.tableView reloadData];
    }
}

- (void)notificationSettingChanged:(id)sender {
    hasChanges = YES;
    UISwitch *cellSwitch = (UISwitch *)sender;
    
    NSMutableDictionary *updatedPreference = [[_notificationPreferences objectForKey:[_notificationPrefArray objectAtIndex:cellSwitch.tag]] mutableCopy];
    
    [updatedPreference setValue:[NSNumber numberWithBool:cellSwitch.on] forKey:@"value"];
    
    [_notificationPreferences setValue:updatedPreference forKey:[_notificationPrefArray objectAtIndex:cellSwitch.tag]];
    [[NSUserDefaults standardUserDefaults] setValue:_notificationPreferences forKey:@"notification_preferences"];
}

- (void)muteBlogSettingChanged:(id)sender {
    hasChanges = YES;
    UISwitch *cellSwitch = (UISwitch *)sender;
    
    NSMutableDictionary *updatedPreference = [[_mutedBlogsArray objectAtIndex:cellSwitch.tag] mutableCopy];
    [updatedPreference setValue:[NSNumber numberWithBool:!cellSwitch.on] forKey:@"value"];
    
    [_mutedBlogsArray setObject:updatedPreference atIndexedSubscript:cellSwitch.tag];
    
    NSMutableDictionary *mutedBlogsDictionary = [[_notificationPreferences objectForKey:@"muted_blogs"] mutableCopy];
    [mutedBlogsDictionary setValue:_mutedBlogsArray forKey:@"value"];
    
    [_notificationPreferences setValue:mutedBlogsDictionary forKey:@"muted_blogs"];
    [[NSUserDefaults standardUserDefaults] setValue:_notificationPreferences forKey:@"notification_preferences"];
}

- (void)dismiss {
    [self dismissModalViewControllerAnimated:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    if (hasChanges)
        [[WordPressComApi sharedApi] saveNotificationSettings:nil failure:^(NSError *error) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"")
                                                            message:error.localizedDescription
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"OK", @"OK button label.")
                                                  otherButtonTitles:nil, nil];
            [alert show];
        }];
    [super viewWillDisappear:animated];
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
    if (_notificationPrefArray && _mutedBlogsArray)
        return 2;
    else if (_notificationPrefArray)
        return 1;
    else
        return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (section == 0)
        return [_notificationPrefArray count];
    else if (section == 1)
        return [_mutedBlogsArray count];
    else
        return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"NotficationSettingsCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
        UISwitch *cellSwitch = [[UISwitch alloc] initWithFrame:CGRectZero]; // Frame is ignored.
        cell.accessoryView = cellSwitch;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    UISwitch *cellSwitch = (UISwitch *)cell.accessoryView;
    cellSwitch.tag = indexPath.row;
    [cellSwitch removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
    
    if (indexPath.section == 0) {
        [cellSwitch addTarget:self action:@selector(notificationSettingChanged:) forControlEvents:UIControlEventValueChanged];
        NSDictionary *notificationPreference = [_notificationPreferences objectForKey:[_notificationPrefArray objectAtIndex:indexPath.row]];
        
        cell.textLabel.text = [[notificationPreference objectForKey:@"desc"] stringByDecodingXMLCharacters];
        cellSwitch.on = [[notificationPreference objectForKey:@"value"] boolValue];
    } else {
        [cellSwitch addTarget:self action:@selector(muteBlogSettingChanged:) forControlEvents:UIControlEventValueChanged];
        NSDictionary *muteBlogSetting = [_mutedBlogsArray objectAtIndex:indexPath.row];
        NSString *blogName = [muteBlogSetting objectForKey:@"blog_name"];
        if ([blogName length] == 0)
            blogName = [muteBlogSetting objectForKey:@"url"];
        cell.textLabel.text = [blogName stringByDecodingXMLCharacters];
        cellSwitch.on = ![[muteBlogSetting objectForKey:@"value"] boolValue];
    }
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0)
       return NSLocalizedString(@"Push Notifications", @"");
    else
        return NSLocalizedString(@"Blogs", @"");
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
}

#pragma mark - Pull to Refresh delegate

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
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"")
                                                        message:error.localizedDescription
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"OK", @"OK button label.")
                                              otherButtonTitles:nil, nil];
        [alert show];
    }
}

@end
