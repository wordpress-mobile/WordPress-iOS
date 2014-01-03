/*
 * SettingsViewController.m
 *
 * Copyright (c) 2013 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

/*
 
 Settings contents:
 
 - Blogs list
    - Add blog
    - Edit/Delete
 - WordPress.com account
    - Sign out / Sign in
 - Media Settings
    - Image Resize
    - Video API
    - Video Quality
    - Video Content
 - Info
    - Version
    - About
    - Extra debug

 */

#import "SettingsViewController.h"
#import "WordPressComApi.h"
#import "AboutViewController.h"
#import "SettingsPageViewController.h"
#import "NotificationSettingsViewController.h"
#import "Blog+Jetpack.h"
#import "LoginViewController.h"
#import "SupportViewController.h"
#import "WPAccount.h"
#import "WPTableViewSectionHeaderView.h"
#import "SupportViewController.h"
#import "ContextManager.h"
#import "NotificationsManager.h"

typedef enum {
    SettingsSectionWpcom = 0,
    SettingsSectionMedia,
    SettingsSectionInfo,
    SettingsSectionCount
} SettingsSection;

CGFloat const blavatarImageViewSize = 43.f;

@interface SettingsViewController () <UIActionSheetDelegate>

@property (nonatomic, strong) NSArray *mediaSettingsArray;
@property (nonatomic, strong) UIBarButtonItem *doneButton;

@end

@implementation SettingsViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Settings", @"App Settings");
    self.doneButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", @"") style:[WPStyleGuide barButtonStyleForBordered] target:self action:@selector(dismiss)];
    self.navigationItem.rightBarButtonItem = self.doneButton;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(defaultAccountDidChange:) name:WPAccountDefaultWordPressComAccountChangedNotification object:nil];

    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [self.tableView reloadData];
}


#pragma mark - Notifications

- (void)defaultAccountDidChange:(NSNotification *)notification {
    NSMutableIndexSet *sections = [NSMutableIndexSet indexSet];
    [sections addIndex:SettingsSectionWpcom];
    [self.tableView reloadSections:sections withRowAnimation:UITableViewRowAnimationFade];
}


#pragma mark - Custom Getter

- (NSArray *)mediaSettingsArray {
    if (_mediaSettingsArray) {
        return _mediaSettingsArray;
    }
    
    // Construct the media data to mimick how it would appear if a settings bundle plist was loaded
    // into an NSDictionary
    // Our settings bundle stored numeric values as strings so we use strings here for backward compatibility.
    NSDictionary *imageResizeDict = [NSDictionary dictionaryWithObjectsAndKeys:@"0", @"DefaultValue", 
                                     @"media_resize_preference", @"Key", 
                                     NSLocalizedString(@"Image Quality", @""), @"Title",
                                     [NSArray arrayWithObjects:NSLocalizedString(@"Always Ask", @"Always Ask (ask for size on every upload) - Image Quality setting"),
                                      NSLocalizedString(@"Small", @"Small - Image Quality setting"),
                                      NSLocalizedString(@"Medium", @"Medium - Image Quality setting"),
                                      NSLocalizedString(@"Large", @"Large - Image Quality setting"),
                                      NSLocalizedString(@"Original Size", @"Original (uncompressed)  - Image Quality setting"), nil], @"Titles",
                                     [NSArray arrayWithObjects:@"0",@"1",@"2",@"3",@"4", nil], @"Values",
                                     NSLocalizedString(@"Set which size images should be uploaded in.", @""), @"Info",
                                     nil];
        
    NSDictionary *videoQualityDict = [NSDictionary dictionaryWithObjectsAndKeys:@"1", @"DefaultValue", 
                                      @"video_quality_preference", @"Key", 
                                      NSLocalizedString(@"Video Quality", @""), @"Title", 
                                      [NSArray arrayWithObjects:NSLocalizedString(@"Original Size", @"Video quality - uncompressed original size for the device"),
                                      NSLocalizedString(@"Medium (480p)", @"Video quality - medium quality, 480p"),
                                      NSLocalizedString(@"Default (360p)", @"Video quality - default size, 360p"),
                                      NSLocalizedString(@"Low (144p)", @"Video quality - low quality, 144p"), nil], @"Titles",
                                      [NSArray arrayWithObjects:@"0", @"3", @"1", @"2", nil], @"Values",
                                      NSLocalizedString(@"Choose the quality at which video should be uploaded when inserting into posts.", @""), @"Info",                                      
                                      nil];
    
    NSDictionary *videoContentDict = [NSDictionary dictionaryWithObjectsAndKeys:@"0", @"DefaultValue", 
                                      @"video_html_preference", @"Key", 
                                      NSLocalizedString(@"Video Content", @""), @"Title", 
                                      [NSArray arrayWithObjects:@"HTML 5",@"HTML 4", nil ], @"Titles", 
                                      [NSArray arrayWithObjects:@"0", @"1", nil], @"Values",
                                      NSLocalizedString(@"Set which HTML standard video should conform to when added to a post.", @""), @"Info",
                                      nil];
    _mediaSettingsArray = [NSArray arrayWithObjects:imageResizeDict, videoQualityDict, videoContentDict, nil];
    return _mediaSettingsArray;
}

