//
//  EditBlogViewController.m
//  WordPress
//
//  Created by Chris Boyd on 7/23/10.

#import "EditSiteViewController.h"
#import "NSURL+IDN.h"
#import "WordPressApi.h"
#import "SFHFKeychainUtils.h"
#import "UIBarButtonItem+Styled.h"
#import "AFHTTPClient.h"

@interface EditSiteViewController (PrivateMethods)
- (void)validateFields;
- (void)validationSuccess:(NSString *)xmlrpc;
- (void)validationDidFail:(id)wrong;
- (void)handleKeyboardWillShow:(NSNotification *)notification;
- (void)handleKeyboardWillHide:(NSNotification *)notification;
- (void)handleViewTapped;
- (void)configureTextField:(UITextField *)textField asPassword:(BOOL)asPassword;
- (void)testJetpack;
@end

@implementation EditSiteViewController

@synthesize password, username, url, geolocationEnabled;
@synthesize blog, tableView, savingIndicator;
@synthesize urlCell, usernameCell, passwordCell;
@synthesize isDotOrg, jpUsername, jpUsernameCell, jpPassword, jpPasswordCell;
@synthesize footerText, buttonText;
@synthesize currentNode;
@synthesize parsedBlog;
@synthesize delegate;
@synthesize isCancellable;

#pragma mark -
#pragma mark View lifecycle

- (void)dealloc {
    self.delegate = nil;
    self.username = nil;
    self.password = nil;
    self.url = nil;
    self.urlCell = nil;
    self.usernameCell = nil;
    self.passwordCell = nil;
    self.tableView = nil;
    self.blog = nil;
    self.footerText = nil;
    self.buttonText = nil;
    self.jpPassword = nil;
    self.jpPasswordCell = nil;
    self.jpUsername = nil;
    self.jpUsernameCell = nil;
    [currentNode release];
    [parsedBlog release];
    [jpUsernameTextField release]; jpUsernameTextField = nil;
    [jpPasswordTextField release]; jpPasswordTextField = nil;
    [subsites release]; subsites = nil;
    [saveButton release]; saveButton = nil;
    [switchCell release]; switchCell = nil;
    [urlTextField release]; urlTextField = nil;
    [usernameTextField release]; usernameTextField = nil;
    [passwordTextField release]; passwordTextField = nil;
    [lastTextField release]; lastTextField = nil;
	[savingIndicator release];
    [super dealloc];
}

- (void)viewDidLoad {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [super viewDidLoad];
    
    if (blog) {
        isDotOrg = !blog.isWPcom;
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
        self.password = [SFHFKeychainUtils getPasswordForUsername:blog.username andServiceName:blog.hostURL error:&error];
        self.geolocationEnabled = blog.geolocationEnabled;
        
        if (isDotOrg) {
            NSString *wporgBlogJetpackKey = [NSString stringWithFormat:@"jetpackblog-%@", blog.url];
            
            self.jpUsername = [[NSUserDefaults standardUserDefaults] objectForKey:wporgBlogJetpackKey];
            self.jpPassword = [SFHFKeychainUtils getPasswordForUsername:jpUsername andServiceName:@"WordPress.com" error:&error];;
        }
        
        if (isCancellable) {
            UIBarButtonItem *barButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)] autorelease];
            self.navigationItem.leftBarButtonItem = barButton;
        }
    }

    self.footerText = NSLocalizedString(@"To access stats, enter the login that was used with the Jetpack plugin.", @"");
	self.buttonText = NSLocalizedString(@"Test Credentials", @"");
    
    saveButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Save", @"Save button label (saving content, ex: Post, Page, Comment, Category).") style:UIBarButtonItemStyleDone target:self action:@selector(save:)];
    
    self.navigationItem.rightBarButtonItem = saveButton;
    
    if (!IS_IPAD){
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
        
        UITapGestureRecognizer *tgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleViewTapped)];
        [tableView addGestureRecognizer:tgr];
        [tgr release];
    }
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
    if (isDotOrg && blog) {
        return 6;
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
            return 2;   // jpusername, jppassword
		default:
            return 1;   // test, install, more info
			break;
	}
	return 0;
}


- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
//    if(section == 1 && isDotOrg)
//		return NSLocalizedString(@"To access stats, enter the login that was used with the Jetpack plugin.", @"");
//    else 
    if(section == 2 && isDotOrg) {
        return self.footerText;
    } else {
		return @"";
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (!blog) {
        return 0.0f;
    }
    if (section < 3)
        return 44.0f;
    if (section == 4)
        return 60.0f;
    else
        return 0.0f;
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
            break;
		default:
			break;
	}
	return result;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == 4) {
        NSString *labelText = labelText = NSLocalizedString(@"Need Jetpack? Tap below and search for 'Jetpack' to install it on your site.", @"");
        CGRect headerFrame = CGRectMake(0.0f, 0.0f, 0.0f, 50.0f);
        UIView *footerView = [[[UIView alloc] initWithFrame:headerFrame] autorelease];
        footerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        UILabel *jetpackLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 15.0f, (IS_IPAD) ? 410.0f : 260.0f, 50.0f)];
        [jetpackLabel setBackgroundColor:[UIColor clearColor]];
        [jetpackLabel setTextColor:[UIColor colorWithRed:0.298039f green:0.337255f blue:0.423529f alpha:1.0f]];
        [jetpackLabel setShadowColor:[UIColor whiteColor]];
        [jetpackLabel setShadowOffset:CGSizeMake(0.0f, 1.0f)];
        [jetpackLabel setFont:[UIFont systemFontOfSize:15.0f]];
        [jetpackLabel setTextAlignment:UITextAlignmentCenter];
        [jetpackLabel setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin];
        
        CGSize maximumLabelSize = CGSizeMake(320.0f,200.0f);
        CGSize labelSize = [labelText sizeWithFont:jetpackLabel.font constrainedToSize:maximumLabelSize lineBreakMode:jetpackLabel.lineBreakMode];
        
        CGRect newFrame = jetpackLabel.frame;
        newFrame.size.height = labelSize.height;
        jetpackLabel.frame = newFrame;
        [jetpackLabel setText:labelText];
        [jetpackLabel setNumberOfLines:0];
        [jetpackLabel sizeToFit];
        
        [footerView addSubview:jetpackLabel];
        [jetpackLabel release];
        
        return footerView;
    } else {
        return nil;
    }
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath {    
    if ([indexPath section] == 0) {
        if (indexPath.row == 0) {
            self.urlCell = (UITableViewTextFieldCell *)[tableView dequeueReusableCellWithIdentifier:@"UrlCell"];
            if (self.urlCell == nil) {
                self.urlCell = [[[UITableViewTextFieldCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"UrlCell"] autorelease];
				self.urlCell.textLabel.text = NSLocalizedString(@"URL", @"");
				urlTextField = [self.urlCell.textField retain];
				urlTextField.placeholder = NSLocalizedString(@"http://example.com", @"");
                [self configureTextField:urlTextField asPassword:NO];
				if(blog.url != nil)
					urlTextField.text = blog.url;
            }
            
            return self.urlCell;
        }
        else if(indexPath.row == 1) {
            self.usernameCell = (UITableViewTextFieldCell *)[tableView dequeueReusableCellWithIdentifier:@"UsernameCell"];
            if (self.usernameCell == nil) {
                self.usernameCell = [[[UITableViewTextFieldCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"UsernameCell"] autorelease];
				self.usernameCell.textLabel.text = NSLocalizedString(@"Username", @"");
				usernameTextField = [self.usernameCell.textField retain];
				usernameTextField.placeholder = NSLocalizedString(@"WordPress username", @"");
                [self configureTextField:usernameTextField asPassword:NO];
				if(blog.username != nil)
					usernameTextField.text = blog.username;
			}
            
            return self.usernameCell;
        }
        else if(indexPath.row == 2) {
            self.passwordCell = (UITableViewTextFieldCell *)[tableView dequeueReusableCellWithIdentifier:@"PasswordCell"];
            if (self.passwordCell == nil) {
                self.passwordCell = [[[UITableViewTextFieldCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"PasswordCell"] autorelease];
				self.passwordCell.textLabel.text = NSLocalizedString(@"Password", @"");
				passwordTextField = [self.passwordCell.textField retain];
				passwordTextField.placeholder = NSLocalizedString(@"WordPress password", @"");
                [self configureTextField:passwordTextField asPassword:YES];
				if(password != nil)
					passwordTextField.text = password;
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
        [switchCell retain];
        switchCell.textLabel.text = NSLocalizedString(@"Geotagging", @"Enables geotagging in blog settings (short label)");
        switchCell.selectionStyle = UITableViewCellSelectionStyleNone;
        switchCell.cellSwitch.on = self.geolocationEnabled;
        [switchCell.cellSwitch addTarget:self action:@selector(toggleGeolocation:) forControlEvents:UIControlEventValueChanged];
        return switchCell;
	} else if (indexPath.section == 2) {
        
        if(indexPath.row == 0) {
            self.jpUsernameCell = (UITableViewTextFieldCell *)[tableView dequeueReusableCellWithIdentifier:@"jpUsernameCell"];
            if (self.jpUsernameCell == nil) {
                self.jpUsernameCell = [[[UITableViewTextFieldCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"jpUsernameCell"] autorelease];
				self.jpUsernameCell.textLabel.text = NSLocalizedString(@"Username", @"");
				jpUsernameTextField = [self.jpUsernameCell.textField retain];
				jpUsernameTextField.placeholder = NSLocalizedString(@"WordPress.com username", @"");
                [self configureTextField:jpUsernameTextField asPassword:NO];
                if (jpUsername != nil) 
                    jpUsernameTextField.text = jpUsername;
			}
            return self.jpUsernameCell;
        }
        else if(indexPath.row == 1) {
            self.jpPasswordCell = (UITableViewTextFieldCell *)[tableView dequeueReusableCellWithIdentifier:@"jpPasswordCell"];
            if (self.jpPasswordCell == nil) {
                self.jpPasswordCell = [[[UITableViewTextFieldCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"jpPasswordCell"] autorelease];
				self.jpPasswordCell.textLabel.text = NSLocalizedString(@"Password", @"");
				jpPasswordTextField = [self.jpPasswordCell.textField retain];
				jpPasswordTextField.placeholder = NSLocalizedString(@"WordPress.com password", @"");
                [self configureTextField:jpPasswordTextField asPassword:YES];
				if(jpPassword != nil)
					jpPasswordTextField.text = jpPassword;
			}            
            return self.jpPasswordCell;
        }
    } else if (indexPath.section == 3) {
        
        UITableViewActivityCell *activityCell = nil;
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"UITableViewActivityCell" owner:nil options:nil];
		for(id currentObject in topLevelObjects)
		{
			if([currentObject isKindOfClass:[UITableViewActivityCell class]])
			{
				activityCell = (UITableViewActivityCell *)currentObject;
				break;
			}
		}

        if(isTestingJetpack) {
			[activityCell.spinner startAnimating];
			self.buttonText = NSLocalizedString(@"Testing Credentials...", @"");
		}
		else {
			[activityCell.spinner stopAnimating];
			self.buttonText = NSLocalizedString(@"Test Credentials", @"");
		}
		
		activityCell.textLabel.text = self.buttonText;
        if (isTestingJetpack) {
            activityCell.selectionStyle = UITableViewCellSelectionStyleNone;
        } else {
            activityCell.selectionStyle = UITableViewCellSelectionStyleBlue;
        }
		return activityCell;
        
	} else if (indexPath.section == 4) {
        UITableViewActivityCell *activityCell = nil;
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"UITableViewActivityCell" owner:nil options:nil];
		for(id currentObject in topLevelObjects)
		{
			if([currentObject isKindOfClass:[UITableViewActivityCell class]])
			{
				activityCell = (UITableViewActivityCell *)currentObject;
				break;
			}
		}
		
		activityCell.textLabel.text = NSLocalizedString(@"Install Jetpack", @"");
        
		return activityCell;
    } else if (indexPath.section == 5) {
        UITableViewActivityCell *activityCell = nil;
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"UITableViewActivityCell" owner:nil options:nil];
		for(id currentObject in topLevelObjects)
		{
			if([currentObject isKindOfClass:[UITableViewActivityCell class]])
			{
				activityCell = (UITableViewActivityCell *)currentObject;
				break;
			}
		}
		
		activityCell.textLabel.text = NSLocalizedString(@"More Information", @"");
        
		return activityCell;
    }
    
    // We shouldn't reach this point, but return an empty cell just in case
    return [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"NoCell"] autorelease];
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
    
    switch (indexPath.section) {
        case 0:
            
            break;
        case 3:
//            for(int i = 0; i < 2; i++) {
//                UITableViewCell *cell = (UITableViewCell *)[tv cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
//                for(UIView *subview in cell.subviews) {
//                    if([subview isKindOfClass:[UITextField class]] == YES) {
//                        UITextField *tempTextField = (UITextField *)subview;
//                        [self textFieldDidEndEditing:tempTextField];
//                    }
//                }
//            }
            
            if([jpUsernameTextField.text length] == 0) {
                self.footerText = NSLocalizedString(@"Username is required.", @"");
                self.buttonText = NSLocalizedString(@"Test Credentials", @"");
                [tv reloadData];
            } else if([jpPasswordTextField.text length] == 0) {
                self.footerText = NSLocalizedString(@"Password is required.", @"");
                self.buttonText = NSLocalizedString(@"Test Credentials", @"");
                [tv reloadData];
            } else {
                self.footerText = @" ";
                self.buttonText = NSLocalizedString(@"Testing Credentials...", @"");
                
                self.jpUsername = jpUsernameTextField.text;
                self.jpPassword = jpPasswordTextField.text;

                [NSThread sleepForTimeInterval:0.15];
                [tv reloadData];
                if (!isTestingJetpack){
                    isTestingJetpack = YES;
                    [self testJetpack];
                }
            }
            break;
        case 4:
            if (blog) {
                NSString *jetpackURL = [blog.xmlrpc stringByReplacingOccurrencesOfString:@"xmlrpc.php" withString:@"wp-admin/plugin-install.php"];
                WPWebViewController *webViewController;
                if ( IS_IPAD ) {
                    webViewController = [[[WPWebViewController alloc] initWithNibName:@"WPWebViewController-iPad" bundle:nil] autorelease];
                }
                else {
                    webViewController = [[[WPWebViewController alloc] initWithNibName:@"WPWebViewController" bundle:nil] autorelease];
                }
                [webViewController setUrl:[NSURL URLWithString:jetpackURL]];
                [webViewController setUsername:blog.username];
                [webViewController setPassword:[blog fetchPassword]];
                [webViewController setWpLoginURL:[NSURL URLWithString:blog.loginURL]];
                [self.navigationController pushViewController:webViewController animated:YES];
            } else {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"No Blog Yet" 
                                                                    message:@"Please enter your blog's info and save before trying to install Jetpack." 
                                                                   delegate:nil 
                                                          cancelButtonTitle:@"OK" 
                                                          otherButtonTitles:nil, nil];
                [alertView show];
                [alertView release];
            }
            break;
        case 5:
            {
                WPWebViewController *webViewController;
                if ( IS_IPAD ) {
                    webViewController = [[[WPWebViewController alloc] initWithNibName:@"WPWebViewController-iPad" bundle:nil] autorelease];
                }
                else {
                    webViewController = [[[WPWebViewController alloc] initWithNibName:@"WPWebViewController" bundle:nil] autorelease];
                }
                [webViewController setUrl:[NSURL URLWithString:@"http://jetpack.me/about/"]];
                [self.navigationController pushViewController:webViewController animated:YES];
            }
            break; 
            
        default:
            break;
    }
}

#pragma mark -
#pragma mark UITextField methods

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    if (lastTextField) {
        [lastTextField release];
        lastTextField = nil;
    }
    lastTextField = [textField retain];
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
                WordPressAppDelegate *appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
                
                if (IS_IPAD) {
                    helpViewController.isBlogSetup = YES;
                    [self.navigationController pushViewController:helpViewController animated:YES];
                }
                else
                    [appDelegate.navigationController presentModalViewController:helpViewController animated:YES];
                
                [helpViewController release];
            }
			break;
		}
		case 1:
			//ok
			break;
		default:
			break;
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


