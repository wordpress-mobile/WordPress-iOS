//
//  EditBlogViewController.m
//  WordPress
//
//  Created by Chris Boyd on 7/23/10.

#import "EditSiteViewController.h"
#import "NSURL+IDN.h"
#import "WordPressApi.h"
#import "WordPressComApi.h"
#import "SFHFKeychainUtils.h"
#import "UIBarButtonItem+Styled.h"
#import "AFHTTPClient.h"
#import "HelpViewController.h"
#import "WPWebViewController.h"
#import "JetpackAuthUtil.h"
#import "JetpackSettingsViewController.h"
#import "ReachabilityUtils.h"

@interface EditSiteViewController (PrivateMethods)

- (void)validateFields;
- (void)validationSuccess:(NSString *)xmlrpc;
- (void)validationDidFail:(id)wrong;
- (void)handleKeyboardDidShow:(NSNotification *)notification;
- (void)handleKeyboardWillHide:(NSNotification *)notification;
- (void)handleViewTapped;
- (void)configureTextField:(UITextField *)textField asPassword:(BOOL)asPassword;
- (NSString *)getURLToValidate;
- (void)enableDisableSaveButton;

@end

@implementation EditSiteViewController {
    UIAlertView *failureAlertView;
}

@synthesize password, username, url, geolocationEnabled;
@synthesize blog, tableView, savingIndicator;
@synthesize urlCell, usernameCell, passwordCell;
@synthesize isCancellable;
@synthesize delegate;
@synthesize startingPwd, startingUser, startingUrl;

#pragma mark -
#pragma mark View lifecycle

- (void)dealloc {
    self.delegate = nil;
    failureAlertView.delegate = nil;
}


- (void)viewDidLoad {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [super viewDidLoad];
    
    if (blog) {
        self.navigationItem.title = NSLocalizedString(@"Edit Blog", @"");
		self.tableView.backgroundColor = [UIColor clearColor];
		if (IS_IPAD){
			self.tableView.backgroundView = nil;
			self.tableView.backgroundColor = [UIColor clearColor];
		}
        self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"welcome_bg_pattern.png"]];
        
        NSError *error = nil;
        self.url = blog.url;
        self.username = blog.username;
        if ([blog isWPcom]) {
            self.password = [SFHFKeychainUtils getPasswordForUsername:blog.username andServiceName:@"WordPress.com" error:&error];
        } else {
            self.password = [SFHFKeychainUtils getPasswordForUsername:blog.username andServiceName:blog.hostURL error:&error];            
        }

        self.startingUser = self.username;
        self.startingPwd = self.password;
        self.startingUrl = self.url;
        self.geolocationEnabled = blog.geolocationEnabled;
    }
    
    if (isCancellable) {
        UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
        self.navigationItem.leftBarButtonItem = barButton;
    }
    
    saveButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Save", @"Save button label (saving content, ex: Post, Page, Comment, Category).") style:UIBarButtonItemStyleDone target:self action:@selector(save:)];
    self.navigationItem.rightBarButtonItem = saveButton;
    
    if (!IS_IPAD) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    }
    
    UITapGestureRecognizer *tgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleViewTapped)];
    tgr.cancelsTouchesInView = NO;
    [tableView addGestureRecognizer:tgr];

}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self refreshTable];
    [self enableDisableSaveButton];
}


