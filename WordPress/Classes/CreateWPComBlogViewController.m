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
#import "WordPressComApi.h"
#import "WPComLanguages.h"
#import "WordPressAppDelegate.h"
#import "ReachabilityUtils.h"
#import "WPAccount.h"
#import "WPTableViewSectionFooterView.h"

@interface CreateWPComBlogViewController () <
    SelectWPComBlogVisibilityViewControllerDelegate,
    UITextFieldDelegate> {
        
    UITableViewTextFieldCell *_blogUrlCell;
    UITableViewTextFieldCell *_blogTitleCell;
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
        _geolocationEnabled = YES;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
    
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
        _userPressedBackButton = YES;
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

- (NSString *)titleForFooterInSection:(NSInteger)section {
    if(section == 0)
		return _footerText;
    else
		return @"";
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    WPTableViewSectionFooterView *header = [[WPTableViewSectionFooterView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 0)];
    header.title = [self titleForFooterInSection:section];
    return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    NSString *title = [self titleForFooterInSection:section];
    return [WPTableViewSectionFooterView heightForTitle:title andWidth:CGRectGetWidth(self.view.bounds)];
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
        
        activityCell.textLabel.font = [WPStyleGuide tableviewTextFont];
        activityCell.textLabel.textColor = [WPStyleGuide tableViewActionColor];
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
            _blogUrlTextField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 1)];
            _blogUrlTextField.leftViewMode = UITextFieldViewModeAlways;
            _blogUrlTextField.keyboardType = UIKeyboardTypeURL;
            _blogUrlTextField.delegate = self;
            [self styleTextFieldCell:_blogUrlCell];
            cell = _blogUrlCell;
        } else if (indexPath.row == 1) {
            if (_blogTitleCell == nil) {
                _blogTitleCell = [[UITableViewTextFieldCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                                 reuseIdentifier:@"TextCell"];
            }
            _blogTitleCell.textLabel.text = NSLocalizedString(@"Site Title", @"Label for site title field in create an account process");
            _blogTitleTextField = _blogTitleCell.textField;
            _blogTitleTextField.placeholder = NSLocalizedString(@"My Site", @"Placeholder for site title field in create an account process");
            _blogTitleTextField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, IS_IOS7 ? 10 : 5, 1)];
            _blogTitleTextField.leftViewMode = UITextFieldViewModeAlways;
            _blogTitleTextField.delegate = self;
            [self styleTextFieldCell:_blogTitleCell];
            cell = _blogTitleCell;
        } else if (indexPath.row == 2) {
            if (_localeCell == nil) {
                _localeCell = [[WPTableViewCell alloc] initWithStyle:UITableViewCellStyleValue1
                                                     reuseIdentifier:@"LocaleCell"];
            }
            _localeCell.textLabel.text = @"Language";
            _localeCell.detailTextLabel.text = [_currentLanguage objectForKey:@"name"];
            _localeCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            [WPStyleGuide configureTableViewCell:_localeCell];
            cell = _localeCell;
        } else if (indexPath.row == 3) {
            if (_blogVisibilityCell == nil) {
                _blogVisibilityCell = [[WPTableViewCell alloc] initWithStyle:UITableViewCellStyleValue1
                                                             reuseIdentifier:@"VisibilityCell"];
            }
            _blogVisibilityCell.textLabel.text = @"Blog Visibility";
            _blogVisibilityCell.detailTextLabel.text = [self textForCurrentBlogVisibility];
            _blogVisibilityCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            [WPStyleGuide configureTableViewCell:_blogVisibilityCell];
            cell = _blogVisibilityCell;
        } else if (indexPath.row == 4) {
            UITableViewCell *geolocationCell = [tableView dequeueReusableCellWithIdentifier:@"GeolocationCell"];
            if(geolocationCell == nil) {
                geolocationCell = [[WPTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"GeolocationCell"];
                geolocationCell.accessoryView = [[UISwitch alloc] init];
            }
            UISwitch *geolocationSwitch = (UISwitch *)geolocationCell.accessoryView;
            geolocationCell.textLabel.text = NSLocalizedString(@"Geotagging", nil);
            geolocationCell.selectionStyle = UITableViewCellSelectionStyleNone;
            geolocationSwitch.on = _geolocationEnabled;
            [geolocationSwitch addTarget:self action:@selector(toggleGeolocation:) forControlEvents:UIControlEventValueChanged];
            [WPStyleGuide configureTableViewCell:geolocationCell];
            cell = geolocationCell;
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
    UISwitch *geolocationSwitch = (UISwitch *)sender;
    _geolocationEnabled = geolocationSwitch.on;
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

    _isCreatingBlog = YES;
    [self.tableView reloadData];
    [[WordPressComApi sharedApi] createWPComBlogWithUrl:_blogUrlTextField.text andBlogTitle:_blogTitleTextField.text andLanguageId:[_currentLanguage objectForKey:@"lang_id"] andBlogVisibility:_blogVisibility success:^(id responseObject){
        NSDictionary *blogDetails = [responseObject dictionaryForKey:@"blog_details"];
        [self createBlog:blogDetails];
        [self.delegate createdBlogWithDetails:blogDetails];
    } failure:^(NSError *error){
        if (!_userPressedBackButton) {
            _isCreatingBlog = NO;
            [self.tableView reloadData];
            [self displayCreationError:error];
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
    NSMutableDictionary *newBlog = [NSMutableDictionary dictionary];
    [newBlog setObject:[blogInfo objectForKey:@"blogname"] forKey:@"blogName"];
    [newBlog setObject:[blogInfo objectForKey:@"blogid"] forKey:@"blogid"];
    [newBlog setObject:[blogInfo objectForKey:@"url"] forKey:@"url"];
    [newBlog setObject:[blogInfo objectForKey:@"xmlrpc"] forKey:@"xmlrpc"];
    [newBlog setObject:@(YES) forKey:@"isAdmin"];

    WPAccount *account = [WPAccount defaultWordPressComAccount];
    
    Blog *blog = [account findOrCreateBlogFromDictionary:newBlog withContext:account.managedObjectContext];
    blog.geolocationEnabled = _geolocationEnabled;
	[blog dataSave];
    [blog syncBlogWithSuccess:^{
        if( ! [blog isWPcom] )
            [[WordPressComApi sharedApi] syncPushNotificationInfo];
    }
                      failure:nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"BlogsRefreshNotification" object:nil];
    
    [[WordPressComApi sharedApi] syncPushNotificationInfo];
}

- (void)displayCreationError:(NSError *)error
{
    NSString *errorMessage = [error.userInfo objectForKey:WordPressComApiErrorMessageKey];
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

- (void)styleTextFieldCell:(UITableViewTextFieldCell *)cell
{
    [WPStyleGuide configureTableViewCell:cell];
    cell.textField.font = [WPStyleGuide tableviewTextFont];
}

@end
