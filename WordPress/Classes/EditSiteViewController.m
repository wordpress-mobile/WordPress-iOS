//
//  EditBlogViewController.m
//  WordPress
//
//  Created by Chris Boyd on 7/23/10.

#import <WordPressApi/WordPressApi.h>
#import "EditSiteViewController.h"
#import "NSURL+IDN.h"
#import "WordPressComApi.h"
#import "AFHTTPClient.h"
#import "SupportViewController.h"
#import "WPWebViewController.h"
#import "JetpackSettingsViewController.h"
#import "ReachabilityUtils.h"
#import "WPAccount.h"
#import "WPTableViewSectionHeaderView.h"
#import <WPXMLRPC/WPXMLRPC.h>
#import <SVProgressHUD/SVProgressHUD.h>
#import <NSDictionary+SafeExpectations.h>

@interface EditSiteViewController ()

@property (nonatomic, copy) NSString *startingPwd, *startingUser, *startingUrl;
@property (nonatomic, strong) UITableViewTextFieldCell *urlCell, *usernameCell, *passwordCell;
@property (nonatomic, weak) UITextField *lastTextField;
@property (nonatomic, strong) UIActivityIndicatorView *savingIndicator;
@property (nonatomic, strong) NSMutableDictionary *notificationPreferences;
@property (nonatomic, strong) UIAlertView *failureAlertView;

@end

@implementation EditSiteViewController

- (id)initWithBlog:(Blog *)blog {
    self = [super init];
    if (self) {
        _blog = blog;
    }
    return self;
}

- (void)dealloc {
    self.failureAlertView.delegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    DDLogInfo(@"%@ %@", self, NSStringFromSelector(_cmd));
    [super viewDidLoad];
    
    if (self.blog) {
        self.navigationItem.title = NSLocalizedString(@"Edit Blog", @"");

        [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
        
        self.url = self.blog.url;
        self.username = self.blog.username;
		self.password = self.blog.password;

        self.startingUser = self.username;
        self.startingPwd = self.password;
        self.startingUrl = self.url;
        self.geolocationEnabled = self.blog.geolocationEnabled;
        
        _notificationPreferences = [[[NSUserDefaults standardUserDefaults] objectForKey:@"notification_preferences"] mutableCopy];
        if (!_notificationPreferences) {
            [[WordPressComApi sharedApi] fetchNotificationSettings:^{
                [self reloadNotificationSettings];
            } failure:^(NSError *error) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"")
                                                                message:error.localizedDescription
                                                               delegate:nil
                                                      cancelButtonTitle:NSLocalizedString(@"OK", @"OK button label.")
                                                      otherButtonTitles:nil, nil];
                [alert show];
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
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.tableView reloadData];
}

#pragma mark - UITableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv {
    if (self.blog && ![self.blog isWPcom]) {
        return 3;
    }
    return 2;
}

- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)section {
    switch (section) {
		case 0:
            return 3;	// URL, username, password
		case 1: // Settings: Geolocation, [ Push Notifications ]
            if (self.blog && ( [self.blog isWPcom] || [self.blog hasJetpack] ) && [[WordPressComApi sharedApi] hasCredentials] && [[NSUserDefaults standardUserDefaults] objectForKey:kApnsDeviceTokenPrefKey] != nil)
                return 2;
            else
                return 1;	
        case 2:
            return 1;
	}
    
	return 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    WPTableViewSectionHeaderView *header = [[WPTableViewSectionHeaderView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 0)];
    header.title = [self titleForHeaderInSection:section];
    
    return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    NSString *title = [self titleForHeaderInSection:section];
    CGFloat height = [WPTableViewSectionHeaderView heightForTitle:title andWidth:CGRectGetWidth(self.view.bounds)];
    
    return height;
}

