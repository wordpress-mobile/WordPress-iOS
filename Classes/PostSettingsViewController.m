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

- (void)setViewMovedUp:(BOOL)movedUp;
- (void)showPicker;
- (void)hidePicker;
- (void)showDatePicker;
- (void)hideDatePicker;
- (void)hidePickerAndKeyboard;

@end

@implementation PostSettingsViewController
@synthesize postDetailViewController;

- (void)dealloc {
    [accesoryToolbar release];
    [pickerView release];
    [datePickerView release];
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

//- (void)keyboardWillShow:(BOOL)notif {
//    [self setViewMovedUp:notif];
//}

// Animate the entire view up or down, to prevent the keyboard from covering the author field.
- (void)setViewMovedUp:(BOOL)movedUp {
    CGRect frame = tableView.frame;
    if (movedUp) {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.3];
        frame.size.height = self.view.frame.size.height - pickerView.frame.size.height - accesoryToolbar.frame.size.height;
        tableView.frame = frame;
        [UIView commitAnimations];

        [tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    } else {
        frame.size.height = self.view.frame.size.height;
        tableView.frame = frame;
        // Only the up movement is animated since the combination with the scroll
        // looks weird on down movement
        [tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
    }
}

- (void)viewDidLoad {
    [FlurryAPI logEvent:@"PostSettings"];

    NSMutableArray *allStatuses = [NSMutableArray arrayWithArray:[postDetailViewController.apost availableStatuses]];
    [allStatuses removeObject:@"Private"];
    statusList = [[NSArray arrayWithArray:allStatuses] retain];
    visibilityList = [[NSArray arrayWithObjects:@"Public", @"Password protected", @"Private", nil] retain];
    pickerView = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 416, 320, 216)];
    pickerView.delegate = self;
    pickerView.dataSource = self;
    pickerView.showsSelectionIndicator = YES;
    isShowingPicker = NO;
    isShowingKeyboard = NO;
    isShowingDatePicker = NO;
    datePickerView = [[UIDatePicker alloc] initWithFrame:pickerView.frame];
    if (postDetailViewController.apost.dateCreated)
        datePickerView.date = postDetailViewController.apost.dateCreated;
    else
        datePickerView.date = [NSDate date];

    datePickerView.minuteInterval = 15;
    [datePickerView addTarget:self action:@selector(datePickerChanged) forControlEvents:UIControlEventValueChanged];

    // Animations look better that way
    self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];

    accesoryToolbar = [[UIToolbar alloc] initWithFrame:postDetailViewController.toolbar.frame];
    accesoryToolbar.tintColor = postDetailViewController.toolbar.tintColor;
    NSMutableArray *barButtons = [NSMutableArray arrayWithCapacity:2];
    UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [barButtons addObject:barButton];
    [barButton release];
    barButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(hidePickerAndKeyboard)];
    [barButtons addObject:barButton];
    [barButton release];
    accesoryToolbar.items = barButtons;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [self reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
            if (([postDetailViewController.apost.dateCreated compare:[NSDate date]] == NSOrderedDescending)
                && ([postDetailViewController.apost.status isEqualToString:@"publish"])) {
                statusLabel.text = @"Scheduled";
            } else {
                statusLabel.text = postDetailViewController.apost.statusTitle;
            }
            if ([postDetailViewController.apost.status isEqualToString:@"private"])
                statusTableViewCell.selectionStyle = UITableViewCellSelectionStyleNone;
            else
                statusTableViewCell.selectionStyle = UITableViewCellSelectionStyleBlue;

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
        case 2:
            [self showDatePicker];
            break;

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

#pragma mark -
#pragma mark Pickers and keyboard animations

- (void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
    if (!isShowingPicker) {
        [pickerView removeFromSuperview];
    }
    if (!isShowingDatePicker) {
        [datePickerView removeFromSuperview];
    }
    if (!isShowingPicker && !isShowingKeyboard && !isShowingDatePicker && accesoryToolbar.superview) {
        [accesoryToolbar removeFromSuperview];
    }
}

- (void)showAccessoryToolbar {
    if (!accesoryToolbar.superview) {
        [postDetailViewController.view insertSubview:accesoryToolbar aboveSubview:postDetailViewController.toolbar];
    }
    CGRect frame = pickerView.frame;
    frame.origin.y = postDetailViewController.view.frame.size.height - frame.size.height - accesoryToolbar.frame.size.height;
    frame.size.height = accesoryToolbar.frame.size.height;
    accesoryToolbar.frame = frame;
}

- (void)hideAccessoryToolbar {
    CGRect frame = pickerView.frame;
    frame.origin.y = postDetailViewController.view.frame.size.height - accesoryToolbar.frame.size.height;
    frame.size.height = accesoryToolbar.frame.size.height;
    accesoryToolbar.frame = frame;
}

- (void)showPicker {
    if (isShowingPicker)
        return;
    if (isShowingKeyboard)
        [passwordTextField resignFirstResponder];
    if (isShowingDatePicker)
        [self hideDatePicker];

    [self setViewMovedUp:YES];

    CGRect frame = pickerView.frame;
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.3];
    [postDetailViewController.view insertSubview:pickerView aboveSubview:postDetailViewController.toolbar];
    frame.origin.y -= frame.size.height;
    pickerView.frame = frame;
    [self showAccessoryToolbar];
    [UIView commitAnimations];
    isShowingPicker = YES;
}

