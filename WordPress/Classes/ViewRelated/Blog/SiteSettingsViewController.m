#import "SiteSettingsViewController.h"
#import "NSURL+IDN.h"
#import "SupportViewController.h"
#import "WPWebViewController.h"
#import "ReachabilityUtils.h"
#import "WPAccount.h"
#import "Blog.h"
#import "WPTableViewSectionHeaderView.h"
#import "SettingTableViewCell.h"
#import "NotificationsManager.h"
#import <SVProgressHUD/SVProgressHUD.h>
#import <NSDictionary+SafeExpectations.h>
#import "NotificationsManager.h"
#import "AccountService.h"
#import "ContextManager.h"
#import <WPXMLRPC/WPXMLRPC.h>
#import "BlogService.h"
#import "WPTextFieldTableViewCell.h"
#import "SettingsTextViewController.h"
#import "SettingsMultiTextViewController.h"
#import "WPGUIConstants.h"

NS_ENUM(NSInteger, SiteSettingsGeneral) {
    SiteSettingsGeneralTitle = 0,
    SiteSettingsGeneralTagline,
    SiteSettingsGeneralURL,
    SiteSettingsGeneralPushNotifications,
    SiteSettingsGeneralCount,
};

NS_ENUM(NSInteger, SiteSettingsAccount) {
    SiteSettingsAccountUsername = 0,
    SiteSettingsAccountPassword,
    SiteSettingsAccountCount,
};

NS_ENUM(NSInteger, SiteSettingsWriting) {
    SiteSettingsWritingGeotagging = 0,
    SiteSettingsWritingCount,
};

NS_ENUM(NSInteger, SiteSettingsSection) {
    SiteSettingsSectionGeneral = 0,
    SiteSettingsSectionAccount,
    SiteSettingsSectionWriting,
    SiteSettingsSectionRemoveSite,
};

NS_ENUM(NSInteger, SiteSettinsAlertTag) {
    SiteSettinsAlertTagSiteRemoval = 201,
};

NSInteger const EditSiteURLMinimumLabelWidth = 30;

@interface SiteSettingsViewController () <UITableViewDelegate, UITextFieldDelegate, UIAlertViewDelegate, UIActionSheetDelegate>

@property (nonatomic, strong) NSArray *tableSections;
#pragma mark - General Section
@property (nonatomic, strong) SettingTableViewCell *siteTitleCell;
@property (nonatomic, strong) SettingTableViewCell *siteTaglineCell;
@property (nonatomic, strong) SettingTableViewCell *addressTextCell;
@property (nonatomic, strong) SettingTableViewCell *pushCell;
#pragma mark - Account Section
@property (nonatomic, strong) SettingTableViewCell *usernameTextCell;
@property (nonatomic, strong) SettingTableViewCell *passwordTextCell;
#pragma mark - Writing Section
@property (nonatomic, strong) SettingTableViewCell *geotaggingCell;
@property (nonatomic, strong) UITableViewCell *removeSiteCell;
#pragma mark - Other properties
@property (nonatomic, strong) NSMutableDictionary *notificationPreferences;

@property (nonatomic, strong) Blog *blog;
@property (nonatomic, strong) NSString *authToken;
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *password;
@property (nonatomic, strong) NSString *url;

@property (nonatomic,   copy) NSString *startingPwd;
@property (nonatomic,   copy) NSString *startingUser;
@property (nonatomic,   copy) NSString *startingUrl;

