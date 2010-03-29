//
//  EditPageViewController.m
//  WordPress
//
//  Created by Janakiram on 01/11/08.
//

#import "EditPageViewController.h"
#import "WPSelectionTableViewController.h"
#import "BlogDataManager.h"
#import "WPNavigationLeftButtonView.h"
#import "PageViewController.h"
#import "WPPhotosListViewController.h"
#import "WordPressAppDelegate.h"



@interface EditPageViewController (private)
- (void)_savePageWithBlog:(NSMutableArray *)arrayPage;
- (void)updateTextViewPlacehoderFieldStatus;
- (void)populateSelectionsControllerWithStatuses;
- (void)bringTextViewUp;
- (void)bringTextViewDown;
-(void) correctlySetStatusTextFieldText;
@end

#define kSelectionsStatusContext1 ((void *)1000)
NSTimeInterval kAnimationDuration1 = 0.3f;

@implementation EditPageViewController
@synthesize mode, selectionTableViewController, pageDetailsController, photosListController, customFieldsTableView;
@synthesize infoText, urlField, selectedLinkRange, currentEditingTextField, isEditing, isCustomFieldsEnabledForThisPage;
@synthesize customFieldsEditCell;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Initialization code
    }

    return self;
}

- (void)refreshUIForCurrentPage {
    self.navigationItem.rightBarButtonItem = nil;
    BlogDataManager *dm = [BlogDataManager sharedDataManager];

    NSString *description = [dm.currentPage valueForKey:@"description"];
    NSString *moreText = [dm.currentPage valueForKey:@"text_more"];

    if (!description ||[description length] == 0) {
        textViewPlaceHolderField.hidden = NO;
        pageContentTextView.text = @"";
    } else {
        textViewPlaceHolderField.hidden = YES;

        if ((moreText != NULL) && ([moreText length] > 0))
            pageContentTextView.text = [NSString stringWithFormat:@"%@\n<!--more-->%@", description, moreText];else
            pageContentTextView.text = description;
    }

    titleTextField.text = [dm.currentPage valueForKey:@"title"];


	[self correctlySetStatusTextFieldText];
	
	[pageDetailsController updatePhotosBadge];
    [photosListController refreshData];
}

- (void)refreshUIForNewPage {
    BlogDataManager *dm = [BlogDataManager sharedDataManager];
    NSString *description = [dm.currentPage valueForKey:@"description"];

    if (!description ||[description length] == 0) {
        textViewPlaceHolderField.hidden = NO;
        pageContentTextView.text = @"";
    } else {
        textViewPlaceHolderField.hidden = YES;
        pageContentTextView.text = description;
    }

    titleTextField.text = [dm.currentPage valueForKey:@"title"];

	

	
	[self correctlySetStatusTextFieldText];

    [photosListController refreshData];
    [pageDetailsController updatePhotosBadge];
}

- (void)viewWillAppear:(BOOL)animated {
   // pageDetailsController.hasChanges = NO;
 

    if (mode == editPage)
        [self refreshUIForCurrentPage];else if (mode == newPage)
        [self refreshUIForNewPage];

//	CGRect frame = subView.frame;
//	frame.origin.y = 0.0f;
//	subView.frame = frame;
//
//	frame=textViewContentView.frame;
//	frame.origin.y = 81.0f;
//	textViewContentView.frame = frame;

	
	//temporarily disable custom fields per ticket # 266
//    isCustomFieldsEnabledForThisPage = [self checkCustomFieldsMinusMetadata];
//
//    if (isCustomFieldsEnabledForThisPage) {
//        customFieldsEditCell.hidden = NO;
//        customFieldsEditCell.userInteractionEnabled = YES;
//    } else {
//        customFieldsEditCell.hidden = YES;
//        customFieldsEditCell.userInteractionEnabled = NO;
//    }
	
	isCustomFieldsEnabledForThisPage = NO;  //temporarily disable custom fields per ticket # 266

    [self postionTextViewContentView];

	[self correctlySetStatusTextFieldText];
    [super viewWillAppear:animated];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    //photosListController.pageDetailViewController = self;

    titleTextField.font = [UIFont fontWithName:@"Helvetica" size:15.0f];
    statusTextField.font = [UIFont fontWithName:@"Helvetica" size:15.0f];
    statusLabel.font = [UIFont fontWithName:@"Helvetica" size:17.0f];
    titleLabel.font = [UIFont fontWithName:@"Helvetica" size:17.0f];

    titleTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    [contentView bringSubviewToFront:pageContentTextView];
    self.title = @"Write";

    //JOHNB TODO: Add a check here for the presence of custom fields in the data model
    // if there are, set CustomFields BOOL to true
   // isCustomFieldsEnabledForThisPage = [self checkCustomFieldsMinusMetadata];
	isCustomFieldsEnabledForThisPage = NO; //temporarily disable custom fields per ticket # 266
    //call a helper to set the originY for textViewContentView
    [self postionTextViewContentView];
    customFieldsEditCell.hidden = YES;
}

