#import <WordPressApi/WordPressApi.h>
#import "EditSiteViewController.h"
#import "NSURL+IDN.h"
#import "WordPressComApi.h"
#import "SupportViewController.h"
#import "WPWebViewController.h"
#import "JetpackSettingsViewController.h"
#import "ReachabilityUtils.h"
#import "WPAccount.h"
#import "Blog.h"
#import "WPTableViewSectionHeaderView.h"
#import "NotificationsManager.h"
#import <WPXMLRPC/WPXMLRPC.h>
#import <SVProgressHUD/SVProgressHUD.h>
#import <NSDictionary+SafeExpectations.h>
#import "NotificationsManager.h"
#import "AccountService.h"
#import "ContextManager.h"

const typedef enum {
    EditSiteRowURL = 0,
    EditSiteRowUsername = 1,
    EditSiteRowPassword = 2,
    EditSiteRowGeotagging = 0,
    EditSiteRowPushNotifications = 1,
    EditSiteRowJetpackConfigure = 0
} EditSiteRow;

const typedef enum {
    TableViewSectionTitle = 0,
    TableViewSectionSettings,
    TableViewSectionSelfHosted
} TableSectionContentType;

static NSString *const TextFieldCellIdentifier = @"TextFieldCellIdentifier";
static NSString *const GeotaggingCellIdentifier = @"GeotaggingCellIdentifier";
static NSString *const PushNotificationsCellIdentifier = @"PushNotificationsCellIdentifier";
static NSString *const JetpackConnectedCellIdentifier = @"JetpackConnectedCellIdentifier";
static CGFloat const EditSiteRowHeight = 48.0;
NSInteger const EditSiteURLMinimumLabelWidth = 30;
NSInteger const EditSiteSectionCount = 2;
NSInteger const EditSiteSectionCountSelfHosted = 3;

NSInteger const EditSiteRowCountForSectionTitle = 2;
NSInteger const EditSiteRowCountForSectionTitleSelfHosted = 3;
NSInteger const EditSiteRowCountForSectionSettings = 2;
NSInteger const EditSiteRowCountForSectionSettingsSelfHosted = 1;
NSInteger const EditSiteRowCountForSectionJetpack = 1;

@interface EditSiteViewController () <UITableViewDelegate, UITextFieldDelegate, UIAlertViewDelegate>

@property (nonatomic,   weak) IBOutlet UITableView *tableView;
@property (nonatomic, strong) UIBarButtonItem *saveButton;
@property (nonatomic, strong) UIActivityIndicatorView *savingIndicator;
@property (nonatomic,   weak) UITextField *lastTextField;
@property (nonatomic,   weak) UITextField *usernameTextField;
@property (nonatomic,   weak) UITextField *passwordTextField;
@property (nonatomic,   weak) UITextField *urlTextField;

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

@implementation EditSiteViewController

- (instancetype)initWithBlog:(Blog *)blog
{
    self = [super init];
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

    if (self.blog) {
        self.navigationItem.title = NSLocalizedString(@"Settings", @"");

        [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];

        self.url = self.blog.url;
        self.authToken = self.blog.authToken;
        self.username = self.blog.username;
        self.password = self.blog.password;

        self.startingUser = self.username;
        self.startingPwd = self.password;
        self.startingUrl = self.url;
        self.geolocationEnabled = self.blog.geolocationEnabled;

        _notificationPreferences = [[[NSUserDefaults standardUserDefaults] objectForKey:@"notification_preferences"] mutableCopy];
        if (!_notificationPreferences) {
            [NotificationsManager fetchNotificationSettingsWithSuccess:^{
                [self reloadNotificationSettings];
            } failure:^(NSError *error) {
                [WPError showAlertWithTitle:NSLocalizedString(@"Error", @"") message:error.localizedDescription];
            }];
        }
    }

    if (self.isCancellable) {
        UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", nil)
                                                                      style:UIBarButtonItemStylePlain
                                                                     target:self
                                                                     action:@selector(cancel:)];
        self.navigationItem.leftBarButtonItem = barButton;
    }

    // Create the save button but don't show it until something changes
    self.saveButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Save", @"Save button label (saving content, ex: Post, Page, Comment, Category).") style:[WPStyleGuide barButtonStyleForDone] target:self action:@selector(save:)];

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

    [self.tableView registerClass:[UITableViewTextFieldCell class] forCellReuseIdentifier:TextFieldCellIdentifier];
    [self.tableView registerClass:[WPTableViewCell class] forCellReuseIdentifier:GeotaggingCellIdentifier];
    [self.tableView registerClass:[WPTableViewCell class] forCellReuseIdentifier:PushNotificationsCellIdentifier];
    [self.tableView registerClass:[WPTableViewCell class] forCellReuseIdentifier:JetpackConnectedCellIdentifier];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self.tableView reloadData];
}

