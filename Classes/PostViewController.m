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
- (void)conditionalLoadOfTabBarController;//to solve issue with crash when selecting comments tab from "new" (newPost) post editing view
- (void)savePostWithBlog:(NSMutableArray *)arrayPost;
- (void)removeProgressIndicator;

@end

@implementation PostViewController

@synthesize postDetailViewController, postDetailEditController, postPreviewController, postSettingsController, postsListController, hasChanges, tabController;
@synthesize mediaViewController, leftView, isVisible, customFieldsDetailController, commentsViewController;
@synthesize selectedViewController, toolbar, contentView, commentsButton, photosButton, hasSaved;
@synthesize settingsButton, editToolbar, cancelEditButton, editModalViewController, post, didConvertDraftToPublished;
@synthesize payload, connection, urlResponse, urlRequest, appDelegate, autosaveView, autosaveButton, isShowingAutosaves;
@synthesize autosaveManager, draftManager, editMode;

@dynamic leftBarButtonItemForEditPost;

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
	appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
	hasSaved = NO;
	
	BOOL clearAutosaves = [[NSUserDefaults standardUserDefaults] boolForKey:@"autosave_clear_preference"];
	if(clearAutosaves == YES) {
		[autosaveManager removeAll];
		[[NSUserDefaults standardUserDefaults] setValue:NO forKey:@"autosave_clear_preference"];
	}
	
	if (DeviceIsPad() == NO)
	{
		//conditionalLoadOfTabBarController is now referenced from viewWillAppear.  Solves Ticket #223 (crash when selecting comments from new post view)
	    if (!leftView) {
			leftView = [WPNavigationLeftButtonView createCopyOfView];
			[leftView setTitle:@"Posts"];
		}
	}
	
	autosaveView = [[AutosaveViewController alloc] initWithNibName:@"AutosaveViewController" bundle:nil];
	autosaveManager = [[AutosaveManager alloc] init];
	draftManager = [[DraftManager alloc] init];
	
	[self refreshButtons];
}
//shouldAutorotateToInterfaceOrientation