- (void)dismiss {
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.tableView isEditing] ? 1 : SettingsSectionCount;
}

// The Sign Out row in Wpcom section can change, so identify it dynamically
- (NSInteger)rowForSignOut {
    NSInteger rowForSignOut = 1;
    if ([NotificationsManager deviceRegisteredForPushNotifications]) {
        rowForSignOut += 1;
    }
    return rowForSignOut;
}

- (NSInteger)rowForNotifications {
    if ([NotificationsManager deviceRegisteredForPushNotifications]) {
        return 1;
    }
    return -1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case SettingsSectionWpcom:
            if ([WPAccount defaultWordPressComAccount]) {
                return [self rowForSignOut] + 1;
            } else {
                return 1;
            }

        case SettingsSectionMedia:
            return [self.mediaSettingsArray count];

        case SettingsSectionInfo:
            return 3;
            
        default:
            return 0;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    WPTableViewSectionHeaderView *header = [[WPTableViewSectionHeaderView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 0)];
    header.fixedWidth = 0.0;
    header.title = [self titleForHeaderInSection:section];
    return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    NSString *title = [self titleForHeaderInSection:section];
    return [WPTableViewSectionHeaderView heightForTitle:title andWidth:CGRectGetWidth(self.view.bounds)];
}

- (NSString *)titleForHeaderInSection:(NSInteger)section {
    if (section == SettingsSectionWpcom) {
        return NSLocalizedString(@"WordPress.com", @"");

    } else if (section == SettingsSectionMedia) {
        return NSLocalizedString(@"Media", @"Title label for the media settings section in the app settings");
		
    } else if (section == SettingsSectionInfo) {
        return NSLocalizedString(@"App Info", @"Title label for the application information section in the app settings");
    }
    
    return nil;
}


- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {    
    cell.textLabel.textAlignment = NSTextAlignmentLeft;
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.accessoryView = nil;

    if (indexPath.section == SettingsSectionWpcom) {
        if ([WPAccount defaultWordPressComAccount]) {
            if (indexPath.row == 0) {
                cell.textLabel.text = NSLocalizedString(@"Username", @"");
                cell.detailTextLabel.text = [[WPAccount defaultWordPressComAccount] username];
                cell.detailTextLabel.textColor = [UIColor UIColorFromHex:0x888888];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                cell.accessibilityIdentifier = @"wpcom-username";
            } else if (indexPath.row == [self rowForNotifications]) {
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                cell.textLabel.text = NSLocalizedString(@"Manage Notifications", @"");
                cell.accessibilityIdentifier = @"wpcom-manage-notifications";
            } else {
                cell.textLabel.textAlignment = NSTextAlignmentCenter;
                cell.textLabel.text = NSLocalizedString(@"Sign Out", @"Sign out from WordPress.com");
                cell.accessibilityIdentifier = @"wpcom-sign-out";
            }
        } else {
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
            cell.textLabel.text = NSLocalizedString(@"Sign In", @"Sign in to WordPress.com");
            cell.accessibilityIdentifier = @"wpcom-sign-in";
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        }
        
    } else if (indexPath.section == SettingsSectionMedia){
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        NSDictionary *dict = self.mediaSettingsArray[indexPath.row];
        cell.textLabel.text = dict[@"Title"];
        NSString *key = dict[@"Key"];
        NSString *currentVal = [[NSUserDefaults standardUserDefaults] objectForKey:key];
        if (currentVal == nil) {
            currentVal = dict[@"DefaultValue"];
        }
        
        NSArray *values = [dict objectForKey:@"Values"];
        NSInteger index = [values indexOfObject:currentVal];
        NSArray *titles = [dict objectForKey:@"Titles"];
        cell.detailTextLabel.text = titles[index];
        
    } else if (indexPath.section == SettingsSectionInfo) {
        if (indexPath.row == 0) {
            // App Version
            cell.textLabel.text = NSLocalizedString(@"Version", @"");
            NSString *appversion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
#if DEBUG
            appversion = [appversion stringByAppendingString:@" (DEV)"];
#endif
            cell.detailTextLabel.text = appversion;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
        } else if (indexPath.row == 1) {
            // About
            cell.textLabel.text = NSLocalizedString(@"About", @"");
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            
        } else if (indexPath.row == 2) {
            // Settings
            cell.textLabel.text = NSLocalizedString(@"Support", @"");
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
    }
}

- (UITableViewCell *)cellForIndexPath:(NSIndexPath *)indexPath {
    NSString *cellIdentifier = @"Cell";
    UITableViewCellStyle cellStyle = UITableViewCellStyleDefault;
    
    switch (indexPath.section) {
        case SettingsSectionWpcom:
            if ([WPAccount defaultWordPressComAccount] && indexPath.row == 0) {
                cellIdentifier = @"WpcomUsernameCell";
                cellStyle = UITableViewCellStyleValue1;
            } else {
                cellIdentifier = @"WpcomCell";
                cellStyle = UITableViewCellStyleDefault;
            }
            break;
            
        case SettingsSectionMedia:
            cellIdentifier = @"Media";
            cellStyle = UITableViewCellStyleValue1;
            break;
            
        case SettingsSectionInfo:
            if (indexPath.row == 0) {
                cellIdentifier = @"InfoCell";
                cellStyle = UITableViewCellStyleValue1;
            }
            break;
        default:
            break;
    }
    
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:cellStyle reuseIdentifier:cellIdentifier];
    }
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self cellForIndexPath:indexPath];
    [WPStyleGuide configureTableViewCell:cell];
    [self configureCell:cell atIndexPath:indexPath];
    
    BOOL isSignInCell = NO;
    if (![[[WPAccount defaultWordPressComAccount] restApi] hasCredentials]) {
        isSignInCell = indexPath.section == SettingsSectionWpcom && indexPath.row == 0;
    }
    
    BOOL isSignOutCell = indexPath.section == SettingsSectionWpcom && indexPath.row == [self rowForSignOut];
    if (isSignOutCell || isSignInCell) {
        [WPStyleGuide configureTableViewActionCell:cell];
    }
    
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == SettingsSectionWpcom) {
        if ([WPAccount defaultWordPressComAccount]) {
            if (indexPath.row == [self rowForSignOut]) {
                [WPMobileStats trackEventForWPCom:StatsEventSettingsClickedSignOutOfDotCom];

                // Present the Sign out ActionSheet
                NSString *signOutTitle = NSLocalizedString(@"You are logged in as %@", @"");
                signOutTitle = [NSString stringWithFormat:signOutTitle, [[WPAccount defaultWordPressComAccount] username]];
                UIActionSheet *actionSheet;
                actionSheet = [[UIActionSheet alloc] initWithTitle:signOutTitle 
                                                          delegate:self 
                                                 cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
                                            destructiveButtonTitle:NSLocalizedString(@"Sign Out", @"")otherButtonTitles:nil, nil ];
                actionSheet.actionSheetStyle = UIActionSheetStyleDefault;
                [actionSheet showInView:self.view];
            } else if (indexPath.row == [self rowForNotifications]) {
                [WPMobileStats trackEventForWPCom:StatsEventSettingsClickedManageNotifications];
            
                NotificationSettingsViewController *notificationSettingsViewController = [[NotificationSettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
                [self.navigationController pushViewController:notificationSettingsViewController animated:YES];
            }
        } else {
            [WPMobileStats trackEventForWPCom:StatsEventSettingsClickedSignIntoDotCom];

            LoginViewController *loginViewController = [[LoginViewController alloc] init];
            loginViewController.onlyDotComAllowed = YES;
            loginViewController.dismissBlock = ^{
                [self.navigationController popToViewController:self animated:YES];
            };
            [self.navigationController pushViewController:loginViewController animated:YES];
        }
        
    } else if (indexPath.section == SettingsSectionMedia) {
        if (indexPath.row == 0) {
            [WPMobileStats trackEventForWPCom:StatsEventSettingsMediaClickedImageResize];
        } else if (indexPath.row == 1) {
            [WPMobileStats trackEventForWPCom:StatsEventSettingsMediaClickedVideoQuality];
        } else if (indexPath.row == 2) {
            [WPMobileStats trackEventForWPCom:StatsEventSettingsMediaClickedVideoContent];
        }
        
        NSDictionary *dict = [self.mediaSettingsArray objectAtIndex:indexPath.row];
        SettingsPageViewController *controller = [[SettingsPageViewController alloc] initWithDictionary:dict];
        [self.navigationController pushViewController:controller animated:YES];

    } else if (indexPath.section == SettingsSectionInfo) {
        if (indexPath.row == 1) {
            [WPMobileStats trackEventForWPCom:StatsEventSettingsClickedAbout];
            
            AboutViewController *aboutViewController = [[AboutViewController alloc] initWithNibName:@"AboutViewController" bundle:nil];
            [self.navigationController pushViewController:aboutViewController animated:YES];
        } else if (indexPath.row == 2) {
            // Support Page
            SupportViewController *supportViewController = [[SupportViewController alloc] init];
            [self.navigationController pushViewController:supportViewController animated:YES];
        }
    }
}

#pragma mark -
#pragma mark Action Sheet Delegate Methods

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        [WPMobileStats trackEventForWPCom:StatsEventSettingsSignedOutOfDotCom];
        
        // Sign out
		[WPAccount removeDefaultWordPressComAccount];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:SettingsSectionWpcom] withRowAnimation:UITableViewRowAnimationFade];
        
        // Remove defaults
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"wpcom_users_blogs"];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"wpcom_user_id"];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"wpcom_users_prefered_blog_id"];
    }
}

@end
