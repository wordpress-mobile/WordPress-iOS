#import "SiteSettingsViewController.h"
#import "NSURL+IDN.h"
#import "SupportViewController.h"
#import "WPWebViewController.h"
#import "ReachabilityUtils.h"
#import "WPAccount.h"
#import "Blog.h"
#import "WPTableViewSectionHeaderFooterView.h"
#import "SettingTableViewCell.h"
#import "NotificationsManager.h"
#import <SVProgressHUD/SVProgressHUD.h>
#import "NotificationsManager.h"
#import "AccountService.h"
#import "ContextManager.h"
#import <WPXMLRPC/WPXMLRPC.h>
#import "BlogService.h"
#import "WPTextFieldTableViewCell.h"
#import "SettingsTextViewController.h"
#import "SettingsMultiTextViewController.h"
#import "WPGUIConstants.h"
#import "PostCategoryService.h"
#import "PostCategory.h"
#import "PostCategoriesViewController.h"
#import "SettingsSelectionViewController.h"
#import "BlogSiteVisibilityHelper.h"
#import "RelatedPostsSettingsViewController.h"
#import "WordPress-Swift.h"
#import <WordPressApi/WordPressApi.h>


NS_ENUM(NSInteger, SiteSettingsGeneral) {
    SiteSettingsGeneralTitle = 0,
    SiteSettingsGeneralTagline,
    SiteSettingsGeneralURL,
    SiteSettingsGeneralPrivacy,
    SiteSettingsGeneralCount,
};

NS_ENUM(NSInteger, SiteSettingsAccount) {
    SiteSettingsAccountUsername = 0,
    SiteSettingsAccountPassword,
    SiteSettingsAccountCount,
};

NS_ENUM(NSInteger, SiteSettingsWriting) {
    SiteSettingsWritingDefaultCategory= 0,
    SiteSettingsWritingDefaultPostFormat,
    SiteSettingsWritingRelatedPosts,
    SiteSettingsWritingCount,
};

NS_ENUM(NSInteger, SiteSettingsDevice) {
    SiteSettingsDeviceGeotagging = 0,
    SiteSettingsDeviceCount
};

NS_ENUM(NSInteger, SiteSettingsAdvanced) {
    SiteSettingsAdvancedStartOver = 0,
    SiteSettingsAdvancedDeleteSite,
    SiteSettingsAdvancedCount,
};

NS_ENUM(NSInteger, SiteSettingsSection) {
    SiteSettingsSectionGeneral = 0,
    SiteSettingsSectionAccount,
    SiteSettingsSectionWriting,
    SiteSettingsSectionDiscussion,
    SiteSettingsSectionDevice,
    SiteSettingsSectionRemoveSite,
    SiteSettingsSectionAdvanced,
};


@interface SiteSettingsViewController () <UITableViewDelegate, UITextFieldDelegate, PostCategoriesViewControllerDelegate>

@property (nonatomic, strong) NSArray *tableSections;
#pragma mark - General Section
@property (nonatomic, strong) SettingTableViewCell *siteTitleCell;
@property (nonatomic, strong) SettingTableViewCell *siteTaglineCell;
@property (nonatomic, strong) SettingTableViewCell *addressTextCell;
@property (nonatomic, strong) SettingTableViewCell *privacyTextCell;
#pragma mark - Account Section
@property (nonatomic, strong) SettingTableViewCell *usernameTextCell;
@property (nonatomic, strong) SettingTableViewCell *passwordTextCell;
#pragma mark - Writing Section
@property (nonatomic, strong) SettingTableViewCell *defaultCategoryCell;
@property (nonatomic, strong) SettingTableViewCell *defaultPostFormatCell;
@property (nonatomic, strong) SettingTableViewCell *relatedPostsCell;
#pragma mark - Discussion Section
@property (nonatomic, strong) SettingTableViewCell *discussionSettingsCell;
#pragma mark - Device Section
@property (nonatomic, strong) SwitchTableViewCell *geotaggingCell;
#pragma mark - Removal Section
@property (nonatomic, strong) UITableViewCell *removeSiteCell;
#pragma mark - Advanced Section
@property (nonatomic, strong) SettingTableViewCell *startOverCell;
@property (nonatomic, strong) SettingTableViewCell *deleteSiteCell;

@property (nonatomic, strong) Blog *blog;
@property (nonatomic, strong) NSString *url;
@property (nonatomic, strong) NSString *authToken;
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *password;
@property (nonatomic, assign) BOOL geolocationEnabled;
@end

@implementation SiteSettingsViewController

- (instancetype)initWithBlog:(Blog *)blog
{
    NSParameterAssert([blog isKindOfClass:[Blog class]]);
    
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        _blog = blog;
    }
    return self;
}