- (void)viewWillAppear:(BOOL)animated {
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(restoreFromAutosave:) name:@"RestoreFromAutosaveNotification" object:nil];
	if (DeviceIsPad() == NO) {
		if ((self.interfaceOrientation == UIInterfaceOrientationPortrait) || (self.interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown)) {
			[postDetailEditController setTextViewHeight:202];
		}
		
		if ((self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft) || (self.interfaceOrientation == UIInterfaceOrientationLandscapeRight)) {
			if (postDetailEditController.isEditing == NO) {
				//[postDetailEditController setTextViewHeight:57]; //#148
			} else {
				[postDetailEditController setTextViewHeight:116];
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
	
	[self refreshButtons];
	
	if (DeviceIsPad() == NO) {
		UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithCustomView:leftView];
		self.leftBarButtonItemForEditPost = cancelButton;
		[cancelButton release];
	}
	
    [super viewWillAppear:animated];
	[self conditionalLoadOfTabBarController];
	
    if(self.editMode == kEditPost) {
        [self refreshUIForCurrentPost];
    }
	else if(self.editMode == kNewPost) {
        //[self refreshUIForCompose];
    }
	else if (self.editMode == kAutorecoverPost) {
        [self refreshUIForCurrentPost];
        self.hasChanges = YES;
    }
	
    if (self.editMode != kNewPost)
		self.editMode = kRefreshPost;
	
    [commentsViewController setIndexForCurrentPost:[[BlogDataManager sharedDataManager] currentPostIndex]];
    [[tabController selectedViewController] viewWillAppear:animated];
	
	isVisible = YES;
	
	if(self.autosaveButton == nil)
		self.autosaveButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[self.autosaveButton setImage:[UIImage imageNamed:@"autosave"] forState:UIControlStateNormal];
	[self checkAutosaves];
}

- (void)refreshButtons {
	if(hasChanges == YES) {
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

- (void)conditionalLoadOfTabBarController {
	// Icons designed by, and included with permission of, IconBuffet | iconbuffet.com
    NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:5];
	
	// post detail controllers
    if (postDetailEditController == nil) {
		if (DeviceIsPad() == YES) {
			postDetailEditController = [[EditPostViewController alloc] initWithNibName:@"EditPostViewController-iPad" bundle:nil];
		} else {
			postDetailEditController = [[EditPostViewController alloc] initWithNibName:@"EditPostViewController" bundle:nil];
		}
    }
	
    postDetailEditController.title = @"Write";
    postDetailEditController.tabBarItem.image = [UIImage imageNamed:@"write.png"];
    postDetailEditController.postDetailViewController = self;
    [array addObject:postDetailEditController];
	
	autosaveView.postDetailViewController = self;
	
    //if (mode == 1 || mode == 2 || mode == 3) { //don't load this tab if mode == 0 (new post) since comments are irrelevant to a brand new post
	NSString *postStatus = [[BlogDataManager sharedDataManager].currentPost valueForKey:@"post_status"];
	if (editMode != kNewPost && ![postStatus isEqualToString:@"Local Draft"]) { //don't load commentsViewController tab if it's a new post or a local draft since comments are irrelevant to a brand new post
		if (commentsViewController == nil) {
			commentsViewController = [[CommentsViewController alloc] initWithNibName:@"CommentsViewController" bundle:nil];
			if (DeviceIsPad() == YES) {
				commentsViewController.isSecondaryViewController = YES;
			}
		}
		
		commentsViewController.title = @"Comments";
		commentsViewController.tabBarItem.image = [UIImage imageNamed:@"comments.png"];
		[array addObject:commentsViewController];
	}
	
	if(DeviceIsPad() == YES) {
		mediaViewController = nil;
		mediaViewController = [[PostMediaViewController alloc] initWithNibName:@"PostMediaViewController-iPad" bundle:nil];
	}
	else if(mediaViewController == nil)
		mediaViewController = [[PostMediaViewController alloc] initWithNibName:@"PostMediaViewController" bundle:nil];
	
    mediaViewController.title = @"Media";
    mediaViewController.tabBarItem.image = [UIImage imageNamed:@"photos.png"];
	mediaViewController.postDetailViewController = self;
	
    [array addObject:mediaViewController];
	
    if (postPreviewController == nil) {
        postPreviewController = [[PostPreviewViewController alloc] initWithNibName:@"PostPreviewViewController" bundle:nil];
    }
	
    postPreviewController.title = @"Preview";
    postPreviewController.tabBarItem.image = [UIImage imageNamed:@"preview.png"];
    postPreviewController.postDetailViewController = self;
    [array addObject:postPreviewController];
	
    if (postSettingsController == nil) {
        postSettingsController = [[PostSettingsViewController alloc] initWithNibName:@"PostSettingsViewController" bundle:nil];
    }
	
    postSettingsController.title = @"Settings";
    postSettingsController.tabBarItem.image = [UIImage imageNamed:@"settings.png"];
    postSettingsController.postDetailViewController = self;
    [array addObject:postSettingsController];
	
	if (DeviceIsPad() == YES) {
		// the iPad has two detail views
		postDetailViewController = [[EditPostViewController alloc] initWithNibName:@"EditPostViewController-iPad" bundle:nil];
		[postDetailViewController disableInteraction];
		
		if (!editModalViewController) {
			editModalViewController = [[FlippingViewController alloc] init];
			
			RotatingNavigationController *editNav = [[[RotatingNavigationController alloc] initWithRootViewController:postDetailEditController] autorelease];
			editModalViewController.frontViewController = editNav;
			postDetailEditController.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:editToolbar] autorelease];
			postDetailEditController.navigationItem.leftBarButtonItem = cancelEditButton;
			
			RotatingNavigationController *previewNav = [[[RotatingNavigationController alloc] initWithRootViewController:postPreviewController] autorelease];
			editModalViewController.backViewController = previewNav;
			postPreviewController.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:previewToolbar] autorelease];
		}
	}
	
	if (tabController) {
		tabController.viewControllers = array;
		self.view = tabController.view;
	}
	else {
		postDetailViewController.view.frame = contentView.bounds;
		[contentView addSubview:postDetailViewController.view];
	}
	
    [array release];
}

