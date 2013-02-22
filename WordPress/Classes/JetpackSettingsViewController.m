//
//  JetpackSettingsViewController.m
//  WordPress
//
//  Created by Eric Johnson on 8/24/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import <SVProgressHUD/SVProgressHUD.h>
#import "JetpackSettingsViewController.h"
#import "Blog+Jetpack.h"
#import "UITableViewTextFieldCell.h"
#import "WordPressComApi.h"
#import "WPWebViewController.h"

@interface JetpackSettingsViewController () <UITableViewTextFieldCellDelegate>

@end

@implementation JetpackSettingsViewController {
    Blog *_blog;
    IBOutlet UIView *_cloudsView;
    IBOutlet UITextView *_messageView;
    IBOutlet UIView *_headerView;
    UITableViewTextFieldCell *_usernameCell;
    UITableViewTextFieldCell *_passwordCell;
    BOOL _authenticating;
}

#define kCheckCredentials NSLocalizedString(@"Verify and Save Credentials", @"");
#define kCheckingCredentials NSLocalizedString(@"Verifing Credentials", @"");

- (id)initWithBlog:(Blog *)blog {
    NSAssert(blog != nil, @"blog can't be nil");

    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        _blog = blog;
    }
    return self;
}

#pragma mark -
#pragma mark LifeCycle Methods

- (void)viewDidLoad {
    WPFLogMethod();
    [super viewDidLoad];

    _cloudsView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"clouds_header"]];

    self.title = NSLocalizedString(@"Jetpack Connect", @"");
    self.tableView.backgroundView = nil;

    if ([self useNavigationController]) {
        if (self.canBeSkipped) {
            self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Skip", @"") style:UIBarButtonItemStyleBordered target:self action:@selector(skip:)];
        }
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Save", @"") style:UIBarButtonItemStyleDone target:self action:@selector(save:)];
    }

    [self updateMessage];
    [self updateSaveButton];
    double delayInSeconds = 0.1;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self checkForJetpack];
    });

    UITapGestureRecognizer *tgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    tgr.cancelsTouchesInView = NO;
    [self.tableView addGestureRecognizer:tgr];
}

#pragma mark -
#pragma mark Instance Methods

- (IBAction)skip:(id)sender {
    if (self.completionBlock) {
        self.completionBlock(NO);
    }
}


- (IBAction)save:(id)sender {
    [self dismissKeyboard];
    [SVProgressHUD show];
    NSString *username = _usernameCell.textField.text;
    NSString *password = _passwordCell.textField.text;
    [self setAuthenticating:YES];
    [_blog validateJetpackUsername:username
                          password:password
                           success:^{
                               [SVProgressHUD dismiss];
                               if (![[WordPressComApi sharedApi] username]) {
                                   [[WordPressComApi sharedApi] signInWithUsername:username password:password success:nil failure:nil];
                               }
                               [self setAuthenticating:NO];
                               if (self.completionBlock) {
                                   self.completionBlock(YES);
                               }
                           } failure:^(NSError *error) {
                               [SVProgressHUD dismiss];
                               [self setAuthenticating:NO];
                               [WPError showAlertWithError:error];
                           }];
}


#pragma mark -
#pragma mark Table view data source

/*
 if ([_blog hasJetpack])
    - Header view
    - Section 0
        - Username: _________
        - Password: _________
    - Section 1 (if !self.navigationController)
        - [ Save credentials ]
 else
    - Header view
    - Secion 0
        - [ Install Jetpack ]
    - Section 1
        - [ More information ]
 */
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv {
    if ([_blog hasJetpack] && [self useNavigationController]) {
        return 1;
    }
    return 2;
}


- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)section {
    if ([_blog hasJetpack] && section == 0) {
        return 2;
    }
	return 1;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"ButtonCell";
    UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    cell.textLabel.textAlignment = UITextAlignmentCenter;

	if ([_blog hasJetpack]) {
		if (indexPath.section == 0) {
            static NSString *TextCellIdentifier = @"TextCell";
            UITableViewTextFieldCell *textCell = (UITableViewTextFieldCell *)[tv dequeueReusableCellWithIdentifier:TextCellIdentifier];
            if (textCell == nil) {
                textCell = [[UITableViewTextFieldCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:TextCellIdentifier];
            }
            if (indexPath.row == 0) {
                textCell.textLabel.text = NSLocalizedString(@"Username:", @"");
                textCell.textField.placeholder = NSLocalizedString(@"WordPress.com username", @"");
                textCell.textField.keyboardType = UIKeyboardTypeEmailAddress;
                textCell.shouldDismissOnReturn = NO;
                textCell.delegate = self;
                textCell.textField.text = _blog.jetpackUsername;
                _usernameCell = textCell;
            } else {
                textCell.textLabel.text = NSLocalizedString(@"Password:", @"");
                textCell.textField.placeholder = NSLocalizedString(@"WordPress.com password", @"");
                textCell.textField.secureTextEntry = YES;
                textCell.shouldDismissOnReturn = YES;
                textCell.delegate = self;
                textCell.textField.text = _blog.jetpackPassword;
                _passwordCell = textCell;
            }
            cell = textCell;
		} else if (indexPath.section == 1) {
            cell.textLabel.text = NSLocalizedString(@"Save credentials", @"");
            if ([self saveEnabled]) {
                cell.textLabel.textColor = [UIColor darkTextColor];
                cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            } else {
                cell.textLabel.textColor = [UIColor lightGrayColor];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
            }
		}
	} else {
		if (indexPath.section == 0) {
            cell.textLabel.text = NSLocalizedString(@"Install Jetpack", @"");
		} else if (indexPath.section == 1) {
            cell.textLabel.text = NSLocalizedString(@"More information", @"");
		}
	}
	    
    return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tv deselectRowAtIndexPath:indexPath animated:YES];
    
	if ([_blog hasJetpack]) {
        if (indexPath.section == 1 && [self saveEnabled]) {
            [self save:nil];
        }
	} else {
        WPWebViewController *webViewController = [[WPWebViewController alloc] init];
        if (indexPath.section == 0) {
            NSString *jetpackURL = [_blog adminUrlWithPath:@"plugin-install.php?tab=plugin-information&plugin=jetpack"];
            [webViewController setUrl:[NSURL URLWithString:jetpackURL]];
            [webViewController setUsername:_blog.username];
            [webViewController setPassword:[_blog fetchPassword]];
            [webViewController setWpLoginURL:[NSURL URLWithString:_blog.loginUrl]];
        } else {
            [webViewController setUrl:[NSURL URLWithString:@"http://ios.wordpress.org/faq/#faq_15"]];
        }
        if ([self useNavigationController]) {
            [self.navigationController pushViewController:webViewController animated:YES];
        } else {
            UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:webViewController];
            navController.modalPresentationStyle = UIModalPresentationPageSheet;
            webViewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissBrowser)];
            [self presentViewController:navController animated:YES completion:nil];
        }
	}
}

#pragma mark - UITableViewTextFieldCellDelegate

- (void)cellWantsToSelectNextField:(UITableViewTextFieldCell *)cell {
    [_passwordCell.textField becomeFirstResponder];
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
}

- (void)cellTextDidChange:(UITableViewTextFieldCell *)cell {
    [self updateSaveButton];
}

#pragma mark - Custom methods

- (BOOL)useNavigationController {
    return !self.ignoreNavigationController && self.navigationController;
}

- (BOOL)saveEnabled {
    return (!_authenticating && _usernameCell.textField.text.length && _passwordCell.textField.text.length);
}

- (void)setAuthenticating:(BOOL)authenticating {
    _authenticating = authenticating;
    [self updateSaveButton];
}

- (void)updateSaveButton {
    if ([self useNavigationController]) {
        self.navigationItem.rightBarButtonItem.enabled = [self saveEnabled];
    } else {
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:1]] withRowAnimation:UITableViewRowAnimationNone];
    }
}


- (void)dismissKeyboard {
    [_usernameCell.textField resignFirstResponder];
    [_passwordCell.textField resignFirstResponder];
}

- (void)dismissBrowser {
    [self dismissViewControllerAnimated:YES completion:^{
        [self checkForJetpack];
    }];
}

- (void)updateMessage {
    if ([_blog hasJetpack]) {
        _messageView.text = NSLocalizedString(@"Looks like you have Jetpack set up on your blog. Congrats!\nSign in with your WordPress.com credentials below to enable Stats and Notifications.", @"");
    } else {
        _messageView.text = NSLocalizedString(@"Jetpack 1.8.2 or later is required for stats. Do you want to install Jetpack?", @"");
    }

    [_messageView sizeToFit];
    CGRect headerFrame = _headerView.frame;
    headerFrame.size.height = CGRectGetMaxY(_messageView.frame) + 10;
    _headerView.frame = headerFrame;
}

- (void)checkForJetpack {
    if ([_blog hasJetpack]) {
        [self tryLoginWithCurrentWPComCredentials];
        return;
    }
    [SVProgressHUD showWithStatus:NSLocalizedString(@"Checking for Jetpack...", @"") maskType:SVProgressHUDMaskTypeBlack];
    [_blog syncOptionsWithWithSuccess:^{
        [SVProgressHUD dismiss];
        if ([_blog hasJetpack]) {
            [self updateMessage];
            [self.tableView reloadData];
            double delayInSeconds = 0.1;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [self tryLoginWithCurrentWPComCredentials];
            });
        }
    } failure:^(NSError *error) {
        [SVProgressHUD dismiss];
        [WPError showAlertWithError:error];
    }];
}

- (void)tryLoginWithCurrentWPComCredentials {
    if ([_blog hasJetpack] && !([[_blog jetpackUsername] length] && [[_blog jetpackPassword] length])) {
        NSString *wpcomUsername = [[WordPressComApi sharedApi] username];
        NSString *wpcomPassword = [[WordPressComApi sharedApi] password];
        if (wpcomPassword && wpcomPassword) {
            [self tryLoginWithUsername:wpcomUsername andPassword:wpcomPassword];
        }
    }
}

- (void)tryLoginWithUsername:(NSString *)username andPassword:(NSString *)password {
    NSAssert(username != nil, @"Can't login with a nil username");
    NSAssert(password != nil, @"Can't login with a nil password");
    _usernameCell.textField.text = username;
    _passwordCell.textField.text = password;
    [self save:nil];
}

@end