@property (nonatomic, assign) BOOL geolocationEnabled;
@property (nonatomic, assign) BOOL isSiteDotCom;
@property (nonatomic, assign) BOOL isKeyboardVisible;

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
    if (self.blog.account) {
        self.tableSections = @[@(SiteSettingsSectionGeneral), @(SiteSettingsSectionWriting)];
    } else {
        self.tableSections = @[@(SiteSettingsSectionGeneral), @(SiteSettingsSectionAccount), @(SiteSettingsSectionWriting)];
    }    
    if ([self.blog supports:BlogFeatureRemovable]) {
        self.tableSections = [self.tableSections arrayByAddingObject:@(SiteSettingsSectionRemoveSite)];
    }
    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refreshTriggered:) forControlEvents:UIControlEventValueChanged];
    
    self.url = self.blog.url;
    self.authToken = self.blog.authToken;
    self.username = self.blog.usernameForSite;
    self.password = self.blog.password;

    self.startingUser = self.username;
    self.startingPwd = self.password;
    self.startingUrl = self.url;
    self.geolocationEnabled = self.blog.geolocationEnabled;

    self.notificationPreferences = [[[NSUserDefaults standardUserDefaults] objectForKey:@"notification_preferences"] mutableCopy];
    if (!self.notificationPreferences) {
        [NotificationsManager fetchNotificationSettingsWithSuccess:^{
            [self reloadNotificationSettings];
        } failure:^(NSError *error) {
            [WPError showAlertWithTitle:NSLocalizedString(@"Error", @"") message:error.localizedDescription];
        }];
    }
    
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
            if ([self.blog supports:BlogFeaturePushNotifications]) {
                return SiteSettingsGeneralCount;
            } else {
                return SiteSettingsGeneralCount-1;
            }
        } break;
        case SiteSettingsSectionAccount:
            return SiteSettingsAccountCount;
        break;
        case SiteSettingsSectionWriting:
            return SiteSettingsWritingCount;
        break;
        case SiteSettingsSectionRemoveSite:
            return 1;
        break;
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
        } break;
        case SiteSettingsAccountPassword: {
            if (self.blog.password) {
                [self.passwordTextCell setTextValue:@"••••••••"];
            } else {
                [self.passwordTextCell setTextValue:NSLocalizedString(@"Enter password", @"(placeholder) Help enter WordPress password")];
            }
            return self.passwordTextCell;
        } break;
    }
    return nil;
}