- (void)viewWillDisappear:(BOOL)animated {
	if (DeviceIsPad() == NO) {
		if ((self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft) || (self.interfaceOrientation == UIInterfaceOrientationLandscapeRight)) {
			[postDetailEditController setTextViewHeight:202];
		}
	}
	
	//    [photoEditingStatusView removeFromSuperview];
	
    if (postDetailEditController.currentEditingTextField)
        [postDetailEditController.currentEditingTextField resignFirstResponder];
	
    [super viewWillDisappear:animated];
	if(self.editMode != kNewPost)
		self.editMode = kRefreshPost;
    [postPreviewController stopLoading];
	isVisible = NO;
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
    [selectedViewController viewWillDisappear:NO];
    [viewController viewWillAppear:NO];

//    if (viewController == photosListController) {
//        if ((self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft) || (self.interfaceOrientation == UIInterfaceOrientationLandscapeRight)) {
//            [photosListController.view addSubview:photoEditingStatusView];
//        } else if ((self.interfaceOrientation == UIInterfaceOrientationPortrait) || (self.interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown)) {
//            [photoEditingStatusView removeFromSuperview];
//        }
//    }
//    else {
//        [photoEditingStatusView removeFromSuperview];
//    }

    if (hasChanges && DeviceIsPad()) {
        [leftView setTitle:@"Cancel"];
		[self refreshButtons];
    }

    selectedViewController = viewController;
}

- (IBAction)cancelView:(id)sender {
    if (!hasChanges) {
        [self stopTimer];
		[self dismissEditView];
        return;
    }

//	if (DeviceIsPad() == NO) {
		[postSettingsController endEditingAction:nil];
		[postDetailEditController endEditingAction:nil];
//	}

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
    BlogDataManager *dm = [BlogDataManager sharedDataManager];
	[postDetailEditController bringTextViewDown];
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
				//NSString *postStatus = [dm.currentPost valueForKey:@"post_status"];
				[self performSelectorInBackground:@selector(addProgressIndicator) withObject:nil];
				
				[(NSMutableDictionary *)[BlogDataManager sharedDataManager].currentPost setValue:@"" forKey:@"mt_text_more"];
				[postSettingsController endEditingAction:nil];
				[postDetailEditController endEditingAction:nil];
				
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
					NSMutableArray *params = [[[NSMutableArray alloc] initWithObjects:dm.currentPost, dm.currentBlog, nil] autorelease];
					BOOL isCurrentPostDraft = dm.isLocaDraftsCurrent;
					
					if (isCurrentPostDraft)
						[dm saveCurrentPostAsDraftWithAsyncPostFlag];
					
					NSString *postId = [dm savePostsFileWithAsynPostFlag:[params objectAtIndex:0]];
					NSMutableArray *argsArray = [NSMutableArray arrayWithArray:params];
					int count = [argsArray count];
					[argsArray insertObject:postId atIndex:count];
					
					[self savePostWithBlog:argsArray];
					[self verifyPublishSuccessful];
					
					hasChanges = NO;
					
					[self removeProgressIndicator];
					[self dismissEditView];
					
					if (DeviceIsPad() == YES) {
						[[BlogDataManager sharedDataManager] makePostWithPostIDCurrent:postId];
					}
					
					[postDetailEditController clearUnsavedPost];
					[self refreshUIForCompose];
				}
			}
		}
	}
	else {
		[self saveAsDraft];
	}
}

