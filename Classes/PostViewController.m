#import "PostViewController.h"
#import "BlogDataManager.h"
#import "WordPressAppDelegate.h"
#import "EditPostViewController.h"
#import "PostPreviewViewController.h"
#import "PostSettingsViewController.h"
#import "WPPhotosListViewController.h"
#import "WPNavigationLeftButtonView.h"
#import "PostsViewController.h"
#import "Reachability.h"
#import "CustomFieldsDetailController.h"
#import "CommentsViewController.h"
#import "WPPublishOnEditController.h"

#define TAG_OFFSET 1010

@interface PostViewController (Private)

- (void)startTimer;
- (void)stopTimer;

- (void)saveAsDraft;
- (void)discard;
- (void)cancel;
- (void)conditionalLoadOfTabBarController;//to solve issue with crash when selecting comments tab from "new" (newPost) post editing view
- (void)savePostWithBlog:(NSMutableArray *)arrayPost;
- (void)removeProgressIndicator;

@end

@implementation PostViewController

@synthesize postDetailEditController, postPreviewController, postSettingsController, postsListController, hasChanges, mode, tabController, photosListController, saveButton;
@synthesize leftView, isVisible;
@synthesize customFieldsDetailController;
@synthesize commentsViewController;
@synthesize selectedViewController;

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

    if (hasChanges) {
        [leftView setTitle:@"Cancel"];
        self.navigationItem.rightBarButtonItem = saveButton;
    }
    
    selectedViewController = viewController;
}

- (void)dealloc {
    [leftView release];
    [postDetailEditController release];
    [postPreviewController release];
    [postSettingsController release];
    [photosListController release];
    [commentsViewController release];
    [saveButton release];

    [self stopTimer];

    [super dealloc];
}

- (IBAction)cancelView:(id)sender {
    if (!hasChanges) {
        [self stopTimer];
        [self.navigationController popViewControllerAnimated:YES];
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
    WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    [delegate setAlertRunning:YES];

    [actionSheet release];
}

- (IBAction)saveAction:(id)sender {
    //saveButton.title = @"Save";
    NSLog(@"Inside Save Action");
    BlogDataManager *dm = [BlogDataManager sharedDataManager];

     if (![[dm.currentPost valueForKey:@"post_status"] isEqualToString:@"Local Draft"]) {
        if ([[Reachability sharedReachability] internetConnectionStatus] == NotReachable) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Communication Error."
                                  message:@"no internet connection."
                                  delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            alert.tag = TAG_OFFSET;
            [alert show];

            WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
            [delegate setAlertRunning:YES];
            [alert release];
            return;
        }
	 }

    if (!hasChanges) {
		NSLog(@"No changes to save...");
        [self stopTimer];
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }
	
	NSString *postStatus = [dm.currentPost valueForKey:@"post_status"];
	if( ![postStatus isEqual:@"Local Draft"] )
	{ 
		[self performSelectorInBackground:@selector(addProgressIndicator) withObject:nil];
    }
	
    //Code for scaling image based on post settings
	NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];
    NSArray *photosArray = [dm.currentPost valueForKey:@"Photos"];
    NSString *filepath;

    for (int i = 0; i <[photosArray count]; i++) {
        filepath = [photosArray objectAtIndex:i];
        NSString *imagePath = [NSString stringWithFormat:@"%@/%@", [dm blogDir:dm.currentBlog], filepath];
        UIImage *scaledImage = [photosListController scaleAndRotateImage:[UIImage imageWithContentsOfFile:imagePath] scaleFlag:YES];
        NSData *imageData = UIImageJPEGRepresentation(scaledImage, 0.5);
        [imageData writeToFile:imagePath atomically:YES];
		
		if(pool)
			[pool release];
		
		pool=[[NSAutoreleasePool alloc] init];

    }
	[pool release];

    //for handling more tag text.
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

        WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
        [delegate setAlertRunning:YES];

        [alert release];

        [self cancel];
        return;
    }

    if (![dm postDescriptionHasValidDescription:dm.currentPost]) {
        [self cancel];
        return;
    }

   // NSString *postStatus = [dm.currentPost valueForKey:@"post_status"];
	//[self.navigationController popViewControllerAnimated:YES];
    if ([postStatus isEqual:@"Local Draft"])
        [self saveAsDraft];else {
       // [self performSelectorInBackground:@selector(addProgressIndicator) withObject:nil];
        //Need to release params
        NSMutableArray *params = [[[NSMutableArray alloc] initWithObjects:dm.currentPost, dm.currentBlog, nil] autorelease];
        BOOL isCurrentPostDraft = dm.isLocaDraftsCurrent;

        if (isCurrentPostDraft)
            [dm saveCurrentPostAsDraftWithAsyncPostFlag];
			
		NSString *postId = [dm savePostsFileWithAsynPostFlag:[params objectAtIndex:0]];
		NSMutableArray *argsArray = [NSMutableArray arrayWithArray:params];
		int count = [argsArray count];
		[argsArray insertObject:postId atIndex:count];

		[self savePostWithBlog:argsArray];
		
		hasChanges = NO;
//		[dm removeAutoSavedCurrentPostFile];

		[self removeProgressIndicator];
		
		[self.navigationController popViewControllerAnimated:YES];
		
    }
}

