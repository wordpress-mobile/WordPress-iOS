#import <WordPressApi/WordPressApi.h>
#import "EditSiteViewController.h"
#import "NSURL+IDN.h"
#import "WordPressComApi.h"
#import "SupportViewController.h"
#import "WPWebViewController.h"
#import "ReachabilityUtils.h"
#import "WPAccount.h"
#import "Blog.h"
#import "WPTableViewSectionHeaderView.h"
#import "NotificationsManager.h"
#import <SVProgressHUD/SVProgressHUD.h>
#import <NSDictionary+SafeExpectations.h>
#import "NotificationsManager.h"
#import "AccountService.h"
#import "ContextManager.h"
#import <WPXMLRPC/WPXMLRPC.h>
#import "BlogService.h"

NS_ENUM(NSInteger, EditSiteRow) {
    EditSiteRowURL = 0,
    EditSiteRowUsername = 1,
    EditSiteRowPassword = 2,
    EditSiteRowTitle = 0,
    EditSiteRowTagline = 1,
    EditSiteRowGeotagging = 0,
    EditSiteRowPushNotifications = 1,
};

NS_ENUM(NSInteger, TableSectionContentType) {
    TableViewSectionTitle = 0,
    TableViewSectionGeneralSettings,
    TableViewSectionMobileSettings,
};

static NSString *const TextFieldCellIdentifier = @"TextFieldCellIdentifier";
static NSString *const GeotaggingCellIdentifier = @"GeotaggingCellIdentifier";
static NSString *const PushNotificationsCellIdentifier = @"PushNotificationsCellIdentifier";
static CGFloat const EditSiteRowHeight = 48.0;
NSInteger const EditSiteURLMinimumLabelWidth = 30;
NSInteger const EditSiteSectionCount = 3;

NSInteger const EditSiteRowCountForSectionTitle = 1;
NSInteger const EditSiteRowCountForSectionTitleSelfHosted = 3;
NSInteger const EditSiteRowCountForSectionSettings = 2;
NSInteger const EditSiteRowCountForSectionSettingsSelfHosted = 1;
NSInteger const EditSiteRowCountForSectionGeneralSettings = 2;

@interface EditSiteViewController () <UITableViewDelegate, UITextFieldDelegate, UIAlertViewDelegate>

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

@end

@implementation EditSiteViewController

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
    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    
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

    [self.tableView registerClass:[UITableViewTextFieldCell class] forCellReuseIdentifier:TextFieldCellIdentifier];
    [self.tableView registerClass:[WPTableViewCell class] forCellReuseIdentifier:GeotaggingCellIdentifier];
    [self.tableView registerClass:[WPTableViewCell class] forCellReuseIdentifier:PushNotificationsCellIdentifier];
    
    [self refreshData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self.tableView reloadData];
}