- (void)testJetpack {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    
    NSURL *baseURL = [NSURL URLWithString:@"https://public-api.wordpress.com/"];
    
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:baseURL];
    [httpClient setAuthorizationHeaderWithUsername:jpUsername password:jpPassword];

    NSMutableURLRequest *mRequest = [httpClient requestWithMethod:@"GET" path:@"get-user-blogs/1.0" parameters:nil];
    
    AFXMLRequestOperation *currentRequest = [[[AFXMLRequestOperation alloc] initWithRequest:mRequest] autorelease];
    
    [currentRequest setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSXMLParser *parser = (NSXMLParser *)responseObject;
        parser.delegate = self;
        [parser parse];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        WPLog(@"Error calling get-user-blogs : %@", [error description]);
        
        if(operation.response.statusCode == 401){
            // If we failed due to bad credentials...
            self.footerText = @"The WordPress.com username or password may be incorrect.  Please check them and try again.";
            
        } else {
            self.footerText = @"There was a server error while testing the credentials. Please try again.";
            
        }
        
    }];
    
    [currentRequest start];
    [httpClient release];
}

- (IBAction)cancel:(id)sender {
    if (isCancellable) {
        [self.delegate controllerDidDismiss:self];
    } else {
        [self.navigationController popToRootViewControllerAnimated:YES];
    }

}

