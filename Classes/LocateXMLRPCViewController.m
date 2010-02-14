//
//  LocateXMLRPC.m
//  WordPress
//
//  Created by John Bickerstaff on 7/11/09.
// 
//

#import "LocateXMLRPCViewController.h"
#import "BlogDataManager.h"
#import "XMLRPCRequest.h"
#import "WordPressAppDelegate.h"


@implementation LocateXMLRPCViewController

@synthesize xmlrpcURLTextField, xmlrpcURLTableView;

//Add a cancel button and a save button.  EditBlogViewController will hopefully be an example of how to do so.
//if second time around, put value of last entry (currentBlog.xmlrpc) into text field
//if that's too hard, leave it...

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.navigationItem.rightBarButtonItem = saveXMLRPCButton;
	self.navigationItem.leftBarButtonItem = cancelXMLRPCButton;
	
	saveXMLRPCButton.enabled = NO;
	didUserEnterURL = NO;
	
	//if the value in currentBlog is not the default set when building the blog
	//the user has tried once before, but we got failure anyway.  Fat fingers being a possibility,
	//put the entry into the text field to assist the user in seeing any errors.
	BlogDataManager *dm = [BlogDataManager sharedDataManager];
	if ([dm.currentBlog objectForKey:@"xmlrpc"] != @"xmlrpc url not set"){
		xmlrpcURLTextField.text = [dm.currentBlog objectForKey:@"xmlrpc"];
	}
}


/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/


- (void)cancel:(id)sender {
	[xmlrpcURLTextField resignFirstResponder];
    [self.navigationController dismissModalViewControllerAnimated:YES];
}

- (IBAction)saveXMLRPCLocation:(id)sender{
	//save in here...
	[self textFieldDidEndEditing:xmlrpcURLTextField];
	[xmlrpcURLTextField resignFirstResponder];
	NSString *xmlrpcurl = xmlrpcURLTextField.text;
	//Now, test that we can actually access their blog with these values...
	//get xmlrpc from the text field
	//get a copy of currentBlog... Hmmm does this stuff exist yet? No, I bet blogid doesn't yet...
	// get blogid, username, pwd from currentBlog
	BlogDataManager *dm = [BlogDataManager sharedDataManager];
	XMLRPCRequest *listMethodsReq = [[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:xmlrpcurl]];
    [listMethodsReq setMethod:@"system.listMethods" withObjects:[NSArray array]];
    NSArray *listOfMethods = [dm executeXMLRPCRequest:listMethodsReq byHandlingError:YES];
	[dm printArrayToLog:listOfMethods andArrayName:@"list of methods from LocateXMLRPC...:-saveXMLRPCLocation"];
    [listMethodsReq release];
	
    if ([listOfMethods isKindOfClass:[NSError class]]){
       // we have an error - alert the user and do not proceed.  Worst case, the user can cancel.
		
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"We did not get a good response from the XMLRPC endpoint URL you supplied. Please check the URL, Network Connection and try again."
															   message:nil  
																delegate:self 
																cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];
		[alert release];
		return;
		
    } else {
		//continue
		[self saveUserEnteredXMLRPCEndpointToCurrentBlog:xmlrpcURLTextField];
		[self.navigationController dismissModalViewControllerAnimated:YES]; 
    }
	
	
	/*
	 if an attempted contact to the supplied URL with the correct username and password actually works{
	 then save the endpoint and dismiss the modalViewController
	 }else{
	 pop up a warning saying we were not able to contact their xmlrpc endpoint successfully
	 and are they sure the url is correct?
	 this gives them a cancel path out of this section of the app
	 */
}


#pragma mark 
#pragma mark Save Endpoint

- (void) saveUserEnteredXMLRPCEndpointToCurrentBlog:(UITextField *)textField{
	
	BlogDataManager *dm = [BlogDataManager sharedDataManager];
	NSString *xmlrpc = textField.text;
	NSLog(@"xmlrpc is %@", xmlrpc);
	[dm.currentBlog setObject:xmlrpc forKey:@"xmlrpc"];
}

#pragma mark 
#pragma mark Text Field Delegate Method(s)


//- (void)textFieldIsDone
//{
//	[urlTextField resignFirstResponder];
//	[self saveUserEnteredXMLRPCEndpointToCurrentBlog:textField];
//}

- (void)textFieldDidBeginEditing:(UITextField *)textField{
	saveXMLRPCButton.enabled = YES;
	if (!didUserEnterURL)
		textField.text = @"http://";
		
	
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
	didUserEnterURL = YES;
	
	
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	
	[textField resignFirstResponder];
	return YES;
	
}
#pragma mark 
#pragma mark Text Field Delegate Method(s)

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
		return xmlrpcURLTableViewCell;
}


#pragma mark -
- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
	[xmlrpcURLTextField release];
	[xmlrpcURLTableView release];
    [super dealloc];
}


@end
