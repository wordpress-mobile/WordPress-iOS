#import "PostDetailViewController.h"
#import "BlogDataManager.h"
#import "PostDetailEditController.h"
#import "WPPostDetailPreviewController.h"
#import "WPPostSettingsController.h"
#import "WPPhotosListViewController.h"

#import "PostsListController.h"


@interface PostDetailViewController (privateMethods)
- (void)startTimer;
- (void)stopTimer;

- (void)_saveAsDrft;
- (void)_savePost:(id)aPost inBlog:(id)aBlog;
- (void)_discard;
- (void)_cancel;

@end

@implementation PostDetailViewController

@synthesize postDetailEditController, postPreviewController, postSettingsController, postsListController, hasChanges, mode, tabController, photosListController, saveButton;

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {

	if( [viewController.title isEqualToString:@"Photos"])
	{
		[photosListController refreshData];
	}
	if( [viewController.title isEqualToString:@"Preview"])
	{
		[postPreviewController refreshWebView];
	}
	else
	{
		[postPreviewController stopLoading];
	}
	
	if( [viewController.title isEqualToString:@"Settings"])
	{
		[postSettingsController reloadData];
	}
	
	if( [viewController.title isEqualToString:@"Write"])
	{
		[postDetailEditController refreshUIForCurrentPost];
	}
	
	self.title = viewController.title;
	
	if( hasChanges ) {
		if ([self.navigationItem.leftBarButtonItem.title isEqualToString:@"Posts"])
			self.navigationItem.leftBarButtonItem.title = @"Cancel";
		self.navigationItem.rightBarButtonItem = saveButton;
	}
}

- (void)tabBarController:(UITabBarController *)tabBarController didEndCustomizingViewControllers:(NSArray *)viewControllers changed:(BOOL)changed 
{
	NSLog(@"tabBarController didEndCustomizingViewControllers");	
}

- (void)dealloc 
{
	[postDetailEditController release];
	[postPreviewController release];
	[postSettingsController release];
	[photosListController release];
	[saveButton release];
	
	[autoSaveTimer invalidate];
	[autoSaveTimer release];
	autoSaveTimer = nil;
	[super dealloc];
}

- (IBAction)cancelView:(id)sender 
{
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
	[actionSheet release];	
}

- (IBAction)saveAction:(id)sender 
{
	if (!hasChanges) {
		[self stopTimer];
		[self.navigationController popViewControllerAnimated:YES]; 
		return;
	}
	
	[postSettingsController endEditingAction:nil];
	[postDetailEditController endEditingAction:nil];

	BlogDataManager *dm = [BlogDataManager sharedDataManager];
	
	NSString *description = [dm.currentPost valueForKey:@"description"];
	NSString *title = [dm.currentPost valueForKey:@"title"];
	NSArray *photos = [dm.currentPost valueForKey:@"Photos"];

	
	if ((!description || [description isEqualToString:@""]) &&
		(!title || [title isEqualToString:@""]) && 
		(!photos || ([photos count] == 0))) {
		
		NSString *msg = [NSString stringWithFormat:@"Please provide either a title or description, or attach photos to the post before saving."];
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Post Error"
														message:msg
													   delegate:nil
											  cancelButtonTitle:nil
											  otherButtonTitles:@"OK",nil];
		[alert show];
		[alert release];
		
		[self _cancel];
		return;

	}

	
	
	
	if( ![dm postDescriptionHasValidDescription:dm.currentPost] )
	{
		[self _cancel];
		return;
	}
	
	NSString *postStatus = [dm.currentPost valueForKey:@"post_status"];

	if( [postStatus isEqual:@"Local Draft"] )
		[self _saveAsDrft];
	else 
		[self _savePost:dm.currentPost inBlog:dm.currentBlog];
}

- (void)autoSaveCurrentPost:(NSTimer *)aTimer
{
//	NSLog(@"autoSaveCurrentPost %@", aTimer);
	
	if( !hasChanges )
	{
		NSLog(@"Returning -- hasChanges is false");
		return;
	}
	
	[postDetailEditController updateValuesToCurrentPost];
	[postSettingsController updateValuesToCurrentPost];
	
	BlogDataManager *dm = [BlogDataManager sharedDataManager];
	[dm autoSaveCurrentPost];
}

- (void)startTimer
{
	if( autoSaveTimer == nil )
	{
		autoSaveTimer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(autoSaveCurrentPost:) userInfo:nil repeats:YES];
		[autoSaveTimer retain];
	}
	else
	{
		NSLog(@"ERROR: There exits a timer, trying to create another timer object.");
	}
}

- (void)stopTimer
{
	if( !autoSaveTimer )
		return;
	
	[autoSaveTimer invalidate];
	[autoSaveTimer release];
	autoSaveTimer = nil;
}

- (void)refreshUIForCompose
{
	self.navigationItem.rightBarButtonItem = nil;
	[tabController setSelectedViewController:[[tabController viewControllers] objectAtIndex:0]];
	UIViewController *vc = [[tabController viewControllers] objectAtIndex:0];
	self.title = vc.title;

	[postDetailEditController refreshUIForCompose];
	[postSettingsController reloadData];
	[photosListController refreshData];
	
	[self updatePhotosBadge];
}

