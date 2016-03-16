#import "SiteSettingsViewController.h"

#import "Blog.h"
#import "BlogService.h"
#import "BlogSiteVisibilityHelper.h"
#import "ContextManager.h"
#import "NSURL+IDN.h"
#import "PostCategory.h"
#import "PostCategoryService.h"
#import "PostCategoriesViewController.h"
#import "RelatedPostsSettingsViewController.h"
#import "SettingsSelectionViewController.h"
#import "SettingsMultiTextViewController.h"
#import "SettingTableViewCell.h"
#import "SettingsTextViewController.h"
#import "WordPress-Swift.h"
#import "WPStyleGuide+ReadableMargins.h"
#import "WPWebViewController.h"

#import <SVProgressHUD/SVProgressHUD.h>
#import <WordPressApi/WordPressApi.h>
#import <WPXMLRPC/WPXMLRPC.h>


NS_ENUM(NSInteger, SiteSettingsGeneral) {
    SiteSettingsGeneralTitle = 0,
    SiteSettingsGeneralTagline,
    SiteSettingsGeneralURL,
    SiteSettingsGeneralPrivacy,
    SiteSettingsGeneralLanguage,
    SiteSettingsGeneralCount,
};

NS_ENUM(NSInteger, SiteSettingsAccount) {
    SiteSettingsAccountUsername = 0,
    SiteSettingsAccountPassword,
    SiteSettingsAccountCount,
};

NS_ENUM(NSInteger, SiteSettingsWriting) {
    SiteSettingsWritingDefaultCategory = 0,
    SiteSettingsWritingDefaultPostFormat,
    SiteSettingsWritingRelatedPosts,
    SiteSettingsWritingCount,
};

NS_ENUM(NSInteger, SiteSettingsDevice) {
    SiteSettingsDeviceGeotagging = 0,
    SiteSettingsDeviceDefaultCategory,
    SiteSettingsDeviceDefaultPostFormat,
    SiteSettingsDeviceCount,
};

NS_ENUM(NSInteger, SiteSettingsAdvanced) {
    SiteSettingsAdvancedStartOver = 0,
    SiteSettingsAdvancedExportContent,
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

#pragma mark - General Section
@property (nonatomic, strong) SettingTableViewCell *siteTitleCell;
@property (nonatomic, strong) SettingTableViewCell *siteTaglineCell;
@property (nonatomic, strong) SettingTableViewCell *addressTextCell;
@property (nonatomic, strong) SettingTableViewCell *privacyTextCell;
@property (nonatomic, strong) SettingTableViewCell *languageTextCell;
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
@property (nonatomic, strong) WPTableViewCell *exportContentCell;
@property (nonatomic, strong) WPTableViewCell *deleteSiteCell;

@property (nonatomic, strong) Blog *blog;
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *password;
@end

@implementation SiteSettingsViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithBlog:(Blog *)blog
{
    NSParameterAssert([blog isKindOfClass:[Blog class]]);
    
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        _blog = blog;
        _username = blog.usernameForSite;
        _password = blog.password;
    }
    return self;
}

- (void)viewDidLoad
{
    DDLogMethod();
    [super viewDidLoad];
    self.navigationItem.title = NSLocalizedString(@"Settings", @"Title for screen that allows configuration of your blog/site settings.");

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleDataModelChange:)
                                                 name:NSManagedObjectContextObjectsDidChangeNotification
                                               object:self.blog.managedObjectContext];

    [WPStyleGuide resetReadableMarginsForTableView:self.tableView];
    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refreshTriggered:) forControlEvents:UIControlEventValueChanged];

    [self refreshData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self.tableView reloadData];
}

