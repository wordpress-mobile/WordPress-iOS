//
//  CommentsListController.m
//  WordPress
//
//  Created by Janakiram on 02/09/08.
//  Copyright 2008 Effigent. All rights reserved.
//

#import "CommentsListController.h"

#import "XMLRPCRequest.h"
#import "XMLRPCResponse.h"
#import "XMLRPCConnection.h"
#import "BlogDataManager.h"


@implementation CommentsListController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
		// Initialization code
	}
	return self;
}

/*
 Implement loadView if you want to create a view hierarchy programmatically
- (void)loadView {
}
 */


// If you need to do additional setup after loading the view, override viewDidLoad.
- (void)viewDidLoad {
	
	
}
 


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
	// Release anything that's not essential, such as cached data
}


- (void)dealloc {
	[super dealloc];
}

- (IBAction)downloadRecentComments:(id)sender {
	
	[self getPostsForBlog:[[BlogDataManager sharedDataManager] currentBlog]];
}


// sync posts for a given blog
- (void) getPostsForBlog:(id)blog {
	WPLog(@"<<<<<<<<<<<<<<<<<< syncPostsForBlog >>>>>>>>>>>>>>");

	[blog setObject:[NSNumber numberWithInt:1] forKey:@"kIsSyncProcessRunning"];
	// Parameters
	NSString *username = [blog valueForKey:@"username"];
	NSString *pwd = [blog valueForKey:@"pwd"];
	NSString *fullURL = [blog valueForKey:@"xmlrpc"];
	NSString *blogid = [blog valueForKey:@"blogid"];

	
	//	WPLog(@"Fetching posts for blog %@ user %@/%@ from %@", blogid, username, pwd, fullURL);
	
	//  ------------------------- invoke metaWeblog.getRecentPosts
	XMLRPCRequest *postsReq = [[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:fullURL]];
	[postsReq setMethod:@"wp.getComments" 
			withObjects:[NSArray arrayWithObjects:blogid,username, pwd, nil]];
	
	NSArray *commentsList = [[BlogDataManager sharedDataManager] executeXMLRPCRequest:postsReq byHandlingError:YES];
	
	NSLog(@"commentsList is (%@)",commentsList);
}


@end