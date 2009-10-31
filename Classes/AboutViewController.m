#import "AboutViewController.h"
#import "WPNavigationLeftButtonView.h"
#import "WordPressAppDelegate.h"
#import "UIViewController+WPAnimation.h"


@interface AboutViewController ( privates )

-(void) loadWebView;

@end

@implementation AboutViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
		// Initialization code
	}
	return self;
}

- (void)viewWillAppear:(BOOL)animated {
	
	self.navigationController.navigationBarHidden= NO;
	self.title=@"Get 2.0 Now!";
	
	[super viewWillAppear:animated];
}
/*
 Implement loadView if you want to create a view hierarchy programmatically
- (void)loadView {
}
 */
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
	if (navigationType == UIWebViewNavigationTypeLinkClicked) {
		[[UIApplication sharedApplication] openURL:[request URL]];
		return NO;
	}
	return YES;
}


	//If you need to do additional setup after loading the view, override viewDidLoad.
- (void)viewDidLoad {
	WPNavigationLeftButtonView *myview = [WPNavigationLeftButtonView createCopyOfView];  
    [myview setTarget:self withAction:@selector(goToHome:)];
    [myview setTitle:@"Home"];
    UIBarButtonItem *barButton  = [[UIBarButtonItem alloc] initWithCustomView:myview];
    self.navigationItem.leftBarButtonItem = barButton;
    [barButton release];
    [myview release];
	
	[self loadWebView];
}

- (IBAction)goToHome:(id)sender {
	[self popTransition:self.navigationController.view];
}


- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	[self loadWebView];
}

-(void) loadWebView {
	NSString *version  = [[[NSBundle mainBundle] infoDictionary] valueForKey:[NSString stringWithFormat:@"CFBundleVersion"]];
	[webView loadHTMLString:[NSString stringWithFormat:@"<font face=\"Helvetica\"> <p style=\"color:rgb(51,51,51);padding-top:8px;\"><br><br><br><br><br><br><br><br><br><br><b style=\"font-size:18px;\">WordPress for iPhone</b><br>Version %@<br><br>"
							 
							 "A new version of WordPress for iPhone is now available. <br><br>WordPress for iPhone 2 is a free update that adds new features and a great new user interface.<br><br>"
							 "<a style=\"color:rgb(37,131,173);text-decoration:none\" href=\"http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewSoftware?id=335703880&mt=8\">Download it now from the App Store!</a></p></font>",version] baseURL:nil];
	[webView setBackgroundColor:[UIColor whiteColor]];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
	if([delegate isAlertRunning] == YES)
		return NO;
	
	// Return YES for supported orientations
	return YES;
}


- (void)didReceiveMemoryWarning {
	WPLog(@"%@ %@", self, NSStringFromSelector(_cmd));
	[super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
	// Release anything that's not essential, such as cached data
}


- (void)dealloc {
	[super dealloc];
}


@end