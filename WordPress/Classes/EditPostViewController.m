#import "EditPostViewController_Internal.h"
#import "WPSegmentedSelectionTableViewController.h"
#import "Post.h"
#import "AutosavingIndicatorView.h"
#import "NSString+XMLExtensions.h"
#import "WPPopoverBackgroundView.h"
#import "WPAddCategoryViewController.h"

NSTimeInterval kAnimationDuration = 0.3f;

NSUInteger const EditPostViewControllerCharactersChangedToAutosave = 20;
NSUInteger const EditPostViewControllerCharactersChangedToAutosaveOnWWAN = 40;
NSTimeInterval const EditPostViewControllerAutosaveInterval = 4;
NSTimeInterval const EditPostViewControllerAutosaveIntervalOnWWAN = 6;

typedef NS_ENUM(NSInteger, EditPostViewControllerAlertTag) {
    EditPostViewControllerAlertTagNone,
    EditPostViewControllerAlertTagLinkHelper,
    EditPostViewControllerAlertTagFailedMedia,
};

@interface EditPostViewController ()
@end

@implementation EditPostViewController {
    IBOutlet UITextView *textView;
    IBOutlet UITextField *titleTextField;
    IBOutlet UITextField *tagsTextField;
    IBOutlet UILabel *titleLabel;
    IBOutlet UITextField *textViewPlaceHolderField;
	IBOutlet UIView *contentView;
	IBOutlet UIView *editView;
	IBOutlet UIBarButtonItem *writeButton;
	IBOutlet UIBarButtonItem *previewButton;
	IBOutlet UIBarButtonItem *attachmentButton;
    IBOutlet UIBarButtonItem *createCategoryBarButtonItem;
    IBOutlet UIImageView *tabPointer;
    IBOutlet UILabel *tagsLabel;
    IBOutlet UILabel *categoriesLabel;
    IBOutlet UIButton *categoriesButton;

    WPKeyboardToolbar *editorToolbar;
	NSArray *statuses;
    UIView *currentView;
    BOOL isTextViewEditing;
    BOOL isEditing;
    BOOL isShowingKeyboard;
    BOOL isExternalKeyboard;
    BOOL isNewCategory;
    BOOL isShowingLinkAlert;
    UITextField *__weak currentEditingTextField;
    WPSegmentedSelectionTableViewController *segmentedTableViewController;
    UIActionSheet *currentActionSheet;
    UITextField *infoText;
    UITextField *urlField;

    UIAlertView *_failedMediaAlertView;
    UIAlertView *_linkHelperAlertView;
    BOOL _isAutosaved;
    BOOL _isAutosaving;
    BOOL _hasChangesToAutosave;
    NSTimer *_autosaveTimer;
    AutosavingIndicatorView *_autosavingIndicatorView;
    NSUInteger _charactersChanged;
}

#pragma mark -
#pragma mark LifeCycle Methods

- (void)dealloc {
    _failedMediaAlertView.delegate = nil;
    _linkHelperAlertView.delegate = nil;
    [_autosaveTimer invalidate];
}

- (id)initWithPost:(AbstractPost *)aPost {
    NSString *nib;
    if (IS_IPAD) {
        nib = @"EditPostViewController-iPad";
    } else {
        nib = @"EditPostViewController";
    }
    
    if (self = [super initWithNibName:nib bundle:nil]) {
        self.apost = aPost;
        if (self.apost.remoteStatus == AbstractPostRemoteStatusLocal) {
            self.editMode = EditPostViewControllerModeNewPost;
        } else {
            self.editMode = EditPostViewControllerModeEditPost;
        }
    }
    
    return self;
}

- (void)viewDidLoad {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [super viewDidLoad];

    titleLabel.text = NSLocalizedString(@"Title:", @"Label for the title of the post field. Should be the same as WP core.");
    tagsLabel.text = NSLocalizedString(@"Tags:", @"Label for the tags field. Should be the same as WP core.");
    tagsTextField.placeholder = NSLocalizedString(@"Separate tags with commas", @"Placeholder text for the tags field. Should be the same as WP core.");
    categoriesLabel.text = NSLocalizedString(@"Categories:", @"Label for the categories field. Should be the same as WP core.");
    textViewPlaceHolderField.placeholder = NSLocalizedString(@"Tap here to begin writing", @"Placeholder for the main body text. Should hint at tapping to enter text (not specifying body text).");
	textViewPlaceHolderField.textAlignment = UITextAlignmentCenter;

    if ([textView respondsToSelector:@selector(setInputAccessoryView:)]) {
        CGRect frame;
        if (IS_IPAD) {
            frame = CGRectMake(0, 0, self.view.frame.size.width, WPKT_HEIGHT_IPAD_PORTRAIT);
        } else {
            frame = CGRectMake(0, 0, self.view.frame.size.width, WPKT_HEIGHT_IPHONE_PORTRAIT);
        }
        if (editorToolbar == nil) {
            editorToolbar = [[WPKeyboardToolbar alloc] initWithFrame:frame];
            editorToolbar.delegate = self;
        }
        textView.inputAccessoryView = editorToolbar;
        textViewPlaceHolderField.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    }

    if (!self.postSettingsViewController) {
        self.postSettingsViewController = [[PostSettingsViewController alloc] initWithPost:self.apost];
        self.postSettingsViewController.postDetailViewController = self;
    }

    if (!self.postPreviewViewController) {
        self.postPreviewViewController = [[PostPreviewViewController alloc] initWithPost:self.apost];
        self.postPreviewViewController.postDetailViewController = self;
    }

    if (!self.postMediaViewController) {
        self.postMediaViewController = [[PostMediaViewController alloc] initWithPost:self.apost];
        self.postMediaViewController.postDetailViewController = self;
    }

    self.postSettingsViewController.view.frame = editView.frame;
    self.postMediaViewController.view.frame = editView.frame;
    self.postPreviewViewController.view.frame = editView.frame;
    
    self.title = [self editorTitle];

    if (!statuses)
        statuses = [NSArray arrayWithObjects:NSLocalizedString(@"Local Draft", @"Post status label in the posts list if the post has not yet been synced to the remote server."), NSLocalizedString(@"Draft", @"Post status label in the posts list if the post is a draft."), NSLocalizedString(@"Private", @"Post status label in the posts list if the post is marked as private. Should be the same as WP core."), NSLocalizedString(@"Pending review", @"Post status label in the post list if the post is pending review. Should be the same as WP core."), NSLocalizedString(@"Published", @"Post status to indicate that the post is live and published. Should be the same as WP core."), nil];
	
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceDidRotate:) name:@"UIDeviceOrientationDidChangeNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newCategoryCreatedNotificationReceived:) name:WPNewCategoryCreatedAndUpdatedInBlogNotificationName object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(insertMediaAbove:) name:@"ShouldInsertMediaAbove" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(insertMediaBelow:) name:@"ShouldInsertMediaBelow" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeMedia:) name:@"ShouldRemoveMedia" object:nil];	
	
    isTextViewEditing = NO;

    currentView = editView;
	writeButton.enabled = NO;
    attachmentButton.enabled = [self shouldEnableMediaTab];

    self.view.backgroundColor = [UIColor scrollViewTexturedBackgroundColor];
	
	if (![self.postMediaViewController isDeviceSupportVideo]){
		//no video icon for older devices
		NSMutableArray *toolbarItems = [NSMutableArray arrayWithArray:self.toolbar.items];
		NSLog(@"toolbar items: %@", toolbarItems);
		
		[toolbarItems removeObjectAtIndex:5];
		[self.toolbar setItems:toolbarItems];
	}
	
	if (self.post && self.post.geolocation != nil && self.post.blog.geolocationEnabled) {
		self.hasLocation.enabled = YES;
	} else {
		self.hasLocation.enabled = NO;
	}

    [self refreshUIForCurrentPost];

    if ([writeButton respondsToSelector:@selector(setTintColor:)]) {
        UIColor *color = [UIColor UIColorFromHex:0x222222];
        writeButton.tintColor = color;
        self.settingsButton.tintColor = color;
        previewButton.tintColor = color;
        attachmentButton.tintColor = color;
        self.photoButton.tintColor = color;
        self.movieButton.tintColor = color;
    }

    if (_autosavingIndicatorView == nil) {
        _autosavingIndicatorView = [[AutosavingIndicatorView alloc] initWithFrame:CGRectZero];
        _autosavingIndicatorView.hidden = YES;

        [self.view addSubview:_autosavingIndicatorView];
        [self positionAutosaveView:nil];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [super viewWillAppear:animated];
    
	self.postSettingsViewController.view.frame = editView.frame;
    self.postMediaViewController.view.frame = editView.frame;
    self.postPreviewViewController.view.frame = editView.frame;

	[self refreshButtons];
	
    textView.frame = self.normalTextFrame;
    CGRect frame = self.normalTextFrame;
    frame.origin.x += 7;
    frame.origin.y += 7;
	frame.size.width -= 14;
	frame.size.height = 200;
    textViewPlaceHolderField.frame = frame;
	textViewPlaceHolderField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
	CABasicAnimation *animateWiggleIt;	
	animateWiggleIt=[CABasicAnimation animationWithKeyPath:@"transform.scale"];
	animateWiggleIt.duration=0.5;
	animateWiggleIt.repeatCount=1;
	animateWiggleIt.autoreverses=NO;
    animateWiggleIt.fromValue=[NSNumber numberWithFloat:0.75];
    animateWiggleIt.toValue=[NSNumber numberWithFloat:1.0];
	[textViewPlaceHolderField.layer addAnimation:animateWiggleIt forKey:@"textViewPlaceHolderField"];

}

