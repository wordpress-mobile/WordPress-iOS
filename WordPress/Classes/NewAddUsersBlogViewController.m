//
//  NewAddUsersBlogViewController.m
//  WordPress
//
//  Created by Sendhil Panchadsaram on 5/2/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <WordPressApi/WordPressApi.h>
#import <SVProgressHUD/SVProgressHUD.h>
#import "WordPressAppDelegate.h"
#import "UIView+FormSheetHelpers.h"
#import "NewAddUsersBlogViewController.h"
#import "WPNUXPrimaryButton.h"
#import "WPNUXSecondaryButton.h"
#import "AddUsersBlogCell.h"
#import "SFHFKeychainUtils.h"
#import "NSString+XMLExtensions.h"
#import "WordPressComApi.h"
#import "Blog.h"

@interface NewAddUsersBlogViewController () <
    UITableViewDelegate,
    UITableViewDataSource> {
    NSArray *_usersBlogs;
    NSMutableArray *_selectedBlogs;
    WPNUXSecondaryButton *_selectAllButton;
    WPNUXPrimaryButton *_addSelectedButton;
    
    CGFloat _viewWidth;
    CGFloat _viewHeight;
}

@property (nonatomic, strong) UITableView *tableView;

@end

@implementation NewAddUsersBlogViewController

CGFloat const AddUsersBlogHeaderHeight = 164.0;
CGFloat const AddUsersBlogStandardOffset = 16.0;
CGFloat const AddUsersBlogLoadingViewHeight = 100.0;
CGFloat const AddUsersBlogTitleVerticalOffset = 23.0;
CGFloat const AddUsersBlogMaxTextWidth = 289.0;
CGFloat const AddUsersBlogBottomBackgroundHeight = 64;


