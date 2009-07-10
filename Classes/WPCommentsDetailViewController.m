//
//  WPCommentsDetailViewController.m
//  WordPress
//
//  Created by Janakiram on 05/09/08.
//

#import "WPCommentsDetailViewController.h"
#import "BlogDataManager.h"
#import "Reachability.h"
#import "WordPressAppDelegate.h"
#import "WPProgressHUD.h"

@interface WPCommentsDetailViewController (Private)
- (BOOL) isConnectedToHost;
- (void) moderateCommentWithSelector:(SEL)selector;
- (void) deleteThisComment;
- (void) approveThisComment;
- (void) markThisCommentAsSpam;
- (void) unapproveThisComment;
@end

@implementation WPCommentsDetailViewController

@synthesize commentsTextView,commenterNameLabel,commentedOnLabel,commentedDateLabel;
@synthesize commentDetails;

- (void)viewWillAppear:(BOOL)animated {
	[self performSelector:@selector(reachabilityChanged)];;
	
	[super viewWillAppear:animated];
}

- (void)reachabilityChanged
{
	connectionStatus = ( [[Reachability sharedReachability] remoteHostStatus] != NotReachable );
	UIColor *textColor = connectionStatus==YES ? [UIColor blackColor] : [UIColor grayColor];
	
	commenterNameLabel.textColor = textColor;
	commentedOnLabel.textColor = textColor;
	commentedDateLabel.textColor = textColor;
	commentsTextView.textColor = textColor;
		
}

// Implement viewDidLoad to do additional setup after loading the view.
- (void)viewDidLoad {
	
	// "Segmented" control to the right
	segmentedControl = [[UISegmentedControl alloc] initWithItems:
											 [NSArray arrayWithObjects:
											  [UIImage imageNamed:@"up.png"],
											  [UIImage imageNamed:@"down.png"],
											  nil]];
	[segmentedControl addTarget:self action:@selector(segmentAction:) forControlEvents:UIControlEventValueChanged];
	segmentedControl.frame = CGRectMake(0, 0, 90, kCustomButtonHeight);
	segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
	segmentedControl.momentary = YES;
	
	//	UIColor *defaultTintColor = [segmentedControl.tintColor retain];	// keep track of this for later
	
	segmentBarItem = [[UIBarButtonItem alloc] initWithCustomView:segmentedControl];
	self.navigationItem.rightBarButtonItem = segmentBarItem;
	
	// Observe the kNetworkReachabilityChangedNotification. When that notification is posted, the
	// method "reachabilityChanged" will be called. 
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged) name:@"kNetworkReachabilityChangedNotification" object:nil];	
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

#pragma mark -
#pragma mark action methods

- (void)segmentAction:(id)sender
{
    if(currentIndex > -1)
	{
        if((currentIndex >0) && [sender selectedSegmentIndex] == 0){          
            [self fillCommentDetails:commentDetails atRow:currentIndex-1];
        }
		
		if( (currentIndex < [commentDetails count]-1) && [sender selectedSegmentIndex] == 1){
             [self fillCommentDetails:commentDetails atRow:currentIndex+1];
        }
		
	}
}

- (void)deleteComment:(id)sender {
    progressAlert = [[WPProgressHUD alloc] initWithLabel:@"deleting"];
    [progressAlert show];
    
    [self performSelectorInBackground:@selector(deleteThisComment) withObject:nil];
}

- (void)approveComment:(id)sender {
    progressAlert = [[WPProgressHUD alloc] initWithLabel:@"moderating"];
    [progressAlert show];
    
    [self performSelectorInBackground:@selector(approveThisComment) withObject:nil];
}

- (void)unApproveComment:(id)sender {
    progressAlert = [[WPProgressHUD alloc] initWithLabel:@"moderating"];
    [progressAlert show];
    
    [self performSelectorInBackground:@selector(unapproveThisComment) withObject:nil];
}

- (void)spamComment:(id)sender {
    progressAlert = [[WPProgressHUD alloc] initWithLabel:@"moderating"];
    [progressAlert show];
    
    [self performSelectorInBackground:@selector(markThisCommentAsSpam) withObject:nil];
}