- (void)autoSaveCurrentPost:(NSTimer *)aTimer {
    if (hasChanges) {
        [postDetailEditController updateValuesToCurrentPost];
        [postSettingsController updateValuesToCurrentPost];

        BlogDataManager *dm = [BlogDataManager sharedDataManager];
        [dm autoSaveCurrentPost];
    }
}

- (void)startTimer {
    if (!autoSaveTimer) {
        autoSaveTimer = [[NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(autoSaveCurrentPost:) userInfo:nil repeats:YES] retain];
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
	if (hasChanges == NO)
    self.navigationItem.rightBarButtonItem = nil;
    [tabController setSelectedViewController:[[tabController viewControllers] objectAtIndex:0]];
    UIViewController *vc = [[tabController viewControllers] objectAtIndex:0];
    self.title = vc.title;

    [postDetailEditController refreshUIForCompose];
    [postSettingsController reloadData];
    [photosListController refreshData];

    [self updatePhotosBadge];
}

- (void)refreshUIForCurrentPost {
    self.navigationItem.rightBarButtonItem = nil;

    [tabController setSelectedViewController:[[tabController viewControllers] objectAtIndex:0]];
    UIViewController *vc = [[tabController viewControllers] objectAtIndex:0];
    self.title = vc.title;
    [postDetailEditController refreshUIForCurrentPost];
    [postSettingsController reloadData];
    [photosListController refreshData];

    [self updatePhotosBadge];
}

- (void)updatePhotosBadge {
    int photoCount = [[[BlogDataManager sharedDataManager].currentPost valueForKey:@"Photos"] count];

    if (photoCount)
        photosListController.tabBarItem.badgeValue = [NSString stringWithFormat:@"%d", photoCount];else
        photosListController.tabBarItem.badgeValue = nil;
}

#pragma mark -
#pragma mark UIActionSheetDelegate methods

- (void)addProgressIndicator {
    NSAutoreleasePool *apool = [[NSAutoreleasePool alloc] init];
    UIActivityIndicatorView *aiv = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    UIBarButtonItem *activityButtonItem = [[UIBarButtonItem alloc] initWithCustomView:aiv];
    [aiv startAnimating];
    [aiv release];

    self.navigationItem.rightBarButtonItem = activityButtonItem;
    [activityButtonItem release];
    [apool release];
}

- (void)removeProgressIndicator {
    if (hasChanges) {
        if ([[leftView title] isEqualToString:@"Posts"] ||[[self.navigationItem.leftBarButtonItem title] isEqualToString:@"Done"])
            [leftView setTitle:@"Cancel"];

        self.navigationItem.rightBarButtonItem = saveButton;
    } else {
        self.navigationItem.rightBarButtonItem = nil;
    }
}

- (void)saveAsDraft {
    BlogDataManager *dm = [BlogDataManager sharedDataManager];
    [dm saveCurrentPostAsDraft];
    hasChanges = NO;
    self.navigationItem.rightBarButtonItem = nil;
    [self stopTimer];
    [dm removeAutoSavedCurrentPostFile];
    [self discard];
}

- (void)discard {
    hasChanges = NO;
    self.navigationItem.rightBarButtonItem = nil;
    [self stopTimer];
    [[BlogDataManager sharedDataManager] clearAutoSavedContext];
    [self.navigationController popViewControllerAnimated:YES];
	
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

    WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    [delegate setAlertRunning:NO];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag != TAG_OFFSET) {
        [self discard];
    }

    WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    [delegate setAlertRunning:NO];
}

