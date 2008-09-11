#import "AboutViewController.h"


@implementation AboutViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
		// Initialization code
	}
	return self;
}

- (IBAction)aboutViewControllerBackAction:(id)sender
{
	[self.navigationController popViewControllerAnimated:YES];
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
	NSString *version  = [[[NSBundle mainBundle] infoDictionary] valueForKey:[NSString stringWithFormat:@"CFBundleVersion"]];
	[webView loadHTMLString:[NSString stringWithFormat:@"<font face=\"Helvetica\"> <p style=\"color:rgb(51,51,51);\"><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><b style=\"font-size:18px;\"><br>WordPress for iPhone</b><br>Version %@<br><br>"
	"An Open Source iPhone app for WordPress blogs.<br><br>"
	"Designed by Automattic in Alabama. Developed by Effigent and the WordPress community.<br><br>"
	 "For more information or to contribute to the project,<br />visit our web site at <a style=\"color:rgb(37,131,173);text-decoration:none\" href=\"http://iphone.wordpress.net/\">iphone.wordpress.org</a>.</p></font>",version] baseURL:nil];
}



- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations
	return NO;
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
