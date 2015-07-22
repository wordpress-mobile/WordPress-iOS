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
#import "SiteTitleViewController.h"

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
};

static NSString *const SettingCellIdentifier = @"SettingCellIdentifier";
static NSString *const GeotaggingCellIdentifier = @"GeotaggingCellIdentifier";
static NSString *const PushNotificationsCellIdentifier = @"PushNotificationsCellIdentifier";
static NSString *const PasswordCellIdentifier = @"PasswordCellIdentifier";

static CGFloat const EditSiteRowHeight = 48.0;
NSInteger const EditSiteURLMinimumLabelWidth = 30;

@interface SiteSettingsViewController () <UITableViewDelegate, UITextFieldDelegate, UIAlertViewDelegate>

@property (nonatomic, strong) UIBarButtonItem *saveButton;
@property (nonatomic,   weak) UITextField *lastTextField;
@property (nonatomic,   weak) UITextField *usernameTextField;
@property (nonatomic,   weak) UITextField *passwordTextField;
@property (nonatomic,   weak) UITextField *urlTextField;
@property (nonatomic, strong) NSMutableDictionary *notificationPreferences;
@property (nonatomic,   weak) UITextField *siteTitleTextField;
@property (nonatomic,   weak) UITextField *siteTaglineTextField;


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