- (void)autoSaveCurrentPost:(NSTimer *)aTimer {
	[postDetailEditController preserveUnsavedPost];
	if (hasChanges) {
		BlogDataManager *dm = [BlogDataManager sharedDataManager];
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
	
	if (DeviceIsPad() == YES) {
		[self editAction:self];
	}
	[self checkAutosaves];
}

- (void)refreshUIForCurrentPost {
	autosaveView.postID = appDelegate.postID;
	
	if(post != nil) {
		
	}
	else {
		if (![[[[BlogDataManager sharedDataManager] currentPost] valueForKey:@"title"] isEqualToString:@""]) {
			self.navigationItem.title = [[[BlogDataManager sharedDataManager] currentPost] valueForKey:@"title"];
		}else{
			self.navigationItem.title = @"Write";
		}
		
		[tabController setSelectedViewController:[[tabController viewControllers] objectAtIndex:0]];
		UIViewController *vc = [[tabController viewControllers] objectAtIndex:0];
		self.title = vc.title;
		[postDetailViewController refreshUIForCurrentPost];
		// avoid overwriting restored post when list is refreshed and reselected.
		// this is a bandaid for bug #445
		if (!DeviceIsPad())
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

- (void)addProgressIndicator {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    spinner.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
    [spinner startAnimating];
	
	UIBarButtonItem *activityButtonItem = [[UIBarButtonItem alloc] initWithCustomView:spinner];
	[self refreshButtons];
    [spinner release];
    [activityButtonItem release];
	
	[pool release];
}

- (void)removeProgressIndicator {
    if (hasChanges) {
        if ([[leftView title] isEqualToString:@"Posts"] || [[self.leftBarButtonItemForEditPost title] isEqualToString:@"Done"])
            [leftView setTitle:@"Cancel"];
    }
	
	[self refreshButtons];
}

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
	[self refreshUIForCompose];
	
	if(andDiscard == YES)
		[self discard];
}

- (void)discard {
    hasChanges = NO;
	[self refreshButtons];
	[postDetailEditController clearUnsavedPost];
	[self refreshUIForCompose];
    [self stopTimer];
	[self dismissEditView];
}

- (void)cancel {
    hasChanges = YES;

    if ([[leftView title] isEqualToString:@"Posts"])
        [leftView setTitle:@"Cancel"];
}

- (void)savePostWithBlog:(NSMutableArray *)arrayPost {
    BlogDataManager *dm = [BlogDataManager sharedDataManager];
    NSString *postId = [arrayPost lastObject];
    BOOL isCurrentPostDraft = dm.isLocaDraftsCurrent;

    BOOL savePostStatus = [dm savePost:[arrayPost objectAtIndex:0]];
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [self stopTimer];

    if (savePostStatus) {
		[dm removeAutoSavedCurrentPostFile];
        [dict setValue:postId forKey:@"savedPostId"];
        [dict setValue:[[dm currentPost] valueForKey:@"postid"] forKey:@"originalPostId"];
        [dict setValue:[NSNumber numberWithInt:isCurrentPostDraft] forKey:@"isCurrentPostDraft"];

	} else {
        [dm removeTempFileForUnSavedPost:postId];

        if (isCurrentPostDraft) {
            [dm restoreUnsavedDraft];
        }
    }

    hasChanges = YES;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"AsynchronousPostIsPosted" object:nil userInfo:dict];
    [dict release];
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
        [postDetailEditController setTextViewHeight:202];
		return YES;
    }

    if ((interfaceOrientation == UIInterfaceOrientationLandscapeLeft) || (interfaceOrientation == UIInterfaceOrientationLandscapeRight)) {
        if (self.interfaceOrientation != interfaceOrientation) {
            if (postDetailEditController.isEditing == NO) {
              //  [postDetailEditController setTextViewHeight:57]; //#148
            } else {
                [postDetailEditController setTextViewHeight:116];
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
	if (DeviceIsPad() == NO) {
		self.navigationItem.leftBarButtonItem = item;
	} else if (DeviceIsPad() == YES) {
		postDetailEditController.navigationItem.leftBarButtonItem = item;
	}
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
	BlogDataManager *dm = [BlogDataManager sharedDataManager];
	
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

- (IBAction)editAction:(id)sender;
{
	[postDetailEditController refreshUIForCurrentPost];
	[editModalViewController setShowingFront:YES animated:NO];
	editModalViewController.modalPresentationStyle = UIModalPresentationPageSheet;
	editModalViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
	[self.splitViewController presentModalViewController:editModalViewController animated:YES];
}

- (IBAction)commentsAction:(id)sender;
{
	// why is this necessary?
	commentsViewController.contentSizeForViewInPopover = commentsViewController.contentSizeForViewInPopover;
	UINavigationController *navController = [[[UINavigationController alloc] initWithRootViewController:commentsViewController] autorelease];
	UIPopoverController *popover = [[[NSClassFromString(@"UIPopoverController") alloc] initWithContentViewController:navController] autorelease];
	[popover presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
	[[CPopoverManager instance] setCurrentPopoverController:popover];
}

- (IBAction)picturesAction:(id)sender;
{//
//	photosListController.contentSizeForViewInPopover = photosListController.contentSizeForViewInPopover;
//	UINavigationController *navController = [[[UINavigationController alloc] initWithRootViewController:photosListController] autorelease];
//	UIPopoverController *popover = [[[NSClassFromString(@"UIPopoverController") alloc] initWithContentViewController:navController] autorelease];
//	[popover presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
//	[[CPopoverManager instance] setCurrentPopoverController:popover];
}

- (IBAction)settingsAction:(id)sender;
{
	postSettingsController.contentSizeForViewInPopover = postSettingsController.contentSizeForViewInPopover;
	UINavigationController *navController = [[[UINavigationController alloc] initWithRootViewController:postSettingsController] autorelease];
	UIPopoverController *popover = [[[NSClassFromString(@"UIPopoverController") alloc] initWithContentViewController:navController] autorelease];
	[popover presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
	[[CPopoverManager instance] setCurrentPopoverController:popover];
}

- (IBAction)locationAction:(id)sender;
{
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


- (IBAction)previewAction:(id)sender;
{
	[[CPopoverManager instance] setCurrentPopoverController:NULL];
	[editModalViewController setShowingFront:NO animated:YES];
}

- (IBAction)previewEditAction:(id)sender;
{
	[[CPopoverManager instance] setCurrentPopoverController:NULL];
	[editModalViewController setShowingFront:YES animated:YES];
}

- (IBAction)previewPublishAction:(id)sender;
{
}

- (void)dismissEditView;
{
	if (DeviceIsPad() == NO) {
        [self.navigationController popViewControllerAnimated:YES];
	} else {
		[self dismissModalViewControllerAnimated:YES];
		[[BlogDataManager sharedDataManager] loadDraftTitlesForCurrentBlog];
		[[BlogDataManager sharedDataManager] loadPostTitlesForCurrentBlog];
		
		UIViewController *theTopVC = [[WordPressAppDelegate sharedWordPressApp].masterNavigationController topViewController];
		if ([theTopVC respondsToSelector:@selector(reselect)])
			[theTopVC performSelector:@selector(reselect)];
	}
}

- (IBAction)newPostAction:(id)sender {
	[self refreshUIForCompose];
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

- (void)showAutosaveButton {	
	[self.autosaveButton setAlpha:0.50];
	self.autosaveButton.tag = 999;
	[self.autosaveButton setHidden:NO];
	int topOfViewStack = appDelegate.navigationController.viewControllers.count - 1;
	
	CGPoint centerOfWindow = [[[appDelegate.navigationController.viewControllers objectAtIndex:topOfViewStack] view] convertPoint:
							  [[appDelegate.navigationController.viewControllers objectAtIndex:topOfViewStack] view].center toView:nil];
	int yPos = centerOfWindow.y+120;
	if(yPos > 328)
		yPos = 328;
	self.autosaveButton.frame = CGRectMake(centerOfWindow.x+120, yPos, 40, 40);

	[self.autosaveButton addTarget:self action:@selector(toggleAutosaves:) forControlEvents:UIControlEventTouchUpInside];
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:2.0];
	[[[appDelegate.navigationController.viewControllers objectAtIndex:topOfViewStack] view] insertSubview:self.autosaveButton atIndex:0];
	[[[appDelegate.navigationController.viewControllers objectAtIndex:topOfViewStack] view] bringSubviewToFront:self.autosaveButton];
	[UIView commitAnimations];
}

- (void)hideAutosaveButton {
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:15.0];
	[self.autosaveButton removeFromSuperview];
	[UIView commitAnimations];
}

- (void)checkAutosaves {
	BlogDataManager *dm = [BlogDataManager sharedDataManager];
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
			[self showAutosaveButton];
		}
		else
			[self hideAutosaveButton];
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
			BlogDataManager *dm = [BlogDataManager sharedDataManager];
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
		[self hideAutosaveButton];
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
	BlogDataManager *dm = [BlogDataManager sharedDataManager];
	
	NSArray *params = [NSArray arrayWithObjects:
					   appDelegate.postID,
					   [[dm currentBlog] objectForKey:@"username"],
					   [dm getPasswordFromKeychainInContextOfCurrentBlog:[dm currentBlog]],
					   nil];
	
	// Execute the XML-RPC request
	XMLRPCRequest *request = [[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:[[dm currentBlog] valueForKey:@"xmlrpc"]]];
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
	[autosaveButton release];
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
	[editModalViewController release];
	
    [self stopTimer];
	
    [super dealloc];
}

@end