- (void)refreshUIForCurrentPost
{
	self.navigationItem.rightBarButtonItem = nil;

	[tabController setSelectedViewController:[[tabController viewControllers] objectAtIndex:0]];
	UIViewController *vc = [[tabController viewControllers] objectAtIndex:0];
	self.title = vc.title;
	[postDetailEditController refreshUIForCurrentPost];
	[postSettingsController reloadData];
	[photosListController refreshData];
	
	[self updatePhotosBadge];
}

- (void)updatePhotosBadge
{
	int photoCount = [[[BlogDataManager sharedDataManager].currentPost valueForKey:@"Photos"] count];
	if( photoCount )
		photosListController.tabBarItem.badgeValue = [NSString stringWithFormat:@"%d",photoCount];
	else 
		photosListController.tabBarItem.badgeValue = nil;	
}

#pragma mark - UIActionSheetDelegate

- (void)addProgressIndicator
{
	NSAutoreleasePool *apool = [[NSAutoreleasePool alloc] init];
	UIActivityIndicatorView *aiv = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
	UIBarButtonItem *activityButtonItem = [[UIBarButtonItem alloc] initWithCustomView:aiv];
	[aiv startAnimating]; 
	[aiv release];
	
	self.navigationItem.rightBarButtonItem = activityButtonItem;
	[activityButtonItem release];
	[apool release];
}

- (void)removeProgressIndicator
{
	//wait incase the other thread did not complete its work.
	while (self.navigationItem.rightBarButtonItem == nil)
	{
		[[NSRunLoop currentRunLoop] runUntilDate:[[NSDate date] addTimeInterval:0.1]];
	}
	
	if(hasChanges) {
		if ([self.navigationItem.leftBarButtonItem.title isEqualToString:@"Posts"])
			self.navigationItem.leftBarButtonItem.title = @"Cancel";
		self.navigationItem.rightBarButtonItem = saveButton;
	}
}

- (void)_saveAsDrft
{
	BlogDataManager *dm = [BlogDataManager sharedDataManager];
	int postIndex = [dm currentPostIndex];
	[dm saveCurrentPostAsDraft];
	hasChanges = NO;
	self.navigationItem.rightBarButtonItem = nil;
	[self stopTimer];
	[dm removeAutoSavedCurrentPostFile];

	//new post is saving as draft.
	if( postIndex == -1 )
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Draft Saved"
														message:@"Your post has been saved to the Local Drafts folder."
													   delegate:self
											  cancelButtonTitle:nil
											  otherButtonTitles:@"OK", nil];
		[alert show];
		[alert release];		
	}
	else 
	{
		[self.navigationController popViewControllerAnimated:YES];	
	}	
}

- (void)_discard
{
	hasChanges = NO;
	self.navigationItem.rightBarButtonItem = nil;
	[self stopTimer];
	[[BlogDataManager sharedDataManager] clearAutoSavedContext];
	[self.navigationController popViewControllerAnimated:YES];
}

- (void)_cancel
{
	hasChanges = YES;
}

- (void)_savePost:(id)aPost inBlog:(id)aBlog
{	
	[self performSelectorInBackground:@selector(addProgressIndicator) withObject:nil];
	BlogDataManager *dm = [BlogDataManager sharedDataManager];
	//TODO: helps us in implementing async in future.
	if( [dm savePost:aPost] )
	{
		[self removeProgressIndicator];
		hasChanges = NO;
		self.navigationItem.rightBarButtonItem = nil;
		[self stopTimer];
		[dm removeAutoSavedCurrentPostFile];

		NSString *statusDesc = [dm statusDescriptionForStatus:[aPost valueForKey:@"post_status"] fromBlog:aBlog];
//		NSString *title = [aPost valueForKey:@"title"];
//		title = ( title == nil ? @"" : title );

		NSString *msg = [NSString stringWithFormat:@"Post was saved to \"%@\" with status \"%@\"", [dm.currentBlog valueForKey:@"blogName"], statusDesc];
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Post Saved"
														message:msg
													   delegate:self
											  cancelButtonTitle:nil
											  otherButtonTitles:@"OK", nil];
		[alert show];
		[alert release];
	}
	else 
	{
		[self removeProgressIndicator];
	}
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	switch ([actionSheet tag])
	{
		case 201:
		{
			if( buttonIndex == 0 )
				[self _discard];
			if( buttonIndex == 1 )
				[self _cancel];			
			break;
		}
		default:
			break;
	}
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
//	if( buttonIndex == 0 )
//	{
//		[self refreshUIForCurrentPost];
//		tabController.selectedViewController = postPreviewController;
//	}
//	else
		[self _discard];
}

