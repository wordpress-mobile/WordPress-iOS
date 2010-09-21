#import "PostViewController.h"
#import "BlogDataManager.h"
#import "WordPressAppDelegate.h"
#import "EditPostViewController.h"
#import "PostPreviewViewController.h"
#import "PostSettingsViewController.h"
#import "WPNavigationLeftButtonView.h"
#import "PostsViewController.h"
#import "Reachability.h"
#import "CommentsViewController.h"
#import "WPPublishOnEditController.h"
#import "CInvisibleToolbar.h"
#import "FlippingViewController.h"
#import "RotatingNavigationController.h"
#import "CPopoverManager.h"
#import "BlogViewController.h"

#define TAG_OFFSET 1010

@interface PostViewController (Private)

- (void)startTimer;
- (void)stopTimer;

- (void)discard;
- (void)cancel;

@end

@implementation PostViewController

@synthesize postDetailViewController, postDetailEditController, postPreviewController, postSettingsController, postsListController, hasChanges, tabController;
@synthesize mediaViewController, leftView, isVisible, commentsViewController, spinner, isPublishing, dm;
@synthesize selectedViewController, toolbar, contentView, commentsButton, photosButton, hasSaved;
@synthesize settingsButton, editToolbar, cancelEditButton, post, didConvertDraftToPublished, isShowingKeyboard;
@synthesize payload, connection, urlResponse, urlRequest, appDelegate, autosaveView, isShowingAutosaves;
@synthesize autosaveManager, draftManager, editMode, wasLocalDraft;

@dynamic leftBarButtonItemForEditPost;

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
	dm = [BlogDataManager sharedDataManager];
	appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
	autosaveView = [[AutosaveViewController alloc] initWithNibName:@"AutosaveViewController" bundle:nil];
	postPreviewController = [[PostPreviewViewController alloc] initWithNibName:@"PostPreviewViewController" bundle:nil];
	autosaveManager = [[AutosaveManager alloc] init];
	draftManager = [[DraftManager alloc] init];
	
	spinner = [[WPProgressHUD alloc] initWithLabel:@"Saving..."];
	hasSaved = NO;
	postDetailEditController.postDetailViewController = self;
	postPreviewController.postDetailViewController = self;
	postSettingsController.postDetailViewController = self;
	mediaViewController.postDetailViewController = self;
	autosaveView.postDetailViewController = self;
	
	if(editMode == kNewPost) {
		NSMutableArray *tabs = [NSMutableArray arrayWithArray:tabController.viewControllers];
		[tabs removeObjectAtIndex:1];
		[tabController setViewControllers:tabs];
	}
	
	BOOL clearAutosaves = [[NSUserDefaults standardUserDefaults] boolForKey:@"autosave_clear_preference"];
	if(clearAutosaves == YES) {
		[autosaveManager removeAll];
		[[NSUserDefaults standardUserDefaults] setValue:NO forKey:@"autosave_clear_preference"];
	}
	
	if (DeviceIsPad() == NO) {
	    if (!leftView) {
			leftView = [WPNavigationLeftButtonView createCopyOfView];
			[leftView setTitle:@"Posts"];
		}
	}
	
    if(self.editMode == kEditPost)
        [self refreshUIForCurrentPost];
	else if(self.editMode == kNewPost)
        [self refreshUIForCompose];
	else if (self.editMode == kAutorecoverPost) {
        [self refreshUIForCurrentPost];
        self.hasChanges = YES;
	}

	[self refreshButtons];
	self.view = tabController.view;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	
	if (DeviceIsPad() == NO) {
		if ((self.interfaceOrientation == UIInterfaceOrientationPortrait) || (self.interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown)) {
			//[postDetailEditController setTextViewHeight:202];
		}
		
		if ((self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft) || (self.interfaceOrientation == UIInterfaceOrientationLandscapeRight)) {
			if (postDetailEditController.isEditing == NO) {
				//[postDetailEditController setTextViewHeight:57]; //#148
			} else {
				//[postDetailEditController setTextViewHeight:116];
			}
		}
	}
	
    [leftView setTarget:self withAction:@selector(cancelView:)];
	
    if (hasChanges == YES) {
        if ([[leftView title] isEqualToString:@"Posts"])
            [leftView setTitle:@"Cancel"];
    }
	else {
        [leftView setTitle:@"Posts"];
    }
	
	if (DeviceIsPad() == NO) {
		UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithCustomView:leftView];
		self.leftBarButtonItemForEditPost = cancelButton;
		[cancelButton release];
	}
	
    if(self.editMode != kNewPost)
		self.editMode = kRefreshPost;
	
    [commentsViewController setIndexForCurrentPost:[[BlogDataManager sharedDataManager] currentPostIndex]];
    [[tabController selectedViewController] viewWillAppear:animated];
	
	isVisible = YES;

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(restoreFromAutosave:) name:@"RestoreFromAutosaveNotification" object:nil];
	[self checkAutosaves];
	[self refreshButtons];
}

