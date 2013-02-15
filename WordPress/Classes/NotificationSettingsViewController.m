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
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:NO];
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
        [[WordPressComApi sharedApi] saveNotificationSettings:nil failure:nil];
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
        return 3;
    else if (_notificationPrefArray)
        return 2;
    else
        return 0;
} 

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (section == 0)
        return 2;
    else if (section == 1)
        return [_notificationPrefArray count];
    else if (section == 2)
        return [_mutedBlogsArray count];
    else
        return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if (indexPath.section == 0) {
        static NSString *CellIdentifier = @"NotficationSettingsCellOnOff";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        bool enableAllNotificationsButtonEnabled = NO;
        bool disableAllNotificationsButtonEnabled = NO;
        
        //Read the PNs settings and enable or disable the ON/OFF buttons
        if (_notificationPreferences) {
            NSMutableArray *keysArray = [[_notificationPreferences allKeys] mutableCopy];
            if ([[_notificationPreferences allKeys] indexOfObject:@"muted_blogs"] != NSNotFound) {
                NSDictionary *mutedBlogsDictionary = [_notificationPreferences objectForKey:@"muted_blogs"];
                NSArray *mutedBlogsArray = [mutedBlogsDictionary objectForKey:@"value"];
                int i=0;
                for ( ; i < [mutedBlogsArray count]; i++) {
                    NSDictionary *currentPreference = [mutedBlogsArray objectAtIndex:i];
                    NSNumber *muted = [currentPreference valueForKey:@"value"];
                    if([muted boolValue] == YES)
                        enableAllNotificationsButtonEnabled = YES;
                    else
                        disableAllNotificationsButtonEnabled = YES;
                }
                [keysArray removeObject:@"muted_blogs"];
            }
            
            for(id key in keysArray) {
                NSDictionary *currentPreference = [_notificationPreferences objectForKey:key];
                NSNumber *enabled = [currentPreference valueForKey:@"value"];
                if([enabled boolValue] == YES)
                    disableAllNotificationsButtonEnabled = YES;
                else
                    enableAllNotificationsButtonEnabled = YES;
            }
        }
        
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
            
        }
        
        if(indexPath.row == 0) {
            cell.textLabel.text = NSLocalizedString(@"Enable all notifications", @"");
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            cell.userInteractionEnabled = YES;
            cell.textLabel.textColor = [UIColor blackColor];
            if(enableAllNotificationsButtonEnabled == NO){
                cell.userInteractionEnabled = NO;
                cell.selectionStyle = UITableViewCellSelectionStyleGray;
                cell.textLabel.textColor = [UIColor grayColor];
            }
        }
        else {
             cell.textLabel.text = NSLocalizedString(@"Disable all notifications", @"");
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            cell.userInteractionEnabled = YES;
            cell.textLabel.textColor = [UIColor blackColor];
            if(disableAllNotificationsButtonEnabled == NO){
                cell.userInteractionEnabled = NO;
                cell.selectionStyle = UITableViewCellSelectionStyleGray;
                cell.textLabel.textColor = [UIColor grayColor];
            }
        }
        
        return cell;
    }
    
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
    
    if (indexPath.section == 1) {
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
        return @"";
    else if (section == 1)
       return NSLocalizedString(@"Push Notifications", @"");
    else
        return NSLocalizedString(@"Blogs", @"");
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.section == 0){
        bool muted = YES;
        if(indexPath.row== 0){
            //all notifications ON
            muted = NO;
        }
        
        if (_notificationPreferences) {
            _notificationPrefArray = [[_notificationPreferences allKeys] mutableCopy];
            if ([_notificationPrefArray indexOfObject:@"muted_blogs"] != NSNotFound) {
                NSMutableDictionary *mutedBlogsDictionary = [[_notificationPreferences objectForKey:@"muted_blogs"] mutableCopy];
                NSMutableArray *mutedBlogsArray = [[mutedBlogsDictionary objectForKey:@"value"] mutableCopy];
                int i=0;
                for ( ; i < [mutedBlogsArray count]; i++) {
                    NSMutableDictionary *updatedPreference = [[mutedBlogsArray objectAtIndex:i] mutableCopy];
                    [updatedPreference setValue:[NSNumber numberWithBool:muted] forKey:@"value"];
                    [mutedBlogsArray setObject:updatedPreference atIndexedSubscript:i];
                }
                [mutedBlogsDictionary setValue:mutedBlogsArray forKey:@"value"];
                [_notificationPreferences setValue:mutedBlogsDictionary forKey:@"muted_blogs"];
                [_notificationPrefArray removeObject:@"muted_blogs"];
            }
            
            for(id key in _notificationPrefArray) {
                NSMutableDictionary *updatedPreference = [[_notificationPreferences objectForKey:key] mutableCopy];
                [updatedPreference setValue:[NSNumber numberWithBool:!muted] forKey:@"value"];
                [_notificationPreferences setValue:updatedPreference forKey:key];
            }
            
            [[NSUserDefaults standardUserDefaults] setValue:_notificationPreferences forKey:@"notification_preferences"];
            hasChanges = true;
            [self reloadNotificationSettings];
        }
    }
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
