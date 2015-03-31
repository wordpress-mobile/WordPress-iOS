#import <WordPressApi/WordPressApi.h>

#import "NotificationSettingsViewController.h"
#import "WordPressAppDelegate.h"
#import "WordPressComApi.h"
#import "NSString+XMLExtensions.h"
#import "DateUtils.h"
#import "WPTableViewSectionHeaderView.h"
#import "WPTableViewSectionFooterView.h"
#import "WPAccount.h"
#import "NotificationsManager.h"
#import "NSDate+StringFormatting.h"

#import <Simperium/Simperium.h>



#pragma mark ==========================================================================================
#pragma mark Constants
#pragma mark ==========================================================================================

static NSString* NotificationSettingPreferencesKey  = @"notification_preferences";
static NSString* NotificationSettingValueKey        = @"value";
static NSString* NotificationSettingMutedBlogsKey   = @"muted_blogs";
static NSString* NotificationSettingMutedUntilKey   = @"mute_until";
static NSString* NotificationSettingForever         = @"forever";
static CGFloat NotificationFooterExtraPadding       = 10.0f;


#pragma mark ==========================================================================================
#pragma mark Private
#pragma mark ==========================================================================================

@interface NotificationSettingsViewController () <UIActionSheetDelegate>

@property (nonatomic, strong) NSMutableDictionary   *notificationPreferences;
@property (nonatomic, strong) NSMutableDictionary   *notificationMutePreferences;
@property (nonatomic, strong) NSMutableArray        *notificationPrefArray;
@property (nonatomic, strong) NSMutableArray        *mutedBlogsArray;
@property (nonatomic, assign) BOOL                  hasChanges;

@end


#pragma mark ==========================================================================================
#pragma mark NotificationSettingsViewController
#pragma mark ==========================================================================================

@implementation NotificationSettingsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.backgroundView = nil;
    self.view.backgroundColor =  [WPStyleGuide itsEverywhereGrey];
    self.title = NSLocalizedString(@"Manage Notifications", @"");

    UIRefreshControl *refreshControl = [UIRefreshControl new];
    [refreshControl addTarget:self action:@selector(refreshNotificationSettings) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
    
    if (self.showCloseButton) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", @"") style:[WPStyleGuide barButtonStyleForBordered] target:self action:@selector(dismiss)];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.notificationPreferences = [[[NSUserDefaults standardUserDefaults] objectForKey:NotificationSettingPreferencesKey] mutableCopy];
    
    // Empty Settings: Display the spinner
    if (!_notificationPreferences) {
        CGFloat refreshControlHeight = CGRectGetHeight(self.refreshControl.frame);
        [self.tableView setContentOffset:CGPointMake(0.0f, -refreshControlHeight) animated:YES];
        [self.refreshControl beginRefreshing];
    }
    
    // Always download the latest settings
    [self reloadNotificationSettings];
    [self refreshNotificationSettings];
}

- (void)refreshNotificationSettings
{
    [NotificationsManager fetchNotificationSettingsWithSuccess:^{
        [self notificationsDidFinishRefreshingWithError:nil];
    } failure:^(NSError *error) {
        [self notificationsDidFinishRefreshingWithError:error];
    }];
}

- (void)reloadNotificationSettings
{
    _notificationPreferences = [[[NSUserDefaults standardUserDefaults] objectForKey:NotificationSettingPreferencesKey] mutableCopy];
    if (!_notificationPreferences) {
        return;
    }
    
    _notificationPrefArray = [[_notificationPreferences allKeys] mutableCopy];
    if ([_notificationPrefArray indexOfObject:NotificationSettingMutedBlogsKey] != NSNotFound) {
        [_notificationPrefArray removeObjectAtIndex:[_notificationPrefArray indexOfObject:NotificationSettingMutedBlogsKey]];
        _mutedBlogsArray = [[[_notificationPreferences objectForKey:NotificationSettingMutedBlogsKey] objectForKey:NotificationSettingValueKey] mutableCopy];
    }
    
    if ([_notificationPrefArray indexOfObject:NotificationSettingMutedUntilKey] != NSNotFound) {
        [_notificationPrefArray removeObjectAtIndex:[_notificationPrefArray indexOfObject:NotificationSettingMutedUntilKey]];
        _notificationMutePreferences = [[_notificationPreferences objectForKey:NotificationSettingMutedUntilKey] mutableCopy];
        
    } else {
        _notificationMutePreferences = [NSMutableDictionary dictionary];
    }
    
    [self resetMuteIfNeeded];
    [self.tableView reloadData];
}

- (void)notificationSettingChanged:(UISwitch *)sender
{
    NSMutableDictionary *updatedPreference = [[_notificationPreferences objectForKey:[_notificationPrefArray objectAtIndex:sender.tag]] mutableCopy];
    [updatedPreference setValue:[NSNumber numberWithBool:sender.on] forKey:NotificationSettingValueKey];
    [_notificationPreferences setValue:updatedPreference forKey:[_notificationPrefArray objectAtIndex:sender.tag]];

    [self save];
}

