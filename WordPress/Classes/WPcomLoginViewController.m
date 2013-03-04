//
//  WPcomLoginViewController.m
//  WordPress
//
//  Created by Chris Boyd on 7/19/10.
//

#import <WordPressApi/WordPressApi.h>

#import "WPcomLoginViewController.h"
#import "UITableViewTextFieldCell.h"
#import "SFHFKeychainUtils.h"
#import "WordPressComApi.h"
#import "WPWebViewController.h"
#import "ReachabilityUtils.h"

@interface WPcomLoginViewController () <UITextFieldDelegate> {
    UITableViewTextFieldCell *loginCell, *passwordCell;
}
@property (nonatomic, strong) NSString *footerText, *buttonText;
@property (nonatomic, assign) BOOL isSigningIn;
@property (nonatomic, strong) WordPressComApi *wpComApi;
@property (nonatomic, strong) void (^successBlock)(NSString *username, NSString *password);
@property (nonatomic, strong) void (^cancelBlock)();
- (void)signIn:(id)sender;
@end


@implementation WPcomLoginViewController

@synthesize footerText, buttonText, isSigningIn, isCancellable, predefinedUsername;
@synthesize delegate;
@synthesize wpComApi = _wpComApi, blog = _blog;

+ (void)presentLoginScreenWithSuccess:(void (^)(NSString *username, NSString *password))success cancel:(void (^)())cancel {
    UIViewController *rootViewController = [[[UIApplication sharedApplication] keyWindow] rootViewController];
    WPcomLoginViewController *loginViewController = [[WPcomLoginViewController alloc] initWithStyle:UITableViewStyleGrouped];
    loginViewController.successBlock = success;
    loginViewController.cancelBlock = cancel;
    loginViewController.isCancellable = YES;
    loginViewController.dismissWhenFinished = YES;
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:loginViewController];
    navController.modalPresentationStyle = UIModalPresentationFormSheet;
    navController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [rootViewController presentViewController:navController animated:YES completion:nil];
}

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [super viewDidLoad];

    self.tableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"welcome_bg_pattern"]];
    self.tableView.backgroundView = nil;
    
    self.wpComApi = [WordPressComApi sharedApi];
	self.footerText = @" ";
	self.buttonText = NSLocalizedString(@"Sign In", @"");
	self.navigationItem.title = NSLocalizedString(@"Sign In", @"");
    
    if (isCancellable) {
        UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
        self.navigationItem.leftBarButtonItem = barButton;
    }
    
	// Setup WPcom table header
	CGRect headerFrame = CGRectMake(0, 0, 320, 70);
	CGRect logoFrame = CGRectMake(40, 20, 229, 43);
	NSString *logoFile = @"logo_wpcom.png";
	if(IS_IPAD == YES) {
		logoFile = @"logo_wpcom@2x.png";
		logoFrame = CGRectMake(150, 20, 229, 43);
	}

	UIView *headerView = [[UIView alloc] initWithFrame:headerFrame];
	UIImageView *logo = [[UIImageView alloc] initWithImage:[UIImage imageNamed:logoFile]];
	logo.frame = logoFrame;
	[headerView addSubview:logo];
	self.tableView.tableHeaderView = headerView;
    	
	if(IS_IPAD)
		self.tableView.backgroundView = nil;
    
}


- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	isSigningIn = NO;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return [super shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 2;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(section == 0)
		return 2;
	else
		return 1;
}


- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if(section == 0)
		return footerText;
    else
		return @"";
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = nil;
	
	if(indexPath.section == 1) {
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
        if(isSigningIn) {
			[activityCell.spinner startAnimating];
			self.buttonText = NSLocalizedString(@"Signing In...", @"");
		}
		else {
			[activityCell.spinner stopAnimating];
			self.buttonText = NSLocalizedString(@"Sign In", @"");
		}
		
		activityCell.textLabel.text = buttonText;
        if (isSigningIn) {
            activityCell.selectionStyle = UITableViewCellSelectionStyleNone;
        } else {
            activityCell.selectionStyle = UITableViewCellSelectionStyleBlue;
        }
		cell = activityCell;
	} else {
        if ([indexPath row] == 0) {
            if (loginCell == nil) {
                loginCell = [[UITableViewTextFieldCell alloc] initWithStyle:UITableViewCellStyleDefault 
                                                            reuseIdentifier:@"TextCell"];
                loginCell.textField.text = self.wpComApi.username;
            }
            loginCell.textLabel.text = NSLocalizedString(@"Username", @"");
            loginCell.textField.placeholder = NSLocalizedString(@"WordPress.com username", @"");
            loginCell.textField.keyboardType = UIKeyboardTypeEmailAddress;
            loginCell.textField.returnKeyType = UIReturnKeyNext;
            loginCell.textField.tag = 0;
            loginCell.textField.delegate = self;
            if( self.predefinedUsername )
                loginCell.textField.text = self.predefinedUsername;
            if(isSigningIn)
                [loginCell.textField resignFirstResponder];
            cell = loginCell;
        }
        else {
            if (passwordCell == nil) {
                passwordCell = [[UITableViewTextFieldCell alloc] initWithStyle:UITableViewCellStyleDefault 
                                                               reuseIdentifier:@"TextCell"];
                passwordCell.textField.text = self.wpComApi.password;
            }
            passwordCell.textLabel.text = NSLocalizedString(@"Password", @"");
            passwordCell.textField.placeholder = NSLocalizedString(@"WordPress.com password", @"");
            passwordCell.textField.keyboardType = UIKeyboardTypeDefault;
            passwordCell.textField.secureTextEntry = YES;
            passwordCell.textField.tag = 1;
            passwordCell.textField.delegate = self;
            if(isSigningIn)
                [passwordCell.textField resignFirstResponder];
            cell = passwordCell;
        }
    }

	return cell;    
}


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tv deselectRowAtIndexPath:indexPath animated:YES];
		
	switch (indexPath.section) {
		case 0:
        {
			UITableViewCell *cell = (UITableViewCell *)[tv cellForRowAtIndexPath:indexPath];
			for(UIView *subview in cell.subviews) {
				if([subview isKindOfClass:[UITextField class]] == YES) {
					UITextField *tempTextField = (UITextField *)subview;
					[tempTextField becomeFirstResponder];
					break;
				}
			}
			break;
        }
		case 1:
			for(int i = 0; i < 2; i++) {
				UITableViewCell *cell = (UITableViewCell *)[tv cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
				for(UIView *subview in cell.subviews) {
					if([subview isKindOfClass:[UITextField class]] == YES) {
						UITextField *tempTextField = (UITextField *)subview;
						[self textFieldDidEndEditing:tempTextField];
					}
				}
			}
			if([loginCell.textField.text isEqualToString:@""]) {
				self.footerText = NSLocalizedString(@"Username is required.", @"");
				self.buttonText = NSLocalizedString(@"Sign In", @"");
				[tv reloadData];
			}
			else if([passwordCell.textField.text isEqualToString:@""]) {
				self.footerText = NSLocalizedString(@"Password is required.", @"");
				self.buttonText = NSLocalizedString(@"Sign In", @"");
				[tv reloadData];
			}
			else {
                
                if (![ReachabilityUtils isInternetReachable]) {
                    [ReachabilityUtils showAlertNoInternetConnection];
                    return;
                }
                
				self.buttonText = NSLocalizedString(@"Signing in...", @"");
				
                [self signIn:self];
			}
			break;
		default:
			break;
	}
}


#pragma mark -
#pragma mark UITextField delegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	
	UITableViewCell *cell = nil;
    UITextField *nextField = nil;
    switch (textField.tag) {
        case 0:
            [textField endEditing:YES];
            cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
            if(cell != nil) {
                nextField = (UITextField*)[cell viewWithTag:1];
                if(nextField != nil)
                    [nextField becomeFirstResponder];
            }
            break;
        case 1:
            [self signIn:self];
            break;
	}

	return YES;	
}


- (void)textFieldDidEndEditing:(UITextField *)textField {
    UITableViewCell *cell = (UITableViewCell *)[textField superview];
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
	
	switch (indexPath.row) {
		case 0:
			if((textField.text != nil) && ([textField.text isEqualToString:@""])) {
				self.footerText = NSLocalizedString(@"Username is required.", @"");
			}
			else {
				textField.text = [[textField.text stringByReplacingOccurrencesOfString:@" " withString:@""] lowercaseString];
			}
			break;
		case 1:
			if((textField.text != nil) && ([textField.text isEqualToString:@""])) {
				self.footerText = NSLocalizedString(@"Password is required.", @"");
			}
			break;
		default:
			break;
	}
	
	[textField resignFirstResponder];
}


#pragma mark -
#pragma mark Custom methods

- (void)signIn:(id)sender {
    if (isSigningIn) {
        return;
    }
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:1]] withRowAnimation:UITableViewRowAnimationNone];
    __weak WPcomLoginViewController *loginController = self;
    NSString *username = loginCell.textField.text;
    NSString *password = passwordCell.textField.text;
    if (![username length] > 0) {
        self.footerText = NSLocalizedString(@"Username is required.", @"");
    } else if (![password length] > 0) {
        self.footerText = NSLocalizedString(@"Password is required.", @"");
    } else {
        isSigningIn = YES;
        self.footerText = @" ";
        [self.wpComApi signInWithUsername:username
                                 password:password
                                  success:^{
                                      [loginController.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:1]] withRowAnimation:UITableViewRowAnimationNone];
                                      if (loginController.delegate) {
                                          [loginController.delegate loginController:loginController didAuthenticateWithUsername:loginController.wpComApi.username];
                                      }
                                      if (loginController.successBlock) {
                                          loginController.successBlock(username, password);
                                      }
                                      if (self.dismissWhenFinished) {
                                          [self dismissViewControllerAnimated:YES completion:nil];
                                      }
                                  } failure:^(NSError *error) {
                                      WPFLog(@"Login failed with username %@: %@", username, error);
                                      loginController.footerText = NSLocalizedString(@"Sign in failed. Please try again.", @"");
                                      loginController.buttonText = NSLocalizedString(@"Sign In", @"");
                                      loginController.isSigningIn = NO;
                                      [loginController.tableView reloadData];
                                  }];
    }
    [self.tableView reloadData];
}


- (IBAction)cancel:(id)sender {
    if (self.delegate) {
        [self.delegate loginControllerDidDismiss:self];
    }
    if (self.cancelBlock) {
        self.cancelBlock();
    }
    if (self.dismissWhenFinished) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

@end