- (NSString *)titleForHeaderInSection:(NSInteger)section {
	switch (section) {
		case 0:
			return self.blog.blogName;
        case 1:
            return NSLocalizedString(@"Settings", @"");
        case 2:
            return NSLocalizedString(@"Jetpack Stats", @"");
	}
	return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *const URLCellIdentifer = @"URLCell";
    static NSString *const UsernameCellIdentifier = @"UsernameCell";
    static NSString *const PasswordCellIdentifier = @"PasswordCell";
    
    if ([indexPath section] == 0) {
        if (indexPath.row == 0) {
            self.urlCell = (UITableViewTextFieldCell *)[tableView dequeueReusableCellWithIdentifier:URLCellIdentifer];
            if (!self.urlCell) {
                UITableViewTextFieldCell *urlCell = [[UITableViewTextFieldCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:URLCellIdentifer];
                self.urlCell = urlCell;
				self.urlCell.textLabel.text = NSLocalizedString(@"URL", @"");
				UITextField *urlField = self.urlCell.textField;
				urlField.placeholder = NSLocalizedString(@"http://my-site-address (URL)", @"(placeholder) Help the user enter a URL into the field");
                urlField.keyboardType = UIKeyboardTypeURL;
                [urlField addTarget:self action:@selector(showSaveButton) forControlEvents:UIControlEventEditingChanged];
                [self configureTextField:urlField asPassword:NO];
                urlField.keyboardType = UIKeyboardTypeURL;
				if (self.blog.url != nil) {
					urlField.text = self.blog.url;
                    
                    // Make a margin exception for URLs since they're so long
                    self.urlCell.minimumLabelWidth = 30;
                } else {
                    urlField.text = @"";
                }
                
                urlField.enabled = [self canEditUsernameAndURL];
                [WPStyleGuide configureTableViewTextCell:self.urlCell];
            }
            
            return self.urlCell;
        }
        else if (indexPath.row == 1) {
            self.usernameCell = [tableView dequeueReusableCellWithIdentifier:UsernameCellIdentifier];
            if (self.usernameCell == nil) {
                self.usernameCell = [[UITableViewTextFieldCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:UsernameCellIdentifier];
				self.usernameCell.textLabel.text = NSLocalizedString(@"Username", @"Label for entering username in the username field");
                UITextField *usernameField = self.usernameCell.textField;
				usernameField = self.usernameCell.textField;
				usernameField.placeholder = NSLocalizedString(@"Enter username", @"(placeholder) Help enter WordPress username");
                [usernameField addTarget:self action:@selector(showSaveButton) forControlEvents:UIControlEventEditingChanged];
                [self configureTextField:usernameField asPassword:NO];
				if (self.blog.username != nil) {
					usernameField.text = self.blog.username;
                } else {
                    usernameField.text = @"";
                }

                usernameField.enabled = [self canEditUsernameAndURL];
                [WPStyleGuide configureTableViewTextCell:self.usernameCell];
			}
            
            return self.usernameCell;
        }
        else if (indexPath.row == 2) {
            self.passwordCell = (UITableViewTextFieldCell *)[tableView dequeueReusableCellWithIdentifier:PasswordCellIdentifier];
            if (self.passwordCell == nil) {
                self.passwordCell = [[UITableViewTextFieldCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:PasswordCellIdentifier];
				self.passwordCell.textLabel.text = NSLocalizedString(@"Password", @"Label for entering password in password field");
                UITextField *passwordField = self.passwordCell.textField;
				passwordField = self.passwordCell.textField;
				passwordField.placeholder = NSLocalizedString(@"Enter password", @"(placeholder) Help user enter password in password field");
                [passwordField addTarget:self action:@selector(showSaveButton) forControlEvents:UIControlEventEditingChanged];
                [self configureTextField:passwordField asPassword:YES];
				if (self.password != nil) {
					passwordField.text = self.password;
                } else {
                    passwordField.text = @"";
                }
                [WPStyleGuide configureTableViewTextCell:self.passwordCell];
                
                // If the other rows can't be edited, it looks better to align the password to the right as well
                if (![self canEditUsernameAndURL]) {
                    passwordField.textAlignment = NSTextAlignmentRight;
                }
			}
            
            return self.passwordCell;
        }
    } else if(indexPath.section == 1) {
        if(indexPath.row == 0) {
            UITableViewCell *geotaggingCell = [tableView dequeueReusableCellWithIdentifier:@"GeotaggingCell"];
            if(geotaggingCell == nil) {
                geotaggingCell = [[WPTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"GeotaggingCell"];
                geotaggingCell.accessoryView = [[UISwitch alloc] init];
            }
            UISwitch *geotaggingSwitch = (UISwitch *)geotaggingCell.accessoryView;
            geotaggingCell.textLabel.text = NSLocalizedString(@"Geotagging", @"Enables geotagging in blog settings (short label)");
            geotaggingCell.selectionStyle = UITableViewCellSelectionStyleNone;
            geotaggingSwitch.on = self.geolocationEnabled;
            [geotaggingSwitch addTarget:self action:@selector(toggleGeolocation:) forControlEvents:UIControlEventValueChanged];
            [WPStyleGuide configureTableViewCell:geotaggingCell];
            return geotaggingCell;
        } else if(indexPath.row == 1) {
            UITableViewCell *pushCell = [tableView dequeueReusableCellWithIdentifier:@"PushCell"];
            if(pushCell == nil) {
                pushCell = [[WPTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"PushCell"];
                pushCell.accessoryView = [[UISwitch alloc] init];
            }
            UISwitch *pushSwitch = (UISwitch *)pushCell.accessoryView;
            pushCell.textLabel.text = NSLocalizedString(@"Push Notifications", @"");
            pushCell.selectionStyle = UITableViewCellSelectionStyleNone;
            pushSwitch.on = [self getBlogPushNotificationsSetting];
            [WPStyleGuide configureTableViewCell:pushCell];
            return pushCell;
        }
	} else if (indexPath.section == 2) {
        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"Cell"];
        }
        cell.textLabel.text = NSLocalizedString(@"Configure", @"");
        if (self.blog.jetpackUsername) {
            cell.detailTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Connected as %@", @"Connected to jetpack as the specified usernaem"), self.blog.jetpackUsername];
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

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [tv cellForRowAtIndexPath:indexPath];
	if (indexPath.section == 0) {
        for (UIView *subview in cell.subviews) {
            if (subview.class == [UITextField class]) {
                [subview becomeFirstResponder];
                break;
            }
        }
	} 
    [tv deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 2) {
        JetpackSettingsViewController *controller = [[JetpackSettingsViewController alloc] initWithBlog:self.blog];
        controller.showFullScreen = NO;
        [controller setCompletionBlock:^(BOOL didAuthenticate) {
            [self.navigationController popViewControllerAnimated:YES];
        }];
        [self.navigationController pushViewController:controller animated:YES];
    }
}

#pragma mark - UITextField methods

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    if (self.lastTextField) {
        self.lastTextField = nil;
    }
    self.lastTextField = textField;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.urlCell.textField) {
        [self.usernameCell.textField becomeFirstResponder];
    } else if (textField == self.usernameCell.textField) {
        [self.passwordCell.textField becomeFirstResponder];
    } else if (textField == self.passwordCell.textField) {
        [self.passwordCell.textField resignFirstResponder];
    }
	return NO;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    UITableViewCell *cell = (UITableViewCell *)[textField superview];
    
    if (NSClassFromString(@"UITableViewCellScrollView")) {
        // iOS7 introduced a private class in between the normal UITableViewCell and the cell views.
        cell = (UITableViewCell*)[cell superview];
    }
    NSMutableString *result = [NSMutableString stringWithString:textField.text];
    [result replaceCharactersInRange:range withString:string];

    if ([result length] == 0) {
        cell.textLabel.textColor = WRONG_FIELD_COLOR;
    } else {
        cell.textLabel.textColor = GOOD_FIELD_COLOR;        
    }
    
    return YES;
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex { 
	switch (buttonIndex) {
		case 0: {
            if ( alertView.tag == 20 ) {
                //Domain Error or malformed response
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString: @"http://ios.wordpress.org/faq/#faq_3"]];
            } else {
                SupportViewController *supportViewController = [[SupportViewController alloc] init];
                [self.navigationController pushViewController:supportViewController animated:YES];
            }
			break;
		}
		case 1:
            if (alertView.tag == 30){
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
                
                WPWebViewController *webViewController = [[WPWebViewController alloc] init];
                [webViewController setUrl:[NSURL URLWithString:path]];
                [webViewController setUsername:self.username];
                [webViewController setPassword:self.password];
                [webViewController setWpLoginURL:[NSURL URLWithString:self.blog.loginUrl]];
                webViewController.shouldScrollToBottom = YES;
                [self.navigationController pushViewController:webViewController animated:YES];
            } else {
                //OK
            }
			break;
		default:
			break;
	}
    if (self.failureAlertView == alertView) {
        self.failureAlertView = nil;
    }
}


#pragma mark -
#pragma mark Custom methods

- (void)configureTextField:(UITextField *)textField asPassword:(BOOL)asPassword {
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

- (void)toggleGeolocation:(id)sender {
    UISwitch *geolocationSwitch = (UISwitch *)sender;
    self.geolocationEnabled = geolocationSwitch.on;
}

- (void)togglePushNotifications:(id)sender {    
    UISwitch *pushSwitch = (UISwitch *)sender;
    BOOL muted = !pushSwitch.on;
    if (_notificationPreferences) {
        NSMutableDictionary *mutedBlogsDictionary = [[_notificationPreferences objectForKey:@"muted_blogs"] mutableCopy];
        NSMutableArray *mutedBlogsArray = [[mutedBlogsDictionary objectForKey:@"value"] mutableCopy];
        NSMutableDictionary *updatedPreference;

        NSNumber *blogID = [self.blog isWPcom] ? self.blog.blogID : [self.blog jetpackBlogID];
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
                [[WordPressComApi sharedApi] saveNotificationSettings:nil failure:nil];
                return;
            }
        }
    }
}

- (NSString *)getURLToValidate {
    NSString *urlToValidate = self.url;
	
    if (![urlToValidate hasPrefix:@"http"]) {
        urlToValidate = [NSString stringWithFormat:@"http://%@", self.url];
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

- (void)validateXmlprcURL:(NSURL *)xmlRpcURL {
    WordPressXMLRPCApi *api = [WordPressXMLRPCApi apiWithXMLRPCEndpoint:xmlRpcURL username:self.usernameCell.textField.text password:self.passwordCell.textField.text];

    [api getBlogOptionsWithSuccess:^(id options){
        if ([options objectForKey:@"wordpress.com"] != nil) {
            self.isSiteDotCom = YES;
            self.blogId = [options stringForKeyPath:@"blog_id.value"];
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

- (void)loginForSiteWithXmlRpcUrl:(NSURL *)xmlRpcURL {
    WordPressXMLRPCApi *api = [WordPressXMLRPCApi apiWithXMLRPCEndpoint:xmlRpcURL username:self.usernameCell.textField.text password:self.passwordCell.textField.text];
    [api getBlogsWithSuccess:^(NSArray *blogs) {
        [SVProgressHUD dismiss];
        self.subsites = blogs;
        [self validationSuccess:[xmlRpcURL absoluteString]];
    } failure:^(NSError *error) {
        [SVProgressHUD dismiss];
        [self validationDidFail:error];
    }];
}

- (void)checkURL {
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
		} else if([error.domain isEqual:AFNetworkingErrorDomain]) {
			NSString *str = [NSString stringWithFormat:NSLocalizedString(@"There was a server error communicating with your site:\n%@\nTap 'Need Help?' to view the FAQ.", @""), [error localizedDescription]];
			NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                      str, NSLocalizedDescriptionKey,
                                      nil];
            NSError *err = [NSError errorWithDomain:@"org.wordpress.iphone" code:NSURLErrorBadServerResponse userInfo:userInfo];
            [self validationDidFail:err];
        } else {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                      NSLocalizedString(@"Unable to find a WordPress site at that URL. Tap 'Need Help?' to view the FAQ.", @""), NSLocalizedDescriptionKey,
                                      nil];
            NSError *err = [NSError errorWithDomain:@"org.wordpress.iphone" code:NSURLErrorBadURL userInfo:userInfo];
            [self validationDidFail:err];
        }
    }];
}

- (void)validationSuccess:(NSString *)xmlrpc {
	[self.savingIndicator stopAnimating];
	[self.savingIndicator setHidden:YES];
    self.blog.geolocationEnabled = self.geolocationEnabled;
    self.blog.account.password = self.password;

    [self cancel:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"BlogsRefreshNotification" object:nil];

    self.saveButton.enabled = YES;
    [self.navigationItem setHidesBackButton:NO animated:NO];

}

- (void)validationDidFail:(NSError *)error {
	[self.savingIndicator stopAnimating];
	[self.savingIndicator setHidden:YES];
    self.saveButton.enabled = YES;
	[self.navigationItem setHidesBackButton:NO animated:NO];

    if (error) {
        NSString *message;
        if ([error code] == 403) {
            message = NSLocalizedString(@"Please try entering your login details again.", @"");
        } else {
            message = [error localizedDescription];
        }

        if (self.failureAlertView == nil) {
            if ([error code] == 405) { // XMLRPC disabled.
                self.failureAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Sorry, can't log in", @"")
                                                              message:message
                                                             delegate:self
                                                    cancelButtonTitle:NSLocalizedString(@"Need Help?", @"")
                                                    otherButtonTitles:NSLocalizedString(@"Enable Now", @""), nil];

                self.failureAlertView.tag = 30;
            } else {
                self.failureAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Sorry, can't log in", @"")
                                                       message:message
                                                      delegate:self
                                             cancelButtonTitle:NSLocalizedString(@"Need Help?", @"")
                                             otherButtonTitles:NSLocalizedString(@"OK", @""), nil];

                if ( [error code] == NSURLErrorBadURL ) {
                    self.failureAlertView.tag = 20; // take the user to the FAQ page when hit "Need Help"
                } else {
                    self.failureAlertView.tag = 10;
                }
            }

            [self.failureAlertView show];
        }
    }
}

