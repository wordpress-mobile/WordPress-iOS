//
//  BlogMainViewController.m
//  WordPress
//
//  Created by Janakiram on 01/09/08.
//  Copyright 2008 Effigent. All rights reserved.
//

#import "BlogMainViewController.h"
#import "PostsListController.h"
#import "BlogDetailModalViewController.h"
#import "BlogDataManager.h"
#import "Reachability.h"
#import "CommentsListController.h"
#import "PagesListController.h"

@implementation BlogMainViewController


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
		// Initialization code
		blogMainMenuContents = [[NSArray alloc] initWithObjects:@"Posts",@"Pages",@"Comments",nil];

	}
	return self;
}

/*
 Implement loadView if you want to create a view hierarchy programmatically
- (void)loadView {
}
 */

/*
 If you need to do additional setup after loading the view, override viewDidLoad.
- (void)viewDidLoad {
}
 */


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations
	return YES;
}


- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
	// Release anything that's not essential, such as cached data
}


- (void)dealloc {
	[blogMainMenuContents release];
	[super dealloc];
}


- (void)viewWillAppear:(BOOL)animated {
		
	BlogDataManager *sharedDataManager = [BlogDataManager sharedDataManager];
	[sharedDataManager loadCommentTitlesForCurrentBlog];

	NSArray *commentsList = [sharedDataManager commentTitlesForBlog:[sharedDataManager currentBlog]];
	awaitingComments = 0;
	
	for ( NSDictionary *dict in commentsList ) {
		WPLog(@"Comment Status is (%@)",[dict valueForKey:@"status"]);
		if ( [[dict valueForKey:@"status"] isEqualToString:@"hold"] ) {
			awaitingComments++;
		}
	}
	
	[postsTableView deselectRowAtIndexPath:[postsTableView indexPathForSelectedRow] animated:NO];
	[postsTableView reloadData];
	
	/* Set the Current Screen Title - JanakiRam */
	self.title = [[sharedDataManager currentBlog] valueForKey:@"blogName"];

	[super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated 
{
	self.title = @"Blogs";
	[super viewDidDisappear:animated];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (section == 0)
		return [blogMainMenuContents count];
	return 0;
}

//- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
//	return 56.0f;
//}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero] autorelease];
	if (indexPath.section == 0) 
	{
		cell.image =[UIImage imageNamed:@"DraftsFolder.png"];
		cell.text = [blogMainMenuContents objectAtIndex:(indexPath.row)];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		cell.font = [cell.font fontWithSize:17.0f];
		
		if ( indexPath.row == 2 ) { // Comments Section

			[[cell viewWithTag:99] removeFromSuperview];
			if ( awaitingComments > 0 ) {
#define LOCALDRAFT_ROW_HEIGHT 44.0f
#define LABEL_HEIGHT 35.0f
				UILabel *badgeLabel = [[UILabel alloc] initWithFrame:CGRectMake(210, (LOCALDRAFT_ROW_HEIGHT - LABEL_HEIGHT)/2 , 80, LABEL_HEIGHT)];
				[badgeLabel setTag:99];
				badgeLabel.textAlignment = UITextAlignmentRight;
				badgeLabel.font = cell.font;
				badgeLabel.text = [NSString stringWithFormat:@"(%d)",awaitingComments];
				[[cell contentView] addSubview:badgeLabel];
				[badgeLabel release];
			}
		}
	}
	return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
//#define LOCALDRAFT_ROW_HEIGHT 44.0f
//	return LOCALDRAFT_ROW_HEIGHT;
	return 44.0f;
}

// Show PostList when row is selected
- (void)tableView:(UITableView *)atableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	BlogDataManager *dataManager = [BlogDataManager sharedDataManager];
	if (indexPath.section == 0 ) {	
		
		if ( indexPath.row == 0 ) {

			PostsListController *postsListController = [[PostsListController alloc] initWithNibName:@"PostsListController" bundle:nil];
			
			postsListController.title = [[dataManager currentBlog] valueForKey:@"blogName"];
			[[self navigationController] pushViewController:postsListController animated:YES];
			[postsListController release];

		} else if ( indexPath.row == 2 ) { // Comments Section
			
			CommentsListController *commentsListController = [[CommentsListController alloc] initWithNibName:@"CommentsListController" bundle:nil];
			commentsListController.title = commentsListController.navigationItem.title =@"Comments";
			
			// set up the edit blog button
			UIBarButtonItem *editCommentButton = [[UIBarButtonItem alloc] 
												  initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
												  target:self
												  action:@selector(editComments:)];
			
			[self navigationController].navigationItem.rightBarButtonItem = editCommentButton;	
			[editCommentButton release];
		
			[[self navigationController] pushViewController:commentsListController animated:YES];
			[commentsListController release];
		}else if ( indexPath.row == 1 ) {
			PagesListController *pagesListController = [[PagesListController alloc] initWithNibName:@"PagesListController" bundle:nil];
			[[self navigationController] pushViewController:pagesListController animated:YES];
			[pagesListController release];
		}
	}
}

- (void)cancel:(id)sender {
	[self.navigationController popViewControllerAnimated:YES];
}

@end