#pragma mark - UITableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return EditSiteSectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == TableViewSectionTitle) {
        if (self.blog.account) {
            return EditSiteRowCountForSectionTitle;
        }
        return EditSiteRowCountForSectionTitleSelfHosted;
    } else if (section == TableViewSectionMobileSettings) {
        if ([self canTogglePushNotifications]) {
            return EditSiteRowCountForSectionSettings;
        }
        return EditSiteRowCountForSectionSettingsSelfHosted;
    } else if (section == TableViewSectionGeneralSettings) {
        return EditSiteRowCountForSectionGeneralSettings;
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
    } else if (section == TableViewSectionMobileSettings) {
        headingTitle = NSLocalizedString(@"Settings", @"");
    }  else if (section == TableViewSectionGeneralSettings) {
        headingTitle = NSLocalizedString(@"General", @"");
    }
    return headingTitle;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForSectionTitleInRow:(NSInteger)row
{
    switch (row) {
        case EditSiteRowURL: {
            UITableViewTextFieldCell *cell = [tableView dequeueReusableCellWithIdentifier:TextFieldCellIdentifier];
            self.urlTextField = cell.textField;
            cell.textLabel.text = NSLocalizedString(@"URL", @"");            
            self.urlTextField.placeholder = NSLocalizedString(@"http://my-site-address (URL)", @"(placeholder) Help the user enter a URL into the field");
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
        } break;
        case EditSiteRowUsername: {
            UITableViewTextFieldCell *cell = [tableView dequeueReusableCellWithIdentifier:TextFieldCellIdentifier];
            
            cell.textLabel.text = NSLocalizedString(@"Username", @"Label for entering username in the username field");
            self.usernameTextField = cell.textField;
            self.usernameTextField.placeholder = NSLocalizedString(@"Enter username", @"(placeholder) Help enter WordPress username");
            [self.usernameTextField addTarget:self action:@selector(showSaveButton) forControlEvents:UIControlEventEditingChanged];
            [self configureTextField:self.usernameTextField asPassword:NO];
            if (self.blog.usernameForSite != nil) {
                self.usernameTextField.text = self.blog.usernameForSite;
            } else {
                self.usernameTextField.text = @"";
            }
            
            self.usernameTextField.enabled = [self canEditUsernameAndURL];
            [WPStyleGuide configureTableViewTextCell:cell];
            
            return cell;
        } break;
        case EditSiteRowPassword: {
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
        } break;
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForMobileSettingsAtRow:(NSInteger)row
{
    if (row == EditSiteRowGeotagging) {
        UITableViewCell *geotaggingCell = [tableView dequeueReusableCellWithIdentifier:GeotaggingCellIdentifier];
        UISwitch *geotaggingSwitch = [[UISwitch alloc] init];
        geotaggingCell.textLabel.text = NSLocalizedString(@"Geotagging", @"Enables geotagging in blog settings (short label)");
        geotaggingCell.selectionStyle = UITableViewCellSelectionStyleNone;
        geotaggingSwitch.on = self.geolocationEnabled;
        [geotaggingSwitch addTarget:self action:@selector(toggleGeolocation:) forControlEvents:UIControlEventValueChanged];
        geotaggingCell.accessoryView = geotaggingSwitch;
        [WPStyleGuide configureTableViewCell:geotaggingCell];
        return geotaggingCell;
    } else if (row == EditSiteRowPushNotifications) {
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
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForSectionGeneralSettingsInRow:(NSInteger)row
{
    switch (row) {
        case EditSiteRowTitle: {
            UITableViewTextFieldCell *cell = [tableView dequeueReusableCellWithIdentifier:TextFieldCellIdentifier];
            cell.textLabel.text = NSLocalizedString(@"Title", @"");
            self.siteTitleTextField = cell.textField;
            self.siteTitleTextField.placeholder = NSLocalizedString(@"A title for the site", @"Placeholder text for the title of a site");
            [self.siteTitleTextField addTarget:self action:@selector(showSaveButton) forControlEvents:UIControlEventEditingChanged];
            [self configureTextField:self.siteTitleTextField asPassword:NO];
            self.siteTitleTextField.keyboardType = UIKeyboardTypeDefault;
            if (self.blog.blogName != nil) {
                self.siteTitleTextField.text = self.blog.blogName;
                
                // Make a margin exception for URLs since they're so long
                cell.minimumLabelWidth = EditSiteURLMinimumLabelWidth;
            } else {
                self.siteTitleTextField.text = @"";
            }
            
            self.siteTitleTextField.enabled = YES;
            [WPStyleGuide configureTableViewTextCell:cell];
            
            return cell;
        } break;
        case EditSiteRowTagline: {
            UITableViewTextFieldCell *cell = [tableView dequeueReusableCellWithIdentifier:TextFieldCellIdentifier];
            cell.textLabel.text = NSLocalizedString(@"Tagline", @"");
            self.siteTaglineTextField = cell.textField;
            self.siteTaglineTextField.placeholder = NSLocalizedString(@"In a few words, explain what this site is about.", @"Placeholder text for the tagline of a site");
            [self.siteTaglineTextField addTarget:self action:@selector(showSaveButton) forControlEvents:UIControlEventEditingChanged];
            [self configureTextField:self.siteTaglineTextField asPassword:NO];
            self.siteTaglineTextField.keyboardType = UIKeyboardTypeDefault;
            self.siteTaglineTextField.text = self.blog.blogTagline;
            cell.minimumLabelWidth = EditSiteURLMinimumLabelWidth;
            self.siteTaglineTextField.enabled = YES;
            [WPStyleGuide configureTableViewTextCell:cell];
            
            return cell;
        } break;
    }
    return [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"NoCell"];;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case TableViewSectionTitle:
            return [self tableView:tableView cellForSectionTitleInRow:indexPath.row];
            break;
        case TableViewSectionMobileSettings: {
            return [self tableView:tableView cellForMobileSettingsAtRow:indexPath.row];
            break;
        }
        case TableViewSectionGeneralSettings: {
            return [self tableView:tableView cellForSectionGeneralSettingsInRow:indexPath.row];
            break;
        }
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

#pragma mark - Custom methods

- (void)refreshData
{
    [self.refreshControl beginRefreshing];
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

- (void)save:(id)sender
{
    [self.urlTextField resignFirstResponder];
    [self.usernameTextField resignFirstResponder];
    [self.passwordTextField resignFirstResponder];
    self.url = [NSURL IDNEncodedURL:self.urlTextField.text];
    self.username = self.usernameTextField.text;
    self.password = self.passwordTextField.text;
    BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:self.blog.managedObjectContext];
    self.blog.blogName = self.siteTitleTextField.text;
    self.blog.blogTagline = self.siteTaglineTextField.text;
    self.blog.geolocationEnabled = self.geolocationEnabled;
    if ([self.blog hasChanges]) {
        [SVProgressHUD show];
        [blogService updateSettingForBlog:self.blog success:^{
            [SVProgressHUD showInfoWithStatus:@"Settings Saved"];
        } failure:^(NSError *error) {
            [SVProgressHUD showErrorWithStatus:@"Settings update failed"];
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
