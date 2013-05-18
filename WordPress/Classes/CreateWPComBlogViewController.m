//
//  CreateWPComBlogViewController.m
//  WordPress
//
//  Created by Sendhil Panchadsaram on 4/10/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "CreateWPComBlogViewController.h"
#import "SelectWPComLanguageViewController.h"
#import "SelectWPComBlogVisibilityViewController.h"
#import "UITableViewTextFieldCell.h"
#import "UITableViewActivityCell.h"
#import "UITableViewSwitchCell.h"
#import "WordPressComApi.h"
#import "WPComLanguages.h"
#import "SFHFKeychainUtils.h"
#import "WordPressAppDelegate.h"
#import "ReachabilityUtils.h"

@interface CreateWPComBlogViewController () <
    SelectWPComBlogVisibilityViewControllerDelegate,
    UITextFieldDelegate> {
        
    UITableViewTextFieldCell *_blogUrlCell;
    UITableViewTextFieldCell *_blogTitleCell;
    UITableViewSwitchCell *_geolocationEnabledCell;
    UITableViewCell *_blogVisibilityCell;
    UITableViewCell *_localeCell;
    
    UITextField *_blogUrlTextField;
    UITextField *_blogTitleTextField;
    
    NSString *_buttonText;
    NSString *_footerText;
    
    BOOL _geolocationEnabled;
    BOOL _isCreatingBlog;
    BOOL _userPressedBackButton;

    NSDictionary *_currentLanguage;
    WordPressComApiBlogVisibility _blogVisibility;
}

@end

@implementation CreateWPComBlogViewController

CGSize const CreateBlogHeaderSize = { 320.0, 70.0 };

NSUInteger const CreateBlogBlogUrlFieldTag = 1;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    
    if (self) {
        _currentLanguage = [WPComLanguages currentLanguage];
        _blogVisibility = WordPressComApiBlogVisibilityPublic;
        _geolocationEnabled = true;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"welcome_bg_pattern"]];
    self.tableView.backgroundView = nil;
    
	_footerText = @" ";
	_buttonText = NSLocalizedString(@"Create WordPress.com Blog", @"");
	self.navigationItem.title = NSLocalizedString(@"Create Blog", @"");
    
    UIImageView *logoImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo_wpcom"]];
    logoImage.frame = CGRectMake(0.0f, 0.0f, CreateBlogHeaderSize.width, CreateBlogHeaderSize.height);
    logoImage.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    logoImage.contentMode = UIViewContentModeCenter;
    self.tableView.tableHeaderView = logoImage;
}

