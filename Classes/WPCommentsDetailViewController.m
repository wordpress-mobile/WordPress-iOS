//
//  WPCommentsDetailViewController.m
//  WordPress
//
//  Created by ramesh kakula on 05/09/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "WPCommentsDetailViewController.h"
#import "BlogDataManager.h"


@implementation WPCommentsDetailViewController

@synthesize commentsTextView,commenterNameLabel,commentedOnLabel,commentedDateLabel;
@synthesize commentDetails;

/*
 // Override initWithNibName:bundle: to load the view using a nib file then perform additional customization that is not appropriate for viewDidLoad.
 - (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
 if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
 // Custom initialization
 }
 return self;
 }
 */

/*
 // Implement loadView to create a view hierarchy programmatically.
 - (void)loadView {
 }
 */

// Implement viewDidLoad to do additional setup after loading the view.
- (void)viewDidLoad {
	
	// "Segmented" control to the right
	UISegmentedControl *segmentedControl = [[[UISegmentedControl alloc] initWithItems:
											 [NSArray arrayWithObjects:
											  [UIImage imageNamed:@"up.png"],
											  [UIImage imageNamed:@"down.png"],
											  nil]] autorelease];
	[segmentedControl addTarget:self action:@selector(segmentAction:) forControlEvents:UIControlEventValueChanged];
	segmentedControl.frame = CGRectMake(0, 0, 90, kCustomButtonHeight);
	segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
	segmentedControl.momentary = YES;
	
	//	UIColor *defaultTintColor = [segmentedControl.tintColor retain];	// keep track of this for later
	
	segmentBarItem = [[UIBarButtonItem alloc] initWithCustomView:segmentedControl];
	self.navigationItem.rightBarButtonItem = segmentBarItem;
	//    self.navigationItem.title = @"1 of 1";
	
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}

- (void)segmentAction:(id)sender
{
    WPLog(@" The count %d  and current index %d",[commentDetails count], currentIndex);
    if(currentIndex > -1)
	{
		//        int i = currentIndex;
        if((currentIndex >0) && [sender selectedSegmentIndex] == 0)
        {
            WPLog(@"WPLog :segmentAction Tag:%d",[sender selectedSegmentIndex]);
            [self fillCommentDetails:commentDetails atRow:currentIndex-1];
        }    
        
        if( (currentIndex < [commentDetails count]-1) && [sender selectedSegmentIndex] == 1)
        {
            WPLog(@"WPLog :segmentAction Tag:%d",[sender selectedSegmentIndex]);
            [self fillCommentDetails:commentDetails atRow:currentIndex+1];
        }    
	}
	
}

- (void)deleteComment:(id)sender
{
         WPLog(@"WPLog :deleteComment");
	[self performSelectorInBackground:@selector(addProgressIndicator) withObject:nil];

	BlogDataManager *sharedDataManager = [BlogDataManager sharedDataManager];
	BOOL result = [sharedDataManager deleteComment:[commentDetails objectAtIndex:currentIndex] forBlog:[sharedDataManager currentBlog]];
	
	if ( result ) {
		[sharedDataManager loadCommentTitlesForCurrentBlog];
		[self.navigationController popViewControllerAnimated:YES];
	}
	[self performSelectorInBackground:@selector(removeProgressIndicator) withObject:nil];
}

- (void)approveComment:(id)sender
{
   WPLog(@"WPLog :approveComment");
 	return ;
    [self performSelectorInBackground:@selector(addProgressIndicator) withObject:nil];
	
	BlogDataManager *sharedDataManager = [BlogDataManager sharedDataManager];
	BOOL result = [sharedDataManager approveComment:[commentDetails objectAtIndex:currentIndex] forBlog:[sharedDataManager currentBlog]];
	if ( result ) {
		[sharedDataManager loadCommentTitlesForCurrentBlog];
		[self.navigationController popViewControllerAnimated:YES];
	}
	[self performSelectorInBackground:@selector(removeProgressIndicator) withObject:nil];
}

- (void)unApproveComment:(id)sender
{
    WPLog(@"WPLog :unApproveComment");
}


-(void)fillCommentDetails:(NSArray*)comments atRow:(int)row
{
	
    currentIndex = row;
	//    WPLog(@"I Am Here  %@ row %d",comments,row);
    self.commentDetails = comments;
	NSCharacterSet *whitespaceCS = [NSCharacterSet whitespaceCharacterSet];
	NSString *author = [[[commentDetails objectAtIndex:row] valueForKey:@"author"] stringByTrimmingCharactersInSet:whitespaceCS];
	NSString *post_title = [[[commentDetails objectAtIndex:row] valueForKey:@"post_title"]stringByTrimmingCharactersInSet:whitespaceCS];
	NSString *post_content = [[[commentDetails objectAtIndex:row] valueForKey:@"content"]stringByTrimmingCharactersInSet:whitespaceCS];
         NSDate *date_created_gmt = [[commentDetails objectAtIndex:row] valueForKey:@"date_created_gmt"];
	NSString *commentStatus = [[commentDetails objectAtIndex:row] valueForKey:@"status"];
	
    static NSDateFormatter *dateFormatter = nil;
	if (dateFormatter == nil) 
    {
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
	
	//    self.navigationItem.title = @"1 of 1";
	
	
	// WPLog(@" The Values .....  %@ %@ %@ ",author,post_title,date_created_gmt);
	
}

- (void)dealloc {
	
    [commentsTextView release];
    [commenterNameLabel release];
    [commentedOnLabel release];
    [commentedDateLabel release];
    [commentDetails release];
    
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
	while (self.navigationItem.rightBarButtonItem == nil)
	{
		[[NSRunLoop currentRunLoop] runUntilDate:[[NSDate date] addTimeInterval:0.1]];
	}
	
	self.navigationItem.rightBarButtonItem = segmentBarItem;
	[apool release];
}


@end
