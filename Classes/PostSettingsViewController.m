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

- (void)showPicker:(UIView *)picker;

@end

@implementation PostSettingsViewController
@synthesize postDetailViewController;

- (void)dealloc {
    [actionSheet release];
    [popover release];
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

- (void)endEditingAction:(id)sender {
	if (passwordTextField != nil){
    [passwordTextField resignFirstResponder];
	}
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
	postDetailViewController.post.password = textField.text;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)endEditingForTextFieldAction:(id)sender {
    [passwordTextField endEditing:YES];
}

- (void)viewDidLoad {
    [FlurryAPI logEvent:@"PostSettings"];

    NSMutableArray *allStatuses = [NSMutableArray arrayWithArray:[postDetailViewController.apost availableStatuses]];
    [allStatuses removeObject:@"Private"];
    statusList = [[NSArray arrayWithArray:allStatuses] retain];
    visibilityList = [[NSArray arrayWithObjects:@"Public", @"Password protected", @"Private", nil] retain];

    CGRect pickerFrame;
	if (DeviceIsPad())
		pickerFrame = CGRectMake(0, 0, 320, 216);  
	else 
		pickerFrame = CGRectMake(0, 40, 320, 216);    
    pickerView = [[UIPickerView alloc] initWithFrame:pickerFrame];
    pickerView.delegate = self;
    pickerView.dataSource = self;
    pickerView.showsSelectionIndicator = YES;
    isShowingKeyboard = NO;
    datePickerView = [[UIDatePicker alloc] initWithFrame:pickerView.frame];
    datePickerView.minuteInterval = 15;
    [datePickerView addTarget:self action:@selector(datePickerChanged) forControlEvents:UIControlEventValueChanged];

    if (!DeviceIsPad()) {
        UIToolbar *accesoryToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 320, 30)];
        accesoryToolbar.tintColor = postDetailViewController.toolbar.tintColor;
        NSMutableArray *barButtons = [NSMutableArray arrayWithCapacity:2];
        UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        [barButtons addObject:barButton];
        [barButton release];
        barButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(endEditingAction:)];
        [barButtons addObject:barButton];
        [barButton release];
        accesoryToolbar.items = barButtons;
        passwordTextField.inputAccessoryView = accesoryToolbar;
        [accesoryToolbar release];
    }
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
            [self showPicker:pickerView];
            break;
        }
        case 1:
        {
            pickerView.tag = TAG_PICKER_VISIBILITY;
            [pickerView reloadAllComponents];
            [pickerView selectRow:[visibilityList indexOfObject:visibilityLabel.text] inComponent:0 animated:NO];
            [self showPicker:pickerView];
            break;
        }
        case 2:
            datePickerView.tag = TAG_PICKER_DATE;
            if (postDetailViewController.apost.dateCreated)
                datePickerView.date = postDetailViewController.apost.dateCreated;
            else
                datePickerView.date = [NSDate date];            
            [self showPicker:datePickerView];
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

- (void)datePickerChanged {
    postDetailViewController.apost.dateCreated = datePickerView.date;
    [tableView reloadData];
}

#pragma mark -
#pragma mark Pickers and keyboard animations

- (void)showPicker:(UIView *)picker {
    if (isShowingKeyboard)
        [passwordTextField resignFirstResponder];
    
    if (DeviceIsPad()) {
        if (popover)
            [popover release];
        UIViewController *fakeController = [[UIViewController alloc] init];
        if (picker.tag == TAG_PICKER_DATE) {
            fakeController.contentSizeForViewInPopover = CGSizeMake(320, 256);

            UISegmentedControl *publishNowButton = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObject:@"Publish inmediately"]];
            publishNowButton.momentary = YES; 
            publishNowButton.frame = CGRectMake(0, 0, 320, 40);
            publishNowButton.segmentedControlStyle = UISegmentedControlStyleBar;
            publishNowButton.tintColor = postDetailViewController.toolbar.tintColor;
            [publishNowButton addTarget:self action:@selector(removeDate) forControlEvents:UIControlEventValueChanged];
            [fakeController.view addSubview:publishNowButton];
            [publishNowButton release];
            CGRect frame = picker.frame;
            frame.origin.y = 40;
            picker.frame = frame;
        } else {
            fakeController.contentSizeForViewInPopover = CGSizeMake(320, 216);
        }

        
        [fakeController.view addSubview:picker];
        popover = [[UIPopoverController alloc] initWithContentViewController:fakeController];
        [fakeController release];
        
        CGRect popoverRect;
        if (picker.tag == TAG_PICKER_STATUS)
            popoverRect = [self.view convertRect:statusLabel.frame fromView:[statusLabel superview]];
        else if (picker.tag == TAG_PICKER_VISIBILITY)
            popoverRect = [self.view convertRect:visibilityLabel.frame fromView:[visibilityLabel superview]];
        else 
            popoverRect = [self.view convertRect:publishOnDateLabel.frame fromView:[publishOnDateLabel superview]];

        popoverRect.size.width = 100;
        [popover presentPopoverFromRect:popoverRect inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    } else {        
        actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:nil cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
        [actionSheet setActionSheetStyle:UIActionSheetStyleAutomatic];
        [actionSheet addSubview:picker];
		UISegmentedControl *closeButton = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObject:@"Done"]];
		closeButton.momentary = YES; 
		closeButton.frame = CGRectMake(260, 7, 50, 30);
		closeButton.segmentedControlStyle = UISegmentedControlStyleBar;
		closeButton.tintColor = [UIColor blackColor];
		[closeButton addTarget:self action:@selector(hidePicker) forControlEvents:UIControlEventValueChanged];
		[actionSheet addSubview:closeButton];
		[closeButton release];

        if (picker.tag == TAG_PICKER_DATE) {
            UISegmentedControl *publishNowButton = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObject:@"Publish inmediately"]];
            publishNowButton.momentary = YES; 
            publishNowButton.frame = CGRectMake(10, 7, 129, 30);
            publishNowButton.segmentedControlStyle = UISegmentedControlStyleBar;
            publishNowButton.tintColor = [UIColor blackColor];
            [publishNowButton addTarget:self action:@selector(removeDate) forControlEvents:UIControlEventValueChanged];
            [actionSheet addSubview:publishNowButton];
            [publishNowButton release];            
        }
		[actionSheet showInView:[[UIApplication sharedApplication] keyWindow]];
		[actionSheet setBounds:CGRectMake(0, 0, 320, 485)];
    }
}

- (void)hidePicker {
    [actionSheet dismissWithClickedButtonIndex:0 animated:YES];
    [actionSheet release]; actionSheet = nil;
}

- (void)removeDate {
    datePickerView.date = [NSDate date];
    postDetailViewController.apost.dateCreated = nil;
    [tableView reloadData];
    if (DeviceIsPad())
        [popover dismissPopoverAnimated:YES];
    else
        [self hidePicker];

}

- (void)keyboardWillShow:(NSNotification *)keyboardInfo {
    isShowingKeyboard = YES;
}

- (void)keyboardWillHide:(NSNotification *)keyboardInfo {
    isShowingKeyboard = NO;
}

@end
