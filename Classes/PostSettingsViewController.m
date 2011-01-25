#import "PostSettingsViewController.h"
#import "WPSelectionTableViewController.h"
#import "WPPublishOnEditController.h"
#import "BlogDataManager.h"
#import "WordPressAppDelegate.h"
#import "WPLabelFooterView.h"

#define kPasswordFooterSectionHeight         68.0f
#define kResizePhotoSettingSectionHeight     60.0f
#define TAG_PICKER_STATUS       0
#define TAG_PICKER_VISIBILITY   1
#define TAG_PICKER_DATE         2

@interface PostSettingsViewController (Private)

- (void)keyboardWillShow:(BOOL)notif;
- (void)setViewMovedUp:(BOOL)movedUp;
- (void)showPicker;
- (void)hidePicker;

@end

@implementation PostSettingsViewController
@synthesize postDetailViewController;

- (void)dealloc {
    [visibilityList release];
    [statusList release];
    [publishOnDateLabel release];
    [publishOnLabel release];
	[passwordTextField release];
    [visibilityLabel release];
    [statusLabel release];
    [publishOnTableViewCell release];
    [visibilityTableViewCell release];
    [statusTableViewCell release];
	[tableView release];
    [super dealloc];
}

- (CGSize)contentSizeForViewInPopover;
{
	return CGSizeMake(320.0, 275.0);
}

- (void)endEditingAction:(id)sender {
	if (passwordTextField != nil){
    [passwordTextField resignFirstResponder];
	}
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
	//	if (passwordTextField == textField)
	//		[self keyboardWillShow:YES];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
	//	if (passwordTextField == textField)
	//		[self keyboardWillShow:NO];
	
	postDetailViewController.post.password = textField.text;
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
    [FlurryAPI logEvent:@"PostSettings"];

    NSMutableArray *allStatuses = [NSMutableArray arrayWithArray:[postDetailViewController.apost availableStatuses]];
    [allStatuses removeObject:@"Private"];
    statusList = [[NSArray arrayWithArray:allStatuses] retain];
    visibilityList = [[NSArray arrayWithObjects:@"Public", @"Password protected", @"Private", nil] retain];
    pickerView = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 200, 320, 200)];
    pickerView.delegate = self;
    pickerView.dataSource = self;
    pickerView.showsSelectionIndicator = YES;
    isShowingPicker = NO;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadData];
}

- (void)didReceiveMemoryWarning {
    WPLog(@"%@ %@", self, NSStringFromSelector(_cmd));
    [super didReceiveMemoryWarning];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	if (DeviceIsPad() == YES) {
		return YES;
	}
	
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
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"Publish";
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.row) {
        case 0:
            statusLabel.text = postDetailViewController.post.statusTitle;
            return statusTableViewCell;
            break;
        case 1:
            if (postDetailViewController.post.password) {
                passwordTextField.text = postDetailViewController.post.password;
                passwordTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
                visibilityLabel.text = @"Password protected";
            } else if ([postDetailViewController.post.status isEqualToString:@"private"]) {
                visibilityLabel.text = @"Private";
            } else {
                visibilityLabel.text = @"Public";
            }

            return visibilityTableViewCell;
            break;
        case 2:
        {
            if (postDetailViewController.apost.dateCreated) {
                if ([postDetailViewController.apost.dateCreated compare:[NSDate date]] == NSOrderedDescending) {
                    publishOnLabel.text = @"Scheduled for";
                } else {
                    publishOnLabel.text = @"Published on";
                }

                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
                [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
                publishOnDateLabel.text = [dateFormatter stringFromDate:postDetailViewController.post.dateCreated];
                [dateFormatter release];
            } else {
                publishOnLabel.text = @"Publish";
                publishOnDateLabel.text = @"inmediately";
            }
            // Resize labels properly
            CGRect frame = publishOnLabel.frame;
            CGSize size = [publishOnLabel.text sizeWithFont:publishOnLabel.font];
            frame.size.width = size.width;
            publishOnLabel.frame = frame;
            frame = publishOnDateLabel.frame;
            frame.origin.x = publishOnLabel.frame.origin.x + publishOnLabel.frame.size.width + 8;
            frame.size.width = publishOnTableViewCell.frame.size.width - frame.origin.x - 8;
            publishOnDateLabel.frame = frame;

            return publishOnTableViewCell;
        }
        default:
            break;
    }
	
    // Configure the cell
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ((indexPath.row == 1) && (postDetailViewController.apost.password))
        return 88.f;
    else
        return 44.0f;
}

