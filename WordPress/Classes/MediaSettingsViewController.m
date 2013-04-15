//
//  MediaSettingsViewController.m
//  WordPress
//
//  Created by Jeffrey Vanneste on 2013-01-05.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "MediaSettingsViewController.h"


#define TAG_PICKER_LINK_TO      0
#define TAG_PICKER_ALIGNMENT    1
#define TAG_PICKER_POSITIONING  2

@implementation MediaSettingsViewController

@synthesize media;
@synthesize mediaSettings;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
	
    // fill the lists with the available options
    linkToOptionsList = [NSArray arrayWithObjects:
                         NSLocalizedString(@"No Linking", @"Media Settings option to have media have no link"),
                         NSLocalizedString(@"Media File", @"Media Settings option to have media link to the file"),
                         NSLocalizedString(@"Current", @"Media Settings option to leave the media alone"), nil];
    positioningOptionsList = [NSArray arrayWithObjects:
                              NSLocalizedString(@"Current", @"Media Settings option to leave the media alone"),
                              NSLocalizedString(@"Above Content", @"Media Settings option to move media above the content"),
                              NSLocalizedString(@"Below Content", @"Media Settings option to move media below the content"), nil];
    alignmentOptionsList = [NSArray arrayWithObjects:
                            NSLocalizedString(@"None", @"Media Settings option to have no alignment"),
                            NSLocalizedString(@"Left", @"Media Settings option to align the media to left"),
                            NSLocalizedString(@"Center", @"Media Settings option to align the media to center"),
                            NSLocalizedString(@"Right", @"Media Settings option to align the media to right"), nil];
        
    if (mediaSettings.captionText != nil) {
        captionTextField.text = mediaSettings.captionText;
    } else {
        captionTextField.text = @"";
    }
    if (mediaSettings.linkHref!= nil) {
        if ([mediaSettings.linkHref caseInsensitiveCompare:media.remoteURL] == NSOrderedSame) {
            linkToLabel.text = [linkToOptionsList objectAtIndex:1];
        } else if ([mediaSettings.linkHref length] > 0) {
            linkToLabel.text = [linkToOptionsList objectAtIndex:2];
        } else {
            linkToLabel.text = [linkToOptionsList objectAtIndex:0];
        }
    } else {
        linkToLabel.text = [linkToOptionsList objectAtIndex:0];
    }
    if (mediaSettings.alignment != nil) {
        if ([mediaSettings.alignment isEqualToString:@"alignleft"]) {
            alignmentLabel.text = [alignmentOptionsList objectAtIndex:1];
        } else if ([mediaSettings.alignment isEqualToString:@"aligncenter"]) {
            alignmentLabel.text = [alignmentOptionsList objectAtIndex:2];
        } else if ([mediaSettings.alignment isEqualToString:@"alignright"]) {
            alignmentLabel.text = [alignmentOptionsList objectAtIndex:3];
        } else {
            alignmentLabel.text = [alignmentOptionsList objectAtIndex:0];
        }
    } else {
        alignmentLabel.text = [alignmentOptionsList objectAtIndex:0];
    }
    positioningLabel.text = [positioningOptionsList objectAtIndex:0];
    
    widthSlider.minimumValue = 0;
    widthSlider.maximumValue = [media.width intValue];
    if (mediaSettings.customWidth != nil) {
        int customWidth = [mediaSettings.customWidth intValue];
        if (customWidth > widthSlider.maximumValue) {
            widthSlider.maximumValue = customWidth;
        }
        int customHeight = customWidth * [media.height intValue]/[media.width intValue];
        imageSizeLabel.text = [NSString stringWithFormat:@"%d x %d", customWidth, customHeight];
        widthSlider.value = customWidth;
    } else {
        imageSizeLabel.text = [NSString stringWithFormat:@"%d x %d", [media.width intValue], [media.height intValue]];
        widthSlider.value = [media.width intValue];
    }    
    
    [tableView setBackgroundView:nil];
    [tableView setBackgroundColor:[UIColor clearColor]]; //Fix for black corners on iOS4. http://stackoverflow.com/questions/1557856/black-corners-on-uitableview-group-style
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"settings_bg"]];
    
    linkToTitleLabel.text = NSLocalizedString(@"Link to", @"Media Settings for what an image/view should link to");
    positioningTitleLabel.text = NSLocalizedString(@"Position", @"Media Settings for where an image/view should be positioned");
    alignmentTitleLabel.text = NSLocalizedString(@"Alignment", @"Media Settings for where an image/view should be aligned");
    captionTitleLabel.text = NSLocalizedString(@"Caption", @"Media Settings for the caption of an image/view");
    widthTitleLabel.text = NSLocalizedString(@"Width", @"Media Settings for the width of image/video");
    captionTextField.placeholder = NSLocalizedString(@"Optional", @"Media Settings for the optional caption");

    // only supporting images right now
    if ([media.mediaType isEqualToString:@"image"]) {
        thumbnail.image = [UIImage imageWithContentsOfFile:media.localURL];
        if((thumbnail.image == nil) && (media.remoteURL != nil)) {
            [thumbnail setImageWithURL:[NSURL URLWithString:media.remoteURL]];
        }
        self.navigationItem.title = NSLocalizedString(@"Image", @"");
    }
    
    isShowingKeyboard = NO;
    
    CGRect pickerFrame;
	if (IS_IPAD)
		pickerFrame = CGRectMake(0.0f, 0.0f, 320.0f, 216.0f);
	else
		pickerFrame = CGRectMake(0.0f, 44.0f, 320.0f, 216.0f);
    pickerView = [[UIPickerView alloc] initWithFrame:pickerFrame];
    pickerView.delegate = self;
    pickerView.dataSource = self;
    pickerView.showsSelectionIndicator = YES;
    
    // on the ipad we want to show a Close button in the toolbar since the back button will not be there
    if (IS_IPAD) {
        cancelButton.title = NSLocalizedString(@"Close", @"Close an action sheet");;
        CGRect rect = tableView.frame;
        rect.origin.y = 44.0f;
        rect.size.height = rect.size.height - 44.0f;
        tableView.frame = rect;
        
        UIToolbar *topToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, 44.0f)];
        topToolbar.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
        UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        topToolbar.items = [NSArray arrayWithObjects:flex, cancelButton, nil];
        [self.view addSubview:topToolbar];
    }
}

