#import "PostViewController.h"
#import "BlogDataManager.h"
#import "WordPressAppDelegate.h"
#import "EditPostViewController.h"
#import "PostPreviewViewController.h"
#import "PostSettingsViewController.h"
#import "WPNavigationLeftButtonView.h"
#import "PostsViewController.h"
#import "WPReachability.h"
#import "CommentsViewController.h"
#import "WPPublishOnEditController.h"
#import "CInvisibleToolbar.h"
#import "FlippingViewController.h"
#import "RotatingNavigationController.h"
#import "CPopoverManager.h"
#import "BlogViewController.h"

#define TAG_OFFSET 1010

@interface PostViewController (Private)

- (void)discard;

@end

@implementation PostViewController

@synthesize postDetailEditController, postPreviewController, postSettingsController, hasChanges, tabController;
@synthesize mediaViewController, isVisible, commentsViewController, spinner, isPublishing;
@synthesize selectedViewController, toolbar, contentView, commentsButton, photosButton, hasSaved;
@synthesize settingsButton, editToolbar, cancelEditButton, post, isShowingKeyboard;
@synthesize payload, connection, urlResponse, urlRequest, appDelegate;
@synthesize editMode;

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [FlurryAPI logEvent:@"Post"];

	appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
	postPreviewController = [[PostPreviewViewController alloc] initWithNibName:@"PostPreviewViewController" bundle:nil];

	spinner = [[WPProgressHUD alloc] initWithLabel:@"Saving..."];
	hasSaved = NO;
	postDetailEditController.postDetailViewController = self;
	postPreviewController.postDetailViewController = self;
	postSettingsController.postDetailViewController = self;
	mediaViewController.postDetailViewController = self;

	if (editMode == kNewPost) {
		NSMutableArray *tabs = [NSMutableArray arrayWithArray:tabController.viewControllers];
		[tabs removeObjectAtIndex:1];
		[tabController setViewControllers:tabs];
	}
		
    if(self.editMode == kEditPost)
        [self refreshUIForCurrentPost];
	else if(self.editMode == kNewPost)
        [self refreshUIForCompose];
	else if (self.editMode == kAutorecoverPost) {
        [self refreshUIForCurrentPost];
        self.hasChanges = YES;
	}
    
	self.view = tabController.view;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	
    if(self.editMode != kNewPost)
		self.editMode = kRefreshPost;
	
    [[tabController selectedViewController] viewWillAppear:animated];
	
	isVisible = YES;

	[self refreshButtons];
}

- (void)refreshButtons {
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                  target:self
                                                                                  action:@selector(cancelView:)];
    self.navigationItem.leftBarButtonItem = cancelButton;
    [cancelButton release];

    UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] init];
    saveButton.title = @"Save";
    saveButton.target = self;
    saveButton.style = UIBarButtonItemStyleDone;
    saveButton.action = @selector(saveAction:);

    if(![self.post hasRemote]) {
        if ([self.post.status isEqualToString:@"publish"]) {
            saveButton.title = @"Publish";
        } else {
            saveButton.title = @"Save";
        }
    } else {
        saveButton.title = @"Update";
    }
    self.navigationItem.rightBarButtonItem = saveButton;

    [saveButton release];
}

- (void)viewWillDisappear:(BOOL)animated {
	[self performSelectorOnMainThread:@selector(dismissKeyboard) withObject:nil waitUntilDone:NO];
	
	if(self.editMode != kNewPost)
		self.editMode = kRefreshPost;
    [postPreviewController stopLoading];
	isVisible = NO;
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewWillDisappear:animated];
}

- (void)dismissKeyboard {
    if (postDetailEditController.currentEditingTextField)
        [postDetailEditController.currentEditingTextField resignFirstResponder];
}

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
    selectedViewController = viewController;
	if (selectedViewController == mediaViewController) {
		[mediaViewController addNotifications];
	} else {
		[mediaViewController removeNotifications];
	}
}

- (IBAction)cancelAction:(id)sender {
	[postDetailEditController.textView resignFirstResponder];
}

- (IBAction)cancelView:(id)sender {
    [FlurryAPI logEvent:@"Post#cancelView"];
    if (!hasChanges) {
        [self discard];
        return;
    }
    [FlurryAPI logEvent:@"Post#cancelView(actionSheet)"];
	[postSettingsController endEditingAction:nil];
	[postDetailEditController endEditingAction:nil];

    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"You have unsaved changes."
                                  delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Discard"
                                  otherButtonTitles:nil];
    actionSheet.tag = 201;
    actionSheet.actionSheetStyle = UIActionSheetStyleAutomatic;
    [actionSheet showInView:self.view];
    [appDelegate setAlertRunning:YES];

    [actionSheet release];
}

