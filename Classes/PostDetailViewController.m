#import "PostDetailViewController.h"
#import "BlogDataManager.h"
#import "PostDetailEditController.h"
#import "WPPostDetailPreviewController.h"
#import "WPPostSettingsController.h"
#import "WPPhotosListViewController.h"
#import "WPNavigationLeftButtonView.h"
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
@synthesize leftView;

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
	
	if( [viewController.title isEqualToString:@"Photos"]){
		[photosListController refreshData];
	}
	
	if( [viewController.title isEqualToString:@"Preview"]){
		[postPreviewController refreshWebView];
	}else{
		[postPreviewController stopLoading];
	}
	
	if( [viewController.title isEqualToString:@"Settings"]){
		[postSettingsController reloadData];
	}
	
	if( [viewController.title isEqualToString:@"Write"]){
		[postDetailEditController refreshUIForCurrentPost];
	}
	
	self.title = viewController.title;
	
	if( hasChanges ) {
		if ([[leftView title] isEqualToString:@"Posts"])
			[leftView setTitle:@"Cancel"];
		
		self.navigationItem.rightBarButtonItem = saveButton;
	}
}

- (void)tabBarController:(UITabBarController *)tabBarController didEndCustomizingViewControllers:(NSArray *)viewControllers changed:(BOOL)changed 
{
	WPLog(@"tabBarController didEndCustomizingViewControllers");	
}

- (void)dealloc 
{
	[leftView release];
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
    WPLog(@" ENTRY FOR  POST   ");

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
	
	if( ![dm postDescriptionHasValidDescription:dm.currentPost] ){
		[self _cancel];
		return;
	}
	
	NSString *postStatus = [dm.currentPost valueForKey:@"post_status"];
	
	if( [postStatus isEqual:@"Local Draft"] )
		[self _saveAsDrft];
	else
	{ 
        //Need to release params
        NSMutableArray *params = [[NSMutableArray alloc] initWithObjects:dm.currentPost,dm.currentBlog,nil];
        //WPLog(@"params Are %@",params);
        [self addAsyncPostOperation:@selector(_savePostWithBlog:) withArg:params];
//      [self _savePost:dm.currentPost inBlog:dm.currentBlog];
    }   
}

- (void)autoSaveCurrentPost:(NSTimer *)aTimer
{
	
	if( !hasChanges ){
		WPLog(@"Returning -- hasChanges is false");
		return;
	}
	
	[postDetailEditController updateValuesToCurrentPost];
	[postSettingsController updateValuesToCurrentPost];
	
	BlogDataManager *dm = [BlogDataManager sharedDataManager];
	[dm autoSaveCurrentPost];
}

- (void)startTimer
{
	if( autoSaveTimer == nil ){
		autoSaveTimer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(autoSaveCurrentPost:) userInfo:nil repeats:YES];
		[autoSaveTimer retain];
	}else{
		WPLog(@"ERROR: There exits a timer, trying to create another timer object.");
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
		if ([[leftView title] isEqualToString:@"Posts"])
			[leftView setTitle:@"Cancel"];
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
	if( postIndex == -1 ){
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Draft Saved"
														message:@"Your post has been saved to the Local Drafts folder."
													   delegate:self
											  cancelButtonTitle:nil
											  otherButtonTitles:@"OK", nil];
		[alert show];
		[alert release];		
	}else {
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
    if ([[leftView title] isEqualToString:@"Posts"])
		[leftView setTitle:@"Cancel"];   
}

- (void)addAsyncPostOperation:(SEL)anOperation withArg:(id)anArg
{
    WPLog(@" addAsyncOperation :anOperation ....");
    if( ![self respondsToSelector:anOperation] ){
		WPLog(@"ERROR: %@ can't respond to the Operation %@.", @"Blog Data Manager", NSStringFromSelector(anOperation));
		return;
	}
    BlogDataManager *dm = [BlogDataManager sharedDataManager];
	NSString *postId=[dm savePostsFileWithAsynPostFlag:[anArg objectAtIndex:0]];
    NSMutableArray *argsArray=[NSMutableArray arrayWithArray:anArg];
    int count=[argsArray count];
    [argsArray insertObject:postId atIndex:count];
	NSInvocationOperation *op = [[NSInvocationOperation alloc] initWithTarget:self selector:anOperation object:argsArray];
	NSOperationQueue *asyncOperationsQueue=[dm asyncPostsOperationsQueue];
	[asyncOperationsQueue addOperation:op];
    [op release];
    
    hasChanges = NO;
    [dm removeAutoSavedCurrentPostFile];
    [self.navigationController popViewControllerAnimated:YES];
}