- (void)viewDidUnload {
    [super viewDidUnload];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

	[linkToTableViewCell becomeFirstResponder];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark Misc Methods
- (void)deleteObject:(id)sender {
    // On ipad show an alert view like how Apple does in the contacts app. On the iPhone show an action sheet.
    if (IS_IPAD) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Remove %@?", @""), media.mediaTypeName] message:@"" delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"") otherButtonTitles:nil];
        [alert addButtonWithTitle:NSLocalizedString(@"Remove", @"")];
        [alert show];
    } else {
        NSString *titleString = [NSString stringWithFormat:NSLocalizedString(@"Remove %@?", @""), media.mediaTypeName];
        UIActionSheet *deleteActionSheet = [[UIActionSheet alloc] initWithTitle:titleString
                                                                       delegate:self
                                                              cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
                                                         destructiveButtonTitle:NSLocalizedString(@"Remove", @"")
                                                              otherButtonTitles:nil];
        
        [deleteActionSheet showInView:self.view];
    }
}

- (void)reloadData {
    [tableView reloadData];
}


#pragma mark -
#pragma mark TableView Methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSInteger sections = 1;
    return sections;
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	switch (indexPath.section) {
        case 0:
            switch (indexPath.row) {
                case 0: // media
                    mediaTableViewCell.selectionStyle = UITableViewCellSelectionStyleNone;
                    return mediaTableViewCell;
                    break;
                case 1: // caption
                    captionTableViewCell.selectionStyle = UITableViewCellSelectionStyleNone;
                    return captionTableViewCell;
                    break;
                case 2: // link to
                    linkToTableViewCell.selectionStyle = UITableViewCellSelectionStyleNone;
                    return linkToTableViewCell;
                    break;
                case 3: // alignment
                    alignmentTableViewCell.selectionStyle = UITableViewCellSelectionStyleNone;
                    return alignmentTableViewCell;
                    break;
                case 4: // positioning
                    positioningTableViewCell.selectionStyle = UITableViewCellSelectionStyleNone;
                    return positioningTableViewCell;
                    break;
                case 5: // width
                    widthTableViewCell.selectionStyle = UITableViewCellSelectionStyleNone;
                    return widthTableViewCell;
                    break;
                default:
                    break;
            }
            break;
    }

    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ((indexPath.section == 0) && (indexPath.row == 5)) {
        // width row 
        return 70.0f;
    } else if ((indexPath.section == 0) && (indexPath.row == 0)) {
        // thumbnail row
        return 188.0f;
    }
	else {
        return 44.0f;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 70;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    
    if(footerView == nil) {
        footerView  = [[UIView alloc] init];
        
        // create a glossy red button
        UIImage *image = [[UIImage imageNamed:@"button_red.png"]
                          stretchableImageWithLeftCapWidth:8 topCapHeight:8];
        deleteButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [deleteButton setBackgroundImage:image forState:UIControlStateNormal];
        
        if (IS_IPAD) {
            [deleteButton setFrame:CGRectMake(30, 20, 480, 44)];
        }
        else {
            [deleteButton setFrame:CGRectMake(10, 20, 300, 44)];
        }
        
        [deleteButton setTitle:[NSString stringWithFormat:NSLocalizedString(@"Remove %@", @""), media.mediaTypeName] forState:UIControlStateNormal];
        [deleteButton.titleLabel setFont:[UIFont boldSystemFontOfSize:20]];
        [deleteButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [deleteButton addTarget:self action:@selector(deleteObject:)
         forControlEvents:UIControlEventTouchUpInside];
        [footerView addSubview:deleteButton];
    }

    return footerView;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (section == 0) {
		return 6;
    }    
    return 0;
}

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (isShowingKeyboard) {
        [captionTextField resignFirstResponder];
    }
    
	switch (indexPath.section) {
		case 0:
			switch (indexPath.row) {
				case 2:
				{
					pickerView.tag = TAG_PICKER_LINK_TO;
					[pickerView reloadAllComponents];
					[pickerView selectRow:[linkToOptionsList indexOfObject:linkToLabel.text] inComponent:0 animated:NO];
					[self showPicker:pickerView];
					break;
				}
                case 3:
				{
					pickerView.tag = TAG_PICKER_ALIGNMENT;
					[pickerView reloadAllComponents];
					[pickerView selectRow:[alignmentOptionsList indexOfObject:alignmentLabel.text] inComponent:0 animated:NO];
					[self showPicker:pickerView];
					break;
				}
                case 4:
				{
					pickerView.tag = TAG_PICKER_POSITIONING;
					[pickerView reloadAllComponents];
					[pickerView selectRow:[positioningOptionsList indexOfObject:positioningLabel.text] inComponent:0 animated:NO];
					[self showPicker:pickerView];
					break;
				}
                    
				default:
					break;
			}
			break;
	}
    [aTableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:YES];
}