- (void)muteBlogSettingChanged:(UISwitch *)sender
{
    NSMutableDictionary *updatedPreference = [[_mutedBlogsArray objectAtIndex:sender.tag] mutableCopy];
    [updatedPreference setValue:[NSNumber numberWithBool:!sender.on] forKey:NotificationSettingValueKey];

    [_mutedBlogsArray setObject:updatedPreference atIndexedSubscript:sender.tag];

    NSMutableDictionary *mutedBlogsDictionary = [[_notificationPreferences objectForKey:NotificationSettingMutedBlogsKey] mutableCopy];
    [mutedBlogsDictionary setValue:_mutedBlogsArray forKey:NotificationSettingValueKey];

    [_notificationPreferences setValue:mutedBlogsDictionary forKey:NotificationSettingMutedBlogsKey];

    [self save];
}

- (void)dismiss
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    self.navigationController.toolbarHidden = YES;
    if (self.hasChanges){
        [NotificationsManager saveNotificationSettings];
    }
    [super viewWillDisappear:animated];
}


#pragma mark - Helpers

- (void)resetMuteIfNeeded
{
    NSString *muteValue = self.notificationMutePreferences[NotificationSettingValueKey];
    if (!muteValue) {
        return;
    }
    
    if ([muteValue isEqualToString:NotificationSettingForever]) {
        return;
    }
    
    NSDate *mutedUntilValue = [NSDate dateWithTimeIntervalSince1970:muteValue.doubleValue];
    
    if ([mutedUntilValue laterDate:[NSDate date]] == mutedUntilValue) {
        return;
    }
    
    // The date is in the past: Remove it
    [self.notificationMutePreferences removeObjectForKey:NotificationSettingValueKey];
    self.notificationPreferences[NotificationSettingMutedUntilKey] = self.notificationMutePreferences;
    
    [self save];
}

- (void)save
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setValue:self.notificationPreferences forKey:NotificationSettingPreferencesKey];
    [userDefaults synchronize];
    
    self.hasChanges = YES;
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (_notificationPrefArray) {
        NSString *mute_value = [_notificationMutePreferences objectForKey:NotificationSettingValueKey];
        if (mute_value && ![mute_value isEqualToString:@"0"]){
            return 1;
        }

        if (_mutedBlogsArray) {
            return 3;
        }

        return 2;
    }

    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return 1;
        case 1:
            return [_notificationPrefArray count];
        case 2:
            return [_mutedBlogsArray count];
        default:
            break;
    }

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

        DDLogInfo(@"muteDictionary: %@", _notificationMutePreferences);

        if (_notificationMutePreferences && [_notificationMutePreferences objectForKey:NotificationSettingValueKey] != nil) {
            NSString *mute_value = [_notificationMutePreferences objectForKey:NotificationSettingValueKey];
            if ([mute_value isEqualToString:NotificationSettingForever]){
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
                    cell.detailTextLabel.text = NSLocalizedString(@"On", @"");
                }
            }
        } else {
            cell.detailTextLabel.text = NSLocalizedString(@"On", @"");
        }
        cell.textLabel.textColor = [UIColor blackColor];
        [WPStyleGuide configureTableViewCell:cell];
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
    [cellSwitch removeTarget:nil action:nil forControlEvents:UIControlEventAllEvents];

    if (indexPath.section == 1) {
        [cellSwitch addTarget:self action:@selector(notificationSettingChanged:) forControlEvents:UIControlEventValueChanged];
        NSDictionary *notificationPreference = [_notificationPreferences objectForKey:[_notificationPrefArray objectAtIndex:indexPath.row]];

        cell.textLabel.text = [[notificationPreference objectForKey:@"desc"] stringByDecodingXMLCharacters];
        cellSwitch.on = [[notificationPreference objectForKey:NotificationSettingValueKey] boolValue];
    } else {
        [cellSwitch addTarget:self action:@selector(muteBlogSettingChanged:) forControlEvents:UIControlEventValueChanged];
        NSDictionary *muteBlogSetting = [_mutedBlogsArray objectAtIndex:indexPath.row];
        NSString *blogName = [muteBlogSetting objectForKey:@"blog_name"];
        if ([blogName length] == 0) {
            blogName = [muteBlogSetting objectForKey:@"url"];
        }
        cell.textLabel.text = [blogName stringByDecodingXMLCharacters];
        cellSwitch.on = ![[muteBlogSetting objectForKey:NotificationSettingValueKey] boolValue];
    }
    [WPStyleGuide configureTableViewCell:cell];
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    CGRect frame = CGRectMake(0.0f, 0.0f, CGRectGetWidth(self.view.bounds), 0.0f);
    WPTableViewSectionHeaderView *header = [[WPTableViewSectionHeaderView alloc] initWithFrame:frame];
    header.title = [self titleForHeaderInSection:section];
    return header;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    NSString *title = [self titleForFooterInSection:section];
    if (!title) {
        return nil;
    }
    
    CGRect frame = CGRectMake(0.0f, 0.0f, CGRectGetWidth(self.view.bounds), 0.0f);
    WPTableViewSectionFooterView *footer = [[WPTableViewSectionFooterView alloc] initWithFrame:frame];
    footer.title = title;
    return footer;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    NSString *title = [self titleForHeaderInSection:section];
    return [WPTableViewSectionHeaderView heightForTitle:title andWidth:CGRectGetWidth(self.view.bounds)];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    NSString *title = [self titleForFooterInSection:section];
    if (!title) {
        return CGFLOAT_MIN;
    }

    CGFloat calculatedHeight = [WPTableViewSectionFooterView heightForTitle:title
                                                                   andWidth:CGRectGetWidth(self.view.bounds)];
    
    return calculatedHeight + NotificationFooterExtraPadding;
}