- (void)refreshButtons {
	if(self.hasChanges == YES) {
		TransparentToolbar *buttonBar = [[TransparentToolbar alloc] initWithFrame:CGRectMake(0, 0, 124, 44)];
		NSMutableArray *buttons = [[NSMutableArray alloc] initWithCapacity:3];
		
		UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] init];
		saveButton.title = @"Save";
		saveButton.target = self;
		saveButton.style = UIBarButtonItemStyleBordered;
		saveButton.action = @selector(saveAction:);
		[buttons addObject:saveButton];
		[saveButton release];
		
		if([postDetailEditController isPostPublished] == NO) {
			UIBarButtonItem *spacer = [[UIBarButtonItem alloc]
									   initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
									   target:nil
									   action:nil];
			[buttons addObject:spacer];
			[spacer release];
			
			UIBarButtonItem *publishButton = [[UIBarButtonItem alloc] init];
			publishButton.title = @"Publish";
			publishButton.target = self;
			publishButton.style = UIBarButtonItemStyleDone;
			publishButton.action = @selector(publish:);
			[buttons addObject:publishButton];
			[publishButton release];
		}
		else {
			buttonBar.frame = CGRectMake(0, 0, 52, 44);
			saveButton.style = UIBarButtonItemStyleDone;
		}

		
		[buttonBar setItems:buttons animated:NO];
		[buttons release];
		
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:buttonBar];
		[buttonBar release];
	}
	else {
		self.navigationItem.rightBarButtonItem = nil;
	}
}

- (void)viewWillDisappear:(BOOL)animated {
	if (DeviceIsPad() == NO) {
		if ((self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft) || (self.interfaceOrientation == UIInterfaceOrientationLandscapeRight)) {
			//[postDetailEditController setTextViewHeight:202];
		}
	}
	
	//    [photoEditingStatusView removeFromSuperview];
	
    if (postDetailEditController.currentEditingTextField)
        [postDetailEditController.currentEditingTextField resignFirstResponder];
	
	if(self.editMode != kNewPost)
		self.editMode = kRefreshPost;
    [postPreviewController stopLoading];
	isVisible = NO;
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewWillDisappear:animated];
}

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
    selectedViewController = viewController;
}

- (IBAction)cancelAction:(id)sender {
	[postDetailEditController.textView resignFirstResponder];
}

- (IBAction)cancelView:(id)sender {
    if (!hasChanges) {
        [self stopTimer];
		[self dismissEditView];
        return;
    }
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
	if(isPublishing == NO)
		spinner.progressMessage.text = @"Saving...";
	else
		spinner.progressMessage.text = @"Publishing...";
	
	[self.postDetailEditController refreshCurrentPostForUI];
	
	[spinner show];
	[self performSelectorInBackground:@selector(saveInBackground) withObject:nil];
}