- (IBAction)saveAction:(id)sender {
    self.post.postTitle = postDetailEditController.titleTextField.text;
    self.post.tags = postDetailEditController.tagsTextField.text;
    self.post.content = postDetailEditController.textView.text;

    [self.tabController.selectedViewController.view endEditing:YES];
    [self.post.original applyRevision];
    [self.post.original upload];
    [self dismissEditView];
}

- (void)resignTextView {
	[postDetailEditController resignTextView];
}

- (void)showError {
	NSString *msg = [NSString stringWithFormat:@"Sorry, something went wrong."];
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Post Error"
                                                    message:msg
                                                   delegate:self
                                          cancelButtonTitle:nil
                                          otherButtonTitles:@"OK", nil];
	alert.tag = TAG_OFFSET;
	[alert show];
	[appDelegate setAlertRunning:YES];
	[alert release];

	// Dismiss spinner
	[spinner dismissWithClickedButtonIndex:0 animated:YES];
	return;
}

- (void)refreshUIForCompose {
	self.navigationItem.title = @"Write";

    [tabController setSelectedViewController:[[tabController viewControllers] objectAtIndex:0]];

    [postDetailEditController refreshUIForCompose];
    [postSettingsController reloadData];
    //[photosListController refreshData];

    [self updatePhotosBadge];
}

- (void)refreshUIForCurrentPost {	
	if(post != nil) {
		self.navigationItem.title = post.postTitle;
		
		[tabController setSelectedViewController:[[tabController viewControllers] objectAtIndex:0]];
		[postDetailEditController refreshUIForCurrentPost];
		[postSettingsController reloadData];
		//[photosListController refreshData];
		
		[commentsViewController setIndexForCurrentPost:[[BlogDataManager sharedDataManager] currentPostIndex]];
		[commentsViewController refreshCommentsList];
		commentsButton.enabled = ([commentsViewController.commentsArray count] > 0);
	}

    [self updatePhotosBadge];
	
	if (self.editMode == kAutorecoverPost && DeviceIsPad()) {
		[self editAction:self];
	}
}

- (void)updatePhotosBadge {
    int photoCount = [[[BlogDataManager sharedDataManager].currentPost valueForKey:@"Photos"] count];

	if (tabController) {
		if (photoCount)
			mediaViewController.tabBarItem.badgeValue = [NSString stringWithFormat:@"%d", photoCount];
		else
			mediaViewController.tabBarItem.badgeValue = nil;
	} else if (toolbar) {
		if (!photoCount)
			photosButton.title = @"No media";
		else if (photoCount == 1)
			photosButton.title = @"1 media item.";
		else
			photosButton.title = [NSString stringWithFormat:@"%d media items.", photoCount];
	}
}

#pragma mark -
#pragma mark UIActionSheetDelegate methods

- (void)discard {
    [FlurryAPI logEvent:@"Post#actionSheet_discard"];
    hasChanges = NO;
    [mediaViewController cancelPendingUpload:self];

	// TODO: remove the mediaViewController notifications - this is pretty kludgy
	[mediaViewController removeNotifications];
    [self.post.original deleteRevision];
    self.post = nil; // Just in case
    [self dismissEditView];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([actionSheet tag] == 201) {
        if (buttonIndex == 0) {
            [self discard];
        }

        if (buttonIndex == 1) {
            [self saveAction:self];
        }
    }

    [appDelegate setAlertRunning:NO];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag != TAG_OFFSET) {
        [self discard];
    }

    [appDelegate setAlertRunning:NO];
}

- (void)setHasChanges:(BOOL)aFlag {
    if (hasChanges == aFlag)
        return;

    hasChanges = aFlag;
	
    NSNumber *postEdited = [NSNumber numberWithBool:hasChanges];
    [[[BlogDataManager sharedDataManager] currentPost] setObject:postEdited forKey:@"hasChanges"];
}

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    WPLog(@"%@ %@", self, NSStringFromSelector(_cmd));
    [super didReceiveMemoryWarning];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// iPad apps should always autorotate
	if (DeviceIsPad() == YES) {
		return YES;
	}
	
    if ([appDelegate isAlertRunning] == YES) {
        return NO;
    }

    if ((interfaceOrientation == UIInterfaceOrientationPortrait) || (interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown)) {
        //[postDetailEditController setTextViewHeight:202];
		return YES;
    }

    if ((interfaceOrientation == UIInterfaceOrientationLandscapeLeft) || (interfaceOrientation == UIInterfaceOrientationLandscapeRight)) {
        if (self.interfaceOrientation != interfaceOrientation) {
            if (postDetailEditController.isEditing == NO) {
              //  [postDetailEditController setTextViewHeight:57]; //#148
            } else {
                //[postDetailEditController setTextViewHeight:116];
				return YES;
            }
        }
    }

	if ([tabController.selectedViewController.title isEqualToString:@"Settings"])
		return NO;

    //return YES;
	return NO; //trac ticket #148
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	//[self.selectedViewController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    if ([tabController.selectedViewController.title isEqualToString:@"Settings"]) {
        [postSettingsController.tableView reloadData];
    }
}