- (void)viewWillDisappear:(BOOL)animated {	
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [super viewWillDisappear:animated];
    
	[titleTextField resignFirstResponder];
	[textView resignFirstResponder];

}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return [super shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}

#pragma mark -
#pragma mark Instance Methods

- (BOOL)shouldEnableMediaTab {
    return ([[self.apost.media filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"mediaType != 'featured'"]] count] > 0) ;
}

- (NSString *)editorTitle {
    NSString *title = @"";
    if (self.editMode == EditPostViewControllerModeNewPost) {
        title = NSLocalizedString(@"New Post", @"Post Editor screen title.");
    } else {
        if ([self.apost.postTitle length] > 0) {
            title = self.apost.postTitle;
        } else {
            title = NSLocalizedString(@"Edit Post", @"Post Editor screen title.");
        }
    }
    return title;
}


- (Post *)post {
    if ([self.apost isKindOfClass:[Post class]]) {
        return (Post *)self.apost;
    } else {
        return nil;
    }
}

- (void)setPost:(Post *)aPost {
    self.apost = aPost;
}

- (void)switchToView:(UIView *)newView {
    if ([newView isEqual:editView]) {
		writeButton.enabled = NO;
		self.settingsButton.enabled = YES;
		previewButton.enabled = YES;
        attachmentButton.enabled = [self shouldEnableMediaTab];
        
    } else if ([newView isEqual:self.postSettingsViewController.view]) {
		writeButton.enabled = YES;
		self.settingsButton.enabled = NO;
		previewButton.enabled = YES;
        attachmentButton.enabled = [self shouldEnableMediaTab];
        
    } else if ([newView isEqual:self.postPreviewViewController.view]) {
		writeButton.enabled = YES;
		self.settingsButton.enabled = YES;
		previewButton.enabled = NO;
        attachmentButton.enabled = [self shouldEnableMediaTab];
        
	} else if ([newView isEqual:self.postMediaViewController.view]) {
		writeButton.enabled = YES;
		self.settingsButton.enabled = YES;
		previewButton.enabled = YES;
		attachmentButton.enabled = NO;
	}
	
    newView.frame = currentView.frame;
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.2];
    
	CGRect pointerFrame = tabPointer.frame;
    if ([newView isEqual:editView]) {
		pointerFrame.origin.x = 22;
    } else if ([newView isEqual:self.postSettingsViewController.view]) {
		pointerFrame.origin.x = 61;
    } else if ([newView isEqual:self.postPreviewViewController.view]) {
		pointerFrame.origin.x = 101;
	} else if ([newView isEqual:self.postMediaViewController.view]) {
		if (IS_IPAD) {
			if ([self.postMediaViewController isDeviceSupportVideo])
				pointerFrame.origin.x = 646;
			else
				pointerFrame.origin.x = 688;
		}
		else {
            pointerFrame.origin.x = [self pointerPositionForAttachmentsTab];
		}
	}
	tabPointer.frame = pointerFrame;
    [currentView removeFromSuperview];
    [contentView addSubview:newView];
    
    [UIView commitAnimations];
    
    currentView = newView;
}

- (NSInteger)pointerPositionForAttachmentsTab {
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) {
        if ([self.postMediaViewController isDeviceSupportVideo])
            return 198;
        else
            return 240;
    } else {
        if ([self.postMediaViewController isDeviceSupportVideo])
            return 358;
        else
            return 400;
    }
}

- (IBAction)switchToEdit {
    if (currentView != editView) {
        [self switchToView:editView];
    }
//	self.navigationItem.title = NSLocalizedString(@"New Post", @"Post Editor screen title.");
    self.navigationItem.title = [self editorTitle];
}

- (IBAction)switchToSettings {
    if (currentView != self.postSettingsViewController.view) {
        [self switchToView:self.postSettingsViewController.view];
    }
	self.navigationItem.title = NSLocalizedString(@"Settings", @"Post Editor / Settings screen title.");
}

- (IBAction)switchToMedia {
    if (currentView != self.postMediaViewController.view) {
        [self switchToView:self.postMediaViewController.view];
    }
	self.navigationItem.title = NSLocalizedString(@"Media", @"Post Editor / Media screen title.");
}

- (IBAction)switchToPreview {
    if (currentView != self.postPreviewViewController.view) {
        [self switchToView:self.postPreviewViewController.view];
    }
	self.navigationItem.title = NSLocalizedString(@"Preview", @"Post Editor / Preview screen title.");
}

- (IBAction)addVideo:(id)sender {
    [self.postMediaViewController showVideoPickerActionSheet:sender];
}

- (IBAction)addPhoto:(id)sender {
    [self.postMediaViewController showPhotoPickerActionSheet:sender];
}