#pragma mark -
#pragma mark UIPickerViewDataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)aPickerView numberOfRowsInComponent:(NSInteger)component {
    if (aPickerView.tag == TAG_PICKER_LINK_TO) {
        return [linkToOptionsList count];
    } else if (aPickerView.tag == TAG_PICKER_ALIGNMENT) {
        return [alignmentOptionsList count];
    } else if (aPickerView.tag == TAG_PICKER_POSITIONING) {
        return [positioningOptionsList count];
    }
    return 0;
}

#pragma mark -
#pragma mark UIPickerViewDelegate

- (NSString *)pickerView:(UIPickerView *)aPickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    if (aPickerView.tag == TAG_PICKER_LINK_TO) {
        return [linkToOptionsList objectAtIndex:row];
    } else if (aPickerView.tag == TAG_PICKER_ALIGNMENT) {
        return [alignmentOptionsList objectAtIndex:row];
    } else if (aPickerView.tag == TAG_PICKER_POSITIONING) {
        return [positioningOptionsList objectAtIndex:row];
    }
    
    return @"";
}

- (void)pickerView:(UIPickerView *)aPickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:media, @"media", mediaSettings, @"mediaSettings", nil];
    if (aPickerView.tag == TAG_PICKER_POSITIONING) {
        positioningLabel.text = [positioningOptionsList objectAtIndex:row];
        if (row == 1) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ShouldInsertMediaAbove" object:self userInfo:userInfo];
        } else if (row == 2) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ShouldInsertMediaBelow" object:self userInfo:userInfo];
        }
    } else {
        if (aPickerView.tag == TAG_PICKER_LINK_TO) {
            linkToLabel.text = [linkToOptionsList objectAtIndex:row];
            if (row == 0) {
                mediaSettings.linkHref = @"";
            } else if (row == 1){
                mediaSettings.linkHref = media.remoteURL;
            } // else leave the linkHref alone
        } else if (aPickerView.tag == TAG_PICKER_ALIGNMENT) {
            alignmentLabel.text = [alignmentOptionsList objectAtIndex:row];
            if (row == 0) {
                mediaSettings.alignment = @"alignnone";
            } else if (row == 1) {
                mediaSettings.alignment = @"alignleft";
            } else if (row == 2) {
                mediaSettings.alignment = @"aligncenter";
            } else if (row == 3) {
                mediaSettings.alignment = @"alignright";
            }
        }
        [[NSNotificationCenter defaultCenter]
         postNotificationName:@"UpdateMedia"
         object:self
         userInfo:userInfo];
    }
    
    [tableView reloadData];
}