- (void)saveInBackground {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	[postDetailEditController.textView resignFirstResponder];
	hasSaved = YES;
	
	if((self.post != nil) && (post.wasLocalDraft == [NSNumber numberWithInt:1]) && (post.isLocalDraft == [NSNumber numberWithInt:0]))
		self.didConvertDraftToPublished = YES;
	
	if((self.post == nil) || (self.post.isLocalDraft == [NSNumber numberWithInt:0])) {
		if ([[Reachability sharedReachability] internetConnectionStatus] == NotReachable) {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Communication Error."
															message:@"no internet connection."
														   delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
			alert.tag = TAG_OFFSET;
			[alert show];
			
			[appDelegate setAlertRunning:YES];
			[alert release];
		}
		else {
			if (!hasChanges) {
				[self stopTimer];
				[self dismissEditView];
			}
			else {
				if(post.isLocalDraft == [NSNumber numberWithInt:1]) {
					post.isLocalDraft = [NSNumber numberWithInt:0];
					post.wasLocalDraft = [NSNumber numberWithInt:1];
					
					[[BlogDataManager sharedDataManager] makeNewPostCurrent];
					[postDetailEditController updateValuesToCurrentPost];
					postDetailEditController.isLocalDraft = NO;
				}
				[(NSMutableDictionary *)[BlogDataManager sharedDataManager].currentPost setValue:@"" forKey:@"mt_text_more"];
				[postSettingsController endEditingAction:nil];
				
				NSString *description = [dm.currentPost valueForKey:@"description"];
				NSString *title = [dm.currentPost valueForKey:@"title"];
				NSArray *photos = [dm.currentPost valueForKey:@"Photos"];
				
				if ((!description ||[description isEqualToString:@""]) &&
					(!title ||[title isEqualToString:@""]) &&
					(!photos || ([photos count] == 0))) {
					NSString *msg = [NSString stringWithFormat:@"Please provide either a title or description or attach photos to the post before saving."];
					UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Post Error"
																	message:msg
																   delegate:self
														  cancelButtonTitle:nil
														  otherButtonTitles:@"OK", nil];
					alert.tag = TAG_OFFSET;
					[alert show];
					[appDelegate setAlertRunning:YES];
					[alert release];
					
					[self cancel];
				}
				else if (![dm postDescriptionHasValidDescription:dm.currentPost]) {
					[self cancel];
				}
				else {
					if(wasLocalDraft == YES) {
						[dm.currentPost setObject:[NSNumber numberWithInt:1] forKey:@"isLocalDraft"];
						wasLocalDraft = YES;
					}
					
					BOOL savePostStatus = [dm savePost:dm.currentPost];
					NSString *postID = [dm.currentPost objectForKey:@"postid"];
					NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
					[self stopTimer];
					
					if(savePostStatus == YES) {
						[dm removeAutoSavedCurrentPostFile];
						[dict setValue:postID forKey:@"savedPostId"];
						[appDelegate setPostID:postID];
						[dict setValue:[[dm currentPost] valueForKey:@"postid"] forKey:@"originalPostId"];
						[dict setValue:[NSNumber numberWithInt:0] forKey:@"isCurrentPostDraft"];
					}
					
					if(wasLocalDraft == NO)
						[[NSNotificationCenter defaultCenter] postNotificationName:@"AsynchronousPostIsPosted" object:nil userInfo:dict];
					
					[dict release];
					
					if (DeviceIsPad() == YES) {
						[[BlogDataManager sharedDataManager] makePostWithPostIDCurrent:postID];
					}
					
					[postID release];
				}
			}
		}
	}
	else {
		[self saveAsDraft];
	}
	
	[self performSelectorOnMainThread:@selector(didSaveInBackground) withObject:nil waitUntilDone:NO];
	
	[pool release];
}

- (void)didSaveInBackground {
	isPublishing = NO;
	hasChanges = NO;
	[self refreshUIForCompose];
	[self verifyPublishSuccessful];
	if(DeviceIsPad() == NO) {
		[self.navigationController popViewControllerAnimated:YES];
	}
	else {
		if(wasLocalDraft == YES)
			[[NSNotificationCenter defaultCenter] postNotificationName:@"DraftsUpdated" object:nil];
		else
			[[NSNotificationCenter defaultCenter] postNotificationName:@"ShouldRefreshPosts" object:nil];
		
	}
	[postDetailEditController clearUnsavedPost];
	[spinner dismissWithClickedButtonIndex:0 animated:YES];
}