- (void)viewDidUnload {
    [super viewDidUnload];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return [super shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv {
    if (blog && ![blog isWPcom]) {
        return 3;
    }
    return 2;
}


- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)section {
    switch (section) {
		case 0:
            return 3;	// URL, username, password
		case 1:
            return 1;	// Settings
        case 2:
//            if ([JetpackAuthUtil getJetpackUsernameForBlog:blog] != nil) {
//                return 2;
//            }
            return 1;
	}
	return 0;
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	NSString *result = nil;
	switch (section) {
		case 0:
			result = blog.blogName;
			break;
        case 1:
            result = NSLocalizedString(@"Settings", @"");
            break;
        case 2:
            result = NSLocalizedString(@"Jetpack Stats", @"");
	}
	return result;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath {    
    if ([indexPath section] == 0) {
        if (indexPath.row == 0) {
            self.urlCell = (UITableViewTextFieldCell *)[tableView dequeueReusableCellWithIdentifier:@"UrlCell"];
            if (self.urlCell == nil) {
                self.urlCell = [[UITableViewTextFieldCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"UrlCell"];
				self.urlCell.textLabel.text = NSLocalizedString(@"URL", @"");
				urlTextField = self.urlCell.textField;
				urlTextField.placeholder = NSLocalizedString(@"http://example.com", @"");
                [urlTextField addTarget:self action:@selector(enableDisableSaveButton) forControlEvents:UIControlEventEditingChanged];
                [self configureTextField:urlTextField asPassword:NO];
                urlTextField.keyboardType = UIKeyboardTypeURL;
				if (blog.url != nil) {
					urlTextField.text = blog.url;
                } else {
                    urlTextField.text = @"";
                }
            }
            
            return self.urlCell;
        }
        else if(indexPath.row == 1) {
            self.usernameCell = (UITableViewTextFieldCell *)[tableView dequeueReusableCellWithIdentifier:@"UsernameCell"];
            if (self.usernameCell == nil) {
                self.usernameCell = [[UITableViewTextFieldCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"UsernameCell"];
				self.usernameCell.textLabel.text = NSLocalizedString(@"Username", @"");
				usernameTextField = self.usernameCell.textField;
				usernameTextField.placeholder = NSLocalizedString(@"WordPress username", @"");
                [usernameTextField addTarget:self action:@selector(enableDisableSaveButton) forControlEvents:UIControlEventEditingChanged];
                [self configureTextField:usernameTextField asPassword:NO];
				if (blog.username != nil) {
					usernameTextField.text = blog.username;
                } else {
                    usernameTextField.text = @"";
                }
			}
            
            return self.usernameCell;
        }
        else if(indexPath.row == 2) {
            self.passwordCell = (UITableViewTextFieldCell *)[tableView dequeueReusableCellWithIdentifier:@"PasswordCell"];
            if (self.passwordCell == nil) {
                self.passwordCell = [[UITableViewTextFieldCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"PasswordCell"];
				self.passwordCell.textLabel.text = NSLocalizedString(@"Password", @"");
				passwordTextField = self.passwordCell.textField;
				passwordTextField.placeholder = NSLocalizedString(@"WordPress password", @"");
                [passwordTextField addTarget:self action:@selector(enableDisableSaveButton) forControlEvents:UIControlEventEditingChanged];
                [self configureTextField:passwordTextField asPassword:YES];
				if (password != nil) {
					passwordTextField.text = password;
                } else {
                    passwordTextField.text = @"";
                }
			}
            return self.passwordCell;
        }				        
    } else if(indexPath.section == 1) {
        if(switchCell == nil) {
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"UITableViewSwitchCell" owner:nil options:nil];
            for(id currentObject in topLevelObjects)
            {
                if([currentObject isKindOfClass:[UITableViewSwitchCell class]])
                {
                    switchCell = (UITableViewSwitchCell *)currentObject;
                    break;
                }
            }
        }
        switchCell.textLabel.text = NSLocalizedString(@"Geotagging", @"Enables geotagging in blog settings (short label)");
        switchCell.selectionStyle = UITableViewCellSelectionStyleNone;
        switchCell.cellSwitch.on = self.geolocationEnabled;
        [switchCell.cellSwitch addTarget:self action:@selector(toggleGeolocation:) forControlEvents:UIControlEventValueChanged];
        return switchCell;
	} else if(indexPath.section == 2) {
        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
        if(!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"Cell"];
        };
        cell.textLabel.text = NSLocalizedString(@"Configure", @"");
        if ([JetpackAuthUtil getJetpackUsernameForBlog:blog] != nil) {
            cell.detailTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Connected as %@", @"Connected to jetpack as the specified usernaem"), [JetpackAuthUtil getJetpackUsernameForBlog:blog]];
        } else {
            cell.detailTextLabel.text = NSLocalizedString(@"Not connected", @"Jetpack is not connected yet.");
        }
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        cell.detailTextLabel.textColor = [UIColor UIColorFromHex:0x888888];
        
        return cell;        
    }
    
    // We shouldn't reach this point, but return an empty cell just in case
    return [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"NoCell"];
}


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [tv cellForRowAtIndexPath:indexPath];
	if (indexPath.section == 0) {
        for(UIView *subview in cell.subviews) {
            if(subview.class == [UITextField class]) {
                [subview becomeFirstResponder];
                break;
            }
        }
	} 
    [tv deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 2) {
        JetpackSettingsViewController *controller = [[JetpackSettingsViewController alloc] initWithNibName:nil bundle:nil];
        controller.blog = blog;
        [self.navigationController pushViewController:controller animated:YES];
    }
}


#pragma mark -
#pragma mark UITextField methods

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    if (lastTextField) {
        lastTextField = nil;
    }
    lastTextField = textField;
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField.returnKeyType == UIReturnKeyNext) {
        UITableViewCell *cell = (UITableViewCell *)[textField superview];
        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
        NSIndexPath *nextIndexPath = [NSIndexPath indexPathForRow:(indexPath.row + 1) inSection:indexPath.section];
        UITableViewCell *nextCell = [self.tableView cellForRowAtIndexPath:nextIndexPath];
        if (nextCell) {
            for (UIView *subview in [nextCell subviews]) {
                if ([subview isKindOfClass:[UITextField class]]) {
                    [subview becomeFirstResponder];
                    break;
                }
            }
        }
    }
	[textField resignFirstResponder];
	return NO;
}


- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    UITableViewCell *cell = (UITableViewCell *)[textField superview];
    NSMutableString *result = [NSMutableString stringWithString:textField.text];
    [result replaceCharactersInRange:range withString:string];

    if ([result length] == 0) {
        cell.textLabel.textColor = WRONG_FIELD_COLOR;
    } else {
        cell.textLabel.textColor = GOOD_FIELD_COLOR;        
    }
    
    return YES;
}

#pragma mark -
#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex { 
	switch(buttonIndex) {
		case 0: {
            if ( alertView.tag == 20 ) {
                //Domain Error or malformed response
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString: @"http://ios.wordpress.org/faq/#faq_3"]];
            } else {
                HelpViewController *helpViewController = [[HelpViewController alloc] init];
                helpViewController.isBlogSetup = YES;
                [self.navigationController pushViewController:helpViewController animated:YES];
            }
			break;
		}
		case 1:
            if (alertView.tag == 30){
                NSString *path = nil;
                NSError *error = NULL;
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
                
                WPWebViewController *webViewController;
                if ( IS_IPAD ) {
                    webViewController = [[WPWebViewController alloc] initWithNibName:@"WPWebViewController-iPad" bundle:nil];
                } else {
                    webViewController = [[WPWebViewController alloc] initWithNibName:@"WPWebViewController" bundle:nil];
                }
                [webViewController setUrl:[NSURL URLWithString:path]];
                [webViewController setUsername:self.username];
                [webViewController setPassword:self.password];
                [webViewController setWpLoginURL:[NSURL URLWithString:blog.loginURL]];
                webViewController.shouldScrollToBottom = YES;
                [self.navigationController pushViewController:webViewController animated:YES];
            } else {
                //OK
            }
			break;
		default:
			break;
	}
    if (failureAlertView == alertView) {
        failureAlertView = nil;
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
    } else {
        textField.returnKeyType = UIReturnKeyNext;
    }
}


- (void)toggleGeolocation:(id)sender {
    self.geolocationEnabled = switchCell.cellSwitch.on;
}


- (void)refreshTable {
	[self.tableView reloadData];
}


- (NSString *)getURLToValidate {
    NSString *urlToValidate = self.url;
	
    if(![urlToValidate hasPrefix:@"http"])
        urlToValidate = [NSString stringWithFormat:@"http://%@", url];
	
    NSError *error = NULL;
    
    NSRegularExpression *wplogin = [NSRegularExpression regularExpressionWithPattern:@"/wp-login.php$" options:NSRegularExpressionCaseInsensitive error:&error];
    NSRegularExpression *wpadmin = [NSRegularExpression regularExpressionWithPattern:@"/wp-admin/?$" options:NSRegularExpressionCaseInsensitive error:&error];
    NSRegularExpression *trailingslash = [NSRegularExpression regularExpressionWithPattern:@"/?$" options:NSRegularExpressionCaseInsensitive error:&error];
    
    urlToValidate = [wplogin stringByReplacingMatchesInString:urlToValidate options:0 range:NSMakeRange(0, [urlToValidate length]) withTemplate:@""];
    urlToValidate = [wpadmin stringByReplacingMatchesInString:urlToValidate options:0 range:NSMakeRange(0, [urlToValidate length]) withTemplate:@""];
    urlToValidate = [trailingslash stringByReplacingMatchesInString:urlToValidate options:0 range:NSMakeRange(0, [urlToValidate length]) withTemplate:@""];
    
    return urlToValidate;
}