- (void)setHasChanges:(BOOL)aFlag {
    if (hasChanges == NO && aFlag == YES)
        [self startTimer];

    hasChanges = aFlag;

    if (hasChanges) {
        if ([[leftView title] isEqualToString:@"Posts"])
            [leftView setTitle:@"Cancel"];

        self.navigationItem.rightBarButtonItem = saveButton;
    }

    NSNumber *postEdited = [NSNumber numberWithBool:hasChanges];
    [[[BlogDataManager sharedDataManager] currentPost] setObject:postEdited forKey:@"hasChanges"];
}

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    if (!saveButton) {
        saveButton = [[UIBarButtonItem alloc] init];
        saveButton.title = @"Save";
        saveButton.target = self;
        saveButton.style = UIBarButtonItemStyleDone;
        saveButton.action = @selector(saveAction :);
    }
	//conditionalLoadOfTabBarController is now referenced from viewWillAppear.  Solves Ticket #223 (crash when selecting comments from new post view)
	    if (!leftView) {
        leftView = [WPNavigationLeftButtonView createCopyOfView];
        [leftView setTitle:@"Posts"];
    }
}
//shouldAutorotateToInterfaceOrientation


- (void)viewWillAppear:(BOOL)animated {
	NSLog(@"inside PostViewController:viewWillAppear");
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

    [leftView setTarget:self withAction:@selector(cancelView:)];
	
	if (![[[[BlogDataManager sharedDataManager] currentPost] valueForKey:@"title"] isEqualToString:@""]) {
		self.navigationItem.title = [[[BlogDataManager sharedDataManager] currentPost] valueForKey:@"title"];
	}else{
		self.navigationItem.title = @"Write";
	}

    if (hasChanges == YES) {
        if ([[leftView title] isEqualToString:@"Posts"]) {
            [leftView setTitle:@"Cancel"];
        }
        
        self.navigationItem.rightBarButtonItem = saveButton;
    } else {
        [leftView setTitle:@"Posts"];
        self.navigationItem.rightBarButtonItem = nil;
    } 

    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithCustomView:leftView];
    self.navigationItem.leftBarButtonItem = cancelButton;
    [cancelButton release];

    [super viewWillAppear:animated];
	[self conditionalLoadOfTabBarController];

    if (mode == editPost) {
        [self refreshUIForCurrentPost];
    } else if (mode == newPost) {
        [self refreshUIForCompose];
    } else if (mode == autorecoverPost) {
        [self refreshUIForCurrentPost];
        self.hasChanges = YES;
    }

    if (mode != newPost)
		mode = refreshPost;
    [commentsViewController setIndexForCurrentPost:[[BlogDataManager sharedDataManager] currentPostIndex]];
    [[tabController selectedViewController] viewWillAppear:animated];
	
	isVisible = YES;
}