- (void)autoSaveCurrentPost:(NSTimer *)aTimer {
	[postDetailEditController preserveUnsavedPost];
	if (hasChanges) {
		Post *autosave = [autosaveManager get:nil];
		
		if(postDetailEditController.isLocalDraft == YES)
			[autosave setIsLocalDraft:[NSNumber numberWithInt:1]];
		else
			[autosave setIsLocalDraft:[NSNumber numberWithInt:0]];
		[autosave setIsAutosave:[NSNumber numberWithInt:1]];
		[autosave setIsHidden:[NSNumber numberWithInt:1]];
		if([postDetailEditController isPostPublished] == YES)
			[autosave setIsPublished:[NSNumber numberWithInt:1]];
		else
			[autosave setIsPublished:[NSNumber numberWithInt:0]];
		[autosave setBlogID:[[dm currentBlog] valueForKey:@"blogid"]];

		if(appDelegate.postID != nil)
			[autosave setPostID:appDelegate.postID];
		else if(([[dm currentPost] valueForKey:@"postid"] != nil) && (![[[dm currentPost] valueForKey:@"postid"] isEqualToString:@""])) {
			NSString *autosavePostID = [NSString stringWithFormat:@"%@-%@",
										[[dm currentBlog] valueForKey:@"url"],
										[[dm currentPost] valueForKey:@"postid"]];
			[autosave setPostID:autosavePostID];
		}
		else
			[autosave setPostID:appDelegate.postID];
		
		[autosave setPostTitle:postDetailEditController.titleTextField.text];
		[autosave setContent:postDetailEditController.textView.text];
		[autosave setDateCreated:[NSDate date]];
		[autosave setStatus:postDetailEditController.statusTextField.text];
		if(postSettingsController.passwordTextField.text != nil)
			[autosave setPassword:postSettingsController.passwordTextField.text];
		[autosaveManager save:autosave];
		[self checkAutosaves];
    }
}

- (void)startTimer {
	BOOL autosaveEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"autosave_enabled_preference"];
    if ((!autoSaveTimer) && (autosaveEnabled == YES)) {
		NSString *autosaveIntervalString = [[NSUserDefaults standardUserDefaults] stringForKey:@"autosave_frequency_preference"];
		int autosaveInterval = [autosaveIntervalString intValue];
		autosaveInterval = autosaveInterval * 60;
		if(autosaveInterval < 60)
			autosaveInterval = 60;
		
        autoSaveTimer = [[NSTimer scheduledTimerWithTimeInterval:autosaveInterval target:self selector:@selector(autoSaveCurrentPost:) userInfo:nil repeats:YES] retain];
    }
}

- (void)stopTimer {
    if (autoSaveTimer) {
        [autoSaveTimer invalidate];
        [autoSaveTimer release];
        autoSaveTimer = nil;
    }
}

- (void)refreshUIForCompose {
	if(draftManager == nil)
		draftManager = [[DraftManager alloc] init];
	
	postDetailViewController.navigationItem.title = @"Write";
	
	if(tabController.viewControllers.count > 4) {
		NSMutableArray *tabs = [NSMutableArray arrayWithArray:tabController.viewControllers];
		[tabs removeObjectAtIndex:1];
		[tabController setViewControllers:tabs];
	}
	
	post = nil;
	post = [draftManager get:appDelegate.postID];
	[self.post setWasLocalDraft:[NSNumber numberWithInt:1]];
	[self.post setIsLocalDraft:[NSNumber numberWithInt:1]];
	[self.post setIsPublished:[NSNumber numberWithInt:0]];
	appDelegate.postID = self.post.postID;
	self.autosaveView.postID = self.post.postID;
	[self refreshButtons];
	
    [tabController setSelectedViewController:[[tabController viewControllers] objectAtIndex:0]];

	[postDetailViewController refreshUIForCompose];
    [postDetailEditController refreshUIForCompose];
    [postSettingsController reloadData];
    //[photosListController refreshData];

    [self updatePhotosBadge];
	[self checkAutosaves];
}

