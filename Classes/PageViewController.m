    //
//  PageViewController.m
//  WordPress
//
//  Created by Chris Boyd on 9/4/10.
//

#import "PageViewController.h"

@implementation PageViewController
@synthesize tabController, appDelegate, dm, selectedPostID, isPublished, pageManager, draftManager;

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
	[[NSNotificationCenter defaultCenter] postNotificationName:@"EditPageViewShouldDisappear" object:nil];
	[super viewWillDisappear:animated];
}

#pragma mark -
#pragma mark UITabBarController delegate

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
    tabBarController.title = @"Write";
}

#pragma mark -
#pragma mark Custom methods

- (void)refreshButtons:(BOOL)hasChanges keyboard:(BOOL)isShowingKeyboard {
	TransparentToolbar *buttonBar = [[TransparentToolbar alloc] initWithFrame:CGRectMake(0, 0, 70, 44)];
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
			buttonBar.frame = CGRectMake(0, 0, 130, 44);
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
		leftButton = nil;
	}
	
	self.navigationItem.leftBarButtonItem = leftButton;
	[leftButton release];
	
	[buttonBar setItems:buttons animated:NO];
	[buttons release];
	[buttonBar release];
}

- (IBAction)hideKeyboard:(id)sender {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"EditPageViewShouldHideKeyboard" object:nil];
}

- (IBAction)dismiss:(id)sender {
	self.selectedPostID = nil;
	[self.navigationController popViewControllerAnimated:YES];
}

- (void)setupBackButton {
	UIBarButtonItem *backButton = [[UIBarButtonItem alloc] init];
	backButton.title = @"Pages";
	self.navigationItem.backBarButtonItem = backButton;
	[backButton release]; 
}

- (IBAction)saveAction:(id)sender {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"EditPageViewShouldSave" object:nil];
}

- (IBAction)publishAction:(id)sender {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"EditPageViewShouldPublish" object:nil];
}

- (IBAction)cancelAction:(id)sender {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"EditPageViewShouldCancel" object:nil];
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
	[selectedPostID release];
	[tabController release];
    [super dealloc];
}


@end