- (void)dealloc
{
    self.delegate = nil;
}

- (void)viewDidLoad
{
    DDLogMethod();
    [super viewDidLoad];
    self.navigationItem.title = NSLocalizedString(@"Settings", @"Title for screen that allows configuration of your blog/site settings.");
    
    NSMutableArray *sections = [NSMutableArray arrayWithObjects:@(SiteSettingsSectionGeneral), nil];
    
    if (!self.blog.account) {
        [sections addObject:@(SiteSettingsSectionAccount)];
    }
    
    if ([self.blog supports:BlogFeatureWPComRESTAPI] && self.blog.isAdmin) {
        // only REST API connections and admins can change Writing options
        [sections addObject:@(SiteSettingsSectionWriting)];
    }
    
    if ([self.blog supports:BlogFeatureWPComRESTAPI]) {
        [sections addObject:@(SiteSettingsSectionDiscussion)];
    }
    
    [sections addObject:@(SiteSettingsSectionDevice)];
    
    if ([self.blog supports:BlogFeatureRemovable]) {
        [sections addObject:@(SiteSettingsSectionRemoveSite)];
    }

    if ([self.blog supports:BlogFeatureSiteManagement]) {
        [sections addObject:@(SiteSettingsSectionAdvanced)];
    }

    self.tableSections = sections;
    
    [WPStyleGuide resetReadableMarginsForTableView:self.tableView];
    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refreshTriggered:) forControlEvents:UIControlEventValueChanged];
    
    self.url = self.blog.url;
    self.authToken = self.blog.authToken;
    self.username = self.blog.usernameForSite;
    self.password = self.blog.password;
    self.geolocationEnabled = self.blog.settings.geolocationEnabled;
    
    [self refreshData];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:animated];
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [self.tableView reloadData];
    [super viewDidAppear:animated];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.tableSections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger settingsSection = [self.tableSections[section] intValue];
    switch (settingsSection) {
        case SiteSettingsSectionGeneral: {
            NSInteger rowsToHide = 0;
            if (![self.blog supports:BlogFeatureWPComRESTAPI]) {
                //  NOTE: Sergio Estevao (2015-08-25): Hides the privacy setting for self-hosted sites not in jetpack 
                // because XML-RPC doens't support this setting to be read or changed.
                rowsToHide += 1;
            }
            return SiteSettingsGeneralCount - rowsToHide;
        }
        case SiteSettingsSectionAccount: {
            return SiteSettingsAccountCount;
        }
        case SiteSettingsSectionWriting: {
            return SiteSettingsWritingCount;
        }
        case SiteSettingsSectionDiscussion: {
            return 1;
        }
        case SiteSettingsSectionDevice: {
            return SiteSettingsDeviceCount;
        }
        case SiteSettingsSectionRemoveSite: {
            return 1;
        }
        case SiteSettingsSectionAdvanced: {
            return SiteSettingsAdvancedCount;
        }
    }
    return 0;
}

- (SettingTableViewCell *)usernameTextCell
{
    if (_usernameTextCell){
        return _usernameTextCell;
    }
    _usernameTextCell = [[SettingTableViewCell alloc] initWithLabel:NSLocalizedString(@"Username", @"Label for entering username in the username field")
                                                           editable:NO
                                                    reuseIdentifier:nil];
    return _usernameTextCell;
}

