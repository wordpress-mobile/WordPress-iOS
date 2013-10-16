//
//  SettingsViewController.m
//  WordPress
//
//  Created by Jorge Bernal on 6/1/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

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
 - Sounds 
    - Mute Sounds
 - Info
    - Version
    - About
    - Extra debug

 */

#import <QuartzCore/QuartzCore.h>
#import "SettingsViewController.h"
#import "WordPressAppDelegate.h"
#import "EditSiteViewController.h"
#import "WelcomeViewController.h"
#import "WPcomLoginViewController.h"
#import "UIImageView+Gravatar.h"
#import "WordPressComApi.h"
#import "AboutViewController.h"
#import "SettingsPageViewController.h"
#import "NotificationSettingsViewController.h"
#import "Blog+Jetpack.h"
#import "GeneralWalkthroughViewController.h"
#import "SupportViewController.h"
#import "WPAccount.h"
#import "WPTableViewSectionHeaderView.h"
#import "AddUsersBlogsViewController.h"

typedef enum {

    SettingsSectionBlogs = 0,
    SettingsSectionBlogsAdd,
    SettingsSectionWpcom,
    SettingsSectionNotifications,
    SettingsSectionMedia,
    SettingsSectionSounds,
    SettingsSectionInfo,
    
    SettingsSectionCount
} SettingsSection;

@interface SettingsViewController () <NSFetchedResultsControllerDelegate, UIActionSheetDelegate, WPcomLoginViewControllerDelegate>

@property (weak, readonly) NSFetchedResultsController *resultsController;
@property (nonatomic, strong) NSArray *mediaSettingsArray;

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
- (UITableViewCell *)cellForIndexPath:(NSIndexPath *)indexPath;
- (void)checkCloseButton;
- (void)setupMedia;
- (void)handleExtraDebugChanged:(id)sender;
- (void)handleMuteSoundsChanged:(id)sender;
- (void)maskImageView:(UIImageView *)imageView corner:(UIRectCorner)corner;

@end

@implementation SettingsViewController {
    NSFetchedResultsController *_resultsController;
}

@synthesize mediaSettingsArray;

#pragma mark -
#pragma mark LifeCycle Methods


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Settings", @"App Settings");
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", @"") style:[WPStyleGuide barButtonStyleForBordered] target:self action:@selector(dismiss)];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:WordPressComApiDidLoginNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        NSMutableIndexSet *sections = [NSMutableIndexSet indexSet];
        [sections addIndex:SettingsSectionWpcom];
        [sections addIndex:SettingsSectionNotifications];
        [self.tableView reloadSections:sections withRowAnimation:UITableViewRowAnimationFade];
    }];
    [[NSNotificationCenter defaultCenter] addObserverForName:WordPressComApiDidLogoutNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        NSMutableIndexSet *sections = [NSMutableIndexSet indexSet];
        [sections addIndex:SettingsSectionWpcom];
        [sections addIndex:SettingsSectionNotifications];
        [self.tableView reloadSections:sections withRowAnimation:UITableViewRowAnimationFade];
    }];
    
    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
    [self setupMedia];    
}


- (void)viewDidUnload {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewDidUnload];
}


- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    // Remove the delegate to avoid a core data error that can occur when a new
    // blog is added, and other rows/sections are added as well (e.g. notifications).
    self.resultsController.delegate = nil;
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self checkCloseButton];
    self.resultsController.delegate = self; // Restore the delegate.
    [self.resultsController performFetch:nil];
    self.editButtonItem.enabled = ([[self.resultsController fetchedObjects] count] > 0); // Disable if we have no blogs.
    [self.tableView reloadData];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return [super shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}


#pragma mark - 
#pragma mark Custom methods

- (void)setupMedia {
    if (mediaSettingsArray) return;
    
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
    self.mediaSettingsArray = [NSArray arrayWithObjects:imageResizeDict, videoQualityDict, videoContentDict, nil];
}