-(BOOL)isConnectedToHost {
    if (![[Reachability sharedReachability] remoteHostStatus] != NotReachable) {
        UIAlertView *connectionFailAlert = [[UIAlertView alloc] initWithTitle:@"No connection to host."
                                                                      message:@"Operation is not supported now."
                                                                     delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [connectionFailAlert show];
        [connectionFailAlert release];		
        return NO;
    }
    return YES;
}

- (void) moderateCommentWithSelector:(SEL)selector {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    if ([self isConnectedToHost]) {
        BlogDataManager *sharedDataManager = [BlogDataManager sharedDataManager];
        
        NSArray *selectedComment = [NSArray arrayWithObjects:[commentDetails objectAtIndex:currentIndex],nil];
        
        [sharedDataManager performSelector:selector withObject:selectedComment withObject:[sharedDataManager currentBlog]];
                
        [sharedDataManager loadCommentTitlesForCurrentBlog];
		[self.navigationController popViewControllerAnimated:YES]; 
    }
    [progressAlert dismissWithClickedButtonIndex:0 animated:YES];
    [progressAlert release];
    [pool release];
}

- (void) deleteThisComment {
    [self moderateCommentWithSelector:@selector(deleteComment:forBlog:)];
}

- (void) approveThisComment {
    [self moderateCommentWithSelector:@selector(approveComment:forBlog:)];
}

- (void) markThisCommentAsSpam {
    [self moderateCommentWithSelector:@selector(spamComment:forBlog:)];
}

- (void) unapproveThisComment {
    [self moderateCommentWithSelector:@selector(unApproveComment:forBlog:)];
}

-(void)fillCommentDetails:(NSArray*)comments atRow:(int)row
{
    currentIndex = row;
    self.commentDetails =(NSMutableArray *)comments;
	NSCharacterSet *whitespaceCS = [NSCharacterSet whitespaceCharacterSet];
	NSString *author = [[[commentDetails objectAtIndex:row] valueForKey:@"author"] stringByTrimmingCharactersInSet:whitespaceCS];
	NSString *post_title = [[[commentDetails objectAtIndex:row] valueForKey:@"post_title"]stringByTrimmingCharactersInSet:whitespaceCS];
	NSString *post_content = [[[commentDetails objectAtIndex:row] valueForKey:@"content"]stringByTrimmingCharactersInSet:whitespaceCS];
	NSDate *date_created_gmt = [[commentDetails objectAtIndex:row] valueForKey:@"date_created_gmt"];
	NSString *commentStatus = [[commentDetails objectAtIndex:row] valueForKey:@"status"];
	
    static NSDateFormatter *dateFormatter = nil;
	if (dateFormatter == nil){
        dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
		[dateFormatter setDateStyle:NSDateFormatterLongStyle];
	}
	
	commentedDateLabel.text  = [NSString stringWithFormat:@"%@",[[dateFormatter stringFromDate:date_created_gmt] description]];
	
    commenterNameLabel.text = author;
    commentedOnLabel.text = post_title; 
    commentsTextView.text = post_content;
    int count = [self.commentDetails count];
    self.navigationItem.title = [NSString stringWithFormat:@"%d of %d",row+1,count];    
	
	if ( [commentStatus isEqualToString:@"hold"] ) {	
		[approveAndUnapproveButtonBar setHidden:NO];
		[deleteButtonBar setHidden:YES];
	} else {
		[approveAndUnapproveButtonBar setHidden:YES];
		[deleteButtonBar setHidden:NO];
	}
	[approveButton setEnabled:NO];
	[unapproveButton setEnabled:NO];
	[spamButton1 setEnabled:YES];
	[spamButton2 setEnabled:YES];
	if ( [commentStatus isEqualToString:@"hold"] ) {
		[approveButton setEnabled:YES];
	
	}else if([commentStatus isEqualToString:@"approve"]){
		[unapproveButton setEnabled:YES];
	}else if([commentStatus isEqualToString:@"spam"]){
		[spamButton1 setEnabled:NO];
		[spamButton2 setEnabled:NO];
	}
	
	[segmentedControl setEnabled:TRUE forSegmentAtIndex:0];
	[segmentedControl setEnabled:TRUE forSegmentAtIndex:1];
	
	if(currentIndex==0)
		[segmentedControl setEnabled:FALSE forSegmentAtIndex:0];
	else if(currentIndex == [commentDetails count]-1)
		[segmentedControl setEnabled:FALSE forSegmentAtIndex:1];
	
}

- (void)dealloc {
	
    [commentsTextView release];
    [commenterNameLabel release];
    [commentedOnLabel release];
    [commentedDateLabel release];
    [commentDetails release];
	[segmentedControl release];
    [segmentBarItem release];
    [super dealloc];
	
}

@end