#pragma mark -
#pragma mark Pickers and keyboard animations

- (void)showPicker:(UIView *)picker {
    if (isShowingKeyboard) {
        [captionTextField resignFirstResponder];
    }
    
    if (IS_IPAD) {
        UIViewController *fakeController = [[UIViewController alloc] init];
        fakeController.contentSizeForViewInPopover = CGSizeMake(320.0f, 216.0f);
        
        [fakeController.view addSubview:picker];
        popover = [[UIPopoverController alloc] initWithContentViewController:fakeController];
        if ([popover respondsToSelector:@selector(popoverBackgroundViewClass)]) {
            popover.popoverBackgroundViewClass = [WPPopoverBackgroundView class];
        }
        
        CGRect popoverRect;
        if (picker.tag == TAG_PICKER_LINK_TO)
            popoverRect = [self.view convertRect:linkToLabel.frame fromView:[linkToLabel superview]];
        else if (picker.tag == TAG_PICKER_ALIGNMENT)
            popoverRect = [self.view convertRect:alignmentLabel.frame fromView:[alignmentLabel superview]];
        else if (picker.tag == TAG_PICKER_POSITIONING)
            popoverRect = [self.view convertRect:positioningLabel.frame fromView:[positioningLabel superview]];
        
        popoverRect.size.width = 100.0f;
        [popover presentPopoverFromRect:popoverRect inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        
    } else {
    
        CGFloat width = self.view.frame.size.width;
        CGFloat height = 0.0;
        
        // Refactor this class to not use UIActionSheets for display. See trac #1509.
        // <rant>Shoehorning a UIPicker inside a UIActionSheet is just madness.</rant>
        // For now, hardcoding height values for the iPhone so we don't get
        // a funky gap at the bottom of the screen on the iPhone 5.
        if(self.view.frame.size.height <= 416.0f) {
            height = 490.0f;
        } else {
            height = 500.0f;
        }
        if(UIInterfaceOrientationIsLandscape(self.interfaceOrientation)){
            height = 460.0f; // Show most of the actionsheet but keep the top of the view visible.
        }
        
        UIView *pickerWrapperView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, width, 260.0f)]; // 216 + 44 (height of the picker and the "tooblar")
        pickerWrapperView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        [pickerWrapperView addSubview:picker];
        
        CGRect pickerFrame = picker.frame;
        pickerFrame.size.width = width;
        picker.frame = pickerFrame;
        
        actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:nil cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
        [actionSheet setActionSheetStyle:UIActionSheetStyleAutomatic];
        [actionSheet setBounds:CGRectMake(0.0f, 0.0f, width, height)];
        
        [actionSheet addSubview:pickerWrapperView];
        
        UISegmentedControl *closeButton = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObject:NSLocalizedString(@"Done", @"Default main action button for closing/finishing a work flow in the app (used in Comments>Edit, Comment edits and replies, post editor body text, etc, to dismiss keyboard).")]];
        closeButton.momentary = YES;
        CGFloat x = self.view.frame.size.width - 60.0f;
        closeButton.frame = CGRectMake(x, 7.0f, 50.0f, 30.0f);
        closeButton.segmentedControlStyle = UISegmentedControlStyleBar;
        if ([closeButton respondsToSelector:@selector(setTintColor:)]) {
            closeButton.tintColor = [UIColor blackColor];
        }
        [closeButton addTarget:self action:@selector(hidePicker) forControlEvents:UIControlEventValueChanged];
        closeButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        [pickerWrapperView addSubview:closeButton];
        
        UISegmentedControl *publishNowButton = nil;
        
        if ([[UISegmentedControl class] respondsToSelector:@selector(appearance)]) {
            // Since we're requiring a black tint we do not want to use the custom text colors.
            NSDictionary *titleTextAttributesForStateNormal = [NSDictionary dictionaryWithObjectsAndKeys:
                                                               [UIColor whiteColor],
                                                               UITextAttributeTextColor,
                                                               [UIColor darkGrayColor],
                                                               UITextAttributeTextShadowColor,
                                                               [NSValue valueWithUIOffset:UIOffsetMake(0, 1)],
                                                               UITextAttributeTextShadowOffset,
                                                               nil];
            
            // The UISegmentControl does not show a pressed state for its button so (for now) use the same
            // state for normal and highlighted.
            // It would be nice to refactor this to use a toolbar and buttons instead of a segmented control to get the
            // correct look and feel.
            [closeButton setTitleTextAttributes:titleTextAttributesForStateNormal forState:UIControlStateNormal];
            [closeButton setTitleTextAttributes:titleTextAttributesForStateNormal forState:UIControlStateHighlighted];
            
            if (publishNowButton) {
                [publishNowButton setTitleTextAttributes:titleTextAttributesForStateNormal forState:UIControlStateNormal];
                [publishNowButton setTitleTextAttributes:titleTextAttributesForStateNormal forState:UIControlStateHighlighted];
            }
        }
        
        [actionSheet showInView:self.view];
        [actionSheet setBounds:CGRectMake(0.0f, 0.0f, width, height)]; // Update the bounds again now that its in the view else it won't draw correctly.
    }
}