#pragma mark - UITableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (self.blog && !self.blog.account.isWpcom) {
        return EditSiteSectionCountSelfHosted;
    }
    return EditSiteSectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == TableViewSectionTitle) {
        if (self.blog.account.isWpcom) {
            return EditSiteRowCountForSectionTitle;
        }
        return EditSiteRowCountForSectionTitleSelfHosted;
    } else if (section == TableViewSectionSettings) {
        if ([self canTogglePushNotifications]) {
            return EditSiteRowCountForSectionSettings;
        }
        return EditSiteRowCountForSectionSettingsSelfHosted;
    } else if (section == TableViewSectionSelfHosted) {
        return EditSiteRowCountForSectionJetpack;
    }
    return 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSString *title = [self titleForHeaderInSection:section];
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
    if (section == TableViewSectionTitle) {
        headingTitle = self.blog.blogName;
    } else if (section == TableViewSectionSettings) {
        headingTitle = NSLocalizedString(@"Settings", @"");
    } else if (section == TableViewSectionSelfHosted) {
        headingTitle = NSLocalizedString(@"Jetpack Stats", @"");
    }
    return headingTitle;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([indexPath section] == TableViewSectionTitle) {
        if (indexPath.row == EditSiteRowURL) {
            UITableViewTextFieldCell *cell = [tableView dequeueReusableCellWithIdentifier:TextFieldCellIdentifier];
            self.urlTextField = cell.textField;
            cell.textLabel.text = NSLocalizedString(@"URL", @"");

            self.urlTextField.placeholder = NSLocalizedString(@"http://my-site-address (URL)", @"(placeholder) Help the user enter a URL into the field");
            self.urlTextField.keyboardType = UIKeyboardTypeURL;
            [self.urlTextField addTarget:self action:@selector(showSaveButton) forControlEvents:UIControlEventEditingChanged];
            [self configureTextField:self.urlTextField asPassword:NO];
            self.urlTextField.keyboardType = UIKeyboardTypeURL;
            if (self.blog.url != nil) {
                self.urlTextField.text = self.blog.url;

                // Make a margin exception for URLs since they're so long
                cell.minimumLabelWidth = EditSiteURLMinimumLabelWidth;
            } else {
                self.urlTextField.text = @"";
            }

            self.urlTextField.enabled = [self canEditUsernameAndURL];
            [WPStyleGuide configureTableViewTextCell:cell];

            return cell;
        } else if (indexPath.row == EditSiteRowUsername) {
            UITableViewTextFieldCell *cell = [tableView dequeueReusableCellWithIdentifier:TextFieldCellIdentifier];

            cell.textLabel.text = NSLocalizedString(@"Username", @"Label for entering username in the username field");
            self.usernameTextField = cell.textField;
            self.usernameTextField.placeholder = NSLocalizedString(@"Enter username", @"(placeholder) Help enter WordPress username");
            [self.usernameTextField addTarget:self action:@selector(showSaveButton) forControlEvents:UIControlEventEditingChanged];
            [self configureTextField:self.usernameTextField asPassword:NO];
            if (self.blog.username != nil) {
                self.usernameTextField.text = self.blog.username;
            } else {
                self.usernameTextField.text = @"";
            }

            self.usernameTextField.enabled = [self canEditUsernameAndURL];
            [WPStyleGuide configureTableViewTextCell:cell];

            return cell;
        } else if (indexPath.row == EditSiteRowPassword) {
            UITableViewTextFieldCell *cell = [tableView dequeueReusableCellWithIdentifier:TextFieldCellIdentifier];

            cell.textLabel.text = NSLocalizedString(@"Password", @"Label for entering password in password field");
            self.passwordTextField = cell.textField;
            self.passwordTextField.placeholder = NSLocalizedString(@"Enter password", @"(placeholder) Help user enter password in password field");
            [self.passwordTextField addTarget:self action:@selector(showSaveButton) forControlEvents:UIControlEventEditingChanged];
            [self configureTextField:self.passwordTextField asPassword:YES];
            if (self.password != nil) {
                self.passwordTextField.text = self.password;
            } else {
                self.passwordTextField.text = @"";
            }
            [WPStyleGuide configureTableViewTextCell:cell];

            // If the other rows can't be edited, it looks better to align the password to the right as well
            if (![self canEditUsernameAndURL]) {
                self.passwordTextField.textAlignment = NSTextAlignmentRight;
            }

            return cell;
        }
    } else if (indexPath.section == TableViewSectionSettings) {
        if (indexPath.row == EditSiteRowGeotagging) {
            UITableViewCell *geotaggingCell = [tableView dequeueReusableCellWithIdentifier:GeotaggingCellIdentifier];
            UISwitch *geotaggingSwitch = [[UISwitch alloc] init];
            geotaggingCell.textLabel.text = NSLocalizedString(@"Geotagging", @"Enables geotagging in blog settings (short label)");
            geotaggingCell.selectionStyle = UITableViewCellSelectionStyleNone;
            geotaggingSwitch.on = self.geolocationEnabled;
            [geotaggingSwitch addTarget:self action:@selector(toggleGeolocation:) forControlEvents:UIControlEventValueChanged];
            geotaggingCell.accessoryView = geotaggingSwitch;
            [WPStyleGuide configureTableViewCell:geotaggingCell];
            return geotaggingCell;

        } else if (indexPath.row == EditSiteRowPushNotifications) {
            UITableViewCell *pushCell = [tableView dequeueReusableCellWithIdentifier:PushNotificationsCellIdentifier];
            UISwitch *pushSwitch = [[UISwitch alloc] init];
            pushCell.textLabel.text = NSLocalizedString(@"Push Notifications", @"");
            pushCell.selectionStyle = UITableViewCellSelectionStyleNone;
            pushSwitch.on = [self getBlogPushNotificationsSetting];
            [pushSwitch addTarget:self action:@selector(togglePushNotifications:) forControlEvents:UIControlEventValueChanged];
            pushCell.accessoryView = pushSwitch;
            [WPStyleGuide configureTableViewCell:pushCell];
            return pushCell;
        }
    } else if (indexPath.section == TableViewSectionSelfHosted) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:JetpackConnectedCellIdentifier];

        cell.textLabel.text = NSLocalizedString(@"Configure", @"");
        if (self.blog.jetpack.connectedUsername) {
            cell.detailTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Connected as %@", @"Connected to jetpack as the specified usernaem"), self.blog.jetpack.connectedUsername];
        } else {
            cell.detailTextLabel.text = NSLocalizedString(@"Not connected", @"Jetpack is not connected yet.");
        }
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        [WPStyleGuide configureTableViewCell:cell];

        return cell;
    }

    // We shouldn't reach this point, but return an empty cell just in case
    return [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"NoCell"];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (indexPath.section == TableViewSectionTitle) {
        for (UIView *subview in cell.subviews) {
            if (subview.class == [UITextField class]) {
                [subview becomeFirstResponder];
                break;
            }
        }
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (indexPath.section == TableViewSectionSelfHosted) {
        JetpackSettingsViewController *controller = [[JetpackSettingsViewController alloc] initWithBlog:self.blog];
        controller.showFullScreen = NO;
        [controller setCompletionBlock:^(BOOL didAuthenticate) {
            [self.navigationController popViewControllerAnimated:YES];
        }];
        [self.navigationController pushViewController:controller animated:YES];
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
    }
    return NO;
}