- (SettingTableViewCell *)passwordTextCell
{
    if (_passwordTextCell) {
        return _passwordTextCell;
    }
    _passwordTextCell = [[SettingTableViewCell alloc] initWithLabel:NSLocalizedString(@"Password", @"Label for entering password in password field")
                                                           editable:YES
                                                    reuseIdentifier:nil];
    return _passwordTextCell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForAccountSettingsInRow:(NSInteger)row
{
    switch (row) {
        case SiteSettingsAccountUsername: {
            if (self.blog.usernameForSite) {
                [self.usernameTextCell setTextValue:self.blog.usernameForSite];
            } else {
                [self.usernameTextCell setTextValue:NSLocalizedString(@"Enter username", @"(placeholder) Help enter WordPress username")];
            }
            return self.usernameTextCell;
        }
        break;
        case SiteSettingsAccountPassword: {
            if (self.blog.password) {
                [self.passwordTextCell setTextValue:@"••••••••"];
            } else {
                [self.passwordTextCell setTextValue:NSLocalizedString(@"Enter password", @"(placeholder) Help enter WordPress password")];
            }
            return self.passwordTextCell;
        }
        break;
    }
    return nil;
}

- (SwitchTableViewCell *)geotaggingCell
{
    if (_geotaggingCell) {
        return _geotaggingCell;
    }
    _geotaggingCell = [SwitchTableViewCell new];
    _geotaggingCell.name = NSLocalizedString(@"Geotagging", @"Enables geotagging in blog settings (short label)");
    _geotaggingCell.on = self.geolocationEnabled;
    __weak SiteSettingsViewController *weakSelf = self;
    _geotaggingCell.onChange = ^(BOOL value){
        [weakSelf toggleGeolocation:value];
    };
    return _geotaggingCell;
}

- (SettingTableViewCell *)defaultCategoryCell
{
    if (_defaultCategoryCell){
        return _defaultCategoryCell;
    }
    _defaultCategoryCell = [[SettingTableViewCell alloc] initWithLabel:NSLocalizedString(@"Default Category", @"Label for selecting the default category of a post")
                                                              editable:YES
                                                       reuseIdentifier:nil];
    return _defaultCategoryCell;
}

- (SettingTableViewCell *)defaultPostFormatCell
{
    if (_defaultPostFormatCell){
        return _defaultPostFormatCell;
    }
    _defaultPostFormatCell = [[SettingTableViewCell alloc] initWithLabel:NSLocalizedString(@"Default Post Format", @"Label for selecting the default post format")
                                                                editable:YES
                                                         reuseIdentifier:nil];
    return _defaultPostFormatCell;
}

- (SettingTableViewCell *)relatedPostsCell
{
    if (_relatedPostsCell){
        return _relatedPostsCell;
    }
    _relatedPostsCell = [[SettingTableViewCell alloc] initWithLabel:NSLocalizedString(@"Related Posts", @"Label for selecting the related posts options")
                                                           editable:YES
                                                    reuseIdentifier:nil];
    return _relatedPostsCell;
}

- (SettingTableViewCell *)discussionSettingsCell
{
    if (_discussionSettingsCell) {
        return _discussionSettingsCell;
    }
    
    _discussionSettingsCell = [[SettingTableViewCell alloc] initWithLabel:NSLocalizedString(@"Discussion", @"Label for selecting the Blog Discussion Settings section")
                                                                 editable:YES
                                                          reuseIdentifier:nil];
    return _discussionSettingsCell;
}

- (UITableViewCell *)removeSiteCell
{
    if (_removeSiteCell) {
        return _removeSiteCell;
    }
    _removeSiteCell = [[WPTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    [WPStyleGuide configureTableViewDestructiveActionCell:_removeSiteCell];
    _removeSiteCell.textLabel.text = NSLocalizedString(@"Remove Site", @"Button to remove a site from the app");
    
    return _removeSiteCell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForWritingSettingsAtRow:(NSInteger)row
{
    switch (row) {
        case (SiteSettingsWritingDefaultCategory):{
            PostCategoryService *postCategoryService = [[PostCategoryService alloc] initWithManagedObjectContext:[[ContextManager sharedInstance] mainContext]];
            PostCategory *postCategory = [postCategoryService findWithBlogObjectID:self.blog.objectID andCategoryID:self.blog.settings.defaultCategoryID];
            [self.defaultCategoryCell setTextValue:[postCategory categoryName]];
            return self.defaultCategoryCell;
        }
        break;
        case (SiteSettingsWritingDefaultPostFormat):{
            [self.defaultPostFormatCell setTextValue:self.blog.defaultPostFormatText];
            return self.defaultPostFormatCell;
        }
        case (SiteSettingsWritingRelatedPosts):{
            return self.relatedPostsCell;
        }
        break;

    }
    return nil;
}

- (SettingTableViewCell *)siteTitleCell
{
    if (_siteTitleCell) {
        return _siteTitleCell;
    }
    _siteTitleCell = [[SettingTableViewCell alloc] initWithLabel:NSLocalizedString(@"Site Title", @"Label for site title blog setting")
                                                          editable:self.blog.isAdmin
                                                   reuseIdentifier:nil];
    return _siteTitleCell;
}

- (SettingTableViewCell *)siteTaglineCell
{
    if (_siteTaglineCell) {
        return _siteTaglineCell;
    }
    _siteTaglineCell = [[SettingTableViewCell alloc] initWithLabel:NSLocalizedString(@"Tagline", @"Label for tagline blog setting")
                                                          editable:self.blog.isAdmin
                                                   reuseIdentifier:nil];
    return _siteTaglineCell;
}

- (SettingTableViewCell *)addressTextCell
{
    if (_addressTextCell) {
        return _addressTextCell;
    }
    _addressTextCell = [[SettingTableViewCell alloc] initWithLabel:NSLocalizedString(@"Address", @"Label for url blog setting")
                                                          editable:NO
                                                   reuseIdentifier:nil];
    return _addressTextCell;
}

- (SettingTableViewCell *)privacyTextCell
{
    if (_privacyTextCell) {
        return _privacyTextCell;
    }
    _privacyTextCell = [[SettingTableViewCell alloc] initWithLabel:NSLocalizedString(@"Privacy", @"Label for the privacy setting")
                                                          editable:self.blog.isAdmin
                                                   reuseIdentifier:nil];
    return _privacyTextCell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForGeneralSettingsInRow:(NSInteger)row
{
    switch (row) {
        case SiteSettingsGeneralTitle: {
            NSString *name = self.blog.settings.name ?: NSLocalizedString(@"A title for the site", @"Placeholder text for the title of a site");
            [self.siteTitleCell setTextValue:name];
            return self.siteTitleCell;
        } break;
        case SiteSettingsGeneralTagline: {
            NSString *tagline = self.blog.settings.tagline ?: NSLocalizedString(@"Explain what this site is about.", @"Placeholder text for the tagline of a site");
            [self.siteTaglineCell setTextValue:tagline];
            return self.siteTaglineCell;
        } break;
        case SiteSettingsGeneralURL: {
            if (self.blog.url) {
                [self.addressTextCell setTextValue:self.blog.url];
            } else {
                [self.addressTextCell setTextValue:NSLocalizedString(@"http://my-site-address (URL)", @"(placeholder) Help the user enter a URL into the field")];
            }
            return self.addressTextCell;
        } break;
        case SiteSettingsGeneralPrivacy: {
            [self.privacyTextCell setTextValue:[BlogSiteVisibilityHelper titleForCurrentSiteVisibilityOfBlog:self.blog]];
            return self.privacyTextCell;
        } break;
    }
    return [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"NoCell"];
}

- (SettingTableViewCell *)startOverCell
{
    if (_startOverCell) {
        return _startOverCell;
    }
    
    _startOverCell = [[SettingTableViewCell alloc] initWithLabel:NSLocalizedString(@"Start Over", @"Label for selecting the Start Over Settings item")
                                                        editable:YES
                                                 reuseIdentifier:nil];
    return _startOverCell;
}

- (SettingTableViewCell *)deleteSiteCell
{
    if (_deleteSiteCell) {
        return _deleteSiteCell;
    }
    
    _deleteSiteCell = [[SettingTableViewCell alloc] initWithLabel:NSLocalizedString(@"Delete Site", @"Label for selecting the Delete Site Settings item")
                                                         editable:YES
                                                  reuseIdentifier:nil];
    return _deleteSiteCell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForAdvancedSettingsAtRow:(NSInteger)row
{
    switch (row) {
        case SiteSettingsAdvancedStartOver: {
            return self.startOverCell;
        } break;
        case SiteSettingsAdvancedDeleteSite: {
            return self.deleteSiteCell;
        } break;
    }

    NSAssert(false, @"Missing Advanced section cell");
    return [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"NoCell"];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger settingsSection = [self.tableSections[indexPath.section] intValue];
    switch (settingsSection) {
        case SiteSettingsSectionGeneral: {
            return [self tableView:tableView cellForGeneralSettingsInRow:indexPath.row];
        }
        case SiteSettingsSectionAccount: {
            return [self tableView:tableView cellForAccountSettingsInRow:indexPath.row];
        }
        case SiteSettingsSectionWriting: {
            return [self tableView:tableView cellForWritingSettingsAtRow:indexPath.row];
        }
        case SiteSettingsSectionDiscussion: {
            return self.discussionSettingsCell;
        }
        case SiteSettingsSectionDevice: {
            return self.geotaggingCell;
        }
        case SiteSettingsSectionRemoveSite: {
            return self.removeSiteCell;
        }
        case SiteSettingsSectionAdvanced: {
            return [self tableView:tableView cellForAdvancedSettingsAtRow:indexPath.row];
        }
    }

    NSAssert(false, @"Missing section handler");
    return nil;
}

#pragma mark - UITableViewDelegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSInteger settingsSection = [self.tableSections[section] intValue];
    NSString *title = [self titleForHeaderInSection:settingsSection];
    if (title.length == 0) {
        return [UIView new];
    }
    
    WPTableViewSectionHeaderFooterView *header = [[WPTableViewSectionHeaderFooterView alloc] initWithReuseIdentifier:nil style:WPTableViewSectionStyleHeader];
    header.title = title;
    return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return WPTableViewDefaultRowHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    NSInteger settingsSection = [self.tableSections[section] intValue];
    NSString *title = [self titleForHeaderInSection:settingsSection];
    return [WPTableViewSectionHeaderFooterView heightForHeader:title width:CGRectGetWidth(self.view.bounds)];
}

- (NSString *)titleForHeaderInSection:(NSInteger)section
{
    NSString *headingTitle = nil;
    switch (section) {
        case SiteSettingsSectionGeneral:
            headingTitle = NSLocalizedString(@"General", @"Title for the general section in site settings screen");
            break;
        case SiteSettingsSectionAccount:
            headingTitle = NSLocalizedString(@"Account", @"Title for the account section in site settings screen");
            break;
        case SiteSettingsSectionDevice:
            headingTitle = NSLocalizedString(@"This Device", @"Title for the device section in site settings screen");
            break;
        case SiteSettingsSectionWriting:
            headingTitle = NSLocalizedString(@"Writing", @"Title for the writing section in site settings screen");
            break;
        case SiteSettingsSectionAdvanced:
            headingTitle = NSLocalizedString(@"Advanced", @"Title for the advanced section in site settings screen");
            break;
    }
    return headingTitle;
}

- (void)showPrivacySelector
{
    NSArray *values = [BlogSiteVisibilityHelper siteVisibilityValuesForBlog:self.blog];
    NSArray *titles = [BlogSiteVisibilityHelper titlesForSiteVisibilityValues:values];
    NSArray *hints  = [BlogSiteVisibilityHelper hintsForSiteVisibilityValues:values];
   
    NSNumber *currentPrivacy = @(self.blog.siteVisibility);
    if (!currentPrivacy) {
        currentPrivacy = [values firstObject];
    }
    
    NSDictionary *settingsSelectionConfiguration = @{
                                      SettingsSelectionDefaultValueKey   : [values firstObject],
                                      SettingsSelectionTitleKey          : NSLocalizedString(@"Privacy", @"Title for screen to select the privacy options for a blog"),
                                      SettingsSelectionTitlesKey         : titles,
                                      SettingsSelectionValuesKey         : values,
                                      SettingsSelectionCurrentValueKey   : currentPrivacy,
                                      SettingsSelectionHintsKey          : hints
                                      };
    
    SettingsSelectionViewController *vc = [[SettingsSelectionViewController alloc] initWithDictionary:settingsSelectionConfiguration];
    __weak __typeof__(self) weakSelf = self;
    vc.onItemSelected = ^(NSNumber *status) {
        // Check if the object passed is indeed an NSString, otherwise we don't want to try to set it as the post format
        if ([status isKindOfClass:[NSNumber class]]) {
            SiteVisibility newSiteVisibility = (SiteVisibility)[status integerValue];
            if (weakSelf.blog.siteVisibility != newSiteVisibility) {
                weakSelf.blog.siteVisibility = newSiteVisibility;
                [weakSelf saveSettings];
            }
        }
    };
    
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)tableView:(UITableView *)tableView didSelectInGeneralSectionRow:(NSInteger)row
{
    switch (row) {
        case SiteSettingsGeneralTitle:{
            if (!self.blog.isAdmin) {
                return;
            }
            SettingsTextViewController *siteTitleViewController = [[SettingsTextViewController alloc] initWithText:self.blog.settings.name
                                                                                                       placeholder:NSLocalizedString(@"A title for the site", @"Placeholder text for the title of a site")
                                                                                                              hint:@""
                                                                                                        isPassword:NO];
            siteTitleViewController.title = NSLocalizedString(@"Site Title", @"Title for screen that show site title editor");
            siteTitleViewController.onValueChanged = ^(NSString *value) {
                self.siteTitleCell.detailTextLabel.text = value;
                if (![value isEqualToString:self.blog.settings.name]){
                    self.blog.settings.name = value;
                    [self saveSettings];
                }
            };
            [self.navigationController pushViewController:siteTitleViewController animated:YES];
        }break;
        case SiteSettingsGeneralTagline:{
            if (!self.blog.isAdmin) {
                return;
            }
            SettingsMultiTextViewController *siteTaglineViewController = [[SettingsMultiTextViewController alloc] initWithText:self.blog.settings.tagline
                                                                                                                   placeholder:NSLocalizedString(@"Explain what this site is about.", @"Placeholder text for the tagline of a site")
                                                                                                                          hint:NSLocalizedString(@"In a few words, explain what this site is about.",@"Explain what is the purpose of the tagline")
                                                                                                                    isPassword:NO];
            siteTaglineViewController.title = NSLocalizedString(@"Tagline", @"Title for screen that show tagline editor");
            siteTaglineViewController.onValueChanged = ^(NSString *value) {
                NSString *normalizedTagline = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                self.siteTaglineCell.detailTextLabel.text = normalizedTagline;
                if (![normalizedTagline isEqualToString:self.blog.settings.tagline]){
                    self.blog.settings.tagline = normalizedTagline;
                    [self saveSettings];
                }
            };
            [self.navigationController pushViewController:siteTaglineViewController animated:YES];
        }break;
        case SiteSettingsGeneralPrivacy:{
            if (!self.blog.isAdmin) {
                return;
            }
            [self showPrivacySelector];
        }break;
    }
}

- (void)tableView:(UITableView *)tableView didSelectInAccountSectionRow:(NSInteger)row
{
    switch (row) {
        case SiteSettingsAccountPassword:{
            SettingsTextViewController *siteTitleViewController = [[SettingsTextViewController alloc] initWithText:self.blog.password
                                                                                                       placeholder:NSLocalizedString(@"Enter password", @"(placeholder) Help enter WordPress password")
                                                                                                              hint:@""
                                                                                                        isPassword:YES];
            siteTitleViewController.title = NSLocalizedString(@"Password", @"Title for screen that shows self hosted password editor.");
            siteTitleViewController.onValueChanged = ^(id value) {
                if (![value isEqualToString:self.blog.password]) {
                    [self.navigationItem setHidesBackButton:YES animated:YES];
                    self.password = value;
                    [self validateLoginCredentials];
                }
            };
            [self.navigationController pushViewController:siteTitleViewController animated:YES];
        }break;
    }
}

- (void)showPostFormatSelector
{
    NSArray *titles = self.blog.sortedPostFormatNames;
    NSArray *formats = self.blog.sortedPostFormats;
    if (titles.count == 0 || self.blog.defaultPostFormatText == nil) {
        return;
    }
    NSString *currentDefaultPostFormat = self.blog.settings.defaultPostFormat;
    if (!currentDefaultPostFormat) {
        currentDefaultPostFormat = formats[0];
    }
    NSDictionary *postFormatsDict = @{
                                      SettingsSelectionDefaultValueKey   : [formats firstObject],
                                      SettingsSelectionTitleKey          : NSLocalizedString(@"Default Post Format", @"Title for screen to select a default post format for a blog"),
                                      SettingsSelectionTitlesKey         : titles,
                                      SettingsSelectionValuesKey         : formats,
                                      SettingsSelectionCurrentValueKey   : currentDefaultPostFormat
                                      };
    
    SettingsSelectionViewController *vc = [[SettingsSelectionViewController alloc] initWithDictionary:postFormatsDict];
    __weak __typeof__(self) weakSelf = self;
    vc.onItemSelected = ^(NSString *status) {
        // Check if the object passed is indeed an NSString, otherwise we don't want to try to set it as the post format
        if ([status isKindOfClass:[NSString class]]) {
            if (weakSelf.blog.settings.defaultPostFormat != status) {
                weakSelf.blog.settings.defaultPostFormat = status;
                [weakSelf saveSettings];
            }
        }
    };
    
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)showRelatedPostsSettings
{
    RelatedPostsSettingsViewController *relatedPostsViewController = [[RelatedPostsSettingsViewController alloc] initWithBlog:self.blog];
    
    [self.navigationController pushViewController:relatedPostsViewController animated:YES];
}

- (void)tableView:(UITableView *)tableView didSelectInWritingSectionRow:(NSInteger)row
{
    switch (row) {
        case SiteSettingsWritingDefaultCategory:{
            PostCategoryService *postCategoryService = [[PostCategoryService alloc] initWithManagedObjectContext:[[ContextManager sharedInstance] mainContext]];
            NSNumber *defaultCategoryID = self.blog.settings.defaultCategoryID ?: @(PostCategoryUncategorized);
            PostCategory *postCategory = [postCategoryService findWithBlogObjectID:self.blog.objectID andCategoryID:defaultCategoryID];
            NSArray *currentSelection = @[];
            if (postCategory){
                currentSelection = @[postCategory];
            }
            PostCategoriesViewController *postCategoriesViewController = [[PostCategoriesViewController alloc] initWithBlog:self.blog
                                                                                                           currentSelection:currentSelection
                                                                                                              selectionMode:CategoriesSelectionModeBlogDefault];
            postCategoriesViewController.delegate = self;
            [self.navigationController pushViewController:postCategoriesViewController animated:YES];
        }
        break;
        case SiteSettingsWritingDefaultPostFormat:{
            [self showPostFormatSelector];
        }
        break;
        case SiteSettingsWritingRelatedPosts:{
            [self showRelatedPostsSettings];
        }
        break;

    }
}

- (void)showStartOverForBlog:(Blog *)blog
{
    NSParameterAssert([blog supportsSiteManagementServices]);

    StartOverViewController *viewController = [[StartOverViewController alloc] initWithBlog:blog];
    [self.navigationController pushViewController:viewController animated:YES];
}

- (void)showDeleteSiteForBlog:(Blog *)blog
{
    NSParameterAssert([blog supportsSiteManagementServices]);
    
    DeleteSiteViewController *viewController = [[DeleteSiteViewController alloc] initWithBlog:blog];
    [self.navigationController pushViewController:viewController animated:YES];
}

- (void)tableView:(UITableView *)tableView didSelectInAdvancedSectionRow:(NSInteger)row
{
    switch (row) {
        case SiteSettingsAdvancedStartOver: {
            [self showStartOverForBlog:self.blog];
        } break;
        case SiteSettingsAdvancedDeleteSite: {
            [self showDeleteSiteForBlog:self.blog];
        } break;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger settingsSection = [self.tableSections[indexPath.section] intValue];
    switch (settingsSection) {
        case SiteSettingsSectionGeneral: {
            [self tableView:tableView didSelectInGeneralSectionRow:indexPath.row];
        } break;
        case SiteSettingsSectionAccount: {
            [self tableView:tableView didSelectInAccountSectionRow:indexPath.row];
        } break;
        case SiteSettingsSectionWriting: {
            [self tableView:tableView didSelectInWritingSectionRow:indexPath.row];
        } break;
        case SiteSettingsSectionDiscussion: {
            [self showDiscussionSettingsForBlog:self.blog];
        } break;
        case SiteSettingsSectionRemoveSite:{
            [tableView deselectSelectedRowWithAnimation:YES];
            [self showRemoveSiteForBlog:self.blog];
        } break;
        case SiteSettingsSectionAdvanced:{
            [self tableView:tableView didSelectInAdvancedSectionRow:indexPath.row];
        } break;
    }
}

#pragma mark - Custom methods

- (IBAction)refreshTriggered:(id)sender
{
    [self refreshData];
}

- (void)refreshData
{
    __weak __typeof__(self) weakSelf = self;
    NSManagedObjectContext *mainContext = [[ContextManager sharedInstance] mainContext];
    BlogService *service = [[BlogService alloc] initWithManagedObjectContext:mainContext];

    [service syncSettingsForBlog:self.blog success:^{
        [weakSelf.refreshControl endRefreshing];
        [weakSelf.tableView reloadData];
    } failure:^(NSError *error) {
        [weakSelf.refreshControl endRefreshing];
    }];
    
}

- (void)toggleGeolocation:(BOOL)value
{
    self.geolocationEnabled = value;

    // Save the change
    self.blog.settings.geolocationEnabled = self.geolocationEnabled;
    [[ContextManager sharedInstance] saveContext:self.blog.managedObjectContext];
}


#pragma mark - Authentication methods

- (NSString *)getURLToValidate
{
    NSString *urlToValidate = self.blog.url;
    
    if (![urlToValidate hasPrefix:@"http"]) {
        urlToValidate = [NSString stringWithFormat:@"http://%@", urlToValidate];
    }
    
    NSError *error = nil;
    
    NSRegularExpression *wplogin = [NSRegularExpression regularExpressionWithPattern:@"/wp-login.php$" options:NSRegularExpressionCaseInsensitive error:&error];
    NSRegularExpression *wpadmin = [NSRegularExpression regularExpressionWithPattern:@"/wp-admin/?$" options:NSRegularExpressionCaseInsensitive error:&error];
    NSRegularExpression *trailingslash = [NSRegularExpression regularExpressionWithPattern:@"/?$" options:NSRegularExpressionCaseInsensitive error:&error];
    
    urlToValidate = [wplogin stringByReplacingMatchesInString:urlToValidate options:0 range:NSMakeRange(0, [urlToValidate length]) withTemplate:@""];
    urlToValidate = [wpadmin stringByReplacingMatchesInString:urlToValidate options:0 range:NSMakeRange(0, [urlToValidate length]) withTemplate:@""];
    urlToValidate = [trailingslash stringByReplacingMatchesInString:urlToValidate options:0 range:NSMakeRange(0, [urlToValidate length]) withTemplate:@""];
    
    return urlToValidate;
}

- (void)validateLoginCredentials
{
    [SVProgressHUD showWithStatus:NSLocalizedString(@"Authenticating", @"") maskType:SVProgressHUDMaskTypeBlack];

    NSURL *xmlRpcURL = [NSURL URLWithString:self.blog.xmlrpc];
    WordPressXMLRPCApi *api = [WordPressXMLRPCApi apiWithXMLRPCEndpoint:xmlRpcURL
                                                               username:self.username
                                                               password:self.password];
    __weak __typeof__(self) weakSelf = self;
    [api getBlogOptionsWithSuccess:^(id options){
        [SVProgressHUD dismiss];
        __typeof__(self) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:strongSelf.blog.managedObjectContext];
        [blogService updatePassword:strongSelf.password forBlog:strongSelf.blog];
        [strongSelf.navigationItem setHidesBackButton:NO animated:NO];
    } failure:^(NSError *error){
        [SVProgressHUD dismiss];
        [weakSelf loginValidationFailedWithError:error];
    }];
}


- (void)loginValidationFailedWithError:(NSError *)error
{
    [self.navigationItem setHidesBackButton:NO animated:NO];
    self.password = self.blog.password;    
    if (error) {
        NSString *message;
        if (error.code == 403) {
            message = NSLocalizedString(@"Please try entering your login details again.", @"");
        } else {
            message = [error localizedDescription];
        }
        if (error.code == 405) {
            [WPError showAlertWithTitle:NSLocalizedString(@"Sorry, can't log in", @"")
                                message:message
                      withSupportButton:YES
                         okPressedBlock:^(UIAlertController *alertView) {
                [self openSiteAdminFromAlert:alertView];
            }];

        } else {
            [WPError showAlertWithTitle:NSLocalizedString(@"Sorry, can't log in", @"") message:message];
        }
    }
}

- (void)openSiteAdminFromAlert:(UIAlertController *)alertView
{
    NSString *path = nil;
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"http\\S+writing.php" options:NSRegularExpressionCaseInsensitive error:&error];
    NSString *msg = [alertView message];
    NSRange rng = [regex rangeOfFirstMatchInString:msg options:0 range:NSMakeRange(0, [msg length])];

    if (rng.location == NSNotFound) {
        path = [self getURLToValidate];
        path = [path stringByReplacingOccurrencesOfString:@"xmlrpc.php" withString:@""];
        path = [path stringByAppendingFormat:@"/wp-admin/options-writing.php"];
    } else {
        path = [msg substringWithRange:rng];
    }

    NSURL *targetURL = [NSURL URLWithString:path];
    WPWebViewController *webViewController = [WPWebViewController webViewControllerWithURL:targetURL];
    webViewController.authToken = self.authToken;
    webViewController.username = self.username;
    webViewController.password = self.password;
    webViewController.wpLoginURL = [NSURL URLWithString:self.blog.loginUrl];
    webViewController.shouldScrollToBottom = YES;
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:webViewController];
    [self presentViewController:navController animated:YES completion:nil];
}

#pragma mark - Saving methods

- (void)saveSettings
{
    if (!self.blog.settings.hasChanges) {
        return;
    }
    
    BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:self.blog.managedObjectContext];
    [blogService updateSettingsForBlog:self.blog success:nil failure:^(NSError *error) {
        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Settings update failed", @"Message to show when setting save failed")];
        DDLogError(@"Error while trying to update BlogSettings: %@", error);
    }];
}

- (IBAction)cancel:(id)sender
{
    if (self.isCancellable) {
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        [self.navigationController popToRootViewControllerAnimated:YES];
    }

    if (self.delegate) {
        // If sender is not nil then the user tapped the cancel button.
        BOOL wascancelled = (sender != nil);
        [self.delegate controllerDidDismiss:self cancelled:wascancelled];
    }
}



#pragma mark - Discussion

- (void)showDiscussionSettingsForBlog:(Blog *)blog
{
    NSParameterAssert(blog);
    
    DiscussionSettingsViewController *settings = [[DiscussionSettingsViewController alloc] initWithBlog:blog];
    [self.navigationController pushViewController:settings animated:YES];
}


#pragma mark - Remove Site

- (void)showRemoveSiteForBlog:(Blog *)blog
{
    NSParameterAssert(blog);
    
    NSString *model = [[UIDevice currentDevice] localizedModel];
    NSString *message = [NSString stringWithFormat:NSLocalizedString(@"Are you sure you want to continue?\n All site data will be removed from your %@.", @"Title for the remove site confirmation alert, %@ will be replaced with iPhone/iPad/iPod Touch"), model];
    NSString *cancelTitle = NSLocalizedString(@"Cancel", nil);
    NSString *destructiveTitle = NSLocalizedString(@"Remove Site", @"Button to remove a site from the app");
    
    UIAlertControllerStyle alertStyle = [UIDevice isPad] ? UIAlertControllerStyleAlert : UIAlertControllerStyleActionSheet;
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil
                                                                             message:message
                                                                      preferredStyle:alertStyle];
    
    [alertController addCancelActionWithTitle:cancelTitle handler:nil];
    [alertController addDestructiveActionWithTitle:destructiveTitle handler:^(UIAlertAction *action) {
        [self confirmRemoveSite:blog];
    }];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)confirmRemoveSite:(Blog *)blog
{
    NSParameterAssert(blog);
    
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:context];
    [blogService removeBlog:blog];
    [self.navigationController popToRootViewControllerAnimated:YES];
}


#pragma mark - PostCategoriesViewControllerDelegate

- (void)postCategoriesViewController:(PostCategoriesViewController *)controller
                   didSelectCategory:(PostCategory *)category
{
    self.blog.settings.defaultCategoryID = category.categoryID;
    self.defaultCategoryCell.detailTextLabel.text = category.categoryName;
    [self saveSettings];
}

@end