- (void)hidePickerAndToolbar:(BOOL)hideToolbar {
    if (!isShowingPicker)
        return;

    CGRect frame = pickerView.frame;
    frame.origin.y += frame.size.height;
    pickerView.frame = frame;
    if (hideToolbar) {
        [self hideAccessoryToolbar];
    }
    isShowingPicker = NO;
}

- (void)hidePicker {
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.3];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
    [self hidePickerAndToolbar:YES];
    [UIView commitAnimations];
}

- (void)removeDate {
    postDetailViewController.apost.dateCreated = nil;
    [tableView reloadData];
    [self hidePickerAndKeyboard];
}

- (void)showDatePicker {
    if (isShowingDatePicker)
        return;
    if (isShowingKeyboard)
        [passwordTextField resignFirstResponder];
    if (isShowingPicker) {
        [self hidePicker];
    }
    [self setViewMovedUp:YES];

    UIBarButtonItem *removeDateButton = [[UIBarButtonItem alloc] initWithTitle:@"Publish inmediately" style:UIBarButtonItemStyleBordered target:self action:@selector(removeDate)];
    NSMutableArray *toolbarItems = [NSMutableArray arrayWithArray:accesoryToolbar.items];
    [toolbarItems insertObject:removeDateButton atIndex:0];
    accesoryToolbar.items = toolbarItems;
    [removeDateButton release];

    CGRect frame = datePickerView.frame;
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.3];
    [postDetailViewController.view insertSubview:datePickerView aboveSubview:postDetailViewController.toolbar];
    frame.origin.y -= frame.size.height;
    datePickerView.frame = frame;
    [self showAccessoryToolbar];
    [UIView commitAnimations];
    isShowingDatePicker = YES;
}

- (void)hideDatePicker {
    if (!isShowingDatePicker)
        return;
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.3];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
    CGRect frame = datePickerView.frame;
    frame.origin.y += frame.size.height;
    datePickerView.frame = frame;
    [self hideAccessoryToolbar];
    [UIView commitAnimations];

    // Remove "publish inmediately" button from toolbar
    NSMutableArray *toolbarItems = [NSMutableArray arrayWithArray:accesoryToolbar.items];
    if ([toolbarItems count] > 2) {
        [toolbarItems removeObjectAtIndex:0];
        accesoryToolbar.items = toolbarItems;
    }

    isShowingDatePicker = NO;
}


- (void)hidePickerAndKeyboard {
    if (isShowingPicker)
        [self hidePicker];

    if (isShowingDatePicker)
        [self hideDatePicker];

    if (isShowingKeyboard)
        [passwordTextField resignFirstResponder];

    [self setViewMovedUp:NO];
}

- (void)keyboardWillShow:(NSNotification *)keyboardInfo {
    isShowingKeyboard = YES;
    if (isShowingPicker)
        [self hidePicker];

    if (isShowingDatePicker)
        [self hideDatePicker];

    [self setViewMovedUp:YES];

    [UIView beginAnimations:@"showKeyboard" context:nil];
    [UIView setAnimationDuration:[[[keyboardInfo userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
    [UIView setAnimationCurve:[[[keyboardInfo userInfo] objectForKey:UIKeyboardAnimationCurveUserInfoKey] doubleValue]];
    if (!DeviceIsPad()) {
        [self showAccessoryToolbar];
    }

    [UIView commitAnimations];
}

- (void)keyboardWillHide:(NSNotification *)keyboardInfo {
    isShowingKeyboard = NO;

    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:[[[keyboardInfo userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
    [UIView setAnimationCurve:[[[keyboardInfo userInfo] objectForKey:UIKeyboardAnimationCurveUserInfoKey] doubleValue]];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];

    if (!DeviceIsPad()) {
        [self hideAccessoryToolbar];
    }

    [UIView commitAnimations];
}

- (void)datePickerChanged {
    postDetailViewController.apost.dateCreated = datePickerView.date;
    [tableView reloadData];
}

@end