- (void)validateFields {
    self.url = [NSURL IDNEncodedURL:self.urlCell.textField.text];
    DDLogInfo(@"blog url: %@", self.url);
    self.username = self.usernameCell.textField.text;
    self.password = self.passwordCell.textField.text;
    
    self.saveButton.enabled = NO;
	[self.navigationItem setHidesBackButton:YES animated:NO];
    BOOL validFields = YES;
    if ([self.urlCell.textField.text isEqualToString:@""]) {
        validFields = NO;
        self.urlCell.textLabel.textColor = WRONG_FIELD_COLOR;
    }
    if ([self.usernameCell.textField.text isEqualToString:@""]) {
        validFields = NO;
        self.usernameCell.textLabel.textColor = WRONG_FIELD_COLOR;
    }
    if ([self.passwordCell.textField.text isEqualToString:@""]) {
        validFields = NO;
        self.passwordCell.textLabel.textColor = WRONG_FIELD_COLOR;
    }
    
    if (validFields) {
        if (self.blog) {
            // If we are editing an existing blog, use the known XML-RPC URL
            // We don't allow editing URL on existing blogs, so XML-RPC shouldn't change
            [self validateXmlprcURL:[NSURL URLWithString:self.blog.xmlrpc]];
        } else {
            [self checkURL];
        }
    } else {
        [self validationDidFail:nil];
    }
}

