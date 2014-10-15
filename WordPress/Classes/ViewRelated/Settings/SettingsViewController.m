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
#import "WPPostViewController.h"
#import "WPTableViewSectionHeaderView.h"
#import "SupportViewController.h"
#import "ContextManager.h"
#import "NotificationsManager.h"
#import "ContextManager.h"
#import "AccountService.h"
#import "WPImageOptimizer.h"
#import "Constants.h"
#import "Media.h"
#import <Lookback/Lookback.h>

typedef enum {
    SettingsSectionWpcom = 0,
    SettingsSectionMedia,
    SettingsSectionEditor,
    SettingsSectionInfo,
    SettingsSectionInternalBeta,
    SettingsSectionCount
} SettingsSection;

static CGFloat const blavatarImageViewSize = 43.0;
static CGFloat const HorizontalMargin = 16.0;
static CGFloat const MediaSizeControlHeight = 44.0;
static CGFloat const SettingsRowHeight = 44.0;

@interface SettingsViewController () <UIActionSheetDelegate>

@property (nonatomic, strong) UIBarButtonItem *doneButton;
@property (nonatomic, assign) BOOL showInternalBetaSection;
@property (nonatomic, strong) UISlider *mediaSizeSlider;
@property (nonatomic, strong) UILabel *mediaCellLabel;

@end

@implementation SettingsViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Settings", @"App Settings");
    self.doneButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", @"") style:[WPStyleGuide barButtonStyleForBordered] target:self action:@selector(dismiss)];
    self.navigationItem.rightBarButtonItem = self.doneButton;
    
#ifdef LOOKBACK_ENABLED
    self.showInternalBetaSection = YES;
#else
    self.showInternalBetaSection = NO;
#endif

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(defaultAccountDidChange:) name:WPAccountDefaultWordPressComAccountChangedNotification object:nil];

    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [self.tableView reloadData];
}

#pragma mark - Notifications

- (void)defaultAccountDidChange:(NSNotification *)notification
{
    NSMutableIndexSet *sections = [NSMutableIndexSet indexSet];
    [sections addIndex:SettingsSectionWpcom];
    [self.tableView reloadSections:sections withRowAnimation:UITableViewRowAnimationFade];
}


#pragma mark - Custom Getter

- (NSString *)titleForMediaCell
{
    NSString *title = NSLocalizedString(@"Image Size", @"Title for the image size settings option.");
    NSString *mediaSize = [Media stringForMediaSize:[Media mediaResizeSetting]];
    return [NSString stringWithFormat:@"%@: %@", title, mediaSize];
}

- (UILabel *)mediaCellLabel
{
    if (_mediaCellLabel) {
        return _mediaCellLabel;
    }

    CGFloat width = CGRectGetWidth(self.tableView.bounds) - (HorizontalMargin * 2);
    CGRect frame = CGRectMake(HorizontalMargin, 0.0, width, MediaSizeControlHeight);
    UILabel *label = [[UILabel alloc] initWithFrame:frame];
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    label.font = [WPStyleGuide tableviewTextFont];
    label.textColor = [WPStyleGuide whisperGrey];
    label.text = [self titleForMediaCell];
    self.mediaCellLabel = label;

    return _mediaCellLabel;
}

- (UISlider *)mediaSizeSlider
{
    if (_mediaSizeSlider) {
        return _mediaSizeSlider;
    }

    CGFloat width = CGRectGetWidth(self.tableView.bounds) - (HorizontalMargin * 2);
    CGRect frame = CGRectMake(HorizontalMargin, CGRectGetHeight(self.mediaCellLabel.frame), width, MediaSizeControlHeight);
    UISlider *slider = [[UISlider alloc] initWithFrame:frame];
    slider.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    slider.continuous = NO;
    slider.minimumTrackTintColor = [WPStyleGuide whisperGrey];
    slider.maximumTrackTintColor = [WPStyleGuide whisperGrey];
    slider.minimumValue = MediaResizeMedium;
    slider.maximumValue = MediaResizeOriginal;
    slider.value = [Media mediaResizeSetting];
    [slider addTarget:self action:@selector(handleImageSizeChanged:) forControlEvents:UIControlEventValueChanged];
    self.mediaSizeSlider = slider;

    return _mediaSizeSlider;
}

- (void)handleImageSizeChanged:(id)sender
{
    NSUInteger value = (NSUInteger)(self.mediaSizeSlider.value + 0.5);
    [Media setMediaResizeSetting:value];

    [self.mediaSizeSlider setValue:value animated:NO];
    self.mediaCellLabel.text = [self titleForMediaCell];
}

- (void)handleEditorChanged:(id)sender
{
    UISwitch *aSwitch = (UISwitch *)sender;
    [WPPostViewController setNewEditorEnabled:aSwitch.on];
}

- (void)handleShakeToPullUpFeedbackChanged:(id)sender
{
    UISwitch *aSwitch = (UISwitch *)sender;
    BOOL shakeForFeedback = aSwitch.on;
    [[NSUserDefaults standardUserDefaults] setBool:shakeForFeedback forKey:WPInternalBetaShakeToPullUpFeedbackKey];
    [Lookback lookback].shakeToRecord = shakeForFeedback;
}

- (void)dismiss {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.tableView isEditing] ? 1 : SettingsSectionCount;
}

// The Sign Out row in Wpcom section can change, so identify it dynamically
- (NSInteger)rowForSignOut
{
    NSInteger rowForSignOut = 1;
    if ([NotificationsManager deviceRegisteredForPushNotifications]) {
        rowForSignOut += 1;
    }
    return rowForSignOut;
}