- (id)init
{
    self = [super init];
    if (self) {
        _selectedBlogs = [[NSMutableArray alloc] init];
        _autoAddSingleBlog = true;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _viewWidth = [self.view formSheetViewWidth];
    _viewHeight = [self.view formSheetViewHeight];
        
    [self addTableView];
    [self addBottomPanel];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self refreshBlogs];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return [super shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}

- (void)addSingleBlog
{
    if ([_usersBlogs count] != 1)
        return;
    
    [self createBlog:[_usersBlogs objectAtIndex:0]];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_usersBlogs count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    AddUsersBlogCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[AddUsersBlogCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }

    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.isWPCom = self.isWPCom;
    
    NSDictionary *blogData = [_usersBlogs objectAtIndex:indexPath.row];
    cell.showTopSeparator = indexPath.row == 0;
    cell.title = [blogData objectForKey:@"blogName"];
    cell.blavatarUrl = [blogData objectForKey:@"url"];
    cell.selected = [_selectedBlogs containsObject:[blogData objectForKey:@"blogid"]];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *blogData = [_usersBlogs objectAtIndex:indexPath.row];
    return [AddUsersBlogCell rowHeightWithText:[blogData objectForKey:@"blogName"]];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *blogData = [_usersBlogs objectAtIndex:indexPath.row];
    NSString *blogId = [blogData objectForKey:@"blogid"];
    if ([_selectedBlogs containsObject:blogId]) {
        [_selectedBlogs removeObject:blogId];
    } else {
        [_selectedBlogs addObject:blogId];
    }
    [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    [self toggleButtons];
}

#pragma mark - Private Methods

- (void)addTableView
{
    CGRect tableViewFrame = CGRectMake(0, 0, _viewWidth, _viewHeight);
    tableViewFrame.size.height -= AddUsersBlogBottomBackgroundHeight;
    
    self.tableView = [[UITableView alloc] initWithFrame:tableViewFrame style:UITableViewStylePlain];
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.view.backgroundColor = [UIColor colorWithRed:30.0/255.0 green:140.0/255.0 blue:190.0/255.0 alpha:1.0];
    self.tableView.tableHeaderView = [self headerView];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.view addSubview:self.tableView];
}

- (void)addBottomPanel
{
    UIView *bottomPanel = [[UIView alloc] init];
    bottomPanel.backgroundColor = [UIColor colorWithRed:42.0/255.0 green:42.0/255.0 blue:42.0/255.0 alpha:1.0];
    bottomPanel.frame = CGRectMake(0, CGRectGetMaxY(self.tableView.frame), _viewWidth, AddUsersBlogBottomBackgroundHeight);
    [self.view addSubview:bottomPanel];
    
    UIView *bottomPanelLine = [[UIView alloc] init];
    bottomPanelLine.backgroundColor = [UIColor colorWithRed:17.0/255.0 green:17.0/255.0 blue:17.0/255.0 alpha:0.95];
    bottomPanelLine.frame = CGRectMake(0, CGRectGetMinY(bottomPanel.frame), _viewWidth, 1);
    [self.view addSubview:bottomPanel];
    
    _selectAllButton = [[WPNUXSecondaryButton alloc] init];
    [_selectAllButton setTitle:NSLocalizedString(@"Select All", nil) forState:UIControlStateNormal];
    [_selectAllButton sizeToFit];
    [_selectAllButton addTarget:self action:@selector(selectAllBlogs) forControlEvents:UIControlEventTouchUpInside];
    [bottomPanel addSubview:_selectAllButton];
    CGFloat selectAllWidth = CGRectGetWidth(_selectAllButton.frame);
    // This part is to ensure that we have the larger of the two widths for the two text options for this button
    // so that regardless of what text is in the button it will fit
    [_selectAllButton setTitle:NSLocalizedString(@"Deselect All", nil) forState:UIControlStateNormal];
    [_selectAllButton sizeToFit];
    CGFloat deselectAllWidth = CGRectGetWidth(_selectAllButton.frame);
    [_selectAllButton setTitle:NSLocalizedString(@"Select All", nil) forState:UIControlStateNormal];
    CGRect selectAllFrame = _selectAllButton.frame;
    selectAllFrame.size.width = selectAllWidth > deselectAllWidth ? selectAllWidth : deselectAllWidth;
    
    _addSelectedButton = [[WPNUXPrimaryButton alloc] init];
    [_addSelectedButton setTitle:NSLocalizedString(@"Add Selected", nil) forState:UIControlStateNormal];
    [_addSelectedButton sizeToFit];
    [_addSelectedButton addTarget:self action:@selector(createBlogs) forControlEvents:UIControlEventTouchUpInside];
    [bottomPanel addSubview:_addSelectedButton];
    
    CGFloat x,y;
    x = AddUsersBlogStandardOffset;
    y = AddUsersBlogStandardOffset;
    _selectAllButton.frame = CGRectMake(x, y, CGRectGetWidth(_selectAllButton.frame), CGRectGetHeight(_selectAllButton.frame));
    
    x = _viewWidth - CGRectGetWidth(_addSelectedButton.frame) - AddUsersBlogStandardOffset;
    y = AddUsersBlogStandardOffset;
    _addSelectedButton.frame = CGRectMake(x, y, CGRectGetWidth(_addSelectedButton.frame), CGRectGetHeight(_addSelectedButton.frame));
}

- (UIView *)headerView
{
    CGFloat x, y;
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, _viewWidth, AddUsersBlogHeaderHeight)];
    headerView.backgroundColor = [UIColor clearColor];
        
    UILabel *title = [[UILabel alloc] init];
    title.backgroundColor = [UIColor clearColor];
    title.textAlignment = UITextAlignmentCenter;
    title.lineBreakMode = UILineBreakModeWordWrap;
    title.font = [UIFont fontWithName:@"OpenSans-Light" size:29.0];
    title.text = NSLocalizedString(@"Select the sites you want to add", nil);
    title.shadowColor = [UIColor colorWithRed:0.0 green:115.0/255.0 blue:164.0/255.0 alpha:0.5];
    title.shadowOffset = CGSizeMake(0.0, 1.0);
    title.textColor = [UIColor whiteColor];
    title.numberOfLines = 0;
    CGSize titleSize = [title.text sizeWithFont:title.font constrainedToSize:CGSizeMake(AddUsersBlogMaxTextWidth, CGFLOAT_MAX) lineBreakMode:UILineBreakModeWordWrap];
    x = (_viewWidth - titleSize.width)/2.0;
    y = CGRectGetHeight(headerView.frame) - titleSize.height - AddUsersBlogTitleVerticalOffset;
    title.frame = CGRectMake(x, y, titleSize.width, titleSize.height);
    [headerView addSubview:title];
    
    return headerView;
}

