#import "EditBlogViewController.h"
#import "Constants.h"
#import "BlogDataManager.h"
#import "WPSelectionTableViewController.h"
#import "WordPressAppDelegate.h"
#import "BlogsViewController.h"
#import "WPNavigationLeftButtonView.h"
#import "UIViewController+WPAnimation.h"
#import "Reachability.h"
#import "WPLabelFooterView.h"
#import "BlogHTTPAuthenticationViewController.h"

#define kResizePhotoSettingSectionHeight    80.0f

@interface EditBlogViewController ()
- (void)populateSelectionsControllerWithNoOfRecentPosts;
- (void)disableLabel:(UILabel *)label andTextField:(UITextField *)textField;
- (BOOL)currentBlogIsNew;
- (void)createBlog;
- (void)updateBlog;
- (void)handleTextFieldChanged:(NSNotification *)note;
- (void)observeTextField:(UITextField *)textField;
- (void)observeTextFields;
- (void)stopObservingTextField:(UITextField *)textField;
- (void)stopObservingTextFields;
@end

@implementation EditBlogViewController

@synthesize blogEditTable;
@synthesize validationView;
@synthesize currentBlog;
@synthesize blogURLTextField;


- (void)disableLabel:(UILabel *)label andTextField:(UITextField *)textField {
    [label setTextColor:kDisabledTextColor];
    [textField setTextColor:kDisabledTextColor];
    [textField setEnabled:NO];
}

- (BOOL)currentBlogIsNew {
    NSString *blogid = [currentBlog valueForKey:kBlogId];
    return !blogid || [blogid isEmpty];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    currentBlog = [[BlogDataManager sharedDataManager] currentBlog];

    noOfPostsTextField.text = [currentBlog valueForKey:kPostsDownloadCount];
	//NSLog(@"kpostsdownloadcount %@",[currentBlog valueForKey:kPostsDownloadCount]);

    self.navigationItem.rightBarButtonItem = saveBlogButton;

    if ([[BlogDataManager sharedDataManager] countOfBlogs] > 0) {
        self.navigationItem.leftBarButtonItem = cancelBlogButton;
    } else {
        self.navigationItem.leftBarButtonItem = nil;
    }

    if ([self currentBlogIsNew]) {
        //[blogURLTextField becomeFirstResponder];	// Trac #353
        saveBlogButton.enabled = NO;
	} else {
        [self disableLabel:blogURLLabel andTextField:blogURLTextField];
        [self disableLabel:userNameLabel andTextField:userNameTextField];
        //[passwordTextField becomeFirstResponder];	// Trac #353
    }
	
	blogHTTPAuthViewController.authEnabled = [[currentBlog objectForKey:@"authEnabled"] boolValue];
	blogHTTPAuthViewController.authUsername = [currentBlog valueForKey:@"authUsername"];
	blogHTTPAuthViewController.authPassword = [[BlogDataManager sharedDataManager] getHTTPPasswordFromKeychainInContextOfCurrentBlog:currentBlog];
	
	[geotaggingSwitch addTarget:self action:@selector(changeGeotaggingSetting) forControlEvents:UIControlEventAllTouchEvents];
	
	[self observeTextFields];
}

#ifdef __IPHONE_3_0
- (void)viewDidUnload {
    [self stopObservingTextFields];
    [super viewDidUnload];
}

#else
- (void)dealloc {
    [self stopObservingTextFields];
    [super dealloc];
}