- (IBAction)showCategories:(id)sender {
    if (isShowingKeyboard) {
        if(isTextViewEditing) {
            [textView resignFirstResponder];
        } else {
            [currentEditingTextField resignFirstResponder];
        }
    }
    [self populateSelectionsControllerWithCategories];
}

- (IBAction)touchTextView:(id)sender {
    [textView becomeFirstResponder];
}

- (CGRect)normalTextFrame {
    if (IS_IPAD) {
        if ((self.interfaceOrientation == UIDeviceOrientationLandscapeLeft)
            || (self.interfaceOrientation == UIDeviceOrientationLandscapeRight)) // Landscape
            return CGRectMake(0, 143, self.view.bounds.size.width, 517);
        else // Portrait
            return CGRectMake(0, 143, self.view.bounds.size.width, 753);
    } else {
        CGFloat y = 136.f;
        CGFloat height = self.toolbar.frame.origin.y - y;
        if ((self.interfaceOrientation == UIDeviceOrientationLandscapeLeft)
            || (self.interfaceOrientation == UIDeviceOrientationLandscapeRight)) // Landscape
			return CGRectMake(0, y, self.view.bounds.size.width, height);
		else // Portrait
			return CGRectMake(0, y, self.view.bounds.size.width, height);
    }
}

- (void)dismissEditView {
    [self dismissModalViewControllerAnimated:YES];

	[[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"PostEditorDismissed" object:self];
}


- (void)refreshButtons {
    if (self.navigationItem.leftBarButtonItem == nil) {
        UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                      target:self
                                                                                      action:@selector(cancelView:)];
        self.navigationItem.leftBarButtonItem = cancelButton;
    }

    NSString *buttonTitle;
    if(![self.apost hasRemote] || ![self.apost.status isEqualToString:self.apost.original.status]) {
        if ([self.apost.status isEqualToString:@"publish"] && ([self.apost.dateCreated compare:[NSDate date]] == NSOrderedDescending)) {
            buttonTitle = NSLocalizedString(@"Schedule", @"Schedule button, this is what the Publish button changes to in the Post Editor if the post has been scheduled for posting later.");
		} else if ([self.apost.status isEqualToString:@"publish"]){
            buttonTitle = NSLocalizedString(@"Publish", @"Publish button label.");
		} else {
            buttonTitle = NSLocalizedString(@"Save", @"Save button label (saving content, ex: Post, Page, Comment).");
        }
    } else {
        buttonTitle = NSLocalizedString(@"Update", @"Update button label (saving content, ex: Post, Page, Comment).");
    }

    if (self.navigationItem.rightBarButtonItem == nil) {
        UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithTitle:buttonTitle style:UIBarButtonItemStyleDone target:self action:@selector(saveAction:)];
        self.navigationItem.rightBarButtonItem = saveButton;
    } else {
        self.navigationItem.rightBarButtonItem.title = buttonTitle;
    }

    BOOL updateEnabled = self.hasChanges || self.apost.remoteStatus == AbstractPostRemoteStatusFailed;
    [self.navigationItem.rightBarButtonItem setEnabled:updateEnabled];
}

- (void)refreshUIForCurrentPost {
    self.navigationItem.title = [self editorTitle];

    titleTextField.text = self.apost.postTitle;
    if (self.post) {
        tagsTextField.text = self.post.tags;
        [categoriesButton setTitle:[NSString decodeXMLCharactersIn:[self.post categoriesText]] forState:UIControlStateNormal];
        [categoriesButton.titleLabel setFont:[UIFont systemFontOfSize:16.0f]];
    }
    
    if(self.apost.content == nil || [self.apost.content isEmpty]) {
        textViewPlaceHolderField.hidden = NO;
        textView.text = @"";
    }
    else {
        textViewPlaceHolderField.hidden = YES;
        if ((self.apost.mt_text_more != nil) && ([self.apost.mt_text_more length] > 0))
			textView.text = [NSString stringWithFormat:@"%@\n<!--more-->\n%@", self.apost.content, self.apost.mt_text_more];
		else
			textView.text = self.apost.content;
    }
    
	// workaround for odd text view behavior on iPad
	[textView setContentOffset:CGPointZero animated:NO];

    [self refreshButtons];
}

- (void)populateSelectionsControllerWithCategories {
    WPFLogMethod();
    if (segmentedTableViewController == nil)
        segmentedTableViewController = [[WPSegmentedSelectionTableViewController alloc] initWithNibName:@"WPSelectionTableViewController" bundle:nil];
	
	NSArray *cats = [self.post.blog sortedCategories];

	NSArray *selObject = [self.post.categories allObjects];
	
    [segmentedTableViewController populateDataSource:cats    //datasource
									   havingContext:kSelectionsCategoriesContext
									 selectedObjects:selObject
									   selectionType:kCheckbox
										 andDelegate:self];
	
    segmentedTableViewController.title = NSLocalizedString(@"Categories", @"");
    if ([createCategoryBarButtonItem respondsToSelector:@selector(setTintColor:)]) {
        createCategoryBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"navbar_add"]style:UIBarButtonItemStyleBordered 
                                                                      target:self 
                                                                      action:@selector(showAddNewCategoryView:)];
    } 
    
    segmentedTableViewController.navigationItem.rightBarButtonItem = createCategoryBarButtonItem;
	
    if (isNewCategory != YES) {
		if (IS_IPAD == YES) {
            UINavigationController *navController;
            if (segmentedTableViewController.navigationController) {
                navController = segmentedTableViewController.navigationController;
            } else {
                navController = [[UINavigationController alloc] initWithRootViewController:segmentedTableViewController];
            }
 			UIPopoverController *popover = [[UIPopoverController alloc] initWithContentViewController:navController];
            if ([popover respondsToSelector:@selector(popoverBackgroundViewClass)]) {
                popover.popoverBackgroundViewClass = [WPPopoverBackgroundView class];
            }
            popover.delegate = self;
			CGRect popoverRect = [self.view convertRect:[categoriesButton frame] fromView:[categoriesButton superview]];
			popoverRect.size.width = MIN(popoverRect.size.width, 100.0f); // the text field is actually really big
            popover.popoverContentSize = CGSizeMake(320.0f, 460.0f);
			[popover presentPopoverFromRect:popoverRect inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
			[[CPopoverManager instance] setCurrentPopoverController:popover];
		
        } else {
			self.editMode = EditPostViewControllerModeEditPost;
			[self.navigationController pushViewController:segmentedTableViewController animated:YES];
		}
    }
	
	isNewCategory = NO;
}

- (void)selectionTableViewController:(WPSelectionTableViewController *)selctionController completedSelectionsWithContext:(void *)selContext selectedObjects:(NSArray *)selectedObjects haveChanges:(BOOL)isChanged {
    WPFLogMethod();
    if (!isChanged) {
        return;
    }

    if (selContext == kSelectionsCategoriesContext) {
        NSLog(@"selected categories: %@", selectedObjects);
        NSLog(@"post: %@", self.post);
        self.post.categories = [NSMutableSet setWithArray:selectedObjects];
        [categoriesButton setTitle:[NSString decodeXMLCharactersIn:[self.post categoriesText]] forState:UIControlStateNormal];
    }

    _hasChangesToAutosave = YES;
    [self autosaveContent];

	[self refreshButtons];
}