- (NSInteger)rowForNotifications
{
    if ([NotificationsManager deviceRegisteredForPushNotifications]) {
        return 1;
    }
    return -1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case SettingsSectionWpcom: {
            NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
            AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
            WPAccount *defaultAccount = [accountService defaultWordPressComAccount];

            if (defaultAccount) {
                return [self rowForSignOut] + 1;
            }

            return 1;
        }

        case SettingsSectionMedia:
            return 1;
        
		case SettingsSectionEditor: {
			if (![WPPostViewController isNewEditorAvailable]) {
				return 0;
			} else {
				return 1;
			}
		}
		
        case SettingsSectionInfo:
            return 2;
        case SettingsSectionInternalBeta:
            if (self.showInternalBetaSection) {
                return 1;
            }
            else {
                return 0;
            }
        default:
            return 0;
            
            
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
	if (section == SettingsSectionEditor && ![WPPostViewController isNewEditorAvailable]) {
		return nil;
	} else {
		WPTableViewSectionHeaderView *header = [[WPTableViewSectionHeaderView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 0)];
		header.fixedWidth = 0.0;
		header.title = [self titleForHeaderInSection:section];
		return header;
	}
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	if (section == SettingsSectionEditor && ![WPPostViewController isNewEditorAvailable]) {
		return 1;
	} else {
		NSString *title = [self titleForHeaderInSection:section];
		return [WPTableViewSectionHeaderView heightForTitle:title andWidth:CGRectGetWidth(self.view.bounds)];
	}
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
	static const CGFloat kDefaultFooterHeight = 16.0f;
	
	if (section == SettingsSectionEditor && ![WPPostViewController isNewEditorAvailable]) {
		return 1;
	} else {
		return kDefaultFooterHeight;
	}
}

- (NSString *)titleForHeaderInSection:(NSInteger)section
{
    if (section == SettingsSectionWpcom) {
        return NSLocalizedString(@"WordPress.com", @"");

    } else if (section == SettingsSectionMedia) {
        return NSLocalizedString(@"Media", @"Title label for the media settings section in the app settings");

    } else if (section == SettingsSectionEditor) {
        return NSLocalizedString(@"Editor", @"Title label for the editor settings section in the app settings");
		
    } else if (section == SettingsSectionInfo) {
        return NSLocalizedString(@"App Info", @"Title label for the application information section in the app settings");
    } else if (section == SettingsSectionInternalBeta) {
        if (self.showInternalBetaSection) {
            return NSLocalizedString(@"Internal Beta", @"");
        } else {
            return @"";
        }
    }

    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section ==  SettingsSectionMedia) {
        return CGRectGetHeight(self.mediaCellLabel.frame) + CGRectGetHeight(self.mediaSizeSlider.frame);
    }
    return SettingsRowHeight;
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    cell.textLabel.textAlignment = NSTextAlignmentLeft;
    cell.accessoryType = UITableViewCellAccessoryNone;

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

    } else if (indexPath.section == SettingsSectionMedia) {
        cell.textLabel.text = nil;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;

    } else if (indexPath.section == SettingsSectionEditor){
        cell.textLabel.text = NSLocalizedString(@"Visual Editor", @"Option to enable the visual editor");
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        UISwitch *aSwitch = (UISwitch *)cell.accessoryView;
        aSwitch.on = [WPPostViewController isNewEditorEnabled];
        
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
    } else if (indexPath.section == SettingsSectionInternalBeta) {
        cell.textLabel.text = NSLocalizedString(@"Shake for Feedback", @"Option to allow the user to shake the device to pull up the feedback mechanism");
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        UISwitch *aSwitch = (UISwitch *)cell.accessoryView;
        aSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:WPInternalBetaShakeToPullUpFeedbackKey];
    }
}

- (UITableViewCell *)cellForIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellIdentifier = @"Cell";
    UITableViewCellStyle cellStyle = UITableViewCellStyleDefault;

    if (indexPath.section == SettingsSectionWpcom) {
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
    } else if (indexPath.section == SettingsSectionMedia) {
            cellIdentifier = @"Media";
            cellStyle = UITableViewCellStyleDefault;
    } else if (indexPath.section == SettingsSectionEditor) {
            cellIdentifier = @"Editor";
            cellStyle = UITableViewCellStyleDefault;
    }

    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:cellStyle reuseIdentifier:cellIdentifier];
    }

    if (indexPath.section == SettingsSectionMedia) {
        CGFloat width = CGRectGetWidth(cell.bounds) - 32.0;
        CGRect frame = self.mediaCellLabel.frame;
        frame.size.width = width;
        self.mediaCellLabel.frame = frame;
        [cell.contentView addSubview:self.mediaCellLabel];

        frame = self.mediaSizeSlider.frame;
        frame.size.width = width;
        self.mediaSizeSlider.frame = frame;
        [cell.contentView addSubview:self.mediaSizeSlider];
    }

    if (indexPath.section == SettingsSectionEditor) {
        UISwitch *optimizeImagesSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
        [optimizeImagesSwitch addTarget:self action:@selector(handleEditorChanged:) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = optimizeImagesSwitch;
    }
    
    if (indexPath.section == SettingsSectionInternalBeta) {
        UISwitch *toggleShakeToPullUpFeedbackSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
        [toggleShakeToPullUpFeedbackSwitch addTarget:self action:@selector(handleShakeToPullUpFeedbackChanged:) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = toggleShakeToPullUpFeedbackSwitch;
    }

    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
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

                if (IS_IPAD) {
                    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                    [actionSheet showFromRect:[cell bounds] inView:cell animated:YES];
                } else {
                    [actionSheet showInView:self.view];
                }

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

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        // Sign out
        NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
        AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];

        [accountService removeDefaultWordPressComAccount];

        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:SettingsSectionWpcom] withRowAnimation:UITableViewRowAnimationFade];
    }
}

@end