- (void)refreshUIForCurrentPost {
	autosaveView.postID = appDelegate.postID;
	
	if(post == nil) {
		self.navigationItem.title = @"Write";
		
		[tabController setSelectedViewController:[[tabController viewControllers] objectAtIndex:0]];
		[postDetailViewController refreshUIForCurrentPost];[postDetailEditController refreshUIForCurrentPost];
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
	[self checkAutosaves];
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

- (IBAction)saveAsDraft {
	[self saveAsDraft:YES];
}

- (void)saveAsDraft:(BOOL)andDiscard {
	hasSaved = YES;
	
	if((post != nil) && (appDelegate.postID != nil))
		post = [draftManager get:appDelegate.postID];
	else
		post = [draftManager get:nil];
	[post setIsLocalDraft:[NSNumber numberWithInt:1]];
	[post setWasLocalDraft:[NSNumber numberWithInt:1]];
	[post setIsAutosave:[NSNumber numberWithInt:0]];
	[post setIsPublished:[NSNumber numberWithInt:0]];
	[post setBlogID:[[[BlogDataManager sharedDataManager] currentBlog] valueForKey:@"blogid"]];
	[post setPostTitle:postDetailEditController.titleTextField.text];
	[post setContent:postDetailEditController.textView.text];
	[post setCategories:postDetailEditController.categoriesTextField.text];
	[post setTags:postDetailEditController.tagsTextField.text];
	[post setDateCreated:[NSDate date]];
	if(postSettingsController.passwordTextField.text != nil)
		[post setPassword:postSettingsController.passwordTextField.text];
	[draftManager save:post];
	[postsListController loadPosts];
	
	[postDetailEditController clearUnsavedPost];
	[self performSelectorOnMainThread:@selector(didSaveInBackground) withObject:nil waitUntilDone:NO];
	
	if(andDiscard == YES)
		[self discard];
}

- (void)discard {
    hasChanges = NO;
	[self refreshButtons];
	[postDetailEditController clearUnsavedPost];
    [self stopTimer];
	if(DeviceIsPad() == NO)
		[self.navigationController popViewControllerAnimated:YES];
}

- (void)cancel {
    hasChanges = YES;

    if ([[leftView title] isEqualToString:@"Posts"])
        [leftView setTitle:@"Cancel"];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([actionSheet tag] == 201) {
        if (buttonIndex == 0) {
            [self discard];
        }

        if (buttonIndex == 1) {
            [self cancel];
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
    if (hasChanges == NO && aFlag == YES)
        [self startTimer];

    hasChanges = aFlag;

    if (hasChanges) {
        if ([[leftView title] isEqualToString:@"Posts"])
            [leftView setTitle:@"Cancel"];
    }
	
	[self refreshButtons];

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

- (UIBarButtonItem *)leftBarButtonItemForEditPost {
	return [self navigationItemForEditPost].leftBarButtonItem;
}

- (void)setLeftBarButtonItemForEditPost:(UIBarButtonItem *)item {
	if (DeviceIsPad() == NO)
		self.navigationItem.leftBarButtonItem = item;
	else if (DeviceIsPad() == YES)
		postDetailEditController.navigationItem.leftBarButtonItem = item;
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
	isPublishing = YES;
	
	if(post.isLocalDraft == [NSNumber numberWithInt:1]) {
		post.isLocalDraft = [NSNumber numberWithInt:0];
		post.wasLocalDraft = [NSNumber numberWithInt:1];
		
		[[BlogDataManager sharedDataManager] makeNewPostCurrent];
		[postDetailEditController updateValuesToCurrentPost];
		postDetailEditController.isLocalDraft = NO;
	}
	postDetailEditController.statusTextField.text = [dm statusDescriptionForStatus:@"Published" fromBlog:dm.currentBlog];
	
	[dm.currentPost setObject:@"publish" forKey:@"post_status"];
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
	[appDelegate showContentDetailViewController:self.postDetailViewController];
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
}


- (void)setMode:(EditPostMode)newMode {
	self.editMode = newMode;
}

#pragma mark -
#pragma mark Autosave methods

// TODO: Move Autosave data methods to their own class

- (IBAction)toggleAutosaves:(id)sender {
	self.editMode = kEditPost;
	
	if(self.isShowingAutosaves == NO)
		[self showAutosaves];
	else
		[self hideAutosaves];
}

- (void)showAutosaves {
	autosaveView.postID = appDelegate.postID;
	[autosaveView resetAutosaves];
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:1.0];
	[UIView setAnimationTransition:UIViewAnimationTransitionFlipFromRight
						   forView:postDetailEditController.view
							 cache:YES];
	[postDetailEditController.view addSubview:autosaveView.view];
	[UIView commitAnimations];
	
	self.isShowingAutosaves = YES;
}

- (void)hideAutosaves {
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:1.0];
	[UIView setAnimationTransition:UIViewAnimationTransitionFlipFromRight
						   forView:postDetailEditController.view
							 cache:YES];
	[autosaveView.view removeFromSuperview];
	[UIView commitAnimations];
	
	self.isShowingAutosaves = NO;
}

- (void)checkAutosaves {
	if(([[dm currentPost] valueForKey:@"postid"] != nil) && (![[[dm currentPost] valueForKey:@"postid"] isEqualToString:@""])) {
		NSString *autosavePostID = [NSString stringWithFormat:@"%@-%@",
									[[dm currentBlog] valueForKey:@"url"],
									[[dm currentPost] valueForKey:@"postid"]];
		[appDelegate setPostID:autosavePostID];
	}
	
	if((appDelegate.postID != nil) && (appDelegate.managedObjectContext != nil)) {
		[autosaveView setPostID:appDelegate.postID];
		[autosaveView resetAutosaves];
		if(([autosaveView autosaves] != nil) && ([[autosaveView autosaves] count] > 0)) {
			[postDetailEditController showAutosaveButton];
		}
		else
			[postDetailEditController hideAutosaveButton];
	}
}

- (void)restoreFromAutosave:(NSNotification *)notification {
	NSDictionary *restoreData = [notification userInfo];
	NSString *uniqueID = [restoreData objectForKey:@"uniqueID"];	
	Post *autosave = [autosaveManager get:uniqueID];
	
	if(autosave != nil) {
		if([autosave.isPublished isEqualToNumber:[NSNumber numberWithInt:0]]) {
			[post setPostTitle:autosave.postTitle];
			[post setContent:autosave.content];
			[post setTags:autosave.tags];
			[post setCategories:autosave.categories];
			[post setStatus:autosave.status];
			[post setPostID:autosave.postID];
			[postDetailEditController refreshUIForCurrentPost];
		}
		else {
			appDelegate.postID = autosave.postID;
			[dm makePostWithPostIDCurrent:autosave.postID];
			if(autosave.postTitle != nil)
				[[dm currentPost] setObject:autosave.postTitle forKey:@"title"];
			if(autosave.content != nil)
				[[dm currentPost] setObject:autosave.content forKey:@"description"];
			if(autosave.tags != nil)
				[[dm currentPost] setObject:autosave.tags forKey:@"mt_keywords"];
			if(autosave.categories != nil)
				[[dm currentPost] setObject:[autosave.categories componentsSeparatedByString:@", "] forKey:@"categories"];
			if(autosave.status != nil) {
				autosave.status = [dm statusDescriptionForStatus:autosave.status fromBlog:[dm currentBlog]];
				[[dm currentPost] setValue:autosave.status forKey:@"post_status"];
			}
			
			[postDetailEditController refreshUIForCurrentPost];
		}
		[autosaveManager removeAllForPostID:autosave.postID];
		[autosaveView resetAutosaves];
		[self toggleAutosaves:self];
		[postDetailEditController hideAutosaveButton];
	}
	
	hasChanges = YES;
	[self refreshButtons];
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
					   [dm.currentBlog objectForKey:@"username"],
					   [dm getPasswordFromKeychainInContextOfCurrentBlog:dm.currentBlog],
					   nil];
	
	// Execute the XML-RPC request
	XMLRPCRequest *request = [[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:[dm.currentBlog valueForKey:@"xmlrpc"]]];
	[request setMethod:@"metaWeblog.getPost" withObjects:params];
	[params release];
	
	connection = [[NSURLConnection alloc] initWithRequest:[request request] delegate:self];
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
					NSNumber *publishedPostID = [f numberFromString:appDelegate.postID];
					NSNumber *newPostID = [responseMeta valueForKey:@"postid"];
					[f release];
					if([publishedPostID isEqualToNumber:newPostID]) {
						[appDelegate setPostID:nil];
						NSDictionary *info = [[NSDictionary alloc] initWithObjectsAndKeys:post.uniqueID, @"uniqueID", nil];
						[[NSNotificationCenter defaultCenter] postNotificationName:@"LocalDraftWasPublishedSuccessfully" object:nil userInfo:info];
						[self setPost:nil];
						[info release];
					}
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
	[autosaveManager release];
	[draftManager release];
	[autosaveView release];
	[payload release];
	[connection release];
	[urlResponse release];
	[urlRequest release];
	[post release];
    [leftView release];
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
    [self stopTimer];
    [super dealloc];
}

@end