- (void)newCategoryCreatedNotificationReceived:(NSNotification *)notification {
    WPFLogMethod();
    if ([segmentedTableViewController curContext] == kSelectionsCategoriesContext) {
        isNewCategory = YES;
        [self populateSelectionsControllerWithCategories];
    }
}


- (IBAction)showAddNewCategoryView:(id)sender
{
    WPFLogMethod();
    WPAddCategoryViewController *addCategoryViewController = [[WPAddCategoryViewController alloc] initWithNibName:@"WPAddCategoryViewController" bundle:nil];
    addCategoryViewController.blog = self.post.blog;
	if (IS_IPAD == YES) {
        [segmentedTableViewController pushViewController:addCategoryViewController animated:YES];
 	} else {
		UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:addCategoryViewController];
		[segmentedTableViewController presentModalViewController:nc animated:YES];
	}
}

- (void)endEditingAction:(id)sender {
    [titleTextField resignFirstResponder];
    [tagsTextField resignFirstResponder];
    [textView resignFirstResponder];
}


- (void)discard {
    [self.apost.original deleteRevision];

	//remove the original post in case of local draft unsaved
	if(self.editMode == EditPostViewControllerModeNewPost)
		[self.apost.original deletePostWithSuccess:nil failure:nil]; //we can pass nil because this is a local draft. no remote errors.
	
	self.apost = nil; // Just in case
    [self dismissEditView];
}

- (IBAction)saveAction:(id)sender {
	if( [self isMediaInUploading] ) {
		[self showMediaInUploadingalert];
		return;
	}
    if ([self hasFailedMedia]) {
        [self showFailedMediaAlert];
        return;
    }
	[self savePost:YES];
}

- (void)savePost:(BOOL)upload{
    [self autosaveContent];

    [self.view endEditing:YES];

    [self.apost.original applyRevision];
    [self.apost.original deleteRevision];
	if (upload) {
		NSString *postTitle = self.apost.postTitle;
        [self.apost.original uploadWithSuccess:^{
            NSLog(@"post uploaded: %@", postTitle);
        } failure:^(NSError *error) {
            NSLog(@"post failed: %@", [error localizedDescription]);
        }];
	} else {
		[self.apost.original save];
	}

    [self dismissEditView];
}

- (void)autosaveContent {
    self.apost.postTitle = titleTextField.text;
    self.navigationItem.title = [self editorTitle];
    self.post.tags = tagsTextField.text;
    self.apost.content = textView.text;
	if ([self.apost.content rangeOfString:@"<!--more-->"].location != NSNotFound)
		self.apost.mt_text_more = @"";

    if ( self.apost.original.password != nil ) { //original post was password protected
        if ( self.apost.password == nil || [self.apost.password isEqualToString:@""] ) { //removed the password
            self.apost.password = @"";
        }
    }

    [self.apost autosave];
    [self restartAutosaveTimer];
}

- (BOOL)canAutosaveRemotely {
    return ((![self.apost.original hasRemote] || [self.apost.original.status isEqualToString:@"draft"]) && self.apost.blog.reachable);
}

- (BOOL)autosaveRemoteWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure {
    if (![self canAutosaveRemotely]) {
        return NO;
    }

    if (![self.apost.original hasRemote]) {
        _isAutosaved = YES;
    }
    [self.apost.original applyRevision];
    self.apost.original.status = @"draft";
    AbstractPostRemoteStatus currentRemoteStatus = self.apost.original.remoteStatus;
    _isAutosaving = YES;
    _hasChangesToAutosave = NO;
    [self showAutosaveIndicator];
    [self.apost.original uploadWithSuccess:^{
        NSString *status = self.apost.status;
        [self.apost updateRevision];
        self.apost.status = status;
        _isAutosaving = NO;
        [self hideAutosaveIndicatorWithSuccess:YES];
        if (success) success();
    } failure:^(NSError *error) {
        // Restore current remote status so failed autosaves don't make the post appear as failed
        // Specially useful when offline
        self.apost.original.remoteStatus = currentRemoteStatus;
        _isAutosaving = NO;
        _hasChangesToAutosave = YES;
        [self hideAutosaveIndicatorWithSuccess:NO];
    }];

    return YES;
}

- (void)restartAutosaveTimer {
    WPFLogMethod();
    [_autosaveTimer invalidate];
    _autosaveTimer = nil;
    if (![self canAutosaveRemotely])
        return;

    if (!_hasChangesToAutosave)
        return;

    _autosaveTimer = [NSTimer scheduledTimerWithTimeInterval:[self autosaveInterval] target:self selector:@selector(autosaveTriggered:) userInfo:nil repeats:NO];
    WPFLog(@"New timer for %@", _autosaveTimer.fireDate);
}

- (void)autosaveTriggered:(NSTimer *)timer {
    WPFLogMethod();
    if ([self canAutosaveRemotely] && !_isAutosaving) {
        WPFLog(@"Autosaving :)");
        [self autosaveRemoteWithSuccess:^{
            WPFLog(@"Autosaved :D");
            [self restartAutosaveTimer];
        } failure:^(NSError *error) {
            WPFLog(@"Error autosaving: %@", error);
            [self restartAutosaveTimer];
        }];
    }
}

- (void)incrementCharactersChangedForAutosaveBy:(NSUInteger)change {
    _charactersChanged += change;
    if (_charactersChanged > [self autosaveCharactersChangedThreshold]) {
        _charactersChanged = 0;
        [self autosaveTriggered:nil];
    }
}

- (void)showAutosaveIndicator {
    [_autosavingIndicatorView startAnimating];
}

- (void)hideAutosaveIndicatorWithSuccess:(BOOL)success {
    [_autosavingIndicatorView stopAnimatingWithSuccess:success];
}

- (NSTimeInterval)autosaveInterval {
    if ([self.apost.blog.reachability isReachableViaWWAN]) {
        return EditPostViewControllerAutosaveIntervalOnWWAN;
    } else {
        return EditPostViewControllerAutosaveInterval;
    }
}

- (NSUInteger)autosaveCharactersChangedThreshold {
    if ([self.apost.blog.reachability isReachableViaWWAN]) {
        return EditPostViewControllerCharactersChangedToAutosaveOnWWAN;
    } else {
        return EditPostViewControllerCharactersChangedToAutosave;
    }
}

- (BOOL)hasFailedMedia {
	BOOL hasFailedMedia = NO;

	NSSet *mediaFiles = self.apost.media;
	for (Media *media in mediaFiles) {
		if(media.remoteStatus == MediaRemoteStatusFailed) {
			hasFailedMedia = YES;
			break;
		}
	}
	mediaFiles = nil;

	return hasFailedMedia;
}

//check if there are media in uploading status
- (BOOL)isMediaInUploading {
	BOOL isMediaInUploading = NO;
	
	NSSet *mediaFiles = self.apost.media;
	for (Media *media in mediaFiles) {
		if(media.remoteStatus == MediaRemoteStatusPushing) {
			isMediaInUploading = YES;
			break;
		}
	}
	mediaFiles = nil;

	return isMediaInUploading;
}