- (UIView *)loadingView
{
    CGFloat x,y;
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, _viewWidth, AddUsersBlogLoadingViewHeight)];
    
    // Create Activity Indicator
    CGFloat activityIndicatorHeight = 20.0;
    CGFloat activityIndicatorWidth = 20.0;
    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] init];
    activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
    x = (_viewWidth - activityIndicatorHeight)/2.0;
    y = 0;
    activityIndicator.frame = CGRectMake(x, y, activityIndicatorWidth, activityIndicatorHeight);
    [activityIndicator startAnimating];
    [view addSubview:activityIndicator];
    
    // Create Loading Label
    UILabel *loading = [[UILabel alloc] init];
    loading.backgroundColor = [UIColor clearColor];
    loading.textColor = [UIColor whiteColor];
    loading.shadowColor = [UIColor blackColor];
    loading.text = NSLocalizedString(@"Loading sites...", nil);
    loading.font = [UIFont fontWithName:@"OpenSans" size:15.0];
    [loading sizeToFit];
    x = (_viewWidth - CGRectGetWidth(loading.frame))/2.0;
    y = CGRectGetMaxY(activityIndicator.frame) + AddUsersBlogStandardOffset;
    loading.frame = CGRectIntegral(CGRectMake(x, y, CGRectGetWidth(loading.frame), CGRectGetHeight(loading.frame)));
    [view addSubview:loading];
    
    return view;
}

- (UIView *)checkmarkAccessoryView
{
    UIImage *image = [UIImage imageNamed:@"addBlogsSelectedImage"];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    return imageView;
}

- (void)refreshBlogs
{
    NSURL *xmlrpc;
    NSString *username = self.username;
    NSString *password = self.password;
    if (self.isWPCom) {
        xmlrpc = [NSURL URLWithString:@"https://wordpress.com/xmlrpc.php"];
    } else {
        xmlrpc = [NSURL URLWithString:self.xmlRPCUrl];
    }
    
    [self.tableView reloadData];
    [SVProgressHUD showWithStatus:NSLocalizedString(@"Loading sites...", nil) maskType:SVProgressHUDMaskTypeBlack];
    
    WPXMLRPCClient *api = [WPXMLRPCClient clientWithXMLRPCEndpoint:xmlrpc];
    [api callMethod:@"wp.getUsersBlogs"
         parameters:[NSArray arrayWithObjects:username, password, nil]
            success:^(AFHTTPRequestOperation *operation, id responseObject) {
                [SVProgressHUD dismiss];
                [self storeUsersVisibleBlogs:responseObject];
                
                if (_usersBlogs.count == 0) {
                    if (self.onNoBlogsLoaded) {
                        self.onNoBlogsLoaded(self);
                    }
                } else {
                    [_usersBlogs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                        NSString *title = [obj valueForKey:@"blogName"];
                        title = [title stringByDecodingXMLCharacters];
                        [obj setValue:title forKey:@"blogName"];
                    }];
                    
                    // Select First Blog
                    NSString *firstBlogId = [[_usersBlogs objectAtIndex:0] objectForKey:@"blogid"];
                    if (![_selectedBlogs containsObject:firstBlogId]) {
                        [_selectedBlogs addObject:firstBlogId];                        
                    }
                    
                    if(_usersBlogs.count == 1 && self.autoAddSingleBlog) {
                        [self selectAllBlogs];
                        [self createBlogs];
                    }
                }
                                
                [self toggleButtons];
                [self.tableView reloadData];
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                [SVProgressHUD dismiss];
                [self.tableView reloadData];
                WPFLog(@"Failed getting user blogs: %@", [error localizedDescription]);
                if (self.onErrorLoading) {
                    self.onErrorLoading(self, error);
                }
            }];
}