- (void)dismiss {
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void)checkCloseButton {
    if ([[self.resultsController fetchedObjects] count] == 0 && ![[WordPressComApi sharedApi] hasCredentials]) {
        if (IS_IPAD) {
            // On the iPad the NUX is displayed as a UIFormSheet which still shows all the sidebar stuff in the background.
            // As this looks pretty ugly, we'll hide it by putting the loading image view on top of it.
            PanelNavigationController *panelNavController = (PanelNavigationController *)self.presentingViewController;
            [panelNavController displayLoadingImageView];
        }

        [WordPressAppDelegate wipeAllKeychainItems];

        GeneralWalkthroughViewController *walkthroughViewController = [[GeneralWalkthroughViewController alloc] init];
        self.navigationController.navigationBar.hidden = YES;
        [self.navigationController pushViewController:walkthroughViewController animated:YES];
    } else {
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }
}


- (void)handleExtraDebugChanged:(id)sender {
    UISwitch *aSwitch = (UISwitch *)sender;
    [[NSUserDefaults standardUserDefaults] setBool:aSwitch.on forKey:@"extra_debug"];
    [NSUserDefaults resetStandardUserDefaults];
}


- (void)handleMuteSoundsChanged:(id)sender {
    UISwitch *aSwitch = (UISwitch *)sender;
    
    if (aSwitch.on) {
        [WPMobileStats trackEventForWPCom:StatsEventSettingsEnabledSounds];
    } else {
        [WPMobileStats trackEventForWPCom:StatsEventSettingsDisabledSounds];
    }

    [[NSUserDefaults standardUserDefaults] setBool:!(aSwitch.on) forKey:kSettingsMuteSoundsKey];
    [NSUserDefaults resetStandardUserDefaults];
}

- (void)maskImageView:(UIImageView *)imageView corner:(UIRectCorner)corner {
    if (IS_IOS7) {
        // We don't want this effect in iOS7
        return;
    }
    
    CGRect frame = CGRectMake(0.0, 0.0, 43.0, 43.0);
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:frame
                                               byRoundingCorners:corner cornerRadii:CGSizeMake(7.0f, 7.0f)];
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.frame = frame;
    maskLayer.path = path.CGPath;
    imageView.layer.mask = maskLayer;
}

#pragma mark - 
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return SettingsSectionCount;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case SettingsSectionBlogs:
            return [[self.resultsController fetchedObjects] count];
            
        case SettingsSectionBlogsAdd:
            return 1;
            
        case SettingsSectionWpcom:
            return ([WordPressComApi sharedApi].username && [[WordPressComApi sharedApi] hasCredentials]) ? 2 : 1;
            
        case SettingsSectionMedia:
            return [mediaSettingsArray count];
			
        case SettingsSectionNotifications:
            if ([[WordPressComApi sharedApi] hasCredentials] && nil != [[NSUserDefaults standardUserDefaults] objectForKey:kApnsDeviceTokenPrefKey])
                return 1;
            else
                return 0;
            
        case SettingsSectionSounds :
            return 1;
            
        case SettingsSectionInfo:
            return 3;
            
        default:
            return 0;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == SettingsSectionBlogs) {
        return NSLocalizedString(@"Remove", @"Button label when removing a blog");
    }
    return nil;
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    WPTableViewSectionHeaderView *header = [[WPTableViewSectionHeaderView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 0)];
    header.title = [self titleForHeaderInSection:section];
    return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    NSString *title = [self titleForHeaderInSection:section];
    return [WPTableViewSectionHeaderView heightForTitle:title andWidth:CGRectGetWidth(self.view.bounds)];
}