#endif

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    // this UIViewController is about to re-appear, make sure we remove the current selection in our table view
    NSIndexPath *tableSelection = [blogEditTable indexPathForSelectedRow];

    if (tableSelection != nil) {
        [blogEditTable deselectRowAtIndexPath:tableSelection animated:NO];
    }

    // we retain this controller in the caller (RootViewController) so load view does not get called
    // everytime we navigate to the view
    // need to update the prompt and the title here as well as in loadView
    if ([self currentBlogIsNew]) {
        self.title = NSLocalizedString(@"Add Blog", @"EditBlogViewController_Title_AddBlog");
			
    } else {
        self.title = NSLocalizedString(@"Edit Blog", @"EditBlogViewController_Title_EditBlog");
		NSString *geotaggingSettingName = [NSString stringWithFormat:@"%@-Geotagging", [currentBlog valueForKey:kBlogId]];
		if([[NSUserDefaults standardUserDefaults] boolForKey:geotaggingSettingName])
			geotaggingSwitch.on = YES;
		else
			geotaggingSwitch.on = NO;
	}

    //[blogEditTable reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 5;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 3;
    }

    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.row) {
        case 0:
            if (indexPath.section == 0) {
                NSString *urlString = [currentBlog objectForKey:@"url"];

                if (urlString) {
                    urlString = [urlString stringByReplacingOccurrencesOfString:@"http://" withString:@""];
                    urlString = [urlString stringByReplacingOccurrencesOfString:@"/xmlrpc.php" withString:@""];
                    blogURLTextField.text = urlString;
                }

                blogURLTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
                return blogURLTableViewCell;
            } else if (indexPath.section == 2) {
				return geotaggingTableViewCell;
			} else if (indexPath.section == 3) {
                NSNumber *value = [currentBlog valueForKey:kResizePhotoSetting];
				
                if (value == nil) {
                    value = [NSNumber numberWithInt:0];
                    [currentBlog setValue:value forKey:kResizePhotoSetting];
                }
				
                resizePhotoControl.on = [value boolValue];
                return resizePhotoViewCell;
            } else if (indexPath.section == 4) {
				BOOL httpAuthEnabled = [[currentBlog objectForKey:@"authEnabled"] boolValue];
				blogHTTPAuthTextField.text = httpAuthEnabled ? @"On" : @"Off";
				return blogHTTPAuthTableViewCell;
			}
			else {
                noOfPostsTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
                return noOfPostsTableViewCell;
            }

            break;
        case 1:
            if (indexPath.section == 0) {
                userNameTextField.text = [currentBlog objectForKey:@"username"];
                userNameTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
                return userNameTableViewCell;
            }
            
            break;

        case 2:
            //passwordTextField.text = [currentBlog objectForKey:@"pwd"];
			passwordTextField.text = [[BlogDataManager sharedDataManager] getPasswordFromKeychainInContextOfCurrentBlog:currentBlog];
            passwordTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
            return passwordTableViewCell;
            break;

        default:
            break;
    }

    return nil;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    //if (section == 3) {
        //This Class creates a view which contains label with color and font attributes and sets the label properties and it is used as footer view for section in tableview.
    //    WPLabelFooterView *labelView = [[[WPLabelFooterView alloc] initWithFrame:CGRectMake(0, 3, 300, 60)] autorelease];
        //Sets the number of lines to be shown in the label.
    //    [labelView setNumberOfLines:(NSInteger) 3];
        //Sets the text alignment of the label.
    //    [labelView setTextAlignment:UITextAlignmentCenter];
        //Sets the text for the label.
    //    [labelView setText:kResizePhotoSettingHintLabel];

    //    return labelView;
    //}

    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == 3) {
        return kResizePhotoSettingSectionHeight;
    }

    return 0.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44.0f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1) {
        [self populateSelectionsControllerWithNoOfRecentPosts];
    }
	if (indexPath.section == 4) {
		blogHTTPAuthViewController.title = @"HTTP Authentication";
		[self.navigationController pushViewController:blogHTTPAuthViewController animated:YES];
    }
}

- (void)populateSelectionsControllerWithNoOfRecentPosts {
    WPSelectionTableViewController *selectionTableViewController = [[WPSelectionTableViewController alloc] initWithNibName:@"WPSelectionTableViewController" bundle:nil];

    BlogDataManager *dm = [BlogDataManager sharedDataManager];

    NSArray *dataSource = [NSArray arrayWithObjects:@"10 Recent Items", @"25 Recent Items", @"50 Recent Items", @"100 Recent Items", nil];

    NSString *curStatus = [[dm currentBlog] valueForKey:kPostsDownloadCount];
    // default value for number of posts is setin BlogDataManager.makeNewBlogCurrent
    NSArray *selObject = (curStatus == nil ? [NSArray arrayWithObject:[dataSource objectAtIndex:0]] : [NSArray arrayWithObject:curStatus]);
    [selectionTableViewController populateDataSource:dataSource
     havingContext:nil
     selectedObjects:selObject
     selectionType:kRadio
     andDelegate:self];

    selectionTableViewController.title = @"Status";
    selectionTableViewController.navigationItem.rightBarButtonItem = nil;
    [self.navigationController pushViewController:selectionTableViewController animated:YES];
    [selectionTableViewController release];
}