#pragma mark -
#pragma mark iPad actions

- (UINavigationItem *)navigationItemForEditPost {
	if (DeviceIsPad() == NO) {
		return self.navigationItem;
	} else if (DeviceIsPad() == YES) {
		return postDetailEditController.navigationItem;
	}
	return nil;
}

- (UIBarButtonItem *)rightBarButtonItemForEditPost {
	if (DeviceIsPad() == NO) {
		return self.navigationItem.rightBarButtonItem;
	} else if (DeviceIsPad() == YES) {
		return [editToolbar.items lastObject];
	}
	return nil;
}

- (void)publish:(id)sender {
    [FlurryAPI logEvent:@"Post#publish"];
	isPublishing = YES;

    postDetailEditController.isLocalDraft = NO;
	postDetailEditController.statusTextField.text = @"Published";
	
    post.status = @"publish";
	
	[self saveAction:sender];
}

- (void)setRightBarButtonItemForEditPost:(UIBarButtonItem *)item;
{
	if (DeviceIsPad() == NO) {
		self.navigationItem.rightBarButtonItem = item;
	} else if (DeviceIsPad() == YES) {
		NSArray *currentItems = editToolbar.items;
		if (currentItems.count < 1) return;
		// TODO: uuuugly
		NSMutableArray *newItems = [NSMutableArray arrayWithArray:currentItems];

		// if we have an item, replace our last item with it;
		// if it's nil, just gray out the current last item.
		// It's this sort of thing that keeps me from sleeping at night.
		if (item) {
			[newItems replaceObjectAtIndex:(newItems.count - 1) withObject:item];
			[item setEnabled:YES];
		}
		else {
			[[newItems objectAtIndex:(newItems.count - 1)] setEnabled:NO];
		}

		[editToolbar setItems:newItems animated:YES];
	}
}

- (IBAction)editAction:(id)sender {
	self.editMode = kEditPost;
	[postDetailEditController refreshUIForCurrentPost];
	[appDelegate showContentDetailViewController:self.postDetailEditController];
}