- (NSString *)titleForHeaderInSection:(NSInteger)section
{
    if (section == SettingsSectionBlogs) {
        return NSLocalizedString(@"Sites", @"Title label for the user sites in the app settings");
        
    } else if (section == SettingsSectionWpcom) {
        return NSLocalizedString(@"WordPress.com", @"");
        
    } else if (section == SettingsSectionBlogsAdd) {
        return nil;
        
    } else if (section == SettingsSectionMedia) {
        return NSLocalizedString(@"Media", @"Title label for the media settings section in the app settings");
		
    } else if (section == SettingsSectionNotifications) {
        if ([[WordPressComApi sharedApi] hasCredentials] && nil != [[NSUserDefaults standardUserDefaults] objectForKey:kApnsDeviceTokenPrefKey])
            return NSLocalizedString(@"Notifications", @"");
        else
            return nil;
        
    } else if (section == SettingsSectionSounds) {
        return NSLocalizedString(@"Sounds", @"Title label for the sounds section in the app settings.");
        
    } else if (section == SettingsSectionInfo) {
        return NSLocalizedString(@"App Info", @"Title label for the application information section in the app settings");
    }
    
    return nil;
}


- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {    
    cell.textLabel.textAlignment = NSTextAlignmentLeft;
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.accessoryView = nil;
    if (indexPath.section == SettingsSectionBlogs) {
        Blog *blog = [self.resultsController objectAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row inSection:0]];
        if ([blog.blogName length] != 0) {
            cell.textLabel.text = blog.blogName;
        } else {
            cell.textLabel.text = blog.url;
        }
        
        [cell.imageView setImageWithBlavatarUrl:blog.blavatarUrl isWPcom:blog.isWPcom];
        
        if (indexPath.row == 0) {
            [self maskImageView:cell.imageView corner:UIRectCornerTopLeft];
        } else if (indexPath.row == ([self.tableView numberOfRowsInSection:indexPath.section] -1)) {
            [self maskImageView:cell.imageView corner:UIRectCornerBottomLeft];
        } else {
            cell.imageView.layer.mask = NULL;
        }
        
    } else if (indexPath.section == SettingsSectionBlogsAdd) {
        cell.textLabel.text = NSLocalizedString(@"Add a Site", @"");
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
    } else if (indexPath.section == SettingsSectionWpcom) {
        if ([[WordPressComApi sharedApi] hasCredentials]) {
            if (indexPath.row == 0) {
                cell.textLabel.text = NSLocalizedString(@"Username:", @"");
                cell.detailTextLabel.text = [WordPressComApi sharedApi].username;
                cell.detailTextLabel.textColor = [UIColor UIColorFromHex:0x888888];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
            } else {
                cell.textLabel.textAlignment = NSTextAlignmentCenter;
                cell.textLabel.text = NSLocalizedString(@"Sign Out", @"Sign out from WordPress.com");
            }
        } else {
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
            cell.textLabel.text = NSLocalizedString(@"Sign In", @"Sign in to WordPress.com");
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        }
        
    } else if (indexPath.section == SettingsSectionMedia){
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        NSDictionary *dict = [mediaSettingsArray objectAtIndex:indexPath.row];
        cell.textLabel.text = [dict objectForKey:@"Title"];
        NSString *key = [dict objectForKey:@"Key"];
        NSString *currentVal = [[NSUserDefaults standardUserDefaults] objectForKey:key];
        if (currentVal == nil) {
            currentVal = [dict objectForKey:@"DefaultValue"];
        }
        
        NSArray *values = [dict objectForKey:@"Values"];
        NSInteger index = [values indexOfObject:currentVal];
        
        NSArray *titles = [dict objectForKey:@"Titles"];
        cell.detailTextLabel.text = [titles objectAtIndex:index];
        
    } else if(indexPath.section == SettingsSectionSounds) {
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.textLabel.text = NSLocalizedString(@"Enable Sounds", @"Title for the setting to enable in-app sounds");
        UISwitch *aSwitch = [[UISwitch alloc] initWithFrame:CGRectZero]; // Frame is ignored.
        [aSwitch addTarget:self action:@selector(handleMuteSoundsChanged:) forControlEvents:UIControlEventValueChanged];
        aSwitch.on = ![[NSUserDefaults standardUserDefaults] boolForKey:kSettingsMuteSoundsKey];
        cell.accessoryView = aSwitch;

    } else if (indexPath.section == SettingsSectionNotifications) {
        if ([[WordPressComApi sharedApi] hasCredentials] && nil != [[NSUserDefaults standardUserDefaults] objectForKey:kApnsDeviceTokenPrefKey]) {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.text = NSLocalizedString(@"Manage Notifications", @"");
        }
    } else if (indexPath.section == SettingsSectionInfo) {
        if (indexPath.row == 0) {
            // App Version
            cell.textLabel.text = NSLocalizedString(@"Version:", @"");
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
        case SettingsSectionBlogs:
            cellIdentifier = @"BlogCell";
            cellStyle = UITableViewCellStyleSubtitle;
            break;
            
        case SettingsSectionWpcom:
            if ([[WordPressComApi sharedApi] hasCredentials] && indexPath.row == 0) {
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
        
        case SettingsSectionSounds:
            cellIdentifier = @"Sounds";
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self cellForIndexPath:indexPath];
    [WPStyleGuide configureTableViewCell:cell];
    [self configureCell:cell atIndexPath:indexPath];
    
    BOOL isSignInCell = NO;
    if (![[WordPressComApi sharedApi] hasCredentials]) {
        isSignInCell = indexPath.section == SettingsSectionWpcom && indexPath.row == 0;
    }
    
    BOOL isSignOutCell = indexPath.section == SettingsSectionWpcom && indexPath.row == 1;
    BOOL isAddBlogsCell = indexPath.section == SettingsSectionBlogsAdd;
    if (isSignOutCell || isAddBlogsCell || isSignInCell) {
        [WPStyleGuide configureTableViewActionCell:cell];
    }
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return (indexPath.section == SettingsSectionBlogs);
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [WPMobileStats trackEventForWPCom:StatsEventSettingsRemovedBlog];
        
        Blog *blog = [self.resultsController objectAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row inSection:0]];
        [blog remove];
        
        if([[self.resultsController fetchedObjects] count] == 0) {
            [self setEditing:NO];
            self.editButtonItem.enabled = NO;
        }
    }   
}