- (void)checkURL {
	NSString *urlToValidate = [self getURLToValidate];
	
    [FileLogger log:@"%@ %@ %@", self, NSStringFromSelector(_cmd), urlToValidate];
    
    if(![ReachabilityUtils isInternetReachable]){
        [ReachabilityUtils showAlertNoInternetConnection];
        [self validationDidFail:nil];
        return;
    }
    
    NSString *uname = usernameTextField.text;
    NSString *pwd = passwordTextField.text;
    [WordPressApi guessXMLRPCURLForSite:urlToValidate success:^(NSURL *xmlrpcURL) {
        WordPressApi *api = [WordPressApi apiWithXMLRPCEndpoint:xmlrpcURL username:uname password:pwd];
        [api getBlogsWithSuccess:^(NSArray *blogs) {
            subsites = blogs;
            [self validationSuccess:[xmlrpcURL absoluteString]];
        } failure:^(NSError *error) {
            [self validationDidFail:error];
        }];
    } failure:^(NSError *error){
        if ([error.domain isEqual:NSURLErrorDomain] && error.code == NSURLErrorUserCancelledAuthentication) {
            [self validationDidFail:nil];
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
	[savingIndicator stopAnimating];
	[savingIndicator setHidden:YES];
    blog.url = self.url;
    blog.xmlrpc = xmlrpc;
    blog.username = self.username;
    blog.geolocationEnabled = self.geolocationEnabled;
	NSError *error = nil;
	//check if the blog is a WP.COM blog
	if(blog.isWPcom) {
		[SFHFKeychainUtils storeUsername:blog.username
                             andPassword:self.password
                          forServiceName:@"WordPress.com"
                          updateExisting:YES
                                   error:&error];

        // If this is the account associated with the api, update the singleton's credentials also.
        WordPressComApi *wpComApi = [WordPressComApi sharedApi];
        if ([wpComApi.username isEqualToString:blog.username]) {
            [wpComApi updateCredentailsFromStore];
        }
	} else {
		[SFHFKeychainUtils storeUsername:blog.username
							 andPassword:self.password
						  forServiceName:blog.hostURL
						  updateExisting:YES
								   error:&error];        
	}
    
    if (error) {
		[FileLogger log:@"%@ %@ Error saving password for %@: %@", self, NSStringFromSelector(_cmd), blog.url, error];
    } else {
		[FileLogger log:@"%@ %@ %@", self, NSStringFromSelector(_cmd), blog.url];
	}
    
    [self cancel:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"BlogsRefreshNotification" object:nil];

    saveButton.enabled = YES;
    [self.navigationItem setHidesBackButton:NO animated:NO];

}


- (void)validationDidFail:(id)wrong {
	[savingIndicator stopAnimating];
	[savingIndicator setHidden:YES];
    if (wrong) {
        if ([wrong isKindOfClass:[UITableViewCell class]]) {
            ((UITableViewCell *)wrong).textLabel.textColor = WRONG_FIELD_COLOR;
        } else if ([wrong isKindOfClass:[NSError class]]) {
            NSError *error = (NSError *)wrong;
			NSString *message;
			if ([error code] == 403) {
				message = NSLocalizedString(@"Please update your credentials and try again.", @"");
			} else {
				message = [error localizedDescription];
			}

            if (failureAlertView == nil) {
                if ([error code] == 405) { // XMLRPC disabled.
                    failureAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Sorry, can't log in", @"")
                                                                  message:message
                                                                 delegate:self
                                                        cancelButtonTitle:NSLocalizedString(@"Need Help?", @"")
                                                        otherButtonTitles:NSLocalizedString(@"Enable Now", @""), nil];

                    failureAlertView.tag = 30;
                } else {
                    failureAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Sorry, can't log in", @"")
                                                           message:message
                                                          delegate:self
                                                 cancelButtonTitle:NSLocalizedString(@"Need Help?", @"")
                                                 otherButtonTitles:NSLocalizedString(@"OK", @""), nil];

                    if ( [error code] == NSURLErrorBadURL ) {
                        failureAlertView.tag = 20; // take the user to the FAQ page when hit "Need Help"
                    } else {
                        failureAlertView.tag = 10;
                    }
                }

                [failureAlertView show];
            }
        }
    }    

    saveButton.enabled = YES;
	[self.navigationItem setHidesBackButton:NO animated:NO];
}


- (void)validateFields {
    self.url = [NSURL IDNEncodedURL:urlTextField.text];
    NSLog(@"blog url: %@", self.url);
    self.username = usernameTextField.text;
    self.password = passwordTextField.text;
    
    saveButton.enabled = NO;
	[self.navigationItem setHidesBackButton:YES animated:NO];
    BOOL validFields = YES;
    if ([urlTextField.text isEqualToString:@""]) {
        validFields = NO;
        self.urlCell.textLabel.textColor = WRONG_FIELD_COLOR;
    }
    if ([usernameTextField.text isEqualToString:@""]) {
        validFields = NO;
        self.usernameCell.textLabel.textColor = WRONG_FIELD_COLOR;
    }
    if ([passwordTextField.text isEqualToString:@""]) {
        validFields = NO;
        self.passwordCell.textLabel.textColor = WRONG_FIELD_COLOR;
    }
    
    if (validFields) {
        [self checkURL];
    } else {
        [self validationDidFail:nil];
    }
}


- (void)save:(id)sender {
    [urlTextField resignFirstResponder];
    [usernameTextField resignFirstResponder];
    [passwordTextField resignFirstResponder];

    if (!savingIndicator) {
        savingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        savingIndicator.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        CGRect frm = savingIndicator.frame;
        frm.origin.x = (self.tableView.frame.size.width / 2.0f) - (frm.size.width / 2.0f);
        savingIndicator.frame = frm;
        UIView *aView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.tableView.frame.size.width, frm.size.height)];
        [aView addSubview:savingIndicator];
        
        [self.tableView setTableFooterView:aView];
    }
    
	[savingIndicator setHidden:NO];
	[savingIndicator startAnimating];

    if (blog) {
        blog.geolocationEnabled = self.geolocationEnabled;
        [blog dataSave];
    }
	
	if(blog == nil || blog.username == nil) {
		[self validateFields];
	} else {
		if ([self.startingUser isEqualToString:usernameTextField.text]
			&& [self.startingPwd isEqualToString:passwordTextField.text]
			&& [self.startingUrl isEqualToString:urlTextField.text]) {
			// No need to check if nothing changed
            [self cancel:nil];
            
		} else {
			[self validateFields];
		}
    }
}