- (BOOL)textField:(UITextField *)textField
    shouldChangeCharactersInRange:(NSRange)range
    replacementString:(NSString *)string
{
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

#pragma mark -
#pragma mark Custom methods

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
    [self.savingIndicator stopAnimating];
    [self.savingIndicator setHidden:YES];
    self.blog.geolocationEnabled = self.geolocationEnabled;
    self.blog.account.password = self.password;

    [self cancel:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"BlogsRefreshNotification" object:nil];

    self.saveButton.enabled = YES;
    [self.navigationItem setHidesBackButton:NO animated:NO];

}

- (void)validationDidFail:(NSError *)error
{
    [self.savingIndicator stopAnimating];
    [self.savingIndicator setHidden:YES];
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

- (void)save:(id)sender
{
    [self.urlTextField resignFirstResponder];
    [self.usernameTextField resignFirstResponder];
    [self.passwordTextField resignFirstResponder];

    self.url = [NSURL IDNEncodedURL:self.urlTextField.text];
    DDLogInfo(@"blog url: %@", self.url);
    self.username = self.usernameTextField.text;
    self.password = self.passwordTextField.text;

    if (!self.savingIndicator) {
        self.savingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        self.savingIndicator.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        CGRect frm = self.savingIndicator.frame;
        frm.origin.x = (self.tableView.frame.size.width / 2.0f) - (frm.size.width / 2.0f);
        self.savingIndicator.frame = frm;
        UIView *aView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.tableView.frame.size.width, frm.size.height)];
        [aView addSubview:self.savingIndicator];

        [self.tableView setTableFooterView:aView];
    }
    [self.savingIndicator setHidden:NO];
    [self.savingIndicator startAnimating];

    if (self.blog) {
        self.blog.geolocationEnabled = self.geolocationEnabled;
        [[ContextManager sharedInstance] saveContext:self.blog.managedObjectContext];
    }
    if (self.blog == nil || self.blog.username == nil) {
        [self validateUrl];
    } else {
        if ([self.startingUser isEqualToString:self.usernameTextField.text] &&
            [self.startingPwd isEqualToString:self.passwordTextField.text] &&
            [self.startingUrl isEqualToString:self.urlTextField.text]) {
            // No need to check if nothing changed
            [self cancel:nil];
        } else {
            [self validateUrl];
        }
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
