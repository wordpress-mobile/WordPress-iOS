#import "PostSettingsViewController.h"
#import "WPSelectionTableViewController.h"
#import "WPPublishOnEditController.h"
#import "BlogDataManager.h"
#import "WordPressAppDelegate.h"
#import "WPLabelFooterView.h"

#define kPasswordFooterSectionHeight         68.0f
#define kResizePhotoSettingSectionHeight     60.0f

@interface PostSettingsViewController (Private)

- (void)keyboardWillShow:(BOOL)notif;
- (void)setViewMovedUp:(BOOL)movedUp;

@end

@implementation PostSettingsViewController

@synthesize postDetailViewController, tableView, passwordTextField, commentsSwitchControl;
@synthesize pingsSwitchControl; //, customFieldsSwitchControl;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Initialization code
    }

    return self;
}

- (void)dealloc {
    [super dealloc];
}

- (void)endEditingAction:(id)sender {
    [passwordTextField resignFirstResponder];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    postDetailViewController.hasChanges = YES;

//	if (passwordTextField == textField)
//		[self keyboardWillShow:YES];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    postDetailViewController.hasChanges = YES;

//	if (passwordTextField == textField)
//		[self keyboardWillShow:NO];

    [[BlogDataManager sharedDataManager].currentPost setValue:textField.text forKey:@"wp_password"];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)endEditingForTextFieldAction:(id)sender {
    [passwordTextField endEditing:YES];
}

- (void)keyboardWillShow:(BOOL)notif {
    [self setViewMovedUp:notif];
}

// Animate the entire view up or down, to prevent the keyboard from covering the author field.
- (void)setViewMovedUp:(BOOL)movedUp {
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.3];
    // Make changes to the view's frame inside the animation block. They will be animated instead
    // of taking place immediately.
    CGRect rect = self.view.frame;

    if (movedUp) {
        // If moving up, not only decrease the origin but increase the height so the view
        // covers the entire screen behind the keyboard.
        rect.origin.y -= kOFFSET_FOR_KEYBOARD;
        rect.size.height += kOFFSET_FOR_KEYBOARD;
    } else {
        // If moving down, not only increase the origin but decrease the height.
        rect.origin.y += kOFFSET_FOR_KEYBOARD;
        rect.size.height -= kOFFSET_FOR_KEYBOARD;
    }

    self.view.frame = rect;

    [UIView commitAnimations];
}

- (void)viewDidLoad {
    passwordLabel.font = [UIFont boldSystemFontOfSize:17.0f];
    publishOnLabel.font = [UIFont boldSystemFontOfSize:17.0f];
    passwordTextField.font = [UIFont systemFontOfSize:16];
    publishOnTextField.font = [UIFont systemFontOfSize:14];

    [publishOnTextField setMinimumFontSize:14];
    [publishOnTextField setAdjustsFontSizeToFitWidth:YES];

    resizePhotoLabel.font = [UIFont boldSystemFontOfSize:17.0f];

    [commentsSwitchControl addTarget:self action:@selector(controlEventValueChanged:) forControlEvents:UIControlEventValueChanged];
    [pingsSwitchControl addTarget:self action:@selector(controlEventValueChanged:) forControlEvents:UIControlEventValueChanged];
    [customFieldsSwitchControl addTarget:self action:@selector(controlEventValueChanged:) forControlEvents:UIControlEventValueChanged];

    [resizePhotoControl addTarget:self action:@selector(changeResizePhotosOptions) forControlEvents:UIControlEventAllTouchEvents];
}

- (void)changeResizePhotosOptions {
    postDetailViewController.hasChanges = YES;
    [[BlogDataManager sharedDataManager].currentPost setValue:[NSNumber numberWithInt:resizePhotoControl.on]
     forKey:kResizePhotoSetting];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadData];
	[self setupHelpButton];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    WPLog(@"%@ %@", self, NSStringFromSelector(_cmd));
    [super didReceiveMemoryWarning];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];

    if ([delegate isAlertRunning] == YES)
        return NO;

    // Return YES for supported orientations
    return YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == 1)
        return kPasswordFooterSectionHeight;

    if (section == 2)
        return kResizePhotoSettingSectionHeight;

    return 0.0f;
}