- (void)showFailedMediaAlert {
    if (_failedMediaAlertView)
        return;
    _failedMediaAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Pending media", @"Title for alert when trying to publish a post with failed media items")
                                                       message:NSLocalizedString(@"There are media items in this post that aren't uploaded to the server. Do you want to continue?", @"")
                                                      delegate:self
                                             cancelButtonTitle:NSLocalizedString(@"No", @"")
                                             otherButtonTitles:NSLocalizedString(@"Post anyway", @""), nil];
    _failedMediaAlertView.tag = EditPostViewControllerAlertTagFailedMedia;
    [_failedMediaAlertView show];
}

- (void)showMediaInUploadingalert {
	//the post is using the network connection and cannot be stoped, show a message to the user
	UIAlertView *blogIsCurrentlyBusy = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Info", @"Info alert title")
																  message:NSLocalizedString(@"A Media file is currently uploading. Please try later.", @"")
																 delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
	[blogIsCurrentlyBusy show];
}

- (IBAction)cancelView:(id)sender {
    if(currentActionSheet) return;
    
    [textView resignFirstResponder];
    [titleTextField resignFirstResponder];
    [tagsTextField resignFirstResponder];
    if (!self.hasChanges) {
		[self.postSettingsViewController endEditingAction:nil];
        [self discard];
        return;
    }
	[self.postSettingsViewController endEditingAction:nil];
	[self endEditingAction:nil];
    
	if( [self isMediaInUploading] ) {
		[self showMediaInUploadingalert];
		return;
	}
		
	UIActionSheet *actionSheet;
	if (![self.apost.original.status isEqualToString:@"draft"] && self.editMode != EditPostViewControllerModeNewPost) {
        // The post is already published in the server or it was intended to be and failed: Discard changes or keep editing
		actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"You have unsaved changes.", @"Title of message with options that shown when there are unsaved changes and the author is trying to move away from the post.")
												  delegate:self
                                         cancelButtonTitle:NSLocalizedString(@"Keep editing", @"Button shown if there are unsaved changes and the author is trying to move away from the post.")
                                    destructiveButtonTitle:NSLocalizedString(@"Discard", @"Button shown if there are unsaved changes and the author is trying to move away from the post.")
										 otherButtonTitles:nil];
    } else if (![self.apost hasRemote] && self.apost.remoteStatus == AbstractPostRemoteStatusLocal) {
        // The post is a local draft or an autosaved draft: Discard or Save
        actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"You have unsaved changes.", @"Title of message with options that shown when there are unsaved changes and the author is trying to move away from the post.")
                                                  delegate:self
                                         cancelButtonTitle:NSLocalizedString(@"Keep editing", @"Button shown if there are unsaved changes and the author is trying to move away from the post.")
                                    destructiveButtonTitle:NSLocalizedString(@"Discard", @"Button shown if there are unsaved changes and the author is trying to move away from the post.")
                                         otherButtonTitles:NSLocalizedString(@"Save Draft", @"Button shown if there are unsaved changes and the author is trying to move away from the post."), nil];
    } else {
        // The post was already a draft
        actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"You have unsaved changes.", @"Title of message with options that shown when there are unsaved changes and the author is trying to move away from the post.")
                                                  delegate:self
                                         cancelButtonTitle:NSLocalizedString(@"Keep editing", @"Button shown if there are unsaved changes and the author is trying to move away from the post.")
                                    destructiveButtonTitle:NSLocalizedString(@"Discard", @"Button shown if there are unsaved changes and the author is trying to move away from the post.")
                                         otherButtonTitles:NSLocalizedString(@"Update Draft", @"Button shown if there are unsaved changes and the author is trying to move away from an already published/saved post."), nil];
    }

    actionSheet.tag = 201;
    actionSheet.actionSheetStyle = UIActionSheetStyleAutomatic;
    if (IS_IPAD) {
        [actionSheet showFromBarButtonItem:self.navigationItem.leftBarButtonItem animated:YES];
    } else {
        [actionSheet showInView:self.view];
    }

    WordPressAppDelegate *appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate setAlertRunning:YES];
    
}

- (IBAction)endTextEnteringButtonAction:(id)sender {
    [textView resignFirstResponder];
	if (IS_IPAD == NO) {
		if((self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft) || (self.interfaceOrientation == UIInterfaceOrientationLandscapeRight)) {
			//#615 -- trick to rotate the interface back to portrait. 
				UIViewController *garbageController = [[UIViewController alloc] init]; 
				[self.navigationController pushViewController:garbageController animated:NO]; 
				[self.navigationController popViewControllerAnimated:NO];
		}
	}
}

- (void)resignTextView {
	[textView resignFirstResponder];
}

//code to append http:// if protocol part is not there as part of urlText.
- (NSString *)validateNewLinkInfo:(NSString *)urlText {
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^[\\w]+:" options:0 error:&error];

    if ([regex numberOfMatchesInString:urlText options:0 range:NSMakeRange(0, [urlText length])] > 0) {
        return urlText;
    } else if([urlText hasPrefix:@"#"]) {
        // link to named anchor
        return urlText;
    } else {
        return [NSString stringWithFormat:@"http://%@", urlText];
    }
}

- (void)showLinkView {
    if (_linkHelperAlertView)
        return;

    _linkHelperAlertView = [[UIAlertView alloc] init];
	if (IS_IPAD || [[UIDevice currentDevice] orientation] == UIInterfaceOrientationPortrait) {
		infoText = [[UITextField alloc] initWithFrame:CGRectMake(12.0, 46.0, 260.0, 31.0)];
		urlField = [[UITextField alloc] initWithFrame:CGRectMake(12.0, 82.0, 260.0, 31.0)];
	}
	else {
		infoText = [[UITextField alloc] initWithFrame:CGRectMake(12.0, 33.0, 260.0, 28.0)];
		urlField = [[UITextField alloc] initWithFrame:CGRectMake(12.0, 65.0, 260.0, 28.0)];
	}

    infoText.placeholder = NSLocalizedString(@"Text to be linked", @"Popup to aid in creating a Link in the Post Editor.");
    urlField.placeholder = NSLocalizedString(@"Link URL", @"Popup to aid in creating a Link in the Post Editor, URL field (where you can type or paste a URL that the text should link.");
	infoText.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
	urlField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    
    NSRange range = textView.selectedRange;
    
    if (range.length > 0)
        infoText.text = [textView.text substringWithRange:range];
    
    infoText.autocapitalizationType = UITextAutocapitalizationTypeNone;
    urlField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    infoText.borderStyle = UITextBorderStyleRoundedRect;
    urlField.borderStyle = UITextBorderStyleRoundedRect;
    infoText.keyboardAppearance = UIKeyboardAppearanceAlert;
    urlField.keyboardAppearance = UIKeyboardAppearanceAlert;
	infoText.keyboardType = UIKeyboardTypeDefault;
	urlField.keyboardType = UIKeyboardTypeURL;
    [_linkHelperAlertView addButtonWithTitle:NSLocalizedString(@"Cancel", @"Cancel button")];
    [_linkHelperAlertView addButtonWithTitle:NSLocalizedString(@"Insert", @"Insert content (link, media) button")];
    _linkHelperAlertView.title = NSLocalizedString(@"Make a Link\n\n\n\n", @"Title of the Link Helper popup to aid in creating a Link in the Post Editor. DON'T REMOVE the line breaks!");
    _linkHelperAlertView.delegate = self;
    [_linkHelperAlertView addSubview:infoText];
    [_linkHelperAlertView addSubview:urlField];
    [infoText becomeFirstResponder];
	
    isShowingLinkAlert = YES;
    _linkHelperAlertView.tag = EditPostViewControllerAlertTagLinkHelper;
    [_linkHelperAlertView show];
}