-(void) correctlySetStatusTextFieldText {
	BlogDataManager *dm = [BlogDataManager sharedDataManager];
	NSString *status = [[dm currentPage] valueForKey:@"page_status"];
	NSString *statusValue = [dm pageStatusDescriptionForStatus:status fromBlog:dm.currentBlog];
	statusValue = (statusValue == nil ? @"" : statusValue);
	statusTextField.text = statusValue;
}

- (IBAction)endTextEnteringButtonAction:(id)sender {
    isTextViewEditing = NO;
    [pageContentTextView resignFirstResponder];
    UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithCustomView:pageDetailsController.leftView];
    pageDetailsController.navigationItem.leftBarButtonItem = barButton;
    [barButton release];
	if((pageDetailsController.interfaceOrientation == UIInterfaceOrientationLandscapeLeft) || 
	   (pageDetailsController.interfaceOrientation == UIInterfaceOrientationLandscapeRight)){
		//[[UIDevice currentDevice] setOrientation:UIInterfaceOrientationPortrait];
	}
	
}

- (IBAction)cancelView:(id)sender {
    if (!pageDetailsController.hasChanges) {
        [pageDetailsController.navigationController popViewControllerAnimated:YES];
        return;
    }

    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"You have unsaved changes."
                                  delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Discard"
                                  otherButtonTitles:nil];
    actionSheet.tag = 202;
    actionSheet.actionSheetStyle = UIActionSheetStyleAutomatic;
    [actionSheet showInView:self.view];
    WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    [delegate setAlertRunning:YES];
    [actionSheet release];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch ([actionSheet tag]) {
        case 202:
        {
            if (buttonIndex == 0) {
                pageDetailsController.hasChanges = NO;
                pageDetailsController.navigationItem.rightBarButtonItem = nil;
                [pageDetailsController.navigationController popViewControllerAnimated:YES];
            }

            if (buttonIndex == 1) {
                pageDetailsController.hasChanges = YES;
            }

            WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
            [delegate setAlertRunning:NO];
            break;
        }
        default:
            break;
    }
}

- (void)endEditingAction:(id)sender {
    [titleTextField resignFirstResponder];
    [pageContentTextView resignFirstResponder];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];

    if ([delegate isAlertRunning] == YES)
        return NO;

    return YES;
}

- (void)setTextViewHeight:(float)height {
    CGRect frame = pageContentTextView.frame;
    frame.size.height = height;
    pageContentTextView.frame = frame;
}

#pragma mark TextView & TextField Delegates
- (void)textViewDidChangeSelection:(UITextView *)aTextView {
    if (!isTextViewEditing) {
        pageDetailsController.hasChanges = YES;
        hasChanges = YES;

        isTextViewEditing = YES;

        if ((self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft) || (self.interfaceOrientation == UIInterfaceOrientationLandscapeRight)) {
            [self setTextViewHeight:105];
        } else if ((self.interfaceOrientation == UIInterfaceOrientationPortrait) || (self.interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown)) {
            [self setTextViewHeight:200];
        }

        [self updateTextViewPlacehoderFieldStatus];
        [self bringTextViewUp];

        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone
                                       target:self action:@selector(endTextEnteringButtonAction:)];

        pageDetailsController.navigationItem.leftBarButtonItem = doneButton;
        [doneButton release];
    }
}