- (void)didMoveToParentViewController:(UIViewController *)parent
{
    // User has pressed back button so make sure the user does not see a strange message
    // or encounters strange behavior as a result of a failed or successful attempt to create an account.
    if (parent == nil) {
        self.delegate = nil;
        _userPressedBackButton = true;
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0)
        return 5;
    else
        return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if(section == 0)
		return _footerText;
    else
		return @"";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
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
        
        if(_isCreatingBlog) {
			[activityCell.spinner startAnimating];
			_buttonText = NSLocalizedString(@"Creating Blog...", nil);
		} else {
			[activityCell.spinner stopAnimating];
			_buttonText = NSLocalizedString(@"Create WordPress.com Blog", nil);
		}
		
		activityCell.textLabel.text = _buttonText;
        if (_isCreatingBlog) {
            activityCell.selectionStyle = UITableViewCellSelectionStyleNone;
        } else {
            activityCell.selectionStyle = UITableViewCellSelectionStyleBlue;
        }
        
		cell = activityCell;
	} else {
        if (indexPath.row == 0) {
            if (_blogUrlCell == nil) {
                _blogUrlCell = [[UITableViewTextFieldCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                               reuseIdentifier:@"TextCell"];
            }
            _blogUrlCell.textLabel.text = NSLocalizedString(@"Blog URL", nil);
            _blogUrlTextField = _blogUrlCell.textField;
            _blogUrlTextField.tag = CreateBlogBlogUrlFieldTag;
            _blogUrlTextField.placeholder = NSLocalizedString(@"myblog.wordpress.com", @"");
            _blogUrlTextField.keyboardType = UIKeyboardTypeURL;
            _blogUrlTextField.delegate = self;
            cell = _blogUrlCell;
        } else if (indexPath.row == 1) {
            if (_blogTitleCell == nil) {
                _blogTitleCell = [[UITableViewTextFieldCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                                 reuseIdentifier:@"TextCell"];
            }
            _blogTitleCell.textLabel.text = NSLocalizedString(@"Blog Title", nil);
            _blogTitleTextField = _blogTitleCell.textField;
            _blogTitleTextField.placeholder = NSLocalizedString(@"My Blog", nil);
            _blogTitleTextField.delegate = self;
            cell = _blogTitleCell;
        } else if (indexPath.row == 2) {
            if (_localeCell == nil) {
                _localeCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                                     reuseIdentifier:@"LocaleCell"];
            }
            _localeCell.textLabel.text = @"Language";
            _localeCell.detailTextLabel.text = [_currentLanguage objectForKey:@"name"];
            _localeCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell = _localeCell;
        } else if (indexPath.row == 3) {
            if (_blogVisibilityCell == nil) {
                _blogVisibilityCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                                             reuseIdentifier:@"VisibilityCell"];
            }
            _blogVisibilityCell.textLabel.text = @"Blog Visibility";
            _blogVisibilityCell.detailTextLabel.text = [self textForCurrentBlogVisibility];
            _blogVisibilityCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell = _blogVisibilityCell;
        } else if (indexPath.row == 4) {
            if(_geolocationEnabledCell == nil) {
                NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"UITableViewSwitchCell" owner:nil options:nil];
                for(id currentObject in topLevelObjects)
                {
                    if([currentObject isKindOfClass:[UITableViewSwitchCell class]])
                    {
                        _geolocationEnabledCell = (UITableViewSwitchCell *)currentObject;
                        break;
                    }
                }
            }
            _geolocationEnabledCell.textLabel.text = NSLocalizedString(@"Geotagging", nil);
            _geolocationEnabledCell.selectionStyle = UITableViewCellSelectionStyleNone;
            _geolocationEnabledCell.cellSwitch.on = _geolocationEnabled;
            [_geolocationEnabledCell.cellSwitch addTarget:self action:@selector(toggleGeolocation:) forControlEvents:UIControlEventValueChanged];
            cell = _geolocationEnabledCell;
        }
    }
    
	return cell;

}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (_isCreatingBlog)
        return;

    if (indexPath.section == 0) {
        if (indexPath.row == 2) {
            SelectWPComLanguageViewController *selectLanguageViewController = [[SelectWPComLanguageViewController alloc] initWithStyle:UITableViewStyleGrouped];
            selectLanguageViewController.currentlySelectedLanguageId = [[_currentLanguage objectForKey:@"lang_id"] intValue];
            selectLanguageViewController.didSelectLanguage = ^(NSDictionary *language){
                _currentLanguage = language;
                [self.tableView reloadData];
            };
            [self.navigationController pushViewController:selectLanguageViewController animated:YES];
        } else if (indexPath.row == 3) {
            SelectWPComBlogVisibilityViewController *selectedVisibilityViewController = [[SelectWPComBlogVisibilityViewController alloc] initWithStyle:UITableViewStyleGrouped];
            selectedVisibilityViewController.currentBlogVisibility = _blogVisibility;
            selectedVisibilityViewController.delegate = self;
            [self.navigationController pushViewController:selectedVisibilityViewController animated:YES];
        }
    } else {
        [self clickedCreateBlog];
    }
}

#pragma mark - UITextField delegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
    
    switch (textField.tag) {
        case CreateBlogBlogUrlFieldTag:
            [_blogTitleTextField becomeFirstResponder];
            break;
        default:
            break;
    }
    
	return YES;
}

#pragma mark - SelectWPComBlogVisibilityViewControllerDelegate

- (void)selectWPComBlogVisibilityViewController:(SelectWPComBlogVisibilityViewController *)viewController didSelectBlogVisibilitySetting:(WordPressComApiBlogVisibility)visibility
{
    _blogVisibility = visibility;
    [self.tableView reloadData];
}

#pragma mark - Private Methods

- (void)toggleGeolocation:(id)sender
{
    _geolocationEnabled = _geolocationEnabledCell.cellSwitch.on;
}

- (void)clickedCreateBlog
{
    [self.view endEditing:YES];

    if (![self areFieldsValid]) {
        [self displayErrorMessage];
        return;
    }
    
    if (![ReachabilityUtils isInternetReachable]) {
        [ReachabilityUtils showAlertNoInternetConnection];
        return;
    }

    _isCreatingBlog = true;
    [self.tableView reloadData];
    [[WordPressComApi sharedApi] createWPComBlogWithUrl:_blogUrlTextField.text andBlogTitle:_blogTitleTextField.text andLanguageId:[_currentLanguage objectForKey:@"lang_id"] andBlogVisibility:_blogVisibility success:^(id responseObject){
        NSDictionary *blogDetails = [responseObject dictionaryForKey:@"blog_details"];
        [self createBlog:blogDetails];
        [self.delegate createdBlogWithDetails:blogDetails];
    } failure:^(NSError *error){
        if (!_userPressedBackButton) {
            _isCreatingBlog = false;
            [self.tableView reloadData];
            [self handleCreationError:error];
        }
    }];
}

