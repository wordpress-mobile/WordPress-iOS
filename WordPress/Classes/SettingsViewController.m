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
#import "ContextManager.h"
#import "AccountService.h"

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
    
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(defaultAccountDidChange:) name:WPAccountWordPressComAccountWasAddedNotification object:nil];
    [nc addObserver:self selector:@selector(defaultAccountDidChange:) name:WPAccountWordPressComAccountWasRemovedNotification object:nil];

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
    NSDictionary *imageResizeDict = [NSDictionary dictionaryWithObjectsAndKeys:@"3", @"DefaultValue",
                                     @"media_resize_preference", @"Key", 
                                     NSLocalizedString(@"Image Quality", @""), @"Title",
                                     [NSArray arrayWithObjects:
                                      NSLocalizedString(@"Small", @"Small - Image Quality setting"),
                                      NSLocalizedString(@"Medium", @"Medium - Image Quality setting"),
                                      NSLocalizedString(@"Large", @"Large - Image Quality setting"),
                                      NSLocalizedString(@"Original Size", @"Original (uncompressed)  - Image Quality setting"), nil], @"Titles",
                                     [NSArray arrayWithObjects:@"1",@"2",@"3",@"4", nil], @"Values",
                                     NSLocalizedString(@"Set which size images should be uploaded in.", @""), @"Info",
                                     nil];
        
    _mediaSettingsArray = [NSArray arrayWithObjects:imageResizeDict, nil];
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
        case SettingsSectionWpcom: {
            NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
            AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
            WPAccount *defaultAccount = [accountService defaultWordPressComAccount];
    
            if (defaultAccount) {
                return [self rowForSignOut] + 1;
            } else {
                return 1;
            }
        }

        case SettingsSectionMedia:
            return [self.mediaSettingsArray count];

        case SettingsSectionInfo:
            return 2;
            
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
        NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
        AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
        WPAccount *defaultAccount = [accountService defaultWordPressComAccount];

        if (defaultAccount) {
            if (indexPath.row == 0) {
                cell.textLabel.text = NSLocalizedString(@"Username", @"");
                cell.detailTextLabel.text = [defaultAccount username];
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
        
        // If setting doesn't exist yet, or if it was set to "0" (which was removed) set it to default
        if (currentVal == nil || [currentVal isEqualToString:@"0"]) {
            currentVal = dict[@"DefaultValue"];
        }
        
        NSArray *values = [dict objectForKey:@"Values"];
        NSInteger index = [values indexOfObject:currentVal];
        NSArray *titles = [dict objectForKey:@"Titles"];
        cell.detailTextLabel.text = titles[index];
        
    } else if (indexPath.section == SettingsSectionInfo) {
        if (indexPath.row == 0) {
            // About
            cell.textLabel.text = NSLocalizedString(@"About", @"");
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        } else if (indexPath.row == 1) {
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
        case SettingsSectionWpcom: {
            NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
            AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
            WPAccount *defaultAccount = [accountService defaultWordPressComAccount];

            if (defaultAccount && indexPath.row == 0) {
                cellIdentifier = @"WpcomUsernameCell";
                cellStyle = UITableViewCellStyleValue1;
            } else {
                cellIdentifier = @"WpcomCell";
                cellStyle = UITableViewCellStyleDefault;
            }
            break;
        }
        case SettingsSectionMedia:
            cellIdentifier = @"Media";
            cellStyle = UITableViewCellStyleValue1;
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
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
    WPAccount *defaultAccount = [accountService defaultWordPressComAccount];

    if (![[defaultAccount restApi] hasCredentials]) {
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
        NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
        AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
        WPAccount *defaultAccount = [accountService defaultWordPressComAccount];

        if (defaultAccount) {
            if (indexPath.row == [self rowForSignOut]) {
                // Present the Sign out ActionSheet
                NSString *signOutTitle = NSLocalizedString(@"You are logged in as %@", @"");
                signOutTitle = [NSString stringWithFormat:signOutTitle, [defaultAccount username]];
                UIActionSheet *actionSheet;
                actionSheet = [[UIActionSheet alloc] initWithTitle:signOutTitle 
                                                          delegate:self 
                                                 cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
                                            destructiveButtonTitle:NSLocalizedString(@"Sign Out", @"")otherButtonTitles:nil, nil ];
                actionSheet.actionSheetStyle = UIActionSheetStyleDefault;
                [actionSheet showInView:self.view];
            } else if (indexPath.row == [self rowForNotifications]) {
                NotificationSettingsViewController *notificationSettingsViewController = [[NotificationSettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
                [self.navigationController pushViewController:notificationSettingsViewController animated:YES];
            }
        } else {
            LoginViewController *loginViewController = [[LoginViewController alloc] init];
            loginViewController.onlyDotComAllowed = YES;
            loginViewController.dismissBlock = ^{
                [self.navigationController popToViewController:self animated:YES];
            };
            [self.navigationController pushViewController:loginViewController animated:YES];
        }
        
    } else if (indexPath.section == SettingsSectionMedia) {
        NSDictionary *dict = [self.mediaSettingsArray objectAtIndex:indexPath.row];
        SettingsPageViewController *controller = [[SettingsPageViewController alloc] initWithDictionary:dict];
        [self.navigationController pushViewController:controller animated:YES];

    } else if (indexPath.section == SettingsSectionInfo) {
        if (indexPath.row == 0) {
            AboutViewController *aboutViewController = [[AboutViewController alloc] initWithNibName:@"AboutViewController" bundle:nil];
            [self.navigationController pushViewController:aboutViewController animated:YES];
        } else if (indexPath.row == 1) {
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
        // Sign out
        NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
        AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];

		[accountService removeDefaultWordPressComAccount];
        
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:SettingsSectionWpcom] withRowAnimation:UITableViewRowAnimationFade];
    }
}

@end