- (void)textViewDidBeginEditing:(UITextView *)aTextView {
    isEditing = YES;

    if ((self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft) || (self.interfaceOrientation == UIInterfaceOrientationLandscapeRight)) {
        [self setTextViewHeight:105];
    } else if ((self.interfaceOrientation == UIInterfaceOrientationPortrait) || (self.interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown)) {
        [self setTextViewHeight:200];
    }

    dismiss = NO;

    if (!isTextViewEditing)
        isTextViewEditing = YES;

    [self updateTextViewPlacehoderFieldStatus];

    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone
                                   target:self action:@selector(endTextEnteringButtonAction:)];

    pageDetailsController.navigationItem.leftBarButtonItem = doneButton;
    [doneButton release];

    [self bringTextViewUp];
}

- (void)bringTextViewUp {
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:kAnimationDuration1];

    if (isCustomFieldsEnabledForThisPage) {
        CGRect frame = textViewContentView.frame;
        frame.origin.y -= 120.0f;
        textViewContentView.frame = frame;

        frame = subView.frame;
        frame.origin.y -= 120.0f;
        subView.frame = frame;
    } else {
        CGRect frame = textViewContentView.frame;
        frame.origin.y -= 80.0f;
        textViewContentView.frame = frame;

        frame = subView.frame;
        frame.origin.y -= 80.0f;
        subView.frame = frame;
    }

    [UIView commitAnimations];
}

- (void)bringTextViewDown {
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.2];
    subView.hidden = NO;

    if (isCustomFieldsEnabledForThisPage) {
        CGRect frame = textViewContentView.frame;
        frame.origin.y += 60.0f;
        textViewContentView.frame = frame;

        frame = subView.frame;
        frame.origin.y = 0.0f;
        subView.frame = frame;
    } else {
        CGRect frame = textViewContentView.frame;
        frame.origin.y = 81.0f;
        textViewContentView.frame = frame;

        frame = subView.frame;
        frame.origin.y = 0.0f;
        subView.frame = frame;
    }

    [UIView commitAnimations];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    self.currentEditingTextField = textField;
    [self textViewDidEndEditing:pageContentTextView];
    //pageDetailsController.hasChanges = YES;
}

//replace "&nbsp" with a space @"&#160;" before Apple's broken TextView handling can do so and break things
//this enables the "http helper" to work as expected
//important is capturing &nbsp BEFORE the semicolon is added.  Not doing so causes a crash in the textViewDidChange method due to array overrun
- (BOOL)textView:(UITextView *)aTextView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
	
	//if nothing has been entered yet, return YES to prevent crash when hitting delete
    if (text.length == 0) {
		return YES;
    }
	
    // create final version of textView after the current text has been inserted
    NSMutableString *updatedText = [[NSMutableString alloc] initWithString:aTextView.text];
    [updatedText insertString:text atIndex:range.location];
	
    NSRange replaceRange = range, endRange = range;
	
    if (text.length > 1) {
        // handle paste
        replaceRange.length = text.length;
    } else {
        // handle normal typing
        replaceRange.length = 6;  // length of "&#160;" is 6 characters
        replaceRange.location -= 5; // look back one characters (length of "&#160;" minus one)
    }
	
    // replace "&nbsp" with "&#160;" for the inserted range
    int replaceCount = [updatedText replaceOccurrencesOfString:@"&nbsp" withString:@"&#160;" options:NSCaseInsensitiveSearch range:replaceRange];
	
    if (replaceCount > 0) {
        // update the textView's text
        aTextView.text = updatedText;
		
        // leave cursor at end of inserted text
        endRange.location += text.length + replaceCount * 1; // length diff of "&nbsp" and "&#160;" is 1 character
        aTextView.selectedRange = endRange; 
		
        [updatedText release];
		
        // let the textView know that it should ingore the inserted text
        return NO;
    }
	
    [updatedText release];
	
    // let the textView know that it should handle the inserted text
    return YES;
}