- (void)save:(id)sender {
    [self.urlCell.textField resignFirstResponder];
    [self.usernameCell.textField resignFirstResponder];
    [self.passwordCell.textField resignFirstResponder];

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
        [self.blog dataSave];
	}
    if (self.blog == nil || self.blog.username == nil) {
		[self validateFields];
	} else {
		if ([self.startingUser isEqualToString:self.usernameCell.textField.text] &&
            [self.startingPwd isEqualToString:self.passwordCell.textField.text] &&
			[self.startingUrl isEqualToString:self.urlCell.textField.text]) {
			// No need to check if nothing changed
            [self cancel:nil];
		} else {
			[self validateFields];
		}
    }
}

- (IBAction)cancel:(id)sender {
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

- (void)showSaveButton {
    BOOL hasContent;
    
    if ([self.urlCell.textField.text isEqualToString:@""] ||
         [self.usernameCell.textField.text isEqualToString:@""] ||
         [self.passwordCell.textField.text isEqualToString:@""]) {
        hasContent = NO;
    } else {
        hasContent = YES;
    }
    
    self.navigationItem.rightBarButtonItem = hasContent ? self.saveButton : nil;
}

- (void)reloadNotificationSettings {
    self.notificationPreferences = [[[NSUserDefaults standardUserDefaults] objectForKey:@"notification_preferences"] mutableCopy];
    if (self.notificationPreferences) {
        [self.tableView reloadData];
    }
}

- (BOOL)getBlogPushNotificationsSetting {
    if (self.notificationPreferences) {
        NSDictionary *mutedBlogsDictionary = [self.notificationPreferences objectForKey:@"muted_blogs"];
        NSArray *mutedBlogsArray = [mutedBlogsDictionary objectForKey:@"value"];
        NSNumber *blogID = [self.blog isWPcom] ? self.blog.blogID : [self.blog jetpackBlogID];
        for (NSDictionary *currentBlog in mutedBlogsArray ){
            NSString *currentBlogID = [currentBlog objectForKey:@"blog_id"];
            if ([blogID intValue] == [currentBlogID intValue]) {
                return ![[currentBlog objectForKey:@"value"] boolValue];
            }
        }
    }
    return YES;
}

- (BOOL)canEditUsernameAndURL {
    return NO;
}

#pragma mark - Keyboard Related Methods

- (void)handleKeyboardDidShow:(NSNotification *)notification {    
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
}

- (void)handleKeyboardWillHide:(NSNotification *)notification {
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
}


- (void)handleViewTapped {
    [self.lastTextField resignFirstResponder];
}


@end
