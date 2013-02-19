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
#import "DateUtils.h"

@interface NotificationSettingsViewController () <EGORefreshTableHeaderDelegate, UIActionSheetDelegate>

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
        if ([_notificationPrefArray indexOfObject:@"mute_until"] != NSNotFound) {
            [_notificationPrefArray removeObjectAtIndex:[_notificationPrefArray indexOfObject:@"mute_until"]];
            _notificationMutePreferences = [[_notificationPreferences objectForKey:@"mute_until"] mutableCopy];
        } else {
            _notificationMutePreferences = [NSMutableDictionary dictionary];
        }
        [self.tableView reloadData];
    }
    [self setupToolbarButtons];
}

- (void)setupToolbarButtons{
    
    return; //Do not show the toolbar with 'mute blogs' option for now
    
    bool toolbarVisible = NO;
    bool muteAvailable = NO;
    
    //show the mute/unmute button only when there are 10+ blogs
    if (_notificationPrefArray && _mutedBlogsArray && [_mutedBlogsArray count] > 10){
        
        if ([[_notificationPreferences allKeys] indexOfObject:@"muted_blogs"] != NSNotFound) {
            toolbarVisible = YES;
            NSDictionary *mutedBlogsDictionary = [_notificationPreferences objectForKey:@"muted_blogs"];
            NSArray *mutedBlogsArray = [mutedBlogsDictionary objectForKey:@"value"];
            int i=0;
            for ( ; i < [mutedBlogsArray count]; i++) {
                NSDictionary *currentPreference = [mutedBlogsArray objectAtIndex:i];
                NSNumber *muted = [currentPreference valueForKey:@"value"];
                if([muted boolValue] == NO){
                    muteAvailable = YES; //One blog is not muted
                    break;
                }
            }
        }
    }
    
    if( toolbarVisible == YES ) {
        
        NSString *buttonLabel = muteAvailable ? NSLocalizedString(@"Mute all blogs", @"") : NSLocalizedString(@"Unmute all blogs", @"");
        self.muteUnmuteBarButton = [[UIBarButtonItem alloc] initWithTitle:buttonLabel
                                                                    style:UIBarButtonItemStyleBordered
                                                                   target:self
                                                                   action:@selector(muteUnmutedButtonClicked:)];
        self.muteUnmuteBarButton.tag = muteAvailable;
        
        self.toolbarItems = @[self.muteUnmuteBarButton];
    }
    
    self.navigationController.toolbarHidden = ! toolbarVisible;
}

- (void)muteUnmutedButtonClicked:(id)sender{
    
    bool muted = self.muteUnmuteBarButton.tag;
    
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
        }
        
        [[NSUserDefaults standardUserDefaults] setValue:_notificationPreferences forKey:@"notification_preferences"];
        hasChanges = true;
        [self reloadNotificationSettings];
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
    [self setupToolbarButtons];
}

- (void)dismiss {
    [self dismissModalViewControllerAnimated:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    self.navigationController.toolbarHidden = YES;
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
        return 1;
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
        
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
        }
        
        cell.textLabel.text = NSLocalizedString(@"Notifications", @"");
     
        WPFLog(@"muteDictionary: %@", _notificationMutePreferences);
        
        if (_notificationMutePreferences && [_notificationMutePreferences objectForKey:@"value"] != nil) {
            NSString *mute_value = [_notificationMutePreferences objectForKey:@"value"];
            if([mute_value isEqualToString:@"forever"]){
                cell.detailTextLabel.text = NSLocalizedString(@"Off", @"");
            } else {
                //check the date before showing it in the cell. Date can be in the past and already expired.
                NSDate* mutedUntilValue = [NSDate dateWithTimeIntervalSince1970:[mute_value doubleValue]];
                NSDate *currentDate = [NSDate date];
                
                if (mutedUntilValue == [mutedUntilValue laterDate:currentDate]){
                    NSDateFormatter *formatter = nil;
                    formatter = [[NSDateFormatter alloc] init];
                    [formatter setTimeStyle:NSDateFormatterShortStyle];
                    cell.detailTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Off Until %@", @""),[formatter stringFromDate:mutedUntilValue]];
                } else {
                    //date is in the past. Remove it.
                    hasChanges = YES;
                    [_notificationMutePreferences removeObjectForKey:@"value"];
                    [_notificationPreferences setValue:_notificationMutePreferences forKey:@"mute_until"];
                    [[NSUserDefaults standardUserDefaults] setValue:_notificationPreferences forKey:@"notification_preferences"];
                    cell.detailTextLabel.text = NSLocalizedString(@"On", @"");
                }
            }
        } else {
            cell.detailTextLabel.text = NSLocalizedString(@"On", @"");
        }
        cell.textLabel.textColor = [UIColor blackColor];
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
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        UIActionSheet *actionSheet;        
        if ([_notificationMutePreferences objectForKey:@"value"] != nil) {
            //Notifications were muted
            actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Notifications", @"")
                                                      delegate:self
                                             cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
                                        destructiveButtonTitle:nil
                                             otherButtonTitles:NSLocalizedString(@"Turn On", @""), nil];
            actionSheet.tag = 100;
        } else {
            //Notifications were not muted
            actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Notifications", @"")
                                                      delegate:self
                                             cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
                                        destructiveButtonTitle:NSLocalizedString(@"Turn Off", @"")
                                             otherButtonTitles:NSLocalizedString(@"Turn Off for 1hr", @""), NSLocalizedString(@"Turn Off Until 8am", @""), nil ];
            actionSheet.tag = 101;
            
        }
        [actionSheet showFromRect:cell.frame inView:self.view animated:YES];
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
    }
}