- (void)textViewDidChange:(UITextView *)aTextView {
    pageDetailsController.hasChanges = YES;

    [self updateTextViewPlacehoderFieldStatus];

    if (![aTextView hasText])
        return;

    if (dismiss == YES) {
        dismiss = NO;
        return;
    }

    NSRange range = [aTextView selectedRange];
    NSArray *stringArray = [NSArray arrayWithObjects:@"http:", @"ftp:", @"https:", @"www.", nil];
    NSString *str = [aTextView text];
    int i, j, count = [stringArray count];
    BOOL searchRes = NO;

    for (j = 4; j <= 6; j++) {
        if (range.location < j)
            return;

        NSRange subStrRange;
        subStrRange.location = range.location - j;
		//see same place in EditPostViewController for more on this change
		//subStrRange.location = str.length -j;
        subStrRange.length = j;
        [self setSelectedLinkRange:subStrRange];
        NSString *subStr = [str substringWithRange:subStrRange];

        for (i = 0; i < count; i++) {
            NSString *searchString = [stringArray objectAtIndex:i];

            if (searchRes = [subStr isEqualToString:[searchString capitalizedString]])
                break;else if (searchRes = [subStr isEqualToString:[searchString lowercaseString]])
                break;else if (searchRes = [subStr isEqualToString:[searchString uppercaseString]])
                break;
        }

        if (searchRes)
            break;
    }

    if (searchRes && dismiss != YES) {
        WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
        [delegate setAlertRunning:YES];
        [pageContentTextView resignFirstResponder];
        UIAlertView *linkAlert = [[UIAlertView alloc] initWithTitle:@"Make a Link" message:@"Would you like help making a link?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Make a Link", nil];
        [linkAlert setTag:1];  // for UIAlertView Delegate to handle which view is popped.
        [linkAlert show];
        [linkAlert release];
    }
}