- (BOOL)hasChanges {
    return self.apost.hasChanges;
}

#pragma mark -
#pragma mark AlertView Delegate Methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    WordPressAppDelegate *delegate = (WordPressAppDelegate*)[[UIApplication sharedApplication] delegate];
	
    if (alertView.tag == EditPostViewControllerAlertTagLinkHelper) {
        isShowingLinkAlert = NO;
        if (buttonIndex == 1) {
            if ((urlField.text == nil) || ([urlField.text isEqualToString:@""])) {
                [delegate setAlertRunning:NO];
                return;
            }
			
            if ((infoText.text == nil) || ([infoText.text isEqualToString:@""]))
                infoText.text = urlField.text;
			
            NSString *urlString = [self validateNewLinkInfo:[urlField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
            NSString *aTagText = [NSString stringWithFormat:@"<a href=\"%@\">%@</a>", urlString, infoText.text];
            
            NSRange range = textView.selectedRange;
            
            NSString *oldText = textView.text;
            NSRange oldRange = textView.selectedRange;
            textView.text = [textView.text stringByReplacingCharactersInRange:range withString:aTagText];
            
            //reset selection back to nothing
            range.length = 0;
            
            if (range.length == 0) {                // If nothing was selected
                range.location += [aTagText length]; // Place selection between tags
                textView.selectedRange = range;
            }
            [[textView.undoManager prepareWithInvocationTarget:self] restoreText:oldText withRange:oldRange];
            [textView.undoManager setActionName:@"link"];            
            
            _hasChangesToAutosave = YES;
            [self autosaveContent];
            [self incrementCharactersChangedForAutosaveBy:MAX(oldRange.length, aTagText.length)];
        }
		
        [delegate setAlertRunning:NO];
        [textView touchesBegan:nil withEvent:nil];
        _linkHelperAlertView = nil;
    } else if (alertView.tag == EditPostViewControllerAlertTagFailedMedia) {
        if (buttonIndex == 1) {
            [self savePost:YES];
        } else {
            [self switchToMedia];
        }
        _failedMediaAlertView = nil;
    }
	
    return;
}


#pragma mark -
#pragma mark ActionSheet Delegate Methods

- (void)willPresentActionSheet:(UIActionSheet *)actionSheet {
    currentActionSheet = actionSheet;
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    currentActionSheet = nil;
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([actionSheet tag] == 201) {
        // Discard
        if (buttonIndex == 0) {
            [self discard];
        }

        if (buttonIndex == 1) {
            // Cancel / Keep editing
			if ([actionSheet numberOfButtons] == 2) {
				[actionSheet dismissWithClickedButtonIndex:0 animated:YES];
            // Save draft
			} else {
                // If you tapped on a button labeled "Save Draft", you probably expect the post to be saved as a draft
                if ((![self.apost hasRemote] || _isAutosaved) && [self.apost.status isEqualToString:@"publish"]) {
                    self.apost.status = @"draft";
                }
                BOOL upload = self.apost.blog.reachable;
                [self savePost:upload];
			}
        }
    }
    
    WordPressAppDelegate *appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate setAlertRunning:NO];
}

#pragma mark - TextView & TextField Delegates

- (BOOL)textViewShouldBeginEditing:(UITextView *)aTextView {
    WPFLogMethod();
    isEditing = YES;
    return YES;
}

- (void)textViewDidBeginEditing:(UITextView *)aTextView {
    WPFLogMethod();
    [textViewPlaceHolderField removeFromSuperview];

    if (!isTextViewEditing) {
        isTextViewEditing = YES;
    }
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    [self incrementCharactersChangedForAutosaveBy:MAX(range.length, text.length)];
    return YES;
}

- (void)textViewDidChange:(UITextView *)aTextView {

    _hasChangesToAutosave = YES;
    [self autosaveContent];

    [self refreshButtons];
}

- (void)textViewDidEndEditing:(UITextView *)aTextView {
    WPFLogMethod();
	currentEditingTextField = nil;
	
	if([textView.text isEqualToString:@""] == YES) {
        [editView addSubview:textViewPlaceHolderField];
	}
	
    isEditing = NO;
    _hasChangesToAutosave = YES;

    if (isTextViewEditing) {
        isTextViewEditing = NO;
		
        [self autosaveContent];

		if (!IS_IPAD) {
            [self refreshButtons];
		}
    }

    [self refreshButtons];
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    if (textField == textViewPlaceHolderField) {
        return NO;
    }
	return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
	return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    currentEditingTextField = textField;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    currentEditingTextField = nil;
#ifdef DEBUGMODE
	if ([textField.text isEqualToString:@"#%#"]) {
		[NSException raise:@"FakeCrash" format:@"Nothing to worry about, textField == #%#"];
	}
#endif
	    
    _hasChangesToAutosave = YES;
    [self autosaveContent];
    [self refreshButtons];
}