#pragma mark - Helpers

- (NSString *)titleForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return @"";
    } else if (section == 1) {
        return NSLocalizedString(@"Push Notifications", @"");
    }

    return NSLocalizedString(@"Sites", @"");
}

- (NSString *)titleForFooterInSection:(NSInteger)section
{
    NSInteger lastSection = self.tableView.numberOfSections - 1;
    if (section != lastSection) {
        return nil;
    }
    
    Simperium *simperium = [[WordPressAppDelegate sharedInstance] simperium];
    NSString *lastSeen = [simperium.networkLastSeenTime shortString] ?: [NSString string];
    NSString *status = [NSString stringWithFormat:@"Network Last Seen: %@ [%@]", lastSeen, simperium.networkStatus];
    return status;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0){
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        UIActionSheet *actionSheet;
        if ([_notificationMutePreferences objectForKey:NotificationSettingValueKey] != nil) {
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
                                        destructiveButtonTitle:nil
                                             otherButtonTitles:NSLocalizedString(@"Turn Off", @""), NSLocalizedString(@"Turn Off for 1hr", @""), NSLocalizedString(@"Turn Off Until 8am", @""), nil ];
            actionSheet.tag = 101;

        }
        [actionSheet showFromRect:cell.frame inView:self.view animated:YES];
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
    }
}


#pragma mark - Action Sheet Delegate Methods

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [actionSheet dismissWithClickedButtonIndex:buttonIndex animated:YES];

    DDLogInfo(@"Button Clicked: %d", buttonIndex);
    NSMutableDictionary *muteDictionary;

    if (actionSheet.tag == 100 ) {
        //Notifications were muted.
        //buttonIndex == 0 -> Turn on, cancel otherwise.
        if (buttonIndex == 0) {
            muteDictionary = [NSMutableDictionary dictionary];
            [muteDictionary setObject:@"0" forKey:NotificationSettingValueKey];
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
                mute_until_value = NotificationSettingForever;
                break;
            }
            case 1:{ //Turn off 1hr
                NSDate *currentDate = [NSDate date];
                NSDateComponents *comps = [[NSDateComponents alloc] init];
                [comps setHour:+1];
                NSCalendar *calendar = [NSCalendar currentCalendar];
                NSDate *oneHourFromNow = [calendar dateByAddingComponents:comps toDate:currentDate options:0];
                int timestamp = [oneHourFromNow timeIntervalSince1970];
                 DDLogInfo(@"Time Stamp: %d", timestamp);
                mute_until_value = [NSString stringWithFormat:@"%d", timestamp];
                break;
            }
            case 2:{ //Turn off until 8am
                NSDate *currentDate = [NSDate date];
                NSCalendar *sysCalendar = [NSCalendar currentCalendar];

                //Get the hr from the current date and check if > 8AM
                unsigned int unitFlags = NSHourCalendarUnit;//Other usage:  =(NSHourCalendarUnit | NSMinuteCalendarUnit | NSDayCalendarUnit | NSMonthCalendarUnit);
                NSDateComponents *comps = [sysCalendar components:unitFlags fromDate:currentDate];
                NSInteger hour = [comps hour]; //Other usage: [comps minute] [comps hour] [comps day] [comps month];

                comps = [[NSDateComponents alloc] init];
                if (hour >= 8){ //add one day if 8AM is already passed
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
                DDLogInfo(@"Time Stamp: %d", timestamp);
                mute_until_value = [NSString stringWithFormat:@"%d", timestamp];
                break;
            }
            default:
                return; //cancel
        }

        muteDictionary = [NSMutableDictionary dictionary];
        [muteDictionary setObject:mute_until_value forKey:NotificationSettingValueKey];
    }

    [_notificationPreferences setValue:muteDictionary forKey:NotificationSettingMutedUntilKey];
    [self save];
    [self reloadNotificationSettings];
}


#pragma mark - Pull to Refresh delegate

- (void)notificationsDidFinishRefreshingWithError:(NSError *)error
{
    if (!error) {
        [self reloadNotificationSettings];
    } else {
        [WPError showAlertWithTitle:(NSLocalizedString(@"Error", @"")) message:error.localizedDescription];
    }
    
    // Note:
    // Stop the spinner after a while, in order to prevent a weird flicker caused by the tableView.reloadData call
    dispatch_time_t delay = (0.1f * NSEC_PER_SEC);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delay), dispatch_get_main_queue(), ^{
        [self.refreshControl endRefreshing];
    });
}

@end