#pragma mark -
#pragma mark Action Sheet Delegate Methods
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	[actionSheet dismissWithClickedButtonIndex:buttonIndex animated:YES];
    
    WPFLog(@"Button Clicked: %d", buttonIndex);
    NSMutableDictionary *muteDictionary;
    
    if (actionSheet.tag == 100 ) {
        //Notifications were muted.
        //buttonIndex == 0 -> Turn on, cancel otherwise.
        if(buttonIndex == 0) {
            hasChanges = YES;
            muteDictionary = [NSMutableDictionary dictionary];
            [muteDictionary setObject:@"0" forKey:@"value"];
        } else {
            return; //cancel
        }
    } else {
        //Notification were not muted.
        //buttonIndex == 0 -> Turn off
        //buttonIndex == 1 -> Turn off 1hr
        //buttonIndex == 2 -> Turn off until 8am
        //cancel otherwise
        NSString *mute_until_value;
        switch (buttonIndex) {
            case 0:
            {
                mute_until_value = @"forever";
                break;
            }
            case 1:{ //Turn off 1hr
                NSDate *currentDate = [NSDate date];
                NSDateComponents *comps = [[NSDateComponents alloc] init];
                [comps setHour:+1];
                NSCalendar *calendar = [NSCalendar currentCalendar];
                NSDate *oneHourFromNow = [calendar dateByAddingComponents:comps toDate:currentDate options:0];
                int timestamp = [oneHourFromNow timeIntervalSince1970];
                 WPFLog(@"Time Stamp: %d", timestamp);
                mute_until_value = [NSString stringWithFormat:@"%d", timestamp];
                break;
            }
            case 2:{ //Turn off until 8am
                NSDate *currentDate = [NSDate date];
                NSCalendar *sysCalendar = [NSCalendar currentCalendar];
                
                //Get the hr from the current date and check if > 8AM
                unsigned int unitFlags = NSHourCalendarUnit;//Other usage:  =(NSHourCalendarUnit | NSMinuteCalendarUnit | NSDayCalendarUnit | NSMonthCalendarUnit);
                NSDateComponents *comps = [sysCalendar components:unitFlags fromDate:currentDate];
                int hour = [comps hour]; //Other usage: [comps minute] [comps hour] [comps day] [comps month];

                comps = [[NSDateComponents alloc] init];
                if(hour >= 8){ //add one day if 8AM is already passed
                    [comps setDay:+1];
                }
                
                //calculate the new date
                NSDate *eightAM = [sysCalendar dateByAddingComponents:comps toDate:currentDate options:0];
                comps = [sysCalendar
                         components:NSDayCalendarUnit | NSYearCalendarUnit | NSMonthCalendarUnit
                         fromDate:eightAM];
                [comps setHour:8];
                
                NSDate *todayOrTomorrow8AM = [sysCalendar dateFromComponents:comps];
                int timestamp = [todayOrTomorrow8AM timeIntervalSince1970];
                WPFLog(@"Time Stamp: %d", timestamp);
                mute_until_value = [NSString stringWithFormat:@"%d", timestamp];
                break;
            }
            default:
                return; //cancel
        }
        
        hasChanges = YES;
        muteDictionary = [NSMutableDictionary dictionary];
        [muteDictionary setObject:mute_until_value forKey:@"value"];
    }
    
    [_notificationPreferences setValue:muteDictionary forKey:@"mute_until"];
    [[NSUserDefaults standardUserDefaults] setValue:_notificationPreferences forKey:@"notification_preferences"];
    [self reloadNotificationSettings];
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