- (SettingTableViewCell *)geotaggingCell
{
    if (_geotaggingCell) {
        return _geotaggingCell;
    }
    _geotaggingCell = [[SettingTableViewCell alloc] initWithLabel:NSLocalizedString(@"Geotagging", @"Enables geotagging in blog settings (short label)")
                                                         editable:NO
                                                  reuseIdentifier:nil];
    UISwitch *geotaggingSwitch = [[UISwitch alloc] init];
    geotaggingSwitch.on = self.geolocationEnabled;
    [geotaggingSwitch addTarget:self action:@selector(toggleGeolocation:) forControlEvents:UIControlEventValueChanged];
    _geotaggingCell.accessoryView = geotaggingSwitch;
    return _geotaggingCell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForWritingSettingsAtRow:(NSInteger)row
{
    if (row == SiteSettingsWritingGeotagging) {
        UISwitch *geotaggingSwitch =  (UISwitch *)self.geotaggingCell.accessoryView;
        geotaggingSwitch.on = self.geolocationEnabled;
        return self.geotaggingCell;
    }
    return nil;
}

- (SettingTableViewCell *)siteTitleCell
{
    if (_siteTitleCell) {
        return _siteTitleCell;
    }
    _siteTitleCell = [[SettingTableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
    _siteTitleCell.textLabel.text = NSLocalizedString(@"Site Title", @"");
    _siteTitleCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return _siteTitleCell;
}

- (SettingTableViewCell *)siteTaglineCell
{
    if (_siteTaglineCell) {
        return _siteTaglineCell;
    }
    _siteTaglineCell = [[SettingTableViewCell alloc] initWithLabel:NSLocalizedString(@"Tagline", @"")
                                                          editable:YES
                                                   reuseIdentifier:nil];
    return _siteTaglineCell;
}

- (SettingTableViewCell *)addressTextCell
{
    if (_addressTextCell) {
        return _addressTextCell;
    }
    _addressTextCell = [[SettingTableViewCell alloc] initWithLabel:NSLocalizedString(@"Address", @"")
                                                          editable:NO
                                                   reuseIdentifier:nil];
    return _addressTextCell;
}

- (SettingTableViewCell *)pushCell
{
    if (_pushCell) {
        return _pushCell;
    }
    _pushCell = [[SettingTableViewCell alloc] initWithLabel:NSLocalizedString(@"Push Notifications", @"")
                                                   editable:NO
                                            reuseIdentifier:nil];
    UISwitch *pushSwitch = [[UISwitch alloc] init];
    [pushSwitch addTarget:self action:@selector(togglePushNotifications:) forControlEvents:UIControlEventValueChanged];
    _pushCell.accessoryView = pushSwitch;
    pushSwitch.on = [self getBlogPushNotificationsSetting];
    return _pushCell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForGeneralSettingsInRow:(NSInteger)row
{
    switch (row) {
        case SiteSettingsGeneralTitle: {
            if (self.blog.blogName) {
                [self.siteTitleCell setTextValue:self.blog.blogName];
            } else {
                [self.siteTitleCell setTextValue:NSLocalizedString(@"A title for the site", @"Placeholder text for the title of a site")];
            }
            return self.siteTitleCell;
        } break;
        case SiteSettingsGeneralTagline: {
            if (self.blog.blogTagline) {
                [self.siteTaglineCell setTextValue:self.blog.blogTagline];
            } else {
                [self.siteTaglineCell setTextValue:NSLocalizedString(@"Explain what this site is about.", @"Placeholder text for the tagline of a site")];
            }
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
        case SiteSettingsGeneralPushNotifications: {
            UISwitch *pushSwitch = (UISwitch *)self.pushCell.accessoryView;
            pushSwitch.on = [self getBlogPushNotificationsSetting];
            return self.pushCell;
        } break;
    }
    return [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"NoCell"];;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger settingsSection = [self.tableSections[indexPath.section] intValue];
    switch (settingsSection) {
        case SiteSettingsSectionGeneral:{
            return [self tableView:tableView cellForGeneralSettingsInRow:indexPath.row];
        }break;
        case SiteSettingsSectionAccount: {
            return [self tableView:tableView cellForAccountSettingsInRow:indexPath.row];
        }break;
        case SiteSettingsSectionWriting: {
            return [self tableView:tableView cellForWritingSettingsAtRow:indexPath.row];
        }break;
        case SiteSettingsSectionRemoveSite: {
            if (self.removeSiteCell) {
                return self.removeSiteCell;
            }
            self.removeSiteCell = [[WPTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
            [WPStyleGuide configureTableViewDestructiveActionCell:self.removeSiteCell];
            self.removeSiteCell.textLabel.text = NSLocalizedString(@"Remove Site", @"Button to remove a site from the app");
            return self.removeSiteCell;
        }break;
    }

    // We shouldn't reach this point, but return an empty cell just in case
    return [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"NoCell"];
}

#pragma mark - UITableViewDelegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSInteger settingsSection = [self.tableSections[section] intValue];
    NSString *title = [self titleForHeaderInSection:settingsSection];
    if (title.length > 0) {
        WPTableViewSectionHeaderView *header = [[WPTableViewSectionHeaderView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 0)];
        header.title = title;
        return header;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return WPTableViewDefaultRowHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    NSString *title = [self titleForHeaderInSection:section];
    CGFloat height = [WPTableViewSectionHeaderView heightForTitle:title andWidth:CGRectGetWidth(self.view.bounds)];
    
    return height;
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
    }
    return headingTitle;
}

- (void)tableView:(UITableView *)tableView didSelectInGeneralSectionRow:(NSInteger)row
{
    switch (row) {
        case SiteSettingsGeneralTitle:{
            SettingsTextViewController *siteTitleViewController = [[SettingsTextViewController alloc] initWithText:self.blog.blogName
                                                                                                 placeholder:NSLocalizedString(@"A title for the site", @"Placeholder text for the title of a site")
                                                                                                              hint:@""
                                                                                                        isPassword:NO];
            siteTitleViewController.title = NSLocalizedString(@"Site Title", @"Title for screen that show site title editor");
            siteTitleViewController.onValueChanged = ^(NSString *value) {
                self.siteTitleCell.detailTextLabel.text = value;
                if (![value isEqualToString:self.blog.blogName]){
                    self.blog.blogName = value;
                    [self save:nil];
                }
            };
            [self.navigationController pushViewController:siteTitleViewController animated:YES];
        }break;
        case SiteSettingsGeneralTagline:{
            SettingsMultiTextViewController *siteTaglineViewController = [[SettingsMultiTextViewController alloc] initWithText:self.blog.blogTagline
                                                                                                 placeholder:NSLocalizedString(@"Explain what this site is about.", @"Placeholder text for the tagline of a site")
                                                                                                              hint:NSLocalizedString(@"In a few words, explain what this site is about.",@"Explain what is the purpose of the tagline")
                                                                                                        isPassword:NO];
            siteTaglineViewController.title = NSLocalizedString(@"Tagline", @"Title for screen that show tagline editor");
            siteTaglineViewController.onValueChanged = ^(NSString *value) {
                NSString *normalizedTagline = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                self.siteTaglineCell.detailTextLabel.text = normalizedTagline;
                if (![normalizedTagline isEqualToString:self.blog.blogTagline]){
                    self.blog.blogTagline = normalizedTagline;
                    [self save:nil];
                }
            };
            [self.navigationController pushViewController:siteTaglineViewController animated:YES];
        }break;
        case SiteSettingsGeneralURL:{
            
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
                    [self validateUrl];
                }
            };
            [self.navigationController pushViewController:siteTitleViewController animated:YES];
        }break;
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
            
            break;
        case SiteSettingsSectionRemoveSite:{
            [self showRemoveSiteForBlog:self.blog];
        }break;
    }
}

#pragma mark - Custom methods

- (IBAction)refreshTriggered:(id)sender
{
    [self refreshData];
}

- (void)refreshData
{
    BlogService *service = [[BlogService alloc] initWithManagedObjectContext:[[ContextManager sharedInstance] mainContext]];
    __weak __typeof__(self) weakSelf = self;
    [service syncSettingsForBlog:self.blog success:^{
        __typeof__(self) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        [strongSelf.refreshControl endRefreshing];
        [strongSelf.tableView reloadData];
    } failure:^(NSError *error) {
        __typeof__(self) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        [strongSelf.refreshControl endRefreshing];
    }];
    
}

- (BOOL)canTogglePushNotifications
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
    WPAccount *defaultAccount = [accountService defaultWordPressComAccount];

    return self.blog &&
        [self.blog supports:BlogFeaturePushNotifications] &&
        [[defaultAccount restApi] hasCredentials] &&
        [NotificationsManager deviceRegisteredForPushNotifications];
}

- (void)toggleGeolocation:(id)sender
{
    UISwitch *geolocationSwitch = (UISwitch *)sender;
    self.geolocationEnabled = geolocationSwitch.on;

    // Save the change
    self.blog.geolocationEnabled = self.geolocationEnabled;
    [[ContextManager sharedInstance] saveContext:self.blog.managedObjectContext];
}

- (void)togglePushNotifications:(id)sender
{
    UISwitch *pushSwitch = (UISwitch *)sender;
    BOOL muted = !pushSwitch.on;
    if (_notificationPreferences) {
        NSMutableDictionary *mutedBlogsDictionary = [[_notificationPreferences objectForKey:@"muted_blogs"] mutableCopy];
        NSMutableArray *mutedBlogsArray = [[mutedBlogsDictionary objectForKey:@"value"] mutableCopy];
        NSMutableDictionary *updatedPreference;

        NSNumber *blogID = [self.blog dotComID];
        for (NSUInteger i = 0; i < [mutedBlogsArray count]; i++) {
            updatedPreference = [mutedBlogsArray[i] mutableCopy];
            NSString *currentblogID = [updatedPreference objectForKey:@"blog_id"];
            if ([blogID intValue] == [currentblogID intValue]) {
                [updatedPreference setValue:[NSNumber numberWithBool:muted] forKey:@"value"];
                [mutedBlogsArray setObject:updatedPreference atIndexedSubscript:i];
                [mutedBlogsDictionary setValue:mutedBlogsArray forKey:@"value"];
                [_notificationPreferences setValue:mutedBlogsDictionary forKey:@"muted_blogs"];
                [[NSUserDefaults standardUserDefaults] setValue:_notificationPreferences forKey:@"notification_preferences"];

                // Send these settings optimistically since they're low-impact (not ideal but works for now)
                [NotificationsManager saveNotificationSettings];
                return;
            }
        }
    }
}

#pragma mark - Authentication methods

- (NSString *)getURLToValidate
{
    NSString *urlToValidate = self.url;

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

- (void)validateXmlprcURL:(NSURL *)xmlRpcURL
{
    WordPressXMLRPCApi *api = [WordPressXMLRPCApi apiWithXMLRPCEndpoint:xmlRpcURL
                                                               username:self.username
                                                               password:self.password];

    [api getBlogOptionsWithSuccess:^(id options){
        if ([options objectForKey:@"wordpress.com"] != nil) {
            self.isSiteDotCom = YES;
            [self loginForSiteWithXmlRpcUrl:[NSURL URLWithString:@"https://wordpress.com/xmlrpc.php"]];
        } else {
            self.isSiteDotCom = NO;
            [self loginForSiteWithXmlRpcUrl:xmlRpcURL];
        }
    } failure:^(NSError *failure){
        [SVProgressHUD dismiss];
        [self validationDidFail:failure];
    }];
}

- (void)loginForSiteWithXmlRpcUrl:(NSURL *)xmlRpcURL
{
    WordPressXMLRPCApi *api = [WordPressXMLRPCApi apiWithXMLRPCEndpoint:xmlRpcURL username:self.usernameTextCell.detailTextLabel.text password:self.password];
    [api getBlogsWithSuccess:^(NSArray *blogs) {
        [SVProgressHUD dismiss];
        [self validationSuccess:[xmlRpcURL absoluteString]];
    } failure:^(NSError *error) {
        [SVProgressHUD dismiss];
        [self validationDidFail:error];
    }];
}

- (void)checkURL
{
    NSString *urlToValidate = [self getURLToValidate];

    DDLogInfo(@"%@ %@ %@", self, NSStringFromSelector(_cmd), urlToValidate);

    [SVProgressHUD showWithStatus:NSLocalizedString(@"Authenticating", @"") maskType:SVProgressHUDMaskTypeBlack];
    [WordPressXMLRPCApi guessXMLRPCURLForSite:urlToValidate success:^(NSURL *xmlrpcURL) {
        [self validateXmlprcURL:xmlrpcURL];
    } failure:^(NSError *error){
        [SVProgressHUD dismiss];
        if ([error.domain isEqual:NSURLErrorDomain] && error.code == NSURLErrorUserCancelledAuthentication) {
            [self validationDidFail:nil];
        } else if ([error.domain isEqual:WPXMLRPCErrorDomain] && error.code == WPXMLRPCInvalidInputError) {
            [self validationDidFail:error];
        } else if ([error.domain isEqual:WordPressXMLRPCApiErrorDomain]) {
            [self validationDidFail:error];
        } else if ([error.domain isEqual:AFURLRequestSerializationErrorDomain] || [error.domain isEqual:AFURLResponseSerializationErrorDomain]) {
            NSString *str = [NSString stringWithFormat:NSLocalizedString(@"There was a server error communicating with your site:\n%@\nTap 'Need Help?' to view the FAQ.", @""), [error localizedDescription]];
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey: str};
            NSError *err = [NSError errorWithDomain:@"org.wordpress.iphone" code:NSURLErrorBadServerResponse userInfo:userInfo];
            [self validationDidFail:err];
        } else {
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey: NSLocalizedString(@"Unable to find a WordPress site at that URL. Tap 'Need Help?' to view the FAQ.", @"")};
            NSError *err = [NSError errorWithDomain:@"org.wordpress.iphone" code:NSURLErrorBadURL userInfo:userInfo];
            [self validationDidFail:err];
        }
    }];
}

- (void)validationSuccess:(NSString *)xmlrpc
{
    self.blog.password = self.password;
    [self.blog.managedObjectContext save:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"BlogsRefreshNotification" object:nil];

    [self.navigationItem setHidesBackButton:NO animated:NO];

}

- (void)validationDidFail:(NSError *)error
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
            [WPError showAlertWithTitle:NSLocalizedString(@"Sorry, can't log in", @"") message:message withSupportButton:YES okPressedBlock:^(UIAlertView *alertView) {
                [self openSiteAdminFromAlert:alertView];
            }];

        } else {
            [WPError showAlertWithTitle:NSLocalizedString(@"Sorry, can't log in", @"") message:message];
        }
    }
}