- (void)hidePicker {
    [actionSheet dismissWithClickedButtonIndex:0 animated:YES];
    actionSheet = nil;
}

- (void)keyboardWillShow:(NSNotification *)keyboardInfo {
    if(IS_IPAD == NO) {
        // on iphone it's possible we need to scroll the tableview when the keyboard is shown
        if (isShowingKeyboard) {
            return;
        }
        
        NSDictionary* userInfo = [keyboardInfo userInfo];
        
        // get the size of the keyboard
        CGSize keyboardSize = [[userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
        
        // resize the tableview
        CGRect viewFrame = tableView.frame;
        viewFrame.size.height -= keyboardSize.height;
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationBeginsFromCurrentState:YES];
        [UIView setAnimationDuration:0.3f];
        [tableView setFrame:viewFrame];

        // scroll the view if the caption textfield is not visible
        if (tableView.contentOffset.y <= 100) {
            tableView.contentOffset = CGPointMake(0, 100);
        }
        [UIView commitAnimations];
    }
    isShowingKeyboard = YES;
}

- (void)keyboardWillHide:(NSNotification *)keyboardInfo {
    if(IS_IPAD == NO) {
        NSDictionary* userInfo = [keyboardInfo userInfo];
        
        // get the size of the keyboard
        CGSize keyboardSize = [[userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
        
        // resize the tableview
        CGRect viewFrame = tableView.frame;
        viewFrame.size.height += keyboardSize.height;
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationBeginsFromCurrentState:YES];
        [UIView setAnimationDuration:0.3f];
        [tableView setFrame:viewFrame];
        [UIView commitAnimations];
    }
    
    isShowingKeyboard = NO;
}

#pragma mark -
#pragma mark Rotation Methods

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return [super shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self reloadData];
}

#pragma mark -
#pragma mark Slider Methods
-(IBAction) sliderChanged:(id) sender{
    UISlider *slider = (UISlider *) sender;
    // step by 10s
    float newStep = roundf((slider.value) / 10.0f);
    slider.value = newStep * 10.0f;
    if (slider.value + 10 > slider.maximumValue) {
        slider.value = slider.maximumValue;
    }
    int width = (int)slider.value;
    int height = width * [media.height intValue]/[media.width intValue];
    imageSizeLabel.text = [NSString stringWithFormat:@"%d x %d", width, height];
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:media, @"media", mediaSettings, @"mediaSettings", nil];
    mediaSettings.customWidth = [NSNumber numberWithInt:width];
    mediaSettings.customHeight = [NSNumber numberWithInt:height];
    [[NSNotificationCenter defaultCenter]
        postNotificationName:@"UpdateMedia"
        object:self
        userInfo:userInfo];
}

#pragma mark -
#pragma mark TextField Methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [captionTextField resignFirstResponder];
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    captionTextField.placeholder = nil;
}

- (IBAction)textFieldReturn:(id)sender {
    [sender resignFirstResponder];
}

- (IBAction)textFieldFinishedEditing:(id)sender {
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:media, @"media", mediaSettings, @"mediaSettings", nil];
    mediaSettings.captionText = captionTextField.text;
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"UpdateMedia"
     object:self
     userInfo:userInfo];
}

- (IBAction)backgroundTouched:(id)sender {
    [captionTextField resignFirstResponder];
}

#pragma mark -
#pragma mark UIActionSheet delegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 0:
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ShouldRemoveMedia" object:media];
            [media remove];
            if(IS_IPAD == YES)
                [self dismissModalViewControllerAnimated:YES];
            else
                [self.navigationController popViewControllerAnimated:YES];
            break;
        default:
            break;
    }
}

#pragma mark -
#pragma mark Cancel button actions

- (IBAction)cancelSelection:(id)sender {
 	if (IS_IPAD)
		[self dismissModalViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark UIAlertViewDelegate delegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ShouldRemoveMedia" object:media];
        [media remove];
        [self dismissModalViewControllerAnimated:YES];
    }
}

@end