//- (void)_savePost:(id)aPost inBlog:(id)aBlog
-(void)_savePostWithBlog:(NSMutableArray *)arrayPost
{	
	BlogDataManager *dm = [BlogDataManager sharedDataManager];
    NSString *postId=[arrayPost lastObject];
    WPLog(@"Post id is %@",postId);    
   if( [dm savePost:[arrayPost objectAtIndex:0]]){
        [self stopTimer];
        NSMutableDictionary *dict=[[NSMutableDictionary alloc]init];
        [dict setValue:postId forKey:@"savedPostId"];
        [dict setValue:[[dm currentPost] valueForKey:@"postid"] forKey:@"originalPostId"];
        
       	[[NSNotificationCenter defaultCenter] postNotificationName:@"AsynchronousPostIsPosted" object:nil userInfo:dict];
        [dict release];
        return;
     }   
		hasChanges = YES;
       
/*
	[self performSelectorInBackground:@selector(addProgressIndicator) withObject:nil];
	BlogDataManager *dm = [BlogDataManager sharedDataManager];
//    [dm.currentPost setValue:[NSNumber numberWithInt:1] forKey:kAsyncPostFlag];
	//TODO: helps us in implementing async in future.
//	if( [dm savePost:aPost] )
	if( [dm savePost:[arrayPost objectAtIndex:0]])
	{
		[self removeProgressIndicator];
		hasChanges = NO;
		self.navigationItem.rightBarButtonItem = nil;
		[self stopTimer];
		[dm removeAutoSavedCurrentPostFile];
        		
//		NSString *statusDesc = [dm statusDescriptionForStatus:[aPost valueForKey:@"post_status"] fromBlog:aBlog];
		NSString *statusDesc = [dm statusDescriptionForStatus:[[arrayPost objectAtIndex:0] valueForKey:@"post_status"] fromBlog:[arrayPost objectAtIndex:1]];
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
*/

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
		if ([[leftView title] isEqualToString:@"Posts"])
			[leftView setTitle:@"Cancel"];
		
		self.navigationItem.rightBarButtonItem = saveButton;
	}
	
	NSNumber *postEdited = [NSNumber numberWithBool:hasChanges];
	[[[BlogDataManager sharedDataManager] currentPost] setObject:postEdited	forKey:@"hasChanges"];
}


#pragma mark - Overridden


- (void)viewDidLoad {
	[super viewDidLoad];
	
	
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
	
	if(!leftView){   
        leftView = [WPNavigationLeftButtonView createView];
        [leftView setTitle:@"Posts"];
    }   
}

- (void)viewWillAppear:(BOOL)animated {
	WPLog(@"pdvc viewWillAppear");
	
    [leftView setTarget:self withAction:@selector(cancelView:)];
	if(hasChanges == YES) {
		if ([[leftView title] isEqualToString:@"Posts"]){
            [leftView setTitle:@"Cancel"];
            WPLog(@" The Title is Set to Cancel");
        }
		
		self.navigationItem.rightBarButtonItem = saveButton;
	}else {
        [leftView setTitle:@"Posts"];
        WPLog(@" The Title is Set to Posts");
        self.navigationItem.rightBarButtonItem = nil;
	}
    // For Setting the Button with title Posts.
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithCustomView:leftView];
    self.navigationItem.leftBarButtonItem = cancelButton;
    [cancelButton release];
	
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
    WPLog(@" RR viewWillDisappear");
    mode = 3;
	[postPreviewController stopLoading];
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}

- (void)didReceiveMemoryWarning {
	WPLog(@"%@ %@", self, NSStringFromSelector(_cmd));
	[super didReceiveMemoryWarning];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if(tabController.selectedIndex == 0) // Only for Write Screen
	{
		WPLog(@"shouldAutorotateToInterfaceOrientation : Auto rotation is called..");
        return (interfaceOrientation == UIInterfaceOrientationLandscapeLeft || interfaceOrientation == UIInterfaceOrientationLandscapeRight ||
                interfaceOrientation == UIInterfaceOrientationPortrait);		
    }
    return NO;
}

@end