- (void)positionTextView:(NSNotification *)notification {
    // Save time: Uncomment this line when you're debugging UITextView positioning
    // textView.backgroundColor = [UIColor blueColor];

    NSDictionary *keyboardInfo = [notification userInfo];

	CGFloat animationDuration = 0.3;
	UIViewAnimationCurve curve = 0.3;
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationCurve:curve];
	[UIView setAnimationDuration:animationDuration];

    CGRect newFrame = self.normalTextFrame;
	if(keyboardInfo != nil) {
		animationDuration = [[keyboardInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
		curve = [[keyboardInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] floatValue];
        [UIView setAnimationCurve:curve];
        [UIView setAnimationDuration:animationDuration];

        BOOL isLandscape = UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation);
        BOOL isShowing = ([notification name] == UIKeyboardWillShowNotification);
        CGRect originalKeyboardFrame = [[keyboardInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
        CGRect keyboardFrame = [self.view convertRect:[self.view.window convertRect:originalKeyboardFrame fromWindow:nil] fromView:nil];

        isExternalKeyboard = keyboardFrame.origin.y + keyboardFrame.size.height > self.view.bounds.size.height;
        /*
         "Full screen" mode for:
         * iPhone Portrait without external keyboard
         * iPhone Landscape
         * iPad Landscape without external keyboard

         Show other fields:
         * iPhone Portrait with external keyboard
         * iPad Portrait
         * iPad Landscape with external keyboard
         */
        BOOL wantsFullScreen = (
                                (!IS_IPAD && !isExternalKeyboard)                  // iPhone without external keyboard
                                || (!IS_IPAD && isLandscape && isExternalKeyboard) // iPhone Landscape with external keyboard
                                || (IS_IPAD && isLandscape && !isExternalKeyboard) // iPad Landscape without external keyboard
                                );
        if (wantsFullScreen && isShowing) {
            [self.navigationController setNavigationBarHidden:YES animated:YES];;
        } else {
            [self.navigationController setNavigationBarHidden:NO animated:YES];
        }
        // If we show/hide the navigation bar, the view frame changes so the converted keyboardFrame is not valid anymore
        keyboardFrame = [self.view convertRect:[self.view.window convertRect:originalKeyboardFrame fromWindow:nil] fromView:nil];
        // Assing this again since changing the visibility status of navigation bar changes the view frame (#1386)
        newFrame = self.normalTextFrame;

        if (isShowing) {
            if (wantsFullScreen) {
                // Make the text view expand covering other fields
                newFrame.origin.x = 0;
                newFrame.origin.y = 0;
            }
            // Adjust height for keyboard (or format bar on external keyboard)
            newFrame.size.height = keyboardFrame.origin.y - newFrame.origin.y;

            [self.toolbar setHidden:YES];
            [tabPointer setHidden:YES];
        } else {
            [self.toolbar setHidden:NO];
            [tabPointer setHidden:NO];
        }
	}

    [textView setFrame:newFrame];
	
	[UIView commitAnimations];
}

- (void)positionAutosaveView:(NSNotification *)notification {
    CGRect frame;
    frame.size.width = 80.f;
    frame.size.height = 20.f;
    frame.origin.x = CGRectGetMaxX(textView.frame) - 4.f - frame.size.width;
    frame.origin.y = CGRectGetMaxY(textView.frame) - 4.f - frame.size.height;

    NSDictionary *keyboardInfo = [notification userInfo];
    if (keyboardInfo) {
        CGRect originalKeyboardFrame = [[keyboardInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
        CGRect keyboardFrame = [self.view convertRect:[self.view.window convertRect:originalKeyboardFrame fromWindow:nil] fromView:nil];
        if (CGRectGetMinY(keyboardFrame) < CGRectGetMaxY(frame)) {
            // Keyboard would cover the indicator, reposition
            frame.origin.y = CGRectGetMinY(keyboardFrame) - 4.f - frame.size.height;
        }
    }

    _autosavingIndicatorView.frame = frame;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration {
    WPFLogMethod();
    CGRect frame = editorToolbar.frame;
    if (UIDeviceOrientationIsLandscape(interfaceOrientation)) {
        if (IS_IPAD) {
            frame.size.height = WPKT_HEIGHT_IPAD_LANDSCAPE;
        } else {
            frame.size.height = WPKT_HEIGHT_IPHONE_LANDSCAPE;
        }
    } else {
        if (IS_IPAD) {
            frame.size.height = WPKT_HEIGHT_IPAD_PORTRAIT;
        } else {
            frame.size.height = WPKT_HEIGHT_IPHONE_PORTRAIT;
        }            
    }
    editorToolbar.frame = frame;

}

- (void)deviceDidRotate:(NSNotification *)notification {
    WPFLogMethod();
    
    if (IS_IPAD) {
        return;
    }
    
    if ([currentView isEqual:self.postMediaViewController.view]) {
        CGRect pointerFrame = tabPointer.frame;
        pointerFrame.origin.x = [self pointerPositionForAttachmentsTab];
        tabPointer.frame = pointerFrame;
    }
	
	// This reinforces text field constraints set above, for when the Link Helper is already showing when the device is rotated.
	if (isShowingLinkAlert) {
		if ([[UIDevice currentDevice] orientation] == UIInterfaceOrientationPortrait) {
			infoText.frame = CGRectMake(12.0, 46.0, 260.0, 31.0);
			urlField.frame = CGRectMake(12.0, 82.0, 260.0, 31.0);
		}
		else {
			infoText.frame = CGRectMake(12.0, 33.0, 260.0, 28.0);
			urlField.frame = CGRectMake(12.0, 65.0, 260.0, 28.0);
		}
	}
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (textField == titleTextField) {
        self.apost.postTitle = [textField.text stringByReplacingCharactersInRange:range withString:string];
        self.navigationItem.title = [self editorTitle];

    } else if (textField == tagsTextField)
        self.post.tags = [tagsTextField.text stringByReplacingCharactersInRange:range withString:string];

    _hasChangesToAutosave = YES;
    [self restartAutosaveTimer];
    [self incrementCharactersChangedForAutosaveBy:MAX(range.length, string.length)];
    [self refreshButtons];
    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    currentEditingTextField = nil;
    [textField resignFirstResponder];
    return YES;
}

- (void)insertMediaAbove:(NSNotification *)notification {
	Media *media = (Media *)[notification object];
	NSString *prefix = @"<br /><br />";
	
	if(self.apost.content == nil || [self.apost.content isEqualToString:@""]) {
		self.apost.content = @"";
		prefix = @"";
	}
	
	NSMutableString *content = [[NSMutableString alloc] initWithString:media.html];
	NSRange imgHTML = [textView.text rangeOfString: content];
	
	NSRange imgHTMLPre = [textView.text rangeOfString:[NSString stringWithFormat:@"%@%@", @"<br /><br />", content]]; 
 	NSRange imgHTMLPost = [textView.text rangeOfString:[NSString stringWithFormat:@"%@%@", content, @"<br /><br />"]]; 
	
	if (imgHTMLPre.location == NSNotFound && imgHTMLPost.location == NSNotFound && imgHTML.location == NSNotFound) {
		[content appendString:[NSString stringWithFormat:@"%@%@", prefix, self.apost.content]];
        self.apost.content = content;
	}
	else { 
		NSMutableString *processedText = [[NSMutableString alloc] initWithString:textView.text]; 
		if (imgHTMLPre.location != NSNotFound) 
			[processedText replaceCharactersInRange:imgHTMLPre withString:@""];
		else if (imgHTMLPost.location != NSNotFound) 
			[processedText replaceCharactersInRange:imgHTMLPost withString:@""];
		else  
			[processedText replaceCharactersInRange:imgHTML withString:@""];  
		 
		[content appendString:[NSString stringWithFormat:@"<br /><br />%@", processedText]]; 
		self.apost.content = content;
	}
    _hasChangesToAutosave = YES;
    [self refreshUIForCurrentPost];
    [self.apost autosave];
    [self incrementCharactersChangedForAutosaveBy:content.length];
}

- (void)insertMediaBelow:(NSNotification *)notification {
	Media *media = (Media *)[notification object];
	NSString *prefix = @"<br /><br />";
	
	if(self.apost.content == nil || [self.apost.content isEqualToString:@""]) {
		self.apost.content = @"";
		prefix = @"";
	}
	
	NSMutableString *content = [[NSMutableString alloc] initWithString:self.apost.content];
	NSRange imgHTML = [content rangeOfString: media.html];
	NSRange imgHTMLPre = [content rangeOfString:[NSString stringWithFormat:@"%@%@", @"<br /><br />", media.html]]; 
 	NSRange imgHTMLPost = [content rangeOfString:[NSString stringWithFormat:@"%@%@", media.html, @"<br /><br />"]];
	
	if (imgHTMLPre.location == NSNotFound && imgHTMLPost.location == NSNotFound && imgHTML.location == NSNotFound) {
		[content appendString:[NSString stringWithFormat:@"%@%@", prefix, media.html]];
        self.apost.content = content;
	}
	else {
		if (imgHTMLPre.location != NSNotFound) 
			[content replaceCharactersInRange:imgHTMLPre withString:@""]; 
		else if (imgHTMLPost.location != NSNotFound) 
			[content replaceCharactersInRange:imgHTMLPost withString:@""];
		else  
			[content replaceCharactersInRange:imgHTML withString:@""];
		[content appendString:[NSString stringWithFormat:@"<br /><br />%@", media.html]];
		self.apost.content = content;
	}
    _hasChangesToAutosave = YES;
    [self refreshUIForCurrentPost];
    [self.apost autosave];
    [self incrementCharactersChangedForAutosaveBy:content.length];
}

- (void)removeMedia:(NSNotification *)notification {
	//remove the html string for the media object
	Media *media = (Media *)[notification object];
	textView.text = [textView.text stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"<br /><br />%@", media.html] withString:@""];
	textView.text = [textView.text stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@<br /><br />", media.html] withString:@""];
	textView.text = [textView.text stringByReplacingOccurrencesOfString:media.html withString:@""];
    _hasChangesToAutosave = YES;
    [self autosaveContent];
    [self refreshUIForCurrentPost];
    [self incrementCharactersChangedForAutosaveBy:media.html.length];
}


#pragma mark - Keyboard toolbar

- (void)undo {
    [textView.undoManager undo];
    _hasChangesToAutosave = YES;
    [self autosaveContent];
}

- (void)redo {
    [textView.undoManager redo];
    _hasChangesToAutosave = YES;
    [self autosaveContent];
}

- (void)restoreText:(NSString *)text withRange:(NSRange)range {
    NSLog(@"restoreText:%@",text);
    NSString *oldText = textView.text;
    NSRange oldRange = textView.selectedRange;
    textView.scrollEnabled = NO;
    // iOS6 seems to have a bug where setting the text like so : textView.text = text;
    // will cause an infinate loop of undos.  A work around is to perform the selector
    // on the main thread.
    // textView.text = text;
    [textView performSelectorOnMainThread:@selector(setText:) withObject:text waitUntilDone:NO];
    textView.scrollEnabled = YES;
    textView.selectedRange = range;
    [[textView.undoManager prepareWithInvocationTarget:self] restoreText:oldText withRange:oldRange];
    _hasChangesToAutosave = YES;
    [self autosaveContent];
    [self incrementCharactersChangedForAutosaveBy:MAX(text.length, range.length)];
}

- (void)wrapSelectionWithTag:(NSString *)tag {
    NSRange range = textView.selectedRange;
    NSRange originalRange = range;
    NSString *selection = [textView.text substringWithRange:range];
    NSString *prefix, *suffix;
    if ([tag isEqualToString:@"ul"] || [tag isEqualToString:@"ol"]) {
        prefix = [NSString stringWithFormat:@"<%@>\n", tag];
        suffix = [NSString stringWithFormat:@"\n</%@>\n", tag];
    } else if ([tag isEqualToString:@"li"]) {
        prefix = [NSString stringWithFormat:@"\t<%@>", tag];
        suffix = [NSString stringWithFormat:@"</%@>\n", tag];
    } else if ([tag isEqualToString:@"more"]) {
        prefix = @"<!--more-->";
        suffix = @"\n";
    } else if ([tag isEqualToString:@"blockquote"]) {
        prefix = [NSString stringWithFormat:@"\n<%@>", tag];
        suffix = [NSString stringWithFormat:@"</%@>\n", tag];
    } else {
        prefix = [NSString stringWithFormat:@"<%@>", tag];
        suffix = [NSString stringWithFormat:@"</%@>", tag];        
    }
    textView.scrollEnabled = NO;
    NSString *replacement = [NSString stringWithFormat:@"%@%@%@",prefix,selection,suffix];
    textView.text = [textView.text stringByReplacingCharactersInRange:range
                                                           withString:replacement];
    textView.scrollEnabled = YES;
    if (range.length == 0) {                // If nothing was selected
        range.location += [prefix length]; // Place selection between tags
    } else {
        range.location += range.length + [prefix length] + [suffix length]; // Place selection after tag
        range.length = 0;
    }
    textView.selectedRange = range;
    _hasChangesToAutosave = YES;
    [self autosaveContent];
    [self incrementCharactersChangedForAutosaveBy:MAX(replacement.length, originalRange.length)];
}

- (void)keyboardToolbarButtonItemPressed:(WPKeyboardToolbarButtonItem *)buttonItem {
    WPFLogMethod();
    if ([buttonItem.actionTag isEqualToString:@"link"]) {
        [self showLinkView];
    } else if ([buttonItem.actionTag isEqualToString:@"done"]) {
        [self endTextEnteringButtonAction:buttonItem];
    } else {
        NSString *oldText = textView.text;
        NSRange oldRange = textView.selectedRange;
        [self wrapSelectionWithTag:buttonItem.actionTag];
        [[textView.undoManager prepareWithInvocationTarget:self] restoreText:oldText withRange:oldRange];
        [textView.undoManager setActionName:buttonItem.actionName];    
    }
}

#pragma mark  -
#pragma mark Table Data Source Methods (for Custom Fields TableView only)

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
	
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
		
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, 200, 25)];
        label.textAlignment = UITextAlignmentLeft;
        label.font = [UIFont systemFontOfSize:16];
        label.textColor = [UIColor grayColor];
        [cell.contentView addSubview:label];
    }
	
	cell.accessoryType=UITableViewCellAccessoryDisclosureIndicator;
    cell.userInteractionEnabled = YES;
    return cell;
}


#pragma mark -
#pragma mark Table delegate
- (NSIndexPath *)tableView:(UITableView *)tableView
  willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    return nil;
}


#pragma mark -
#pragma mark Keyboard management 

- (void)keyboardWillShow:(NSNotification *)notification {
    WPFLogMethod();
	isShowingKeyboard = YES;
    if (isEditing) {
        [self positionTextView:notification];
        editorToolbar.doneButton.hidden = IS_IPAD && ! isExternalKeyboard;
    }
    [self positionAutosaveView:notification];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    WPFLogMethod();
	isShowingKeyboard = NO;
    [self positionTextView:notification];
    [self positionAutosaveView:notification];
}

#pragma mark -
#pragma mark UIPopoverController delegate

- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController {
    if ((popoverController.contentViewController) && ([popoverController.contentViewController class] == [UINavigationController class])) {
        UINavigationController *nav = (UINavigationController *)popoverController.contentViewController;
        if ([nav.viewControllers count] == 2) {
            WPSegmentedSelectionTableViewController *selController = [nav.viewControllers objectAtIndex:0];
            [selController popViewControllerAnimated:YES];
        }
    }
    return YES;
}

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    WPLog(@"%@ %@", self, NSStringFromSelector(_cmd));
    [super didReceiveMemoryWarning];
}

@end