- (IBAction)cancel:(id)sender {
    if (isCancellable) {
        [self dismissModalViewControllerAnimated:YES];
//
    } else {
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
    
    if (self.delegate){
        // If sender is not nil then the user tapped the cancel button.
        BOOL wascancelled = (sender != nil);
        [self.delegate controllerDidDismiss:self cancelled:wascancelled];
    }
}

- (void)enableDisableSaveButton {
    BOOL hasContent;
    
    if ( [urlTextField.text isEqualToString:@""] ||
         [usernameTextField.text isEqualToString:@""] ||
         [passwordTextField.text isEqualToString:@""] )
    {
        hasContent = FALSE;
    } else {
        hasContent = TRUE;
    }
    
    self.navigationItem.rightBarButtonItem.enabled = hasContent;
}

#pragma mark -
#pragma mark Keyboard Related Methods

- (void)handleKeyboardDidShow:(NSNotification *)notification {    
    CGRect rect = [[notification.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];    
    CGRect frame = self.view.frame;
    if(UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
        frame.size.height -= rect.size.width;
    } else {
        frame.size.height -= rect.size.height;
    }
    self.view.frame = frame;
    
    CGPoint point = [tableView convertPoint:lastTextField.frame.origin fromView:lastTextField];
    if (!CGRectContainsPoint(frame, point)) {
        NSIndexPath *indexPath = [tableView indexPathForRowAtPoint:point];
        [tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
    }
}


- (void)handleKeyboardWillHide:(NSNotification *)notification {
    CGRect rect = [[notification.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect frame = self.view.frame;
    if(UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
        frame.size.height += rect.size.width;
    } else {
        frame.size.height += rect.size.height;
    }

    [UIView animateWithDuration:0.3 animations:^{
        self.view.frame = frame;
    }];
}


- (void)handleViewTapped {
    [lastTextField resignFirstResponder];
}


@end
