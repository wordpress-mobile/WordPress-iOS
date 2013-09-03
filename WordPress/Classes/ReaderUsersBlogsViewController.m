//
//  ReaderUsersBlogsViewController.m
//  WordPress
//
//  Created by Eric J on 6/6/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "ReaderUsersBlogsViewController.h"
#import "AddUsersBlogCell.h"
#import "WordPressAppDelegate.h"
#import "WPNUXUtility.h"

@interface ReaderUsersBlogsViewController ()<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *blogs;
@property (nonatomic, strong) NSNumber *primaryBlogId;

- (NSString *)getCellTitleForIndexPath:(NSIndexPath *)indexPath;
- (void)handleCloseButtonTapped:(id)sender;

@end

@implementation ReaderUsersBlogsViewController

+ (id)presentAsModalWithDelegate:(id<ReaderUsersBlogsDelegate>)delegate {
	ReaderUsersBlogsViewController *controller = [[ReaderUsersBlogsViewController alloc] init];
	controller.delegate = delegate;
	controller.title = NSLocalizedString(@"My Blogs", @"Title of the list of the user's blogs as shown in the reader.");
	
	UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
    navController.navigationBar.translucent = NO;
	navController.modalPresentationStyle = UIModalPresentationFormSheet;
    if (!IS_IPAD) {
        // Avoid a weird issue on the iPad with cross dissolves when the keyboard is visible. 
        navController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    }
    [[[WordPressAppDelegate sharedWordPressApplicationDelegate] panelNavigationController] presentViewController:navController animated:YES completion:nil];

	return controller;
}

#pragma mark - Lifecycle Methods

- (id)init {
	self = [super init];
	if (self) {
		self.blogs = [[NSUserDefaults standardUserDefaults] arrayForKey:@"wpcom_users_blogs"];
		self.primaryBlogId = [[NSUserDefaults standardUserDefaults] objectForKey:@"wpcom_users_prefered_blog_id"];
	}
	return self;
}

- (void)viewDidLoad {
	
	self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"ui-texture"]];
    self.view.backgroundColor = [WPNUXUtility backgroundColor];
	
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
	_tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _tableView.backgroundColor = [UIColor clearColor];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.view addSubview:_tableView];
	
	if (self.navigationItem.leftBarButtonItem == nil) {
		self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", @"")
																		style:[WPStyleGuide barButtonStyleForBordered]
																	   target:self
																	   action:@selector(handleCloseButtonTapped:)];
	}
	
	[_tableView reloadData];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return [super shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}


#pragma mark - Instance Methods

- (NSString *)getCellTitleForIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *dict = [_blogs objectAtIndex:indexPath.row];
    if ([[[dict objectForKey:@"blogName"] trim] length] == 0) {
        return [dict objectForKey:@"url"];
	} else {
        return [dict objectForKey:@"blogName"];
	}
}


- (void)handleCloseButtonTapped:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - UITableView Delegate Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_blogs count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    AddUsersBlogCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[AddUsersBlogCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
		[cell hideCheckmark:YES];
		UIView *backgroundView = [[UIView alloc] initWithFrame:cell.frame];
		backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		backgroundView.backgroundColor = [UIColor colorWithRed:192.0f/255.0f green:192.0f/255.0f blue:192.0f/255.0f alpha:1.0f];
		cell.selectedBackgroundView = backgroundView;
		cell.isWPCom = YES;
    }

    NSDictionary *dict = [_blogs objectAtIndex:indexPath.row];
    cell.showTopSeparator = ( indexPath.row == 0 ) ? YES : NO;
    cell.title = [self getCellTitleForIndexPath:indexPath];
    cell.blavatarUrl = [dict objectForKey:@"url"];
    
    return cell;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [AddUsersBlogCell rowHeightWithText:[self getCellTitleForIndexPath:indexPath]];
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *dict = [_blogs objectAtIndex:indexPath.row];
	[self.delegate userDidSelectBlog:dict];
	
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end