- (void)reloadData {
    passwordTextField.text = postDetailViewController.post.password;
	
    [tableView reloadData];
}

- (void)tableView:(UITableView *)atableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.row) {
        case 0:
        {
            if ([postDetailViewController.post.status isEqualToString:@"private"])
                break;

            pickerView.tag = TAG_PICKER_STATUS;
            [pickerView reloadAllComponents];
            [pickerView selectRow:[statusList indexOfObject:postDetailViewController.apost.statusTitle] inComponent:0 animated:NO];
            [self showPicker];
            break;
        }
        case 1:
        {
            pickerView.tag = TAG_PICKER_VISIBILITY;
            [pickerView reloadAllComponents];
            [pickerView selectRow:[visibilityList indexOfObject:visibilityLabel.text] inComponent:0 animated:NO];
            [self showPicker];
            break;
        }
        default:
            break;
    }
    [atableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:YES];
}

#pragma mark -
#pragma mark UIPickerViewDataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)aPickerView numberOfRowsInComponent:(NSInteger)component {
    if (aPickerView.tag == TAG_PICKER_STATUS) {
        return [statusList count];
    } else if (aPickerView.tag == TAG_PICKER_VISIBILITY) {
        return [visibilityList count];
    }
    return 0;
}

#pragma mark -
#pragma mark UIPickerViewDelegate

- (NSString *)pickerView:(UIPickerView *)aPickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    if (aPickerView.tag == TAG_PICKER_STATUS) {
        return [statusList objectAtIndex:row];
    } else if (aPickerView.tag == TAG_PICKER_VISIBILITY) {
        return [visibilityList objectAtIndex:row];
    }

    return @"";
}

- (void)pickerView:(UIPickerView *)aPickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if (aPickerView.tag == TAG_PICKER_STATUS) {
        postDetailViewController.post.statusTitle = [statusList objectAtIndex:row];
    } else if (aPickerView.tag == TAG_PICKER_VISIBILITY) {
        NSString *visibility = [visibilityList objectAtIndex:row];
        if ([visibility isEqualToString:@"Private"]) {
            postDetailViewController.post.status = @"private";
            postDetailViewController.post.password = nil;
        } else {
            if ([postDetailViewController.post.status isEqualToString:@"private"]) {
                postDetailViewController.post.status = @"publish";
            }
            if ([visibility isEqualToString:@"Password protected"]) {
                postDetailViewController.post.password = @"";
            } else {
                postDetailViewController.post.password = nil;
            }
        }
    }

    [tableView reloadData];
}

- (void)showPicker {
    if (isShowingPicker)
        return;

    [passwordTextField resignFirstResponder];

    CGRect frame = pickerView.frame;
    frame.origin.y += frame.size.height;
    pickerView.frame = frame;
    [UIView beginAnimations:nil context:nil];
    [postDetailViewController.view insertSubview:pickerView aboveSubview:postDetailViewController.toolbar];
    frame.origin.y -= frame.size.height;
    pickerView.frame = frame;
    [UIView commitAnimations];
    isShowingPicker = YES;
}

- (void)hidePicker {
    if (!isShowingPicker)
        return;

    [UIView beginAnimations:nil context:nil];
    CGRect frame = pickerView.frame;
    frame.origin.y += frame.size.height;
    pickerView.frame = frame;
    [pickerView removeFromSuperview];
    [UIView commitAnimations];
    isShowingPicker = NO;
}


@end