- (NSArray *)tableSections
{
    NSMutableArray *sections = [NSMutableArray arrayWithObjects:@(SiteSettingsSectionGeneral), nil];

    if (!self.blog.account) {
        [sections addObject:@(SiteSettingsSectionAccount)];
    }

    if ([self.blog supports:BlogFeatureWPComRESTAPI] && self.blog.isAdmin) {
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

    return sections;
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.tableSections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger settingsSection = [self.tableSections[section] integerValue];
    switch (settingsSection) {
        case SiteSettingsSectionGeneral:
        {
            NSInteger rowCount = SiteSettingsGeneralCount;
            
            // NOTE: Sergio Estevao (2015.08.25): Hide Privacy because of lack of support in .org
            if (![self.blog supports:BlogFeatureWPComRESTAPI]) {
                --rowCount;
            }
            
            // NOTE: Jorge Leandro Perez (2016.02.10): .org Language Settings is inconsistent with .com!
            if (!self.blog.supportsSiteManagementServices) {
                --rowCount;
            }
            
            return rowCount;
        }
        case SiteSettingsSectionAccount:
        {
            return SiteSettingsAccountCount;
        }
        case SiteSettingsSectionWriting:
        {
            return SiteSettingsWritingCount;
        }
        case SiteSettingsSectionDiscussion:
        {
            return 1;
        }
        case SiteSettingsSectionDevice:
        {
            if ([self.blog supports:BlogFeatureWPComRESTAPI]) {
                // NOTE: Brent Coursey (2016-02-03): Only show geotagging cell for user of the REST API (REST).
                // Any post default options are available in the Writing section for REST users.
                return 1;
            }
            return SiteSettingsDeviceCount;
        }
        case SiteSettingsSectionRemoveSite:
        {
            return 1;
        }
        case SiteSettingsSectionAdvanced:
        {
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
        case SiteSettingsAccountUsername:
            if (self.blog.usernameForSite) {
                [self.usernameTextCell setTextValue:self.blog.usernameForSite];
            } else {
                [self.usernameTextCell setTextValue:NSLocalizedString(@"Enter username", @"(placeholder) Help enter WordPress username")];
            }
            return self.usernameTextCell;

        case SiteSettingsAccountPassword:
            if (self.blog.password) {
                [self.passwordTextCell setTextValue:@"••••••••"];
            } else {
                [self.passwordTextCell setTextValue:NSLocalizedString(@"Enter password", @"(placeholder) Help enter WordPress password")];
            }
            return self.passwordTextCell;

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
    _geotaggingCell.on = self.blog.settings.geolocationEnabled;
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

- (void)configureDefaultCategoryCell
{
    PostCategoryService *postCategoryService = [[PostCategoryService alloc] initWithManagedObjectContext:[[ContextManager sharedInstance] mainContext]];
    PostCategory *postCategory = [postCategoryService findWithBlogObjectID:self.blog.objectID andCategoryID:self.blog.settings.defaultCategoryID];
    [self.defaultCategoryCell setTextValue:[postCategory categoryName]];
}

- (void)configureDefaultPostFormatCell
{
    [self.defaultPostFormatCell setTextValue:self.blog.defaultPostFormatText];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForWritingSettingsAtRow:(NSInteger)row
{
    switch (row) {
        case (SiteSettingsWritingDefaultCategory):
            [self configureDefaultCategoryCell];
            return self.defaultCategoryCell;

        case (SiteSettingsWritingDefaultPostFormat):
            [self configureDefaultPostFormatCell];
            return self.defaultPostFormatCell;

        case (SiteSettingsWritingRelatedPosts):
            return self.relatedPostsCell;
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForDeviceSettingsAtRow:(NSInteger)row
{
    switch (row) {
        case (SiteSettingsDeviceGeotagging):
            return self.geotaggingCell;

        case (SiteSettingsDeviceDefaultCategory):
            [self configureDefaultCategoryCell];
            return self.defaultCategoryCell;

        case (SiteSettingsDeviceDefaultPostFormat):
            [self configureDefaultPostFormatCell];
            return self.defaultPostFormatCell;
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

- (SettingTableViewCell *)languageTextCell
{
    if (_languageTextCell) {
        return _languageTextCell;
    }
    _languageTextCell = [[SettingTableViewCell alloc] initWithLabel:NSLocalizedString(@"Language", @"Label for the privacy setting")
                                                           editable:self.blog.isAdmin
                                                    reuseIdentifier:nil];
    return _languageTextCell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForGeneralSettingsInRow:(NSInteger)row
{
    switch (row) {
        case SiteSettingsGeneralTitle:
        {
            NSString *name = self.blog.settings.name ?: NSLocalizedString(@"A title for the site", @"Placeholder text for the title of a site");
            [self.siteTitleCell setTextValue:name];
            return self.siteTitleCell;
        }
        case SiteSettingsGeneralTagline:
        {
            NSString *tagline = self.blog.settings.tagline ?: NSLocalizedString(@"Explain what this site is about.", @"Placeholder text for the tagline of a site");
            [self.siteTaglineCell setTextValue:tagline];
            return self.siteTaglineCell;
        }
        case SiteSettingsGeneralURL:
        {
            if (self.blog.url) {
                [self.addressTextCell setTextValue:self.blog.url];
            } else {
                [self.addressTextCell setTextValue:NSLocalizedString(@"http://my-site-address (URL)", @"(placeholder) Help the user enter a URL into the field")];
            }
            return self.addressTextCell;
        }
        case SiteSettingsGeneralPrivacy:
        {
            [self.privacyTextCell setTextValue:[BlogSiteVisibilityHelper titleForCurrentSiteVisibilityOfBlog:self.blog]];
            return self.privacyTextCell;
        }
        case SiteSettingsGeneralLanguage:
        {
            NSInteger languageId = self.blog.settings.languageID.integerValue;
            NSString *name = [[Languages sharedInstance] nameForLanguageWithId:languageId];
            
            [self.languageTextCell setTextValue:name];
            return self.languageTextCell;
        }
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

- (WPTableViewCell *)exportContentCell
{
    if (_exportContentCell) {
        return _exportContentCell;
    }
    
    _exportContentCell = [[WPTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    [WPStyleGuide configureTableViewActionCell:_exportContentCell];
    _exportContentCell.textLabel.text = NSLocalizedString(@"Export Content", @"Label for selecting the Export Content Settings item");

    return _exportContentCell;
}

- (WPTableViewCell *)deleteSiteCell
{
    if (_deleteSiteCell) {
        return _deleteSiteCell;
    }
    
    _deleteSiteCell = [[WPTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    [WPStyleGuide configureTableViewActionCell:_deleteSiteCell];
    _deleteSiteCell.textLabel.text = NSLocalizedString(@"Delete Site", @"Label for selecting the Delete Site Settings item");

    return _deleteSiteCell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForAdvancedSettingsAtRow:(NSInteger)row
{
    switch (row) {
        case SiteSettingsAdvancedStartOver:
            return self.startOverCell;

        case SiteSettingsAdvancedExportContent:
            return self.exportContentCell;

        case SiteSettingsAdvancedDeleteSite:
            return self.deleteSiteCell;
    }

    NSAssert(false, @"Missing Advanced section cell");
    return [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"NoCell"];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger settingsSection = [self.tableSections[indexPath.section] integerValue];
    switch (settingsSection) {
        case SiteSettingsSectionGeneral:
            return [self tableView:tableView cellForGeneralSettingsInRow:indexPath.row];

        case SiteSettingsSectionAccount:
            return [self tableView:tableView cellForAccountSettingsInRow:indexPath.row];

        case SiteSettingsSectionWriting:
            return [self tableView:tableView cellForWritingSettingsAtRow:indexPath.row];

        case SiteSettingsSectionDiscussion:
            return self.discussionSettingsCell;

        case SiteSettingsSectionDevice:
            return [self tableView:tableView cellForDeviceSettingsAtRow:indexPath.row];

        case SiteSettingsSectionRemoveSite:
            return self.removeSiteCell;

        case SiteSettingsSectionAdvanced:
            return [self tableView:tableView cellForAdvancedSettingsAtRow:indexPath.row];
    }

    NSAssert(false, @"Missing section handler");
    return nil;
}

#pragma mark - UITableViewDelegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSInteger settingsSection = [self.tableSections[section] integerValue];
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
    NSInteger settingsSection = [self.tableSections[section] integerValue];
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

        case SiteSettingsSectionWriting:
            headingTitle = NSLocalizedString(@"Writing", @"Title for the writing section in site settings screen");
            break;

        case SiteSettingsSectionDevice:
            headingTitle = NSLocalizedString(@"This Device", @"Title for the device section in site settings screen");
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

- (void)showLanguageSelectorForBlog:(Blog *)blog
{
    NSParameterAssert(blog);
    
    __weak __typeof__(self) weakSelf = self;
    
    LanguageViewController *languageViewController = [[LanguageViewController alloc] initWithBlog:blog];
    languageViewController.onChange = ^(NSNumber *newLanguageID){
        weakSelf.blog.settings.languageID = newLanguageID;
        [weakSelf saveSettings];
    };
    
    [self.navigationController pushViewController:languageViewController animated:YES];
}

- (void)tableView:(UITableView *)tableView didSelectInGeneralSectionRow:(NSInteger)row
{
    if (!self.blog.isAdmin) {
        return;
    }

    switch (row) {
        case SiteSettingsGeneralTitle:
            [self showEditSiteTitleController];
            break;

        case SiteSettingsGeneralTagline:
            [self showEditSiteTaglineController];
            break;

        case SiteSettingsGeneralPrivacy:
            [self showPrivacySelector];
            break;
            
        case SiteSettingsGeneralLanguage:
            [self showLanguageSelectorForBlog:self.blog];
            break;
    }
}

- (void)tableView:(UITableView *)tableView didSelectInAccountSectionRow:(NSInteger)row
{
    if (row != SiteSettingsAccountPassword) {
        return;
    }
    SettingsTextViewController *siteTitleViewController = [[SettingsTextViewController alloc] initWithText:self.blog.password
                                                                                               placeholder:NSLocalizedString(@"Enter password", @"(placeholder) Help enter WordPress password")
                                                                                                      hint:@""
                                                                                                isPassword:YES];
    siteTitleViewController.title = NSLocalizedString(@"Password", @"Title for screen that shows self hosted password editor.");
    siteTitleViewController.onValueChanged = ^(id value) {
        if (![value isEqualToString:self.blog.password]) {
            self.password = value;
            [self validateLoginCredentials];
        }
    };
    [self.navigationController pushViewController:siteTitleViewController animated:YES];
}

- (void)showEditSiteTitleController
{
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
}

- (void)showEditSiteTaglineController
{
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
        if (![normalizedTagline isEqualToString:self.blog.settings.tagline]) {
            self.blog.settings.tagline = normalizedTagline;
            [self saveSettings];
        }
    };
    [self.navigationController pushViewController:siteTaglineViewController animated:YES];
}

- (void)showDefaultCategorySelector
{
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
                if ([weakSelf savingWritingDefaultsIsAvailable]) {
                    [weakSelf saveSettings];
                }
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
        case SiteSettingsWritingDefaultCategory:
            [self showDefaultCategorySelector];
            break;

        case SiteSettingsWritingDefaultPostFormat:
            [self showPostFormatSelector];
            break;

        case SiteSettingsWritingRelatedPosts:
            [self showRelatedPostsSettings];
            break;
    }
}

- (void)tableView:(UITableView *)tableView didSelectInDeviceSectionRow:(NSInteger)row
{
    switch (row) {
        case SiteSettingsDeviceDefaultCategory:
            [self showDefaultCategorySelector];
            break;

        case SiteSettingsDeviceDefaultPostFormat:
            [self showPostFormatSelector];
            break;
    }
}

- (void)showStartOverForBlog:(Blog *)blog
{
    NSParameterAssert([blog supportsSiteManagementServices]);

    StartOverViewController *viewController = [[StartOverViewController alloc] initWithBlog:blog];
    [self.navigationController pushViewController:viewController animated:YES];
}

- (void)tableView:(UITableView *)tableView didSelectInAdvancedSectionRow:(NSInteger)row
{
    switch (row) {
        case SiteSettingsAdvancedStartOver:
            [self showStartOverForBlog:self.blog];
            break;

        case SiteSettingsAdvancedExportContent:
            [self confirmExportContent];
            break;

        case SiteSettingsAdvancedDeleteSite:
            [self checkSiteDeletable];
            break;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger settingsSection = [self.tableSections[indexPath.section] intValue];
    switch (settingsSection) {
        case SiteSettingsSectionGeneral:
            [self tableView:tableView didSelectInGeneralSectionRow:indexPath.row];
            break;

        case SiteSettingsSectionAccount:
            [self tableView:tableView didSelectInAccountSectionRow:indexPath.row];
            break;

        case SiteSettingsSectionWriting:
            [self tableView:tableView didSelectInWritingSectionRow:indexPath.row];
            break;

        case SiteSettingsSectionDiscussion:
            [self showDiscussionSettingsForBlog:self.blog];
            break;

        case SiteSettingsSectionDevice:
            [self tableView:tableView didSelectInDeviceSectionRow:indexPath.row];
            break;

        case SiteSettingsSectionRemoveSite:
            [self showRemoveSiteForBlog:self.blog];
            [tableView deselectSelectedRowWithAnimation:YES];
            break;

        case SiteSettingsSectionAdvanced:
            [self tableView:tableView didSelectInAdvancedSectionRow:indexPath.row];
            break;
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
    // Save the change
    self.blog.settings.geolocationEnabled = value;
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
    } failure:^(NSError *error){
        [SVProgressHUD dismiss];
        [weakSelf loginValidationFailedWithError:error];
    }];
}


- (void)loginValidationFailedWithError:(NSError *)error
{
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
    webViewController.authToken = self.blog.authToken;
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

- (BOOL)savingWritingDefaultsIsAvailable
{
    return [self.blog supports:BlogFeatureWPComRESTAPI] && self.blog.isAdmin;
}

- (IBAction)cancel:(id)sender
{
    if (self.isCancellable) {
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        [self.navigationController popToRootViewControllerAnimated:YES];
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
    if ([self savingWritingDefaultsIsAvailable]) {
        [self saveSettings];
    }
}

#pragma mark - Notification handlers

- (void)handleDataModelChange:(NSNotification *)note
{
    NSSet *updatedObjects = note.userInfo[NSUpdatedObjectsKey];
    if ([updatedObjects containsObject:self.blog]) {
        [self.tableView reloadData];
    }
}

@end