- (IBAction)controlEventValueChanged:(id)sender {
    postDetailViewController.hasChanges = YES;

    if (commentsSwitchControl == sender)
        [[BlogDataManager sharedDataManager].currentPost setValue:[NSNumber numberWithInt:commentsSwitchControl.on] forKey:@"not_used_allow_comments"];else if (pingsSwitchControl == sender)
        [[BlogDataManager sharedDataManager].currentPost setValue:[NSNumber numberWithInt:pingsSwitchControl.on] forKey:@"not_used_allow_pings"];else if (customFieldsSwitchControl == sender) {
        //TODO:JOHNB CustomFields  do something similar here, but first add the appropriate value to current post build in Blog Data Manager
        [[BlogDataManager sharedDataManager].currentPost setValue:[NSNumber numberWithInt:customFieldsSwitchControl.on] forKey:@"custom_fields_enabled"];
    }
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    BlogDataManager *dataManager = [BlogDataManager sharedDataManager];

    NSMutableDictionary *post = [dataManager currentPost];

    switch (indexPath.section) {
        case 0:
        {
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateStyle:NSDateFormatterFullStyle];
            [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
            publishOnTextField.text = [dateFormatter stringFromDate:[[dataManager currentPost] valueForKey:@"date_created_gmt"]];
            [dateFormatter release];
            return publishOnTableViewCell;
        }
//		case 1:
//		{
//
//			if (indexPath.row == 0) {
//				tagsTextField.text = [post valueForKey:@"mt_keywords"];
//				tagsTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
//				return tagsTableViewCell;
//			}
//			else {
//				NSArray *array = [[dataManager currentPost] valueForKey:@"categories"];
//				categoriesTextField.text = [array componentsJoinedByString:@", "];
//				return categoriesTableViewCell;
//			}
//
//		}
//		case 2:
//			commentsSwitchControl.on = [[post valueForKey:@"not_used_allow_comments"] intValue];
//			pingsSwitchControl.on = [[post valueForKey:@"not_used_allow_pings"] intValue];
//			return pingsTableViewCell;
        case 1:

            if (indexPath.row == 0) {
                passwordTextField.text = [post valueForKey:@"wp_password"];
                passwordTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
                return passwordTableViewCell;
            }

            break;
        case 2:

            if (indexPath.row == 0) {
                NSNumber *value = [post valueForKey:kResizePhotoSetting];

                if (value == nil) {
                    value = [NSNumber numberWithInt:0];
                    [post setValue:value forKey:kResizePhotoSetting];
                }

                resizePhotoControl.on = [value boolValue];
                return resizePhotoViewCell;
            }
        default:
            break;
    }

    // Configure the cell
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44.0f;
}

//will be called when auto save method is called.
- (void)updateValuesToCurrentPost {
    BlogDataManager *dm = [BlogDataManager sharedDataManager];

    NSString *str = passwordTextField.text;
    str = (str != nil ? str : @"");
    [dm.currentPost setValue:str forKey:@"wp_password"];

    //[dm.currentPost setValue:[NSNumber numberWithInt:customFieldsSwitchControl.on] forKey:@"custom_fields_enabled"];
    //[dm printDictToLog:dm.currentPost andArrayName:@"from update values: currentPost"];
}

- (void)reloadData {
    BlogDataManager *dm = [BlogDataManager sharedDataManager];
    passwordTextField.text = [dm.currentPost valueForKey:@"wp_password"];
    [tableView reloadData];
}

- (void)tableView:(UITableView *)atableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        WPPublishOnEditController *publishOnEditController = [[WPPublishOnEditController alloc] initWithNibName:@"WPPublishOnEditController" bundle:nil];
        publishOnEditController.settingController = self;
		publishOnEditController.title = @"Publish Date";
        [postDetailViewController.navigationController pushViewController:publishOnEditController animated:YES];
        [publishOnEditController release];
    }

    [atableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:YES];
}

- (void)setupHelpButton {
}

- (IBAction)helpButtonClicked:(id)sender {
	PostSettingsHelpViewController *helpView = [[PostSettingsHelpViewController alloc] init];
	[self.navigationController pushViewController:helpView animated:YES];
	[helpView release];
}

@end