@property (nonatomic, strong) NSArray *tableSections;

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

    self.navigationItem.title = NSLocalizedString(@"Settings", @"");
    if ([self.blog isHostedAtWPcom]) {
        self.tableSections = @[@(SiteSettingsSectionGeneral), @(SiteSettingsSectionWriting)];
    } else {
        self.tableSections = @[@(SiteSettingsSectionGeneral), @(SiteSettingsSectionAccount), @(SiteSettingsSectionWriting)];
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

    if (self.isCancellable) {
        UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", nil)
                                                                      style:UIBarButtonItemStylePlain
                                                                     target:self
                                                                     action:@selector(cancel:)];
        self.navigationItem.leftBarButtonItem = barButton;
    }

    // Create the save button but don't show it until something changes
    self.saveButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Save", @"Save button label (saving content, ex: Post, Page, Comment, Category).")
                                                       style:[WPStyleGuide barButtonStyleForDone]
                                                      target:self
                                                      action:@selector(save:)];

    if (!IS_IPAD) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleKeyboardDidShow:)
                                                     name:UIKeyboardDidShowNotification
                                                   object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleKeyboardWillHide:)
                                                     name:UIKeyboardWillHideNotification
                                                   object:nil];
    }

    UITapGestureRecognizer *tgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleViewTapped)];
    tgr.cancelsTouchesInView = NO;
    [self.tableView addGestureRecognizer:tgr];

    [self.tableView registerClass:[SettingTableViewCell class] forCellReuseIdentifier:SettingCellIdentifier];
    [self.tableView registerClass:[WPTableViewCell class] forCellReuseIdentifier:GeotaggingCellIdentifier];
    [self.tableView registerClass:[WPTableViewCell class] forCellReuseIdentifier:PushNotificationsCellIdentifier];
    [self.tableView registerClass:[WPTextFieldTableViewCell class] forCellReuseIdentifier:PasswordCellIdentifier];
    
    [self refreshData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self.tableView reloadData];
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
        case SiteSettingsSectionGeneral:
            return SiteSettingsGeneralCount;
        break;
        case SiteSettingsSectionAccount:
            return SiteSettingsAccountCount;
        break;
        case SiteSettingsSectionWriting:
            return SiteSettingsWritingCount;
        break;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForAccountSettingsInRow:(NSInteger)row
{
    switch (row) {
        case SiteSettingsAccountUsername: {
            SettingTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:SettingCellIdentifier];
            cell.textLabel.text = NSLocalizedString(@"Username", @"Label for entering username in the username field");
            if (self.blog.usernameForSite) {
                cell.detailTextLabel.text = self.blog.usernameForSite;
            } else {
                cell.detailTextLabel.text = NSLocalizedString(@"Enter username", @"(placeholder) Help enter WordPress username");
            }
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            [WPStyleGuide configureTableViewCell:cell];
            return cell;
        } break;
        case SiteSettingsAccountPassword: {
            WPTextFieldTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:PasswordCellIdentifier];
            cell.textLabel.text = NSLocalizedString(@"Password", @"Label for entering password in password field");
            if (self.blog.usernameForSite) {
                cell.textField.text = self.password;
            } else {
                cell.textField.text = @"";
            }
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            [WPStyleGuide configureTableViewTextCell:cell];
            [self configureTextField:cell.textField asPassword:YES];
            cell.textField.textAlignment = NSTextAlignmentRight;
            cell.textField.enabled = NO;
            return cell;
        } break;
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForWritingSettingsAtRow:(NSInteger)row
{
    if (row == SiteSettingsWritingGeotagging) {
        UITableViewCell *geotaggingCell = [tableView dequeueReusableCellWithIdentifier:GeotaggingCellIdentifier];
        UISwitch *geotaggingSwitch = [[UISwitch alloc] init];
        geotaggingCell.textLabel.text = NSLocalizedString(@"Geotagging", @"Enables geotagging in blog settings (short label)");
        geotaggingCell.selectionStyle = UITableViewCellSelectionStyleNone;
        geotaggingSwitch.on = self.geolocationEnabled;
        [geotaggingSwitch addTarget:self action:@selector(toggleGeolocation:) forControlEvents:UIControlEventValueChanged];
        geotaggingCell.accessoryView = geotaggingSwitch;
        [WPStyleGuide configureTableViewCell:geotaggingCell];
        return geotaggingCell;
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForGeneralSettingsInRow:(NSInteger)row
{
    switch (row) {
        case SiteSettingsGeneralTitle: {
            SettingTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:SettingCellIdentifier];
            cell.textLabel.text = NSLocalizedString(@"Site Title", @"");
            if (self.blog.blogName) {
                cell.detailTextLabel.text = self.blog.blogName;
            } else {
                cell.detailTextLabel.text = NSLocalizedString(@"A title for the site", @"Placeholder text for the title of a site");
            }
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            [WPStyleGuide configureTableViewCell:cell];
            return cell;
        } break;
        case SiteSettingsGeneralTagline: {
            SettingTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:SettingCellIdentifier];
            cell.textLabel.text = NSLocalizedString(@"Tagline", @"");
            if (self.blog.blogTagline) {
                cell.detailTextLabel.text = self.blog.blogTagline;
            } else {
                cell.detailTextLabel.text = NSLocalizedString(@"Explain what this site is about.", @"Placeholder text for the tagline of a site");
            }
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            [WPStyleGuide configureTableViewCell:cell];
            return cell;
        } break;
        case SiteSettingsGeneralURL: {
            SettingTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:SettingCellIdentifier];
            cell.textLabel.text = NSLocalizedString(@"Address", @"");
            if (self.blog.url) {
                cell.detailTextLabel.text = self.blog.url;
            } else {
                cell.detailTextLabel.text = NSLocalizedString(@"http://my-site-address (URL)", @"(placeholder) Help the user enter a URL into the field");
            }
            cell.accessoryType = UITableViewCellAccessoryNone;
            [WPStyleGuide configureTableViewCell:cell];
            return cell;
        } break;
        case SiteSettingsGeneralPushNotifications: {
            UITableViewCell *pushCell = [tableView dequeueReusableCellWithIdentifier:PushNotificationsCellIdentifier];
            pushCell = [[WPTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:PushNotificationsCellIdentifier];
            UISwitch *pushSwitch = [[UISwitch alloc] init];
            pushCell.textLabel.text = NSLocalizedString(@"Push Notifications", @"");
            pushCell.selectionStyle = UITableViewCellSelectionStyleNone;
            [pushSwitch addTarget:self action:@selector(togglePushNotifications:) forControlEvents:UIControlEventValueChanged];
            pushCell.accessoryView = pushSwitch;
            [WPStyleGuide configureTableViewCell:pushCell];
            pushSwitch.on = [self getBlogPushNotificationsSetting];
            return pushCell;
        } break;
    }
    return [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"NoCell"];;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger settingsSection = [self.tableSections[indexPath.section] intValue];
    switch (settingsSection) {
        case SiteSettingsSectionGeneral:
            return [self tableView:tableView cellForGeneralSettingsInRow:indexPath.row];
            break;
        case SiteSettingsSectionAccount: {
            return [self tableView:tableView cellForAccountSettingsInRow:indexPath.row];
            break;
        }
        case SiteSettingsSectionWriting: {
            return [self tableView:tableView cellForWritingSettingsAtRow:indexPath.row];
            break;
        }
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
    return EditSiteRowHeight;
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
            SiteTitleViewController *siteTitleViewController = [[SiteTitleViewController alloc] init];
            siteTitleViewController.title = NSLocalizedString(@"Site Title", @"Title for screen that show site title editor");
            [self.navigationController pushViewController:siteTitleViewController animated:YES];
        }break;
        case SiteSettingsGeneralTagline:{
            
        }break;
        case SiteSettingsGeneralURL:{
            
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
            
            break;
        case SiteSettingsSectionWriting:
            
            break;
    }
}
#pragma mark - UITextField methods

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    if (self.lastTextField) {
        self.lastTextField = nil;
    }
    self.lastTextField = textField;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.urlTextField) {
        [self.usernameTextField becomeFirstResponder];
    } else if (textField == self.usernameTextField) {
        [self.passwordTextField becomeFirstResponder];
    } else if (textField == self.passwordTextField) {
        [self.passwordTextField resignFirstResponder];
    } else if (textField == self.siteTitleTextField) {
        [self.siteTaglineTextField becomeFirstResponder];
    } else if (textField == self.siteTaglineTextField) {
        [self.siteTaglineTextField resignFirstResponder];
    }
    return NO;
}