- (IBAction)locationAction:(id)sender {
	if(DeviceIsPad()) {
		PostLocationViewController *locationView = [[PostLocationViewController alloc] initWithNibName:@"PostLocationViewController" bundle:nil];
		locationView.contentSizeForViewInPopover = locationView.contentSizeForViewInPopover;
		UINavigationController *navController = [[[UINavigationController alloc] initWithRootViewController:locationView] autorelease];
		UIPopoverController *popover = [[[NSClassFromString(@"UIPopoverController") alloc] initWithContentViewController:navController] autorelease];
		[popover presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
		[[CPopoverManager instance] setCurrentPopoverController:popover];
		[locationView release];
	}
	else
		[postDetailEditController showLocationMapView:sender];
}

- (void)dismissEditView {
	if (DeviceIsPad() == NO) {
        [appDelegate.navigationController popViewControllerAnimated:YES];
	} else {
		[self dismissModalViewControllerAnimated:YES];
		[[BlogDataManager sharedDataManager] loadDraftTitlesForCurrentBlog];
		[[BlogDataManager sharedDataManager] loadPostTitlesForCurrentBlog];
		
		UIViewController *theTopVC = [[WordPressAppDelegate sharedWordPressApp].masterNavigationController topViewController];
		if ([theTopVC respondsToSelector:@selector(reselect)])
			[theTopVC performSelector:@selector(reselect)];
	}

	// TODO: remove the mediaViewController notifications - this is pretty kludgy
	[FlurryAPI logEvent:@"PostView#dismissEditView"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"PostEditorDismissed" object:self];
	[mediaViewController removeNotifications];
}


- (void)setMode:(EditPostMode)newMode {
	self.editMode = newMode;
}

#pragma mark -
#pragma mark Photo list delegate: iPad

- (void)displayPhotoListImagePicker:(UIImagePickerController *)picker;
{
	if (!photoPickerPopover) {
		photoPickerPopover = [[NSClassFromString(@"UIPopoverController") alloc] initWithContentViewController:picker];
	}
	//picker.contentSizeForViewInPopover = photosListController.contentSizeForViewInPopover;
	photoPickerPopover.contentViewController = picker;


	// TODO: this is pretty kludgy
	UIBarButtonItem *buttonItem = [editToolbar.items objectAtIndex:1];
	[photoPickerPopover presentPopoverFromBarButtonItem:buttonItem permittedArrowDirections:UIPopoverArrowDirectionAny animated:NO];
	[[CPopoverManager instance] setCurrentPopoverController:photoPickerPopover];
}

- (void)hidePhotoListImagePicker;
{
	[photoPickerPopover dismissPopoverAnimated:NO];

	// TODO: this is pretty kludgy
	UIBarButtonItem *buttonItem = [editToolbar.items objectAtIndex:1];
	[popoverController presentPopoverFromBarButtonItem:buttonItem permittedArrowDirections:UIPopoverArrowDirectionAny animated:NO];
	[[CPopoverManager instance] setCurrentPopoverController:photoPickerPopover];
}

- (IBAction)addPhotoAction:(id)sender {
	
}

#pragma mark -
#pragma mark NSURLConnection delegate

- (void)verifyPublishSuccessful {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	
	NSArray *params = [NSArray arrayWithObjects:
					   appDelegate.postID,
                       self.post.blog.username,
					   self.post.blog.password,
					   nil];
	
	// Execute the XML-RPC request
	XMLRPCRequest *request = [[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:self.post.blog.xmlrpc]];
	[request setMethod:@"metaWeblog.getPost" withObjects:params];
	
	connection = [[NSURLConnection alloc] initWithRequest:[request request] delegate:self];
    [request release];
	if (connection) {
		payload = [[NSMutableData data] retain];
	}
	//[xmlrpcRequest release];
}

- (void)stop {
	[connection cancel];
}

- (void)connection:(NSURLConnection *)conn didReceiveResponse:(NSURLResponse *)response {	
	[self.payload setLength:0];
	[self setUrlResponse:response];
}

- (void)connection:(NSURLConnection *)conn didReceiveData:(NSData *)data {
	[self.payload appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)conn {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	conn = nil;
	
	if(payload != nil)
	{
		NSString  *str = [[NSString alloc] initWithData:payload encoding:NSUTF8StringEncoding];
		if ( ! str ) {
			str = [[NSString alloc] initWithData:payload encoding:[NSString defaultCStringEncoding]];
			payload = (NSMutableData *)[[str dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES] retain];
		}
		
		if ([urlResponse isKindOfClass:[NSHTTPURLResponse class]]) {
			if ([(NSHTTPURLResponse *)urlResponse statusCode] < 400) {
				XMLRPCResponse *xmlrpcResponse = [[XMLRPCResponse alloc] initWithData:payload];
				
				
				if (![xmlrpcResponse isKindOfClass:[NSError class]]) {
					NSDictionary *responseMeta = [xmlrpcResponse object];
					NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
					[f setNumberStyle:NSNumberFormatterDecimalStyle];
					if(appDelegate.postID != nil) {
						NSNumber *publishedPostID = [f numberFromString:appDelegate.postID];
						NSNumber *newPostID = [responseMeta objectForKey:@"postid"];
						@try {
							if([publishedPostID isEqualToNumber:newPostID]) {
								[appDelegate setPostID:nil];
								NSDictionary *info = [[NSDictionary alloc] initWithObjectsAndKeys:post.postID, @"postID", nil];
								[[NSNotificationCenter defaultCenter] postNotificationName:@"LocalDraftWasPublishedSuccessfully" object:nil userInfo:info];
								[self setPost:nil];
								[info release];
							}
						} 
						@catch (id exception) {
							NSLog(@"%@", exception);
						} 
						
					}
                    [f release];
				}
				
				[xmlrpcResponse release];
			}
			
		}
		
		[str release];
	}
}

- (void)connection:(NSURLConnection *)conn didFailWithError:(NSError *)error {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	[self setPost:nil];
	[appDelegate setPostID:nil];
}

#pragma mark -
#pragma mark Dealloc

- (void)dealloc {
    self.post = nil;

    [payload release];
    [connection release];
    [urlResponse release];
    [urlRequest release];
    [postDetailEditController release];
    [postPreviewController release];
    [postSettingsController release];
    [mediaViewController release];
    [commentsViewController release];
    [toolbar release];
    [contentView release];
    [photoPickerPopover release];
    [commentsButton release];
    [photosButton release];
    [settingsButton release];

    [super dealloc];
}

@end