- (void)toggleGeolocation:(id)sender {
    self.geolocationEnabled = switchCell.cellSwitch.on;
}

- (void)refreshTable {
	[self.tableView reloadData];
}

- (void)checkURL {	
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
    
    [FileLogger log:@"%@ %@ %@", self, NSStringFromSelector(_cmd), urlToValidate];
    // FIXME: add HTTP Auth support back
    // Currently on https://github.com/AFNetworking/AFNetworking/tree/experimental-authentication-challenge
    [WordPressApi guessXMLRPCURLForSite:urlToValidate success:^(NSURL *xmlrpcURL) {
        WordPressApi *api = [WordPressApi apiWithXMLRPCEndpoint:xmlrpcURL username:usernameTextField.text password:passwordTextField.text];
        [api getBlogsWithSuccess:^(NSArray *blogs) {
            subsites = [blogs retain];
            [self validationSuccess:[xmlrpcURL absoluteString]];
        } failure:^(NSError *error) {
            [self validationDidFail:error];
        }];
    } failure:^(NSError *error){
        if ([error.domain isEqual:NSURLErrorDomain] && error.code == NSURLErrorUserCancelledAuthentication) {
            [self validationDidFail:nil];
        } else {
            // FIXME: find a better error
            NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                      NSLocalizedString(@"Unable to read the WordPress site on that URL. Tap Need Help? to learn more and resolve this error.", @""),NSLocalizedDescriptionKey,
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
    [self.navigationController popToRootViewControllerAnimated:YES];
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

            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Sorry, can't log in", @"")
																message:message
                                                               delegate:self
                                                      cancelButtonTitle:NSLocalizedString(@"Need Help?", @"")
                                                      otherButtonTitles:NSLocalizedString(@"OK", @""), nil];
            if ( [error code] == NSURLErrorBadURL ) {
                alertView.tag = 20; // take the user to the FAQ page when hit "Need Help"
            } else {
                alertView.tag = 10;
            }
            [alertView show];
            [alertView release];            
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
	
	if (savingIndicator == nil) {
		savingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
		[savingIndicator setFrame:CGRectMake(0,0,20,20)];
		[savingIndicator setCenter:CGPointMake(tableView.center.x, savingIndicator.center.y)];
		UIView *aView = [[UIView alloc] init];
		[aView addSubview:savingIndicator];
		
		[self.tableView setTableFooterView:aView];
        [aView release];
	}
	[savingIndicator setHidden:NO];
	[savingIndicator startAnimating];

    if (blog) {
        blog.geolocationEnabled = self.geolocationEnabled;
        [blog dataSave];
    }
	
	if(blog == nil || blog.username == nil) {
		[self validateFields];
	} else 
		if ([self.username isEqualToString:usernameTextField.text]
			&& [self.password isEqualToString:passwordTextField.text]
			&& [self.url isEqualToString:urlTextField.text]) {
			// No need to check if nothing changed
            [self.navigationController popToRootViewControllerAnimated:YES];
		} else {
			[self validateFields];
		}
}


- (void)handleKeyboardWillShow:(NSNotification *)notification {
    CGRect rect = [[notification.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, rect.size.height, 0.0);
    tableView.contentInset = contentInsets;
    tableView.scrollIndicatorInsets = contentInsets;
    
    CGRect frame = self.view.frame;
    frame.size.height -= rect.size.height;
    if (!CGRectContainsPoint(frame, lastTextField.frame.origin)) {
        CGPoint scrollPoint = CGPointMake(0.0, lastTextField.frame.origin.y - rect.size.height/2.0);
        [tableView setContentOffset:scrollPoint animated:YES];
    }
}

- (void)handleKeyboardWillHide:(NSNotification *)notification {
    [UIView animateWithDuration:0.3 animations:^{
        tableView.contentInset = UIEdgeInsetsZero;
        tableView.scrollIndicatorInsets = UIEdgeInsetsZero;
    }];
}

- (void)handleViewTapped {
    [lastTextField resignFirstResponder];
}


#pragma mark -
#pragma mark XMLParser Delegate Methods

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
	self.currentNode = [NSMutableString string];
    if([elementName isEqualToString:@"blog"]) {
        self.parsedBlog = [NSMutableDictionary dictionary];
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
	if (self.currentNode) {
        [self.currentNode appendString:string];
    }	
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    
    if ([elementName isEqualToString:@"apikey"]) {
        [blog setValue:currentNode forKey:@"apiKey"];
        [blog dataSave];
        
    } else if([elementName isEqualToString:@"blog"]) {
        // We might get a miss-match due to http vs https or a trailing slash
        // so convert the strings to urls and compare their hosts.
        NSURL *parsedURL = [NSURL URLWithString:[parsedBlog objectForKey:@"url"]];
        NSURL *blogURL = [NSURL URLWithString:blog.url];
        if (![blogURL scheme]) {
            blogURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@", blog.url]];
        }
        [FileLogger log:@"Blog URL - %@", blogURL];
        NSString *parsedHost = [NSString stringWithFormat:@"%@%@",[parsedURL host],[parsedURL path]] ;
        NSString *blogHost = [NSString stringWithFormat:@"%@%@",[blogURL host], [blogURL path]];
        NSRange range = [parsedHost rangeOfString:blogHost];
        
        if (range.length > 0) {
            NSNumber *blogID = [[parsedBlog objectForKey:@"id"] numericValue];
            if ([blogID isEqualToNumber:[self.blog blogID]]) {
                // do nothing.
            } else {
                blog.blogID = blogID;
                [blog dataSave];
            }
            
            // Mark that a match was found but continue.
            // http://ios.trac.wordpress.org/ticket/1251
            foundMatchingBlogInAPI = YES;
            NSLog(@"Matched parsedBlogURL: %@ to blogURL: %@ ", parsedURL, blogURL);
        }
        
        self.parsedBlog = nil;
        
    } else if([elementName isEqualToString:@"id"]) {
        [parsedBlog setValue:currentNode forKey:@"id"];
        [FileLogger log:@"Blog id - %@", currentNode];
    } else if([elementName isEqualToString:@"url"]) {
        [parsedBlog setValue:currentNode forKey:@"url"];
        [FileLogger log:@"Blog original URL - %@", currentNode];
    } else if([elementName isEqualToString:@"userinfo"]) {
        [parser abortParsing];
        
        if (foundMatchingBlogInAPI) {     
            self.currentNode = nil;
            self.parsedBlog = nil;
            
            //TODO: The test was good. Save the credentials and mark the test a success.
            self.footerText = @"Test successful";
            return;
        } else {
            
            // Coudn't find the blog in the api.
            self.footerText = @"Sorry, we could not find your stats linked to this WordPress.com account.";
            //        [[NSUserDefaults standardUserDefaults] removeObjectForKey:wporgBlogJetpackKey];
            
        }
        
        isTestingJetpack = NO;
        [self refreshTable];
    }
    
	self.currentNode = nil;
}


@end