- (BOOL)areFieldsValid
{
    BOOL areFieldsFilled = [[_blogTitleTextField.text trim] length] != 0 && [[_blogUrlTextField.text trim] length] != 0;
    BOOL urlDoesNotHavePeriod = [_blogUrlTextField.text rangeOfString:@"."].location == NSNotFound;
    
    return areFieldsFilled && urlDoesNotHavePeriod;
}

- (void)displayErrorMessage
{
    NSString *errorMessage;
    
    if ([[_blogUrlTextField.text trim] length] == 0) {
        errorMessage = NSLocalizedString(@"Blog address is required.", nil);
    } else if ([_blogUrlTextField.text rangeOfString:@"."].location != NSNotFound) {
        errorMessage = NSLocalizedString(@"Blog url cannot contain a period", nil);
    } else if ([[_blogTitleTextField.text trim] length] == 0) {
        errorMessage = NSLocalizedString(@"Must set a blog title", nil);
    }
    
    if (errorMessage != nil) {
        _footerText = errorMessage;
        [self.tableView reloadData];
    }
}

// TODO : Figure out where to put this so we aren't duplicating code with AddUsersBlogViewController
- (void)createBlog:(NSDictionary *)blogInfo {
    NSError *error;
    NSString *username = [[NSUserDefaults standardUserDefaults] objectForKey:@"wpcom_username_preference"];
    NSString *password = [SFHFKeychainUtils getPasswordForUsername:username
                                                    andServiceName:@"WordPress.com"
                                                             error:&error];
    
    NSMutableDictionary *newBlog = [NSMutableDictionary dictionary];
    [newBlog setObject:username forKey:@"username"];
    [newBlog setObject:password forKey:@"password"];
    [newBlog setObject:[blogInfo objectForKey:@"blogname"] forKey:@"blogName"];
    [newBlog setObject:[blogInfo objectForKey:@"blogid"] forKey:@"blogid"];
    [newBlog setObject:[blogInfo objectForKey:@"url"] forKey:@"url"];
    [newBlog setObject:[blogInfo objectForKey:@"xmlrpc"] forKey:@"xmlrpc"];
    [newBlog setObject:@(true) forKey:@"isAdmin"];
    
    
    WordPressAppDelegate *appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
    Blog *blog = [Blog createFromDictionary:newBlog withContext:appDelegate.managedObjectContext];
    blog.geolocationEnabled = _geolocationEnabled;
	[blog dataSave];
    [blog syncBlogWithSuccess:^{
        if( ! [blog isWPcom] )
            [[WordPressComApi sharedApi] syncPushNotificationInfo];
    }
                      failure:nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"BlogsRefreshNotification" object:nil];
    
    [appDelegate.managedObjectContext save:&error];
    if (error != nil) {
        NSLog(@"Error adding blogs: %@", [error localizedDescription]);
    }
    [[WordPressComApi sharedApi] syncPushNotificationInfo];
}

- (void)handleCreationError:(NSError *)error
{
    NSString *errorCode = [error.userInfo objectForKey:WordPressComApiErrorCodeKey];
    NSString *errorMessage;
    if ([errorCode isEqualToString:WordPressComApiErrorCodeInvalidBlogUrl]) {
        errorMessage = NSLocalizedString(@"Invalid Site Address", nil);
    } else if ([errorCode isEqualToString:WordPressComApiErrorCodeInvalidBlogTitle]) {
        NSLocalizedString(@"Invalid blog title", nil);
    } else {
        errorMessage = NSLocalizedString(@"Unknown error", nil);
    }
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:errorMessage delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil, nil];
    [alertView show];
}

- (NSString *)textForCurrentBlogVisibility
{
    if (_blogVisibility == WordPressComApiBlogVisibilityPublic) {
        return NSLocalizedString(@"Public", nil);
    } else if (_blogVisibility == WordPressComApiComBlogVisibilityPrivate) {
        return NSLocalizedString(@"Private", nil);
    } else {
        return NSLocalizedString(@"Hidden", nil);
    }
}

@end