- (void)conditionalLoadOfTabBarController {
	// Icons designed by, and included with permission of, IconBuffet | iconbuffet.com
    NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:5];
	
    if (postDetailEditController == nil) {
        postDetailEditController = [[EditPostViewController alloc] initWithNibName:@"EditPostViewController" bundle:nil];
    }
	
    postDetailEditController.title = @"Write";
    postDetailEditController.tabBarItem.image = [UIImage imageNamed:@"write.png"];
    postDetailEditController.postDetailViewController = self;
    [array addObject:postDetailEditController];
    
    //if (mode == 1 || mode == 2 || mode == 3) { //don't load this tab if mode == 0 (new post) since comments are irrelevant to a brand new post
	NSString *postStatus = [[BlogDataManager sharedDataManager].currentPost valueForKey:@"post_status"];
	if (mode != newPost && ![postStatus isEqualToString:@"Local Draft"]) { //don't load commentsViewController tab if it's a new post or a local draft since comments are irrelevant to a brand new post
		if (commentsViewController == nil) {
			commentsViewController = [[CommentsViewController alloc] initWithNibName:@"CommentsViewController" bundle:nil];
		}
		
		commentsViewController.title = @"Comments";
		commentsViewController.tabBarItem.image = [UIImage imageNamed:@"talk_bubbles.png"];
		[array addObject:commentsViewController];
	}
	
    if (photosListController == nil) {
        photosListController = [[WPPhotosListViewController alloc] initWithNibName:@"WPPhotosListViewController" bundle:nil];
    }
	
    photosListController.title = @"Photos";
    photosListController.tabBarItem.image = [UIImage imageNamed:@"photos.png"];
    photosListController.delegate = self;
	
    [array addObject:photosListController];
	
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
	
    tabController.viewControllers = array;
    self.view = tabController.view;
	
    [array release];
}

- (void)viewWillDisappear:(BOOL)animated {
    if ((self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft) || (self.interfaceOrientation == UIInterfaceOrientationLandscapeRight)) {
        [postDetailEditController setTextViewHeight:202];
    }

//    [photoEditingStatusView removeFromSuperview];

    if (postDetailEditController.currentEditingTextField)
        [postDetailEditController.currentEditingTextField resignFirstResponder];

    [super viewWillDisappear:animated];
   if (mode != newPost)
	   mode = refreshPost;
    [postPreviewController stopLoading];
	isVisible = NO;
}

- (void)didReceiveMemoryWarning {
    WPLog(@"%@ %@", self, NSStringFromSelector(_cmd));
    [super didReceiveMemoryWarning];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	NSLog(@"inside PostViewController: should autorotate");
//    if ([[[[self tabController] selectedViewController] title] isEqualToString:@"Photos"]) {
//        if ((interfaceOrientation == UIInterfaceOrientationLandscapeLeft) || (interfaceOrientation == UIInterfaceOrientationLandscapeRight)) {
//            [photosListController.view addSubview:photoEditingStatusView];
//        } else if ((interfaceOrientation == UIInterfaceOrientationPortrait) || (interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown)) {
//            [photoEditingStatusView removeFromSuperview];
//        }
//    }
	

    //Code to disable landscape when alert is raised.
//    WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
//
//    if ([delegate isAlertRunning] == YES) {
//        return NO;
//    }
//
//    if ((interfaceOrientation == UIInterfaceOrientationPortrait) || (interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown)) {
//        [postDetailEditController setTextViewHeight:202];
//		return YES;
//    }
//
//    if ((interfaceOrientation == UIInterfaceOrientationLandscapeLeft) || (interfaceOrientation == UIInterfaceOrientationLandscapeRight)) {
//        if (self.interfaceOrientation != interfaceOrientation) {
//            if (postDetailEditController.isEditing == NO) {
//              //  [postDetailEditController setTextViewHeight:57]; //#148
//            } else {
//                //[postDetailEditController setTextViewHeight:116];
//				//return YES;
//				return NO;
//            }
//        }
//    }
//	
//	if ([tabController.selectedViewController.title isEqualToString:@"Settings"])
//		return NO;
//
//    //return YES;
	return NO; //trac ticket #148
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	//[self.selectedViewController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    if ([tabController.selectedViewController.title isEqualToString:@"Settings"]) {
        [postSettingsController.tableView reloadData];
    }
}

- (void)useImage:(UIImage *)theImage {
    BlogDataManager *dataManager = [BlogDataManager sharedDataManager];
    self.hasChanges = YES;

    id currentPost = dataManager.currentPost;

    if (![currentPost valueForKey:@"Photos"]) {
        [currentPost setValue:[NSMutableArray array] forKey:@"Photos"];
    }

    UIImage *image = [photosListController scaleAndRotateImage:theImage scaleFlag:NO];
    [[currentPost valueForKey:@"Photos"] addObject:[dataManager saveImage:image]];

    [self updatePhotosBadge];
}

- (id)photosDataSource {
    return [[[BlogDataManager sharedDataManager] currentPost] valueForKey:@"Photos"];
}

@end