- (BOOL)textField:(UITextField *)textField
    shouldChangeCharactersInRange:(NSRange)range
    replacementString:(NSString *)string
{
    if (!(textField == self.usernameTextField || textField == self.passwordTextField)) {
        return YES;
    }
    // Adjust the text color of the containing cell's textLabel if
    // the entered information is invalid.
    if ([textField isDescendantOfView:self.tableView]) {

        UITableViewCell *cell = (id)[textField superview];
        while (![cell.class isSubclassOfClass:[UITableViewCell class]]) {
            cell = (id)cell.superview;

            // This is a protection against a textfield not placed withing a
            // table view cell
            if ([cell.class isSubclassOfClass:[UITableView class]]) {
                return YES;
            }
        }

        NSMutableString *result = [NSMutableString stringWithString:textField.text];
        [result replaceCharactersInRange:range withString:string];

        if ([result length] == 0) {
            cell.textLabel.textColor = [WPStyleGuide validationErrorRed];
        } else {
            cell.textLabel.textColor = [WPStyleGuide whisperGrey];
        }
    }

    return YES;
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

- (void)configureTextField:(UITextField *)textField asPassword:(BOOL)asPassword
{
    textField.keyboardType = UIKeyboardTypeDefault;
    textField.autocorrectionType = UITextAutocorrectionTypeNo;
    textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    textField.delegate = self;
    if (asPassword) {
        textField.secureTextEntry = YES;
        textField.returnKeyType = UIReturnKeyDone;
    } else {
        textField.returnKeyType = UIReturnKeyNext;
    }
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
    WordPressXMLRPCApi *api = [WordPressXMLRPCApi apiWithXMLRPCEndpoint:xmlRpcURL username:self.usernameTextField.text password:self.passwordTextField.text];

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
    WordPressXMLRPCApi *api = [WordPressXMLRPCApi apiWithXMLRPCEndpoint:xmlRpcURL username:self.usernameTextField.text password:self.passwordTextField.text];
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
    self.blog.geolocationEnabled = self.geolocationEnabled;
    self.blog.password = self.password;

    [self cancel:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"BlogsRefreshNotification" object:nil];

    self.saveButton.enabled = YES;
    [self.navigationItem setHidesBackButton:NO animated:NO];

}

- (void)validationDidFail:(NSError *)error
{
    self.saveButton.enabled = YES;
    [self.navigationItem setHidesBackButton:NO animated:NO];

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

- (void)save:(UIBarButtonItem *)sender
{
    [self.urlTextField resignFirstResponder];
    [self.usernameTextField resignFirstResponder];
    [self.passwordTextField resignFirstResponder];
    [self.siteTitleTextField resignFirstResponder];
    [self.siteTaglineTextField resignFirstResponder];
    
    self.url = [NSURL IDNEncodedURL:self.urlTextField.text];
    self.username = self.usernameTextField.text;
    self.password = self.passwordTextField.text;
    BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:self.blog.managedObjectContext];
    self.blog.blogName = self.siteTitleTextField.text;
    self.blog.blogTagline = self.siteTaglineTextField.text;
    self.blog.geolocationEnabled = self.geolocationEnabled;
    if ([self.blog hasChanges]) {
        sender.enabled = NO;
        [SVProgressHUD show];
        [blogService updateSettingForBlog:self.blog success:^{
            [SVProgressHUD showInfoWithStatus:NSLocalizedString(@"Settings Saved", @"Message to show when settings are saved")];
            sender.enabled = YES;
        } failure:^(NSError *error) {
            [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Settings update failed", @"Message to show when setting save failed")];
            sender.enabled = YES;
        }];
    }
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

- (void)showSaveButton
{
    BOOL hasContent;

    if ([self.urlTextField.text isEqualToString:@""] ||
         [self.usernameTextField.text isEqualToString:@""] ||
         [self.passwordTextField.text isEqualToString:@""]) {
        hasContent = NO;
    } else {
        hasContent = YES;
    }

    self.navigationItem.rightBarButtonItem = hasContent ? self.saveButton : nil;
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

#pragma mark - Keyboard Related Methods

- (void)handleKeyboardDidShow:(NSNotification *)notification
{
    if (_isKeyboardVisible) {
        return;
    }

    CGRect rect = [[notification.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect frame = self.view.frame;

    // Slight hack to account for tab bar; ditch this when we switch to a translucent tab bar
    CGSize tabBarSize = CGSizeZero;
    if ([self tabBarController]) {
        tabBarSize = [[[self tabBarController] tabBar] bounds].size;
    }

    if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
        frame.size.height -= rect.size.width - tabBarSize.height;
    } else {
        frame.size.height -= rect.size.height - tabBarSize.height;
    }

    self.view.frame = frame;

    CGPoint point = [self.tableView convertPoint:self.lastTextField.frame.origin fromView:self.lastTextField];
    if (!CGRectContainsPoint(frame, point)) {
        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:point];
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
    }

    _isKeyboardVisible = YES;
}

- (void)handleKeyboardWillHide:(NSNotification *)notification
{
    CGRect rect = [[notification.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect frame = self.view.frame;
    if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
        frame.size.height += rect.size.width;
    } else {
        frame.size.height += rect.size.height;
    }

    [UIView animateWithDuration:0.3 animations:^{
        self.view.frame = frame;
    }];

    _isKeyboardVisible = NO;
}

- (void)handleViewTapped
{
    [self.lastTextField resignFirstResponder];
}

@end
