//
//  PageViewController.m
//  WordPress
//
//  Created by Chris Boyd on 9/4/10.
//

#import "PageViewController.h"
#import "EditPageViewController.h"

@implementation PageViewController
@synthesize tabController, mediaViewController, appDelegate, dm, selectedPostID, isPublished, pageManager, draftManager, canPublish, isEditing;

#pragma mark -
#pragma mark View lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
		[self setupBackButton];
    }
	
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [FlurryAPI logEvent:@"Page"];
	
	appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
	dm = [BlogDataManager sharedDataManager];
	draftManager = [[DraftManager alloc] init];
	
	if(pageManager == nil)
		pageManager = [[PageManager alloc] initWithXMLRPCUrl:[dm.currentBlog objectForKey:@"xmlrpc"]];
	
	self.navigationItem.title = @"Write";
	self.view = tabController.view;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self setupBackButton];
}

- (void)viewWillDisappear:(BOOL)animated {
	if (DeviceIsPad() == YES) {
		if ( selectedPostID == nil /*||  [selectedPostID isEqual:@"0"] */) //page is not saved yet!
			[[NSNotificationCenter defaultCenter] postNotificationName:@"EditPageViewShouldDisappear" object:nil];
		else if([draftManager exists:selectedPostID] ){ //page was deleted
			[[NSNotificationCenter defaultCenter] postNotificationName:@"EditPageViewShouldDisappear" object:nil];
		} else { 
			[[NSNotificationCenter defaultCenter] postNotificationName:@"EditPageViewIsDeleted" object:nil];
		}
	} else 
		[[NSNotificationCenter defaultCenter] postNotificationName:@"EditPageViewShouldDisappear" object:nil];
	
	[super viewWillDisappear:animated];
}

#pragma mark -
#pragma mark UITabBarController delegate

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
    tabBarController.title = @"Write";
	if (viewController == mediaViewController) {
		[mediaViewController addNotifications];
	} else {
		[mediaViewController removeNotifications];
	}
}

#pragma mark -
#pragma mark Custom methods

- (void)refreshButtons:(BOOL)hasChanges keyboard:(BOOL)isShowingKeyboard {
	TransparentToolbar *buttonBar = [[TransparentToolbar alloc] initWithFrame:CGRectMake(0, 0, 55, 44)];
	NSMutableArray *buttons = [[NSMutableArray alloc] initWithCapacity:3];
	
	if(hasChanges == YES) {
		UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] init];
		saveButton.title = @"Save";
		saveButton.target = self;
		saveButton.style = UIBarButtonItemStyleBordered;
		saveButton.action = @selector(saveAction:);
		[buttons addObject:saveButton];
		[saveButton release];
	}
	
	if((self.isPublished == NO) && (hasChanges == YES)) {
		if(buttons.count > 0) {
			buttonBar.frame = CGRectMake(0, 0, 125, 44);
			UIBarButtonItem *spacer = [[UIBarButtonItem alloc]
									   initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
									   target:nil
									   action:nil];
			[buttons addObject:spacer];
			[spacer release];
		}
		
		UIBarButtonItem *publishButton = [[UIBarButtonItem alloc] init];
		publishButton.title = @"Publish";
		publishButton.target = self;
		publishButton.style = UIBarButtonItemStyleDone;
		publishButton.action = @selector(publishAction:);
		if(self.canPublish == NO)
			publishButton.enabled = NO;
		[buttons addObject:publishButton];
		
		[publishButton release];
	}
	else {
		if(buttons.count > 0) {
			UIBarButtonItem *saveButton = [buttons objectAtIndex:0];
			saveButton.style = UIBarButtonItemStyleDone;
		}
	}
	
	if(buttons.count > 0)
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:buttonBar];
	else
		self.navigationItem.rightBarButtonItem = nil;
	
	// Left side
	if (!DeviceIsPad()){
	UIBarButtonItem *leftButton = [[UIBarButtonItem alloc] init];
	leftButton.target = self;
	leftButton.style = UIBarButtonItemStyleBordered;
	
	if(isShowingKeyboard == YES) {
		leftButton.title = @"Done";
		leftButton.action = @selector(hideKeyboard:);
	}
	else if(hasChanges == YES) {
		leftButton.title = @"Cancel";
		leftButton.action = @selector(cancelAction:);
	}
	else {
        [leftButton release];
		leftButton = nil;
	}
	
	self.navigationItem.leftBarButtonItem = leftButton;
	[leftButton release];
	}
	
	[buttonBar setItems:buttons animated:NO];
	[buttons release];
	[buttonBar release];
}

- (IBAction)hideKeyboard:(id)sender {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"EditPageViewShouldHideKeyboard" object:nil];
}

- (IBAction)dismiss:(id)sender {
	// TODO: remove the mediaViewController notifications - this is pretty kludgy
	[mediaViewController removeNotifications];
	self.selectedPostID = nil;
	
	if(DeviceIsPad() == NO)
		[self.navigationController popViewControllerAnimated:YES];
}

- (void)setupBackButton {
	UIBarButtonItem *backButton = [[UIBarButtonItem alloc] init];
	backButton.title = @"Pages";
	self.navigationItem.backBarButtonItem = backButton;
	[backButton release]; 
}

- (IBAction)saveAction:(id)sender {
	// TODO: remove the mediaViewController notifications - this is pretty kludgy
	[mediaViewController removeNotifications];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"EditPageViewShouldSave" object:nil];
}

- (IBAction)publishAction:(id)sender {
	// TODO: remove the mediaViewController notifications - this is pretty kludgy
	[mediaViewController removeNotifications];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"EditPageViewShouldPublish" object:nil];
}

- (IBAction)cancelAction:(id)sender {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"EditPageViewShouldCancel" object:nil];
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
            if (self.isEditing == NO) {
				//  [postDetailEditController setTextViewHeight:57]; //#148
            } else {
				[[NSNotificationCenter defaultCenter] postNotificationName:@"EditPageViewShouldResizeContentArea" object:nil];
                //[postDetailEditController setTextViewHeight:116];
				return YES;
            }
        }
    }
	
    //return YES;
	return NO; //trac ticket #148
}

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)orientation duration:(NSTimeInterval)duration {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"EditPageViewShouldStopEditing" object:nil];
}

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

#pragma mark -
#pragma mark Dealloc

- (void)dealloc {
	[mediaViewController release];
	[selectedPostID release];
	[tabController release];
    [super dealloc];
}


@end