- (void)openSiteAdminFromAlert:(UIAlertView *)alertView
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

- (void)validateUrl
{
    if (self.blog) {
        // If we are editing an existing blog, use the known XML-RPC URL
        // We don't allow editing URL on existing blogs, so XML-RPC shouldn't change
        [self validateXmlprcURL:[NSURL URLWithString:self.blog.xmlrpc]];
    } else {
        [self checkURL];
    }
}

#pragma mark - Saving methods

- (void)saveSettings
{
    BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:self.blog.managedObjectContext];
    self.blog.blogName = self.siteTitleCell.detailTextLabel.text;
    self.blog.blogTagline = self.siteTaglineCell.detailTextLabel.text;
    self.blog.geolocationEnabled = self.geolocationEnabled;
    if ([self.blog hasChanges]) {
        [blogService updateSettingForBlog:self.blog success:^{
        } failure:^(NSError *error) {
            [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Settings update failed", @"Message to show when setting save failed")];
        }];
    }
}

- (IBAction)save:(UIBarButtonItem *)sender
{
    [self saveSettings];
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

- (void)reloadNotificationSettings
{
    self.notificationPreferences = [[[NSUserDefaults standardUserDefaults] objectForKey:@"notification_preferences"] mutableCopy];
    if (self.notificationPreferences) {
        [self.tableView reloadData];
    }
}

- (BOOL)getBlogPushNotificationsSetting
{
    if (self.notificationPreferences) {
        NSDictionary *mutedBlogsDictionary = [self.notificationPreferences objectForKey:@"muted_blogs"];
        NSArray *mutedBlogsArray = [mutedBlogsDictionary objectForKey:@"value"];
        NSNumber *blogID = [self.blog dotComID];
        for (NSDictionary *currentBlog in mutedBlogsArray ){
            NSString *currentBlogID = [currentBlog objectForKey:@"blog_id"];
            if ([blogID intValue] == [currentBlogID intValue]) {
                return ![[currentBlog objectForKey:@"value"] boolValue];
            }
        }
    }
    return YES;
}

- (BOOL)canEditUsernameAndURL
{
    return NO;
}

#pragma mark - Remove Site

- (void)showRemoveSiteForBlog:(Blog *)blog
{
    NSString *model = [[UIDevice currentDevice] localizedModel];
    NSString *title = [NSString stringWithFormat:NSLocalizedString(@"Are you sure you want to continue?\n All site data will be removed from your %@.", @"Title for the remove site confirmation alert, %@ will be replaced with iPhone/iPad/iPod Touch"), model];
    NSString *cancelTitle = NSLocalizedString(@"Cancel", nil);
    NSString *destructiveTitle = NSLocalizedString(@"Remove Site", @"Button to remove a site from the app");
    if (IS_IPAD) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Remove Site", @"Remove site confirmation alert title")
                                                        message:title
                                                       delegate:self
                                              cancelButtonTitle:cancelTitle
                                              otherButtonTitles:destructiveTitle, nil];
        alert.tag = SiteSettinsAlertTagSiteRemoval;
        [alert show];
    } else {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:title
                                                                 delegate:self
                                                        cancelButtonTitle:cancelTitle
                                                   destructiveButtonTitle:destructiveTitle
                                                        otherButtonTitles:nil];
        actionSheet.tag = SiteSettinsAlertTagSiteRemoval;
        [actionSheet showInView:self.view];
    }
}

- (void)confirmRemoveSite
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:context];
    [blogService removeBlog:self.blog];
    [self.navigationController popToRootViewControllerAnimated:YES];
}

#pragma mark - Action sheet delegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (actionSheet.tag == SiteSettinsAlertTagSiteRemoval) {
        if (buttonIndex == actionSheet.destructiveButtonIndex) {
            [self confirmRemoveSite];
        }
    }
}

#pragma mark - Alert view delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == SiteSettinsAlertTagSiteRemoval) {
        if (buttonIndex == alertView.firstOtherButtonIndex) {
            [self confirmRemoveSite];
        }
    }
}

@end