#pragma mark - 
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == SettingsSectionBlogs) {
        [WPMobileStats trackEventForWPCom:StatsEventSettingsClickedEditBlog];
        
        Blog *blog = [self.resultsController objectAtIndexPath:indexPath];

		EditSiteViewController *editSiteViewController = [[EditSiteViewController alloc] init];
        editSiteViewController.blog = blog;
        [self.navigationController pushViewController:editSiteViewController animated:YES];

    } else if (indexPath.section == SettingsSectionBlogsAdd) {
        [WPMobileStats trackEventForWPCom:StatsEventSettingsClickedAddBlog];
        
        WelcomeViewController *welcomeViewController = [[WelcomeViewController alloc] initWithStyle:UITableViewStyleGrouped];
        welcomeViewController.title = NSLocalizedString(@"Add a Site", nil);
        [self.navigationController pushViewController:welcomeViewController animated:YES];
    } else if (indexPath.section == SettingsSectionWpcom) {
        if ([[WordPressComApi sharedApi] hasCredentials]) {
            if (indexPath.row == 1) {
                [WPMobileStats trackEventForWPCom:StatsEventSettingsClickedSignOutOfDotCom];

                // Present the Sign out ActionSheet
                NSString *signOutTitle = NSLocalizedString(@"You are logged in as %@", @"");
                signOutTitle = [NSString stringWithFormat:signOutTitle, [WordPressComApi sharedApi].username];
                UIActionSheet *actionSheet;
                actionSheet = [[UIActionSheet alloc] initWithTitle:signOutTitle 
                                                          delegate:self 
                                                 cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
                                            destructiveButtonTitle:NSLocalizedString(@"Sign Out", @"")otherButtonTitles:nil, nil ];
                actionSheet.actionSheetStyle = UIActionSheetStyleDefault;
                [actionSheet showInView:self.view];
            }
        } else {
            [WPMobileStats trackEventForWPCom:StatsEventSettingsClickedSignIntoDotCom];
            
            WPcomLoginViewController *loginViewController = [[WPcomLoginViewController alloc] initWithStyle:UITableViewStyleGrouped];
            loginViewController.delegate = self;
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
        
        NSDictionary *dict = [mediaSettingsArray objectAtIndex:indexPath.row];
        SettingsPageViewController *controller = [[SettingsPageViewController alloc] initWithDictionary:dict];
        [self.navigationController pushViewController:controller animated:YES];
    
    } else if (indexPath.section == SettingsSectionNotifications) {
        [WPMobileStats trackEventForWPCom:StatsEventSettingsClickedManageNotifications];
        
        NotificationSettingsViewController *notificationSettingsViewController = [[NotificationSettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
        [self.navigationController pushViewController:notificationSettingsViewController animated:YES];
    } else if (indexPath.section == SettingsSectionSounds) {
        // nothing to do.
        
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
#pragma mark NSFetchedResultsController

- (NSFetchedResultsController *)resultsController {
    if (_resultsController) {
        return _resultsController;
    }

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSManagedObjectContext *moc = [[WordPressAppDelegate sharedWordPressApplicationDelegate] managedObjectContext];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"Blog" inManagedObjectContext:moc]];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"blogName" ascending:YES]]];
    
    // For some reasons, the cache sometimes gets corrupted
    // Since we don't really use sections we skip the cache here
    _resultsController = [[NSFetchedResultsController alloc]
                                                      initWithFetchRequest:fetchRequest
                                                      managedObjectContext:moc
                                                      sectionNameKeyPath:nil
                                                      cacheName:nil];
    _resultsController.delegate = self;

    NSError *error = nil;
    if (![_resultsController performFetch:&error]) {
        WPFLog(@"Couldn't fetch blogs: %@", [error localizedDescription]);
        _resultsController = nil;
    }
    return _resultsController;
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView beginUpdates];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView endUpdates];
    [self checkCloseButton];
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
    
    if (NSFetchedResultsChangeUpdate == type && newIndexPath != nil) {
        // Seriously, Apple?
        // http://developer.apple.com/library/ios/#releasenotes/iPhone/NSFetchedResultsChangeMoveReportedAsNSFetchedResultsChangeUpdate/_index.html
        type = NSFetchedResultsChangeMove;
    }
    
    switch (type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[self.tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [self.tableView deleteRowsAtIndexPaths:[NSArray
                                                    arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView insertRowsAtIndexPaths:[NSArray
                                                    arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}


#pragma mark - 
#pragma mark WPComLoginViewControllerDelegate

- (void)loginController:(WPcomLoginViewController *)loginController didAuthenticateWithAccount:(WPAccount *)account {
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:SettingsSectionWpcom] withRowAnimation:UITableViewRowAnimationFade];
    AddUsersBlogsViewController *addUsersBlogsView = [[AddUsersBlogsViewController alloc] initWithAccount:[WPAccount defaultWordPressComAccount]];
    addUsersBlogsView.isWPcom = YES;
    [self.navigationController pushViewController:addUsersBlogsView animated:YES];

    [self checkCloseButton];
}


- (void)loginControllerDidDismiss:(WPcomLoginViewController *)loginController {
    [self.navigationController popToRootViewControllerAnimated:YES];
}


#pragma mark -
#pragma mark Action Sheet Delegate Methods

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if(buttonIndex == 0) {
        [WPMobileStats trackEventForWPCom:StatsEventSettingsSignedOutOfDotCom];
        
        // Sign out
        [[WordPressComApi sharedApi] signOut]; //Signout first, then remove the account
		[WPAccount removeDefaultWordPressComAccount];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:SettingsSectionWpcom] withRowAnimation:UITableViewRowAnimationFade];
        [self checkCloseButton];
    }
}

@end