- (void)selectionTableViewController:(WPSelectionTableViewController *)selctionController completedSelectionsWithContext:(void *)selContext selectedObjects:(NSArray *)selectedObjects haveChanges:(BOOL)isChanged {
    if (!isChanged) {
        [selctionController clean];
        return;
    }

    BlogDataManager *dataManager = [BlogDataManager sharedDataManager];
    [[dataManager currentBlog] setObject:[selectedObjects objectAtIndex:0] forKey:kPostsDownloadCount];
    noOfPostsTextField.text = [selectedObjects objectAtIndex:0];

    [selctionController clean];
}

- (void)cancel:(id)sender {
    [[BlogDataManager sharedDataManager] resetCurrentBlog];
    [self.navigationController dismissModalViewControllerAnimated:YES];
}

- (void)addProgressIndicator {
    NSAutoreleasePool *apool = [[NSAutoreleasePool alloc] init];

    [self.view addSubview:validationView];
    validationView.alpha = 0.0;
    [self.view bringSubviewToFront:validationView];
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.5];
    [UIView setAnimationTransition:UIViewAnimationTransitionNone forView:self.view cache:YES];
    validationView.alpha = 0.7;
    [UIView commitAnimations];

    [apool release];
}

- (void)removeProgressIndicator {
    NSAutoreleasePool *apool = [[NSAutoreleasePool alloc] init];

    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.5];
    [UIView setAnimationTransition:UIViewAnimationTransitionNone forView:self.view cache:YES];
    [UIView setAnimationDelegate:self];
    validationView.alpha = 0.0;
    [UIView commitAnimations];

    [validationView removeFromSuperview];

    [apool release];
}

- (void)showSpinner {
    [self performSelectorInBackground:@selector(addProgressIndicator) withObject:nil];
}

- (void)hideSpinner {
    [self performSelectorInBackground:@selector(removeProgressIndicator) withObject:nil];
}

- (void)setBlogAttributes {
    NSString *username = userNameTextField.text;
    NSString *pwd = passwordTextField.text;
    NSString *url = [blogURLTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSNumber *value = [NSNumber numberWithBool:resizePhotoControl.on];
	NSString *authUsername = blogHTTPAuthViewController.blogHTTPAuthUsername.text;
	NSString *authPassword = blogHTTPAuthViewController.blogHTTPAuthPassword.text;
	BOOL authEnabled = blogHTTPAuthViewController.blogHTTPAuthEnabled.on;

	NSString *authBlogURL = [url stringByAppendingString:@"_auth"];
    [currentBlog setValue:url forKey:@"url"];
    [currentBlog setValue:username forKey:@"username"];
	[currentBlog setValue:[NSNumber numberWithBool:authEnabled] forKey:@"authEnabled"];
    //[currentBlog setValue:pwd forKey:@"pwd"];
	[[BlogDataManager sharedDataManager] updatePasswordInKeychain:pwd andUserName:username andBlogURL:url];
	
	//if (authEnabled) {
		[currentBlog setValue:authUsername forKey:@"authUsername"];
		[[BlogDataManager sharedDataManager] updatePasswordInKeychain:authPassword
														  andUserName:authUsername
														   andBlogURL:authBlogURL];
	//}

    [currentBlog setValue:value forKey:kResizePhotoSetting];
}

	
- (void)saveBlog:(id)sender {
    [self showSpinner];
    [self setBlogAttributes];

    if ([[Reachability sharedReachability] internetConnectionStatus] == NotReachable) {
        [[WordPressAppDelegate sharedWordPressApp] showErrorAlert:kNoInternetErrorMessage];
        return;
    }

    if ([self currentBlogIsNew]) {
        [self createBlog];

    } else {
        [self updateBlog];
    }

    [self hideSpinner];
	
}

- (void)changeGeotaggingSetting {
	NSString *geotaggingSettingName = [NSString stringWithFormat:@"%@-Geotagging", [currentBlog valueForKey:kBlogId]];
	if(geotaggingSwitch.on)
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:geotaggingSettingName];
	else
		[[NSUserDefaults standardUserDefaults] setBool:NO forKey:geotaggingSettingName];
}
	
