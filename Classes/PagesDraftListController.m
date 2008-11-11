//
//  PagesDraftListController.m
//  WordPress
//
//  Created by JanakiRam on 06/11/08.
//  Copyright 2008 Prithvi Information Solutions Limited. All rights reserved.
//

#import "PagesDraftListController.h"
#import "BlogDataManager.h"
#import "PagesListController.h"
#import "PageDetailViewController.h"
#import "PageDetailsController.h"


@implementation PagesDraftListController
@synthesize pagesListController;


- (id)initWithStyle:(UITableViewStyle)style {
	if (self = [super initWithStyle:style]) {
	}
	return self;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [dm numberOfPageDrafts];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	static NSString *MyIdentifier = @"DraftsTableCell";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:MyIdentifier] autorelease];
	}
	// Configure the cell
	cell.text = [[dm pageDraftTitleAtIndex:indexPath.row] valueForKey:@"title"];
	cell.font = [cell.font fontWithSize:15.0f];
	return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	[dm makePageDraftAtIndexCurrent:indexPath.row];
	PageDetailsController *pageDetailsController=pagesListController.pageDetailsController;
	pageDetailsController.mode = 1; 
	[tableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:YES];
	WPLog(@"11111AFTER makePageDraftAtIndexCurrent-------%@",pageDetailsController);

	WPLog(@"11111AFTER makePageDraftAtIndexCurrent ----%@",pagesListController.pageDetailsController);

	[[pagesListController navigationController] pushViewController:pagesListController.pageDetailsController animated:YES];
}



- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	
	if (editingStyle == UITableViewCellEditingStyleDelete) {
//		if( [dm deleteDraftAtIndex:indexPath.row forBlog:dm.currentBlog] )
//		{
//			[dm loadPageDraftTitlesForCurrentBlog];
//			[tableView reloadData];			
//		}
		
	}
	if (editingStyle == UITableViewCellEditingStyleInsert) {
	}
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}

- (UITableViewCellAccessoryType)tableView:(UITableView *)tableView accessoryTypeForRowWithIndexPath:(NSIndexPath *)indexPath
{
	return UITableViewCellAccessoryDisclosureIndicator;
}



- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"DraftsUpdated" object:nil];
	[super dealloc];
}


- (void)viewDidLoad {
	[super viewDidLoad];
	dm = [BlogDataManager sharedDataManager];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePostsAndDraftsList) name:@"DraftsUpdated" object:nil];

}

- (void)updatePostsAndDraftsList{
	WPLog(@"updatePostsAndDraftsList");
	[self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	self.navigationItem.title = [NSString stringWithFormat:@"Local Drafts"];
	[(UITableView *) self.view reloadData];
	
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations
	return YES;
}


@end