- (void)setHasChanges:(BOOL)aFlag
{
	if( hasChanges == NO && aFlag == YES )
		[self startTimer];
	
	hasChanges = aFlag;
	if(hasChanges) {
		if ([self.navigationItem.leftBarButtonItem.title isEqualToString:@"Posts"])
			self.navigationItem.leftBarButtonItem.title = @"Cancel";
		self.navigationItem.rightBarButtonItem = saveButton;
	}
	
	NSNumber *postEdited = [NSNumber numberWithBool:hasChanges];
	[[[BlogDataManager sharedDataManager] currentPost] setObject:postEdited	forKey:@"hasChanges"];
}


#pragma mark - Overridden


- (void)viewDidLoad {
	[super viewDidLoad];
	
	

	UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] init];
	cancelButton.title = @"Posts";
	cancelButton.target = self;
	cancelButton.action = @selector(cancelView:);
	self.navigationItem.leftBarButtonItem = cancelButton;
	[cancelButton release];
	
	if (!saveButton) {
		saveButton = [[UIBarButtonItem alloc] init];
		saveButton.title = @"Save";
		saveButton.target = self;
		saveButton.style = UIBarButtonItemStyleDone;
		saveButton.action = @selector(saveAction:);
	} 

	// Icons designed by, and included with permission of, IconBuffet | iconbuffet.com
	
	NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:5];

	if (postDetailEditController == nil) {
		postDetailEditController = [[PostDetailEditController alloc] initWithNibName:@"PostDetailEditController" bundle:nil];
	}
	postDetailEditController.title = @"Write";
	postDetailEditController.tabBarItem.image = [UIImage imageNamed:@"write.png"];
	postDetailEditController.postDetailViewController = self;
	[array addObject:postDetailEditController];
	
	if (photosListController == nil) {
		photosListController = [[WPPhotosListViewController alloc] initWithNibName:@"WPPhotosListViewController" bundle:nil];
	}
	photosListController.title = @"Photos";
	photosListController.tabBarItem.image = [UIImage imageNamed:@"photos.png"];
	photosListController.postDetailViewController = self;
	[array addObject:photosListController];
	

	if (postPreviewController == nil) {
		postPreviewController = [[WPPostDetailPreviewController alloc] initWithNibName:@"WPPostDetailPreviewController" bundle:nil];
	}
	postPreviewController.title = @"Preview";
	postPreviewController.tabBarItem.image = [UIImage imageNamed:@"preview.png"];
	postPreviewController.postDetailViewController = self;
	[array addObject:postPreviewController];

	
	if(postSettingsController == nil) {
	 postSettingsController = [[WPPostSettingsController alloc] initWithNibName:@"WPPostSettingsController" bundle:nil];	
	}
	postSettingsController.title = @"Settings";
	postSettingsController.tabBarItem.image = [UIImage imageNamed:@"settings.png"];
	postSettingsController.postDetailViewController = self;
	[array addObject:postSettingsController];
	
	
	
	
	
	tabController.viewControllers = array;
	self.view = tabController.view;
	
	//lazy loading of nib by viewcontrollers we are unable to access the view outlets for the very first time.
	//with this viewcontroller will load the nib and connects view outlets.
	//in order to avoid delegate method calls i am setting to nil first and then resetting to self at the end.
	tabController.delegate = nil;
	tabController.selectedIndex = 1;
	tabController.selectedIndex = 2;
	tabController.selectedIndex = 3;
	tabController.selectedIndex = 0;
	tabController.delegate = self;

	[array release];
}

- (void)viewWillAppear:(BOOL)animated {
	NSLog(@"pdvc viewWillAppear");
	if(hasChanges == YES) {
		if ([self.navigationItem.leftBarButtonItem.title isEqualToString:@"Posts"])
			self.navigationItem.leftBarButtonItem.title = @"Cancel";
		self.navigationItem.rightBarButtonItem = saveButton;
	}
	else {
		UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] init];
		cancelButton.title = @"Posts";
		cancelButton.target = self;
		cancelButton.action = @selector(cancelView:);
		self.navigationItem.leftBarButtonItem = cancelButton;
		[cancelButton release];
		
		self.navigationItem.rightBarButtonItem = nil;
	}
	//	BlogDataManager *dataManager = [BlogDataManager sharedDataManager];
	//	NSLog(@"objects %@",postSettingsController.selectionTableViewController.table);
	//	NSLog(@"categories %@",[(NSArray *)[postSettingsController.selectionTableViewController.objects valueForKey:@"categoryName"] componentsJoinedByString:@","]);
	//	[dataManager.currentPost setValue: forKey:@"categories"];
	//categoryName
	
	[super viewWillAppear:animated];
	if( mode == 1 )
		[self refreshUIForCurrentPost];
	else if( mode == 0 )
		[self refreshUIForCompose];
	else if( mode == 2 )	//auto recovery mode
	{
		[self refreshUIForCurrentPost];
		self.hasChanges = YES;
	}

	mode = 3;
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	mode = 3;
	[postPreviewController stopLoading];
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}

- (void)didReceiveMemoryWarning {
		NSLog(@"%@ %@", self, NSStringFromSelector(_cmd));
	[super didReceiveMemoryWarning];
}

	
	
@end