- (void)updateTextViewPlacehoderFieldStatus {
    if ([pageContentTextView.text length] == 0) {
        textViewPlaceHolderField.hidden = NO;
    } else {
        textViewPlaceHolderField.hidden = YES;
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView {
   if ((self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft) || (self.interfaceOrientation == UIInterfaceOrientationLandscapeRight)) {
	
        [self setTextViewHeight:137];
		
    } else if ((self.interfaceOrientation == UIInterfaceOrientationPortrait) || (self.interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown)) {
        [self setTextViewHeight:287];
    }
	
	if((pageDetailsController.interfaceOrientation == UIInterfaceOrientationLandscapeLeft) || (pageDetailsController.interfaceOrientation == UIInterfaceOrientationLandscapeRight)){
		
	}
    isEditing = NO;

    dismiss = NO;

    if (isTextViewEditing)
        isTextViewEditing = NO;

    [self bringTextViewDown];
    NSString *text = textView.text;
    [[[BlogDataManager sharedDataManager] currentPage] setObject:text forKey:@"description"];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    self.currentEditingTextField = nil;

    if (textField == titleTextField)
        [[BlogDataManager sharedDataManager].currentPage setValue:textField.text forKey:@"title"];

    CGRect frame = subView.frame;
    frame.origin.y = 0.0f;
    subView.frame = frame;

    frame = textViewContentView.frame;
    frame.origin.y = 81.0f;
    textViewContentView.frame = frame;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    pageDetailsController.hasChanges = YES;
    hasChanges = YES;
    return YES;
}

- (IBAction)showStatusViewAction:(id)sender {
    [self populateSelectionsControllerWithStatuses];
}

- (IBAction)showCustomFieldsTableView:(id)sender {
    [self populateCustomFieldsTableViewControllerWithCustomFields];
}

- (void)selectionTableViewController:(WPSelectionTableViewController *)selctionController completedSelectionsWithContext:(void *)selContext selectedObjects:(NSArray *)selectedObjects haveChanges:(BOOL)isChanged {
    if (!isChanged) {
        [selctionController clean];
        return;
    }

    BlogDataManager *dm = [BlogDataManager sharedDataManager];

    if (selContext == kSelectionsStatusContext1) {
        NSString *curStatus = [selectedObjects lastObject];
        NSString *status = [dm pageStatusForStatusDescription:curStatus fromBlog:dm.currentBlog];

        if (status) {
            [[dm currentPage] setObject:status forKey:@"page_status"];
            statusTextField.text = curStatus;
        }
    }

    [selctionController clean];
    pageDetailsController.hasChanges = YES;
}

- (void)populateSelectionsControllerWithStatuses {
    if (selectionTableViewController == nil)
        selectionTableViewController = [[WPSelectionTableViewController alloc] initWithNibName:@"WPSelectionTableViewController" bundle:nil];

    BlogDataManager *dm = [BlogDataManager sharedDataManager];
    NSDictionary *postStatusList = [[dm currentBlog] valueForKey:@"pageStatusList"];
    NSArray *dataSource = [postStatusList allValues];

    if (dm.currentPageIndex == -1 || dm.isLocaDraftsCurrent)
        dataSource = [dataSource arrayByAddingObject:@"Local Draft"];

    NSString *curStatus = [dm.currentPage valueForKey:@"page_status"];

    NSString *statusValue = [dm statusDescriptionForStatus:curStatus fromBlog:dm.currentBlog];

    NSArray *selObject = (statusValue == nil ? [NSArray array] : [NSArray arrayWithObject:statusValue]);

    [selectionTableViewController populateDataSource:dataSource
     havingContext:kSelectionsStatusContext1
     selectedObjects:selObject
     selectionType:kRadio
     andDelegate:self];

    selectionTableViewController.title = @"Status";
    selectionTableViewController.navigationItem.rightBarButtonItem = nil;
    [pageDetailsController.navigationController pushViewController:selectionTableViewController animated:YES];
}

- (void)populateCustomFieldsTableViewControllerWithCustomFields {
    //initialize the new view if it doesn't exist
    if (customFieldsTableView == nil)
        customFieldsTableView = [[CustomFieldsTableView alloc] initWithNibName:@"CustomFieldsTableView" bundle:nil];

    customFieldsTableView.pageDetailsController = self.pageDetailsController;
    //load the CustomFieldsTableView  Note: customFieldsTableView loads some data in viewDidLoad
    [customFieldsTableView setIsPost:NO];     //since we're dealing with pages, NOT posts
    [pageDetailsController.navigationController pushViewController:customFieldsTableView animated:YES];
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
    pageDetailsController.hasChanges = YES;
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    self.currentEditingTextField = nil;
    [textField resignFirstResponder];
    pageDetailsController.hasChanges = YES;
    return YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    pageDetailsController.hasChanges = NO;
    [titleTextField resignFirstResponder];
    [pageContentTextView resignFirstResponder];
    mode = refreshPage;
}

- (void)didReceiveMemoryWarning {
    WPLog(@"%@ %@", self, NSStringFromSelector(_cmd));
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
}

- (void)dealloc {
    [pageDetailsController release];
    [selectionTableViewController release];
    //[customFieldsTableView release];
    [super dealloc];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];

    if ([alertView tag] == 1) {
        if (buttonIndex == 1)
            [self showLinkView];else {
            dismiss = YES;
            [pageContentTextView touchesBegan:nil withEvent:nil];
            [delegate setAlertRunning:NO];
        }
    }

    if ([alertView tag] == 2) {
        if (buttonIndex == 1) {
            if ((urlField.text == nil) || ([urlField.text isEqualToString:@""]))
                return;

            if ((infoText.text == nil) || ([infoText.text isEqualToString:@""]))
                infoText.text = urlField.text;

            NSString *commentsStr = pageContentTextView.text;
            NSRange rangeToReplace = [self selectedLinkRange];
            NSString *urlString = [self validateNewLinkInfo:urlField.text];
            NSString *aTagText = [NSString stringWithFormat:@"<a href=\"%@\">%@</a>", urlString, infoText.text];;
            pageContentTextView.text = [commentsStr stringByReplacingOccurrencesOfString:[commentsStr substringWithRange:rangeToReplace] withString:aTagText options:NSCaseInsensitiveSearch range:rangeToReplace];

            BlogDataManager *dm = [BlogDataManager sharedDataManager];
            NSString *str = pageContentTextView.text;
            str = (str != nil ? str : @"");
            [dm.currentPage setValue:str forKey:@"description"];
        }

        dismiss = YES;
        [delegate setAlertRunning:NO];
        [pageContentTextView touchesBegan:nil withEvent:nil];
    }

    return;
}

//code to append http:// if protocol part is not there as part of urlText.
- (NSString *)validateNewLinkInfo:(NSString *)urlText {
    NSArray *stringArray = [NSArray arrayWithObjects:@"http:", @"ftp:", @"https:", nil];
    int i, count = [stringArray count];
    BOOL searchRes = NO;

    for (i = 0; i < count; i++) {
        NSString *searchString = [stringArray objectAtIndex:i];

        if (searchRes = [urlText hasPrefix:[searchString capitalizedString]])
            break;else if (searchRes = [urlText hasPrefix:[searchString lowercaseString]])
            break;else if (searchRes = [urlText hasPrefix:[searchString uppercaseString]])
            break;
    }

    NSString *returnStr;

    if (searchRes)
        returnStr = [NSString stringWithString:urlText];else
        returnStr = [NSString stringWithFormat:@"http://%@", urlText];

    return returnStr;
}

//code to Show the link view
//when create link button of the create hyperlink alert is clicked.

- (void)showLinkView {
    UIAlertView *addURLSourceAlert = [[UIAlertView alloc] initWithFrame:CGRectMake(0, 0, 0, 0.0)];
    infoText = [[UITextField alloc] initWithFrame:CGRectMake(12.0, 48.0, 260.0, 29.0)];
    urlField = [[UITextField alloc] initWithFrame:CGRectMake(12.0, 82.0, 260.0, 29.0)];
    infoText.placeholder = @"Text to be linked";
    urlField.placeholder = @"Link URL";
    //infoText.enabled = YES;

    infoText.autocapitalizationType = UITextAutocapitalizationTypeNone;
    urlField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    infoText.borderStyle = UITextBorderStyleRoundedRect;
    urlField.borderStyle = UITextBorderStyleRoundedRect;
    infoText.keyboardAppearance = UIKeyboardAppearanceAlert;
    urlField.keyboardAppearance = UIKeyboardAppearanceAlert;
    [addURLSourceAlert addButtonWithTitle:@"Cancel"];
    [addURLSourceAlert addButtonWithTitle:@"Save"];
    addURLSourceAlert.title = @"Make a Link\n\n\n\n";
    addURLSourceAlert.delegate = self;
    [addURLSourceAlert addSubview:infoText];
    [addURLSourceAlert addSubview:urlField];
    [infoText becomeFirstResponder];
    CGAffineTransform upTransform = CGAffineTransformMakeTranslation(0.0, 140.0);
    [addURLSourceAlert setTransform:upTransform];
    [addURLSourceAlert setTag:2];
    [addURLSourceAlert show];
    [addURLSourceAlert release];

    WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    [delegate setAlertRunning:NO];
}

#pragma mark -
#pragma mark Custom Fields methods
- (void)postionTextViewContentView {
    if (isCustomFieldsEnabledForThisPage) {
        //originY = 214.0f;
        originY = 125.0f;
        CGRect frame = textViewContentView.frame;
        frame.origin.y = originY;
        [textViewContentView setFrame:frame];
    } else {
        originY = 80.0f;
        CGRect frame = textViewContentView.frame;
        frame.origin.y = originY;
        [textViewContentView setFrame:frame];
    }
}

- (BOOL)checkCustomFieldsMinusMetadata {
    BlogDataManager *dm = [BlogDataManager sharedDataManager];
    NSMutableArray *tempCustomFieldsArray = [dm.currentPage valueForKey:@"custom_fields"];

    //if there is anything (>=1) in the array, start proceessing, otherwise return NO
    if (tempCustomFieldsArray.count >= 1) {
        //strip out any underscore-containing NSDicts inside the array, as this is metadata we don't need
        int dictsCount = [tempCustomFieldsArray count];

        for (int i = 0; i < dictsCount; i++) {
            NSString *tempKey = [[tempCustomFieldsArray objectAtIndex:i] objectForKey:@"key"];
            NSLog(@"Strip Metadata tempKey is... %@", tempKey);

            //if tempKey contains an underscore, remove that object (NSDict with metadata) from the array and move on
            if ([tempKey rangeOfString:@"_"].location != NSNotFound) {
                NSLog(@"Found an underscore metadata 'member' and removing it %@", tempKey);
                [tempCustomFieldsArray removeObjectAtIndex:i];
                //if I remove one, the count goes down and we stop too soon unless we subtract one from i
                //and re-set dictsCount.  Doing this keeps us in sync with the actual array.count
                i--;
                dictsCount = [tempCustomFieldsArray count];
            }
        }

        //if the count of everything minus the metedata is one or greater, there is at least one custom field on this post, so return YES
        if (dictsCount >= 1) {
            return YES;
        } else {
            return NO;
        }
    } else {
        return NO;
    }
}

@end
