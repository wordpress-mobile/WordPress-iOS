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
#import "WPAccount.h"
#import "Blog.h"

@interface ReaderUsersBlogsViewController ()<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *blogs;
@property (nonatomic, strong) NSNumber *primaryBlogId;

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
    [[[WordPressAppDelegate sharedWordPressApplicationDelegate] navigationController] presentViewController:navController animated:YES completion:nil];

	return controller;
}

#pragma mark - Lifecycle Methods

- (id)init {
	self = [super init];
	if (self) {
		self.blogs = [[WPAccount defaultWordPressComAccount] visibleBlogs];
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

- (NSString *)getCellTitleForBlog:(Blog *)blog {
    if ([[blog.blogName trim] length] == 0) {
        return blog.hostURL;
	} else {
        return blog.blogName;
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

    Blog *blog = [_blogs objectAtIndex:indexPath.row];
    cell.showTopSeparator = ( indexPath.row == 0 ) ? YES : NO;
    cell.title = [self getCellTitleForBlog:blog];
    cell.blavatarUrl = [blog blavatarUrl];
    
    return cell;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    Blog *blog = [_blogs objectAtIndex:indexPath.row];
    return [AddUsersBlogCell rowHeightWithText:[self getCellTitleForBlog:blog]];
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *dict = [_blogs objectAtIndex:indexPath.row];
	[self.delegate userDidSelectBlog:dict];
	
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end