- (void)storeUsersVisibleBlogs:(NSArray *)blogs
{
    _usersBlogs = [blogs filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        NSNumber *hidden = [evaluatedObject objectForKey:@"hidden"];
        return ((hidden == nil) || [hidden boolValue]);
    }]];
    [_usersBlogs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSString *title = [obj valueForKey:@"blogName"];
        title = [title stringByDecodingXMLCharacters];
        [obj setValue:title forKey:@"blogName"];
    }];
}

- (void)createBlogs
{
    _addSelectedButton.enabled = NO;
    
    for (NSDictionary *blog in _usersBlogs) {
		if([_selectedBlogs containsObject:[blog valueForKey:@"blogid"]]) {
			[self createBlog:blog];
		}
	}
    
    NSError *error;
    [[WordPressAppDelegate sharedWordPressApplicationDelegate].managedObjectContext save:&error];
    if (error != nil) {
        NSLog(@"Error adding blogs: %@", [error localizedDescription]);
    }
    
    if (self.blogAdditionCompleted) {
        self.blogAdditionCompleted(self);
    }
}

- (void)createBlog:(NSDictionary *)blogInfo
{
    NSMutableDictionary *newBlog = [NSMutableDictionary dictionaryWithDictionary:blogInfo];
    [newBlog setObject:self.username forKey:@"username"];
    [newBlog setObject:self.password forKey:@"password"];
    WPLog(@"creating blog: %@", newBlog);
    Blog *blog = [Blog createFromDictionary:newBlog withContext:[WordPressAppDelegate sharedWordPressApplicationDelegate].managedObjectContext];
	blog.geolocationEnabled = true;
	[blog dataSave];
    [blog syncBlogWithSuccess:^{
        if( ! [blog isWPcom] )
            [[WordPressComApi sharedApi] syncPushNotificationInfo];
    }
                      failure:nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"BlogsRefreshNotification" object:nil];
}

- (void)toggleButtons
{
    _addSelectedButton.enabled = [_selectedBlogs count] > 0;
    _selectAllButton.enabled = [_usersBlogs count] != 0;
    if ([_selectedBlogs count] == [_usersBlogs count]) {
        [_selectAllButton setTitle:NSLocalizedString(@"Deselect All", nil) forState:UIControlStateNormal];
    } else {
        [_selectAllButton setTitle:NSLocalizedString(@"Select All", nil) forState:UIControlStateNormal];
    }
}

- (void)selectAllBlogs
{
    [_selectAllButton removeTarget:self action:@selector(selectAllBlogs) forControlEvents:UIControlEventTouchUpInside];
    [_selectAllButton addTarget:self action:@selector(deselectAllBlogs) forControlEvents:UIControlEventTouchUpInside];
    [_selectAllButton setTitle:NSLocalizedString(@"Deselect All", nil) forState:UIControlStateNormal];
    
    [_selectedBlogs removeAllObjects];
    for (NSDictionary *blogData in _usersBlogs) {
        NSString *blogId = [blogData objectForKey:@"blogid"];
        [_selectedBlogs addObject:blogId];
    }
    
    [self toggleButtons];
    [self.tableView reloadData];
}

- (void)deselectAllBlogs
{
    [_selectAllButton removeTarget:self action:@selector(deselectAllBlogs) forControlEvents:UIControlEventTouchUpInside];
    [_selectAllButton addTarget:self action:@selector(selectAllBlogs) forControlEvents:UIControlEventTouchUpInside];
    [_selectAllButton setTitle:NSLocalizedString(@"Select All", nil) forState:UIControlStateNormal];
    
    [_selectedBlogs removeAllObjects];
    
    [self toggleButtons];
    [self.tableView reloadData];
}

@end
