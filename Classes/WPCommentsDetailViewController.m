//
//  WPCommentsDetailViewController.m
//  WordPress
//
//  Created by Janakiram on 05/09/08.
//  Copyright 2008 Effigent. All rights reserved.
//

#import "WPCommentsDetailViewController.h"
#import "BlogDataManager.h"
#import "Reachability.h"
#import "WordPressAppDelegate.h"


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

- (void)deleteComment:(id)sender
{
    UIAlertView *deleteAlert = [[UIAlertView alloc] initWithTitle:@"Delete Comment" message:@"Are you sure you want to delete this comment?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];                                                
    [deleteAlert setTag:1];  // for UIAlertView Delegate to handle which view is popped.
    [deleteAlert show];
	WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
	[delegate setAlertRunning:YES];

}

- (void)approveComment:(id)sender
{
	UIAlertView *deleteAlert = [[UIAlertView alloc] initWithTitle:@"Approve Comment" message:@"Are you sure you want to approve this comment?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];                                                
	[deleteAlert setTag:2];  // for UIAlertView Delegate to handle which view is popped.
	[deleteAlert show];
	WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
	[delegate setAlertRunning:YES];

}

- (void)unApproveComment:(id)sender
{
	UIAlertView *deleteAlert = [[UIAlertView alloc] initWithTitle:@"Unapprove Comment" message:@"Are you sure you want to unapprove this comment?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];  
	[deleteAlert setTag:3];  // for UIAlertView Delegate to handle which view is popped.
	[deleteAlert show];
	WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
	[delegate setAlertRunning:YES];

}

- (void)spamComment:(id)sender
{
	UIAlertView *deleteAlert = [[UIAlertView alloc] initWithTitle:@"Spam Comment" message:@"Are you sure you want to mark the comment as spam?. This action can only be reversed in the web admin." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
	[deleteAlert setTag:4];  // for UIAlertView Delegate to handle which view is popped.
	[deleteAlert show];
	WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
	[delegate setAlertRunning:YES];

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
	NSAutoreleasePool *apool = [[NSAutoreleasePool alloc] init];
	while (self.navigationItem.rightBarButtonItem == nil){
		[[NSRunLoop currentRunLoop] runUntilDate:[[NSDate date] addTimeInterval:0.1]];
	}
	
	self.navigationItem.rightBarButtonItem = segmentBarItem;
	[apool release];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	//optimised code but need to comprimise at Alert messages.....Common message for all @"Operation is not supported now."
	if ( buttonIndex == 1 )		 // OK
	{
			if ( ![[Reachability sharedReachability] remoteHostStatus] != NotReachable ) {
			
			UIAlertView *alert1 = [[UIAlertView alloc] initWithTitle:@"No connection to host."
															 message:@"Operation is not supported now."
															delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
			[alert1 show];
			[alert1 release];		
			return;
		}  
		
		[self performSelectorInBackground:@selector(addProgressIndicator) withObject:nil];
		BlogDataManager *sharedDataManager = [BlogDataManager sharedDataManager];

		BOOL result;
		NSArray *selectedComments=[NSArray arrayWithObjects:[commentDetails objectAtIndex:currentIndex],nil];
		if([alertView tag] == 1){
			result = [sharedDataManager deleteComment:selectedComments forBlog:[sharedDataManager currentBlog]];
		} else if([alertView tag] == 2){
			result = [sharedDataManager approveComment:(NSMutableArray *)selectedComments forBlog:[sharedDataManager currentBlog]];
		} else if([alertView tag] == 3){
			result = [sharedDataManager unApproveComment:(NSMutableArray *)selectedComments forBlog:[sharedDataManager currentBlog]];
		}else if([alertView tag] == 4){
			result = [sharedDataManager spamComment:(NSMutableArray *)selectedComments forBlog:[sharedDataManager currentBlog]];
		}
		
		[sharedDataManager loadCommentTitlesForCurrentBlog];
		[self.navigationController popViewControllerAnimated:YES];
		
		[self performSelectorInBackground:@selector(removeProgressIndicator) withObject:nil];
    }
    [alertView autorelease];
	WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
	[delegate setAlertRunning:NO];

}

@end