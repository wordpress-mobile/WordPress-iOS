//
//  NewAddUsersBlogViewController.m
//  WordPress
//
//  Created by Sendhil Panchadsaram on 5/2/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <WordPressApi/WordPressApi.h>
#import "WordPressAppDelegate.h"
#import "UIView+FormSheetHelpers.h"
#import "NewAddUsersBlogViewController.h"
#import "AddUsersBlogCell.h"
#import "SFHFKeychainUtils.h"
#import "NSString+XMLExtensions.h"
#import "WordPressComApi.h"
#import "Blog.h"
#import <SVProgressHUD/SVProgressHUD.h>

@interface NewAddUsersBlogViewController () {
    NSArray *_usersBlogs;
    NSMutableArray *_selectedBlogs;
    UIButton *_selectAll;
    UIButton *_addBlogs;
    BOOL _loading;
    
    CGFloat _viewWidth;
    CGFloat _viewHeight;
}

@end

@implementation NewAddUsersBlogViewController

CGFloat const AddUsersBlogHeaderHeight = 164.0;
CGFloat const AddUsersBlogStandardOffset = 16.0;
CGFloat const AddUsersBlogLoadingViewHeight = 100.0;
CGFloat const AddUsersBlogLogoVerticalOffset = 79.0;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
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
    self.view.backgroundColor = [UIColor colorWithRed:30.0/255.0 green:140.0/255.0 blue:190.0/255.0 alpha:1.0];
    self.tableView.tableHeaderView = [self headerView];
    self.tableView.tableFooterView = [self footerView];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
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

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (_loading)
        return [self loadingView];
    else
        return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (_loading)
        return AddUsersBlogLoadingViewHeight;
    else
        return 0.0;
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

- (UIView *)headerView
{
    CGFloat x, y;
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, _viewWidth, AddUsersBlogHeaderHeight)];
    headerView.backgroundColor = [UIColor clearColor];
    
    // Add Info Button
    UIButton *infoButton;
    UIImage *infoButtonImage = [UIImage imageNamed:@"infoButton"];
    if (infoButton == nil) {
        infoButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [infoButton setImage:infoButtonImage forState:UIControlStateNormal];
        infoButton.frame = CGRectMake(AddUsersBlogStandardOffset, AddUsersBlogStandardOffset, infoButtonImage.size.width, infoButtonImage.size.height);
        [infoButton addTarget:self action:@selector(clickedInfoButton:) forControlEvents:UIControlEventTouchUpInside];
        [headerView addSubview:infoButton];
    }
    
    // Add "Add" Button
    UIButton *addBlogsButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [addBlogsButton setTitle:@"Add Blogs" forState:UIControlStateNormal];
    [addBlogsButton sizeToFit];
    [addBlogsButton addTarget:self action:@selector(createBlogs) forControlEvents:UIControlEventTouchUpInside];
    x = _viewWidth - CGRectGetWidth(addBlogsButton.frame) - AddUsersBlogStandardOffset;
    y = AddUsersBlogStandardOffset;
    addBlogsButton.frame = CGRectMake(x, y, CGRectGetWidth(addBlogsButton.frame), CGRectGetHeight(addBlogsButton.frame));
    addBlogsButton.enabled = NO;
    [headerView addSubview:addBlogsButton];
    _addBlogs = addBlogsButton;
    
    // Add Select All Button
    UIButton *selectAllButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [selectAllButton setTitle:NSLocalizedString(@"Select All", nil) forState:UIControlStateNormal];
    [selectAllButton sizeToFit];
    [selectAllButton addTarget:self action:@selector(selectAllBlogs) forControlEvents:UIControlEventTouchUpInside];
    x = _viewWidth - CGRectGetWidth(addBlogsButton.frame) - AddUsersBlogStandardOffset;
    y = CGRectGetMaxY(addBlogsButton.frame) + AddUsersBlogStandardOffset;
    selectAllButton.frame = CGRectMake(x, y, CGRectGetWidth(selectAllButton.frame), CGRectGetHeight(selectAllButton.frame
                                                                                                    ));
    [headerView addSubview:selectAllButton];
    _selectAll = selectAllButton;
    
    // Add Logo
    UILabel *logo = [[UILabel alloc] init];
    logo = [[UILabel alloc] init];
    logo.backgroundColor = [UIColor clearColor];
    logo.font = [UIFont fontWithName:@"Genericons-Regular" size:60];
    logo.text = @""; // WordPress Logo
    logo.shadowColor = [UIColor colorWithRed:0.0 green:115.0/255.0 blue:164.0/255.0 alpha:0.5];
    logo.textColor = [UIColor whiteColor];
    [logo sizeToFit];

    // Unfortunately the way iOS generates the Genericons Font results in far too much space on the top and the bottom, so for now we will adjust this by hand.
    CGFloat extraSpaceOnTop = 18.0;
    x = (_viewWidth - CGRectGetWidth(logo.frame))/2.0;
    y = AddUsersBlogLogoVerticalOffset-extraSpaceOnTop;
    logo.frame = CGRectIntegral(CGRectMake(x, y, CGRectGetWidth(logo.frame), CGRectGetHeight(logo.frame)));
    
    [headerView addSubview:logo];
    
    return headerView;
}

- (UIView *)footerView
{
    // This just adds a little bit of space at the bottom of the tableview so the final table view cell
    // doesn't terminate on the bottom abruptly without some spacing.
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, _viewWidth, AddUsersBlogStandardOffset)];
    footerView.backgroundColor = [UIColor clearColor];
    return footerView;
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
    loading.text = NSLocalizedString(@"Loading blogs...", nil);
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
        xmlrpc = [NSURL URLWithString:self.url];
    }
    
    _loading = true;
    [self.tableView reloadData];
    
    WPXMLRPCClient *api = [WPXMLRPCClient clientWithXMLRPCEndpoint:xmlrpc];
    [api callMethod:@"wp.getUsersBlogs"
         parameters:[NSArray arrayWithObjects:username, password, nil]
            success:^(AFHTTPRequestOperation *operation, id responseObject) {
                _loading = false;
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
                    
                    if(_usersBlogs.count == 1 && self.autoAddSingleBlog) {
                        [self selectAllBlogs];
                        [self createBlogs];
                    }
                }
                
                [self toggleButtons];
                [self.tableView reloadData];
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                _loading = false;
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
    _addBlogs.enabled = NO;
    
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
    _addBlogs.enabled = [_selectedBlogs count] > 0;
    _selectAll.enabled = [_usersBlogs count] != 0;
}

- (void)selectAllBlogs
{
    [_selectAll removeTarget:self action:@selector(selectAllBlogs) forControlEvents:UIControlEventTouchUpInside];
    [_selectAll addTarget:self action:@selector(deselectAllBlogs) forControlEvents:UIControlEventTouchUpInside];
    [_selectAll setTitle:NSLocalizedString(@"Deselect All", nil) forState:UIControlStateNormal];
    
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
    [_selectAll removeTarget:self action:@selector(deselectAllBlogs) forControlEvents:UIControlEventTouchUpInside];
    [_selectAll addTarget:self action:@selector(selectAllBlogs) forControlEvents:UIControlEventTouchUpInside];
    [_selectAll setTitle:NSLocalizedString(@"Select All", nil) forState:UIControlStateNormal];
    
    [_selectedBlogs removeAllObjects];
    
    [self toggleButtons];
    [self.tableView reloadData];
}

@end