#pragma mark saveBlog
- (void)createBlog {
    BlogDataManager *dm = [BlogDataManager sharedDataManager];
	dm.isProblemWithXMLRPC = NO;
	// isProblem... gets set to YES inside BlogDataManager's refreshCurrentBlog method if there's a problem getting the xmlrpc endpoint url. 
	// set to NO again later in this method if it was set to YES in refreshCurrentBlog.

    NSString *username = [currentBlog valueForKey:@"username"];
    NSString *url = [currentBlog valueForKey:@"url"];
	NSString *authUsername = [currentBlog valueForKey:@"authUsername"];
	NSNumber *authEnabled = [currentBlog objectForKey:@"authEnabled"];

    //NSDictionary *newBlog = [NSDictionary dictionaryWithObjectsAndKeys:username, @"username", pwd, @"pwd", url, @"url", nil];
	//taking out @"pwd" here as it's in keychain now
	
	NSDictionary *newBlog = [NSDictionary dictionaryWithObjectsAndKeys:username, @"username", url, @"url", authEnabled, @"authEnabled", authUsername, @"authUsername", nil];

    if ([dm doesBlogExists:newBlog]) {
        [[WordPressAppDelegate sharedWordPressApp] showErrorAlert:[NSString stringWithFormat:kBlogExistsErrorMessage, url]];
        return;
    }

    //if ([dm refreshCurrentBlog:url user:username password:pwd]) {
		//taking out @"pwd" here too...
	if ([dm refreshCurrentBlog:url user:username]) {
        [dm.currentBlog setObject:[NSNumber numberWithInt:1] forKey:@"kIsSyncProcessRunning"];
        [dm wrapperForSyncPostsAndGetTemplateForBlog:dm.currentBlog];
        [dm saveCurrentBlog];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"NewBlogAdded" object:nil];
        [self.navigationController dismissModalViewControllerAnimated:YES];
    } else {
			if (dm.isProblemWithXMLRPC) {
				//this handles the case of not getting the XMLRPC endpoint and launches a view to ask user for input
				[self showLocateXMLRPCModalViewWithAnimation:YES];
				saveBlogButton.title = @"Try Again";
				dm.isProblemWithXMLRPC = NO;
				return;
			}
	}
	[self changeGeotaggingSetting];
}

- (void)updateBlog {
    BlogDataManager *dm = [BlogDataManager sharedDataManager];

    NSString *username = [currentBlog valueForKey:@"username"];
    NSString *url = [currentBlog valueForKey:@"url"];
	NSString *pwd = [dm getBlogPasswordFromKeychainWithUsername:username andBlogName:url];

    if ([dm validateCurrentBlog:url user:username password:pwd]) {
        [dm performSelector:@selector(generateTemplateForBlog:) withObject:[[dm.currentBlog copy] autorelease]];
        [dm addSyncPostsForBlogToQueue:dm.currentBlog];
        [dm saveCurrentBlog];
		[self changeGeotaggingSetting];

        [self.navigationController dismissModalViewControllerAnimated:YES];
    }
}

- (void)didReceiveMemoryWarning {
    WPLog(@"%@ %@", self, NSStringFromSelector(_cmd));
    [super didReceiveMemoryWarning];
}

- (void)handleTextFieldChanged:(NSNotification *)note {

    saveBlogButton.enabled = !([blogURLTextField.text isEmpty] ||
                               [userNameTextField.text isEmpty] ||
                               [passwordTextField.text isEmpty]);
}

- (void)observeTextField:(UITextField *)textField {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleTextFieldChanged:)
                                                 name:@"UITextFieldTextDidChangeNotification"
                                               object:textField];

}

- (void)observeTextFields {
    [self observeTextField:blogURLTextField];
    [self observeTextField:userNameTextField];
    [self observeTextField:passwordTextField];
}

- (void)stopObservingTextField:(UITextField *)textField {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"UITextFieldTextDidChangeNotification"
                                                  object:textField];
}

- (void)stopObservingTextFields {
    [self stopObservingTextField:blogURLTextField];
    [self stopObservingTextField:userNameTextField];
    [self stopObservingTextField:passwordTextField];
}

- (void)setAuthEnabledText:(BOOL)authEnabled {
	blogHTTPAuthTextField.text = authEnabled ? @"On" : @"Off";
}

#pragma mark UITextFieldDelegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];

    if (textField == blogURLTextField) {
        [userNameTextField becomeFirstResponder];
    } else if (textField == userNameTextField) {
        [passwordTextField becomeFirstResponder];
    }

    return YES;
}

#pragma mark -
#pragma mark Show LocateXMLRPC Modal View

- (void)showLocateXMLRPCModalViewWithAnimation:(BOOL)animate {
	LocateXMLRPCViewController *locateXMLRPCViewController = [[[LocateXMLRPCViewController alloc] initWithNibName:@"LocateXMLRPCViewController" bundle:nil] autorelease];
	UINavigationController *modalNavigationController = [[UINavigationController alloc] initWithRootViewController:locateXMLRPCViewController];
		
	[self.navigationController presentModalViewController:modalNavigationController animated:animate];

	[modalNavigationController release];
}


@end
