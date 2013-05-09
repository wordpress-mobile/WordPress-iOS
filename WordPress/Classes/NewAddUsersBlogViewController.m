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
#import "WPWalkthroughButton.h"
#import "AddUsersBlogCell.h"
#import "SFHFKeychainUtils.h"
#import "NSString+XMLExtensions.h"
#import "WordPressComApi.h"
#import "Blog.h"
#import <SVProgressHUD/SVProgressHUD.h>

@interface NewAddUsersBlogViewController () <
    UITableViewDelegate,
    UITableViewDataSource> {
    NSArray *_usersBlogs;
    NSMutableArray *_selectedBlogs;
    WPWalkthroughButton *_selectAllButton;
    WPWalkthroughButton *_addSelectedButton;
    BOOL _loading;
    
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
CGFloat const AddUsersBlogBottomButtonWidth = 136.0;
CGFloat const AddUsersBlogBottomButtonHeight = 32.0;


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

- (void)addTableView
{
    CGRect tableViewFrame = self.view.bounds;
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
    bottomPanel.backgroundColor = [UIColor clearColor];
    bottomPanel.frame = CGRectMake(0, CGRectGetMaxY(self.tableView.frame), _viewWidth, AddUsersBlogBottomBackgroundHeight);
    [self.view addSubview:bottomPanel];
    
    CGFloat x,y;
    x = (_viewWidth - 2*AddUsersBlogBottomButtonWidth - AddUsersBlogStandardOffset)/2.0;
    y = AddUsersBlogStandardOffset;
    _selectAllButton = [[WPWalkthroughButton alloc] init];
    _selectAllButton.text = NSLocalizedString(@"Select All", nil);
    _selectAllButton.frame = CGRectMake(x, y, AddUsersBlogBottomButtonWidth, AddUsersBlogBottomButtonHeight);
    [_selectAllButton addTarget:self action:@selector(selectAllBlogs) forControlEvents:UIControlEventTouchUpInside];
    [bottomPanel addSubview:_selectAllButton];
    
    x = CGRectGetMaxX(_selectAllButton.frame) + AddUsersBlogStandardOffset;
    y = AddUsersBlogStandardOffset;
    _addSelectedButton = [[WPWalkthroughButton alloc] init];
    _addSelectedButton.text = NSLocalizedString(@"Add Selected", nil);
    _addSelectedButton.frame = CGRectMake(x, y, AddUsersBlogBottomButtonWidth, AddUsersBlogBottomButtonHeight);
    [_addSelectedButton addTarget:self action:@selector(createBlogs) forControlEvents:UIControlEventTouchUpInside];
    [bottomPanel addSubview:_addSelectedButton];
}

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
    
    UILabel *title = [[UILabel alloc] init];
    title.backgroundColor = [UIColor clearColor];
    title.textAlignment = UITextAlignmentCenter;
    title.font = [UIFont fontWithName:@"OpenSans-Light" size:29.0];
    title.text = NSLocalizedString(@"Select the sites you want to add", nil);
    title.shadowColor = [UIColor colorWithRed:0.0 green:115.0/255.0 blue:164.0/255.0 alpha:0.5];
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
        _selectAllButton.text = NSLocalizedString(@"Deselect All", nil);
    } else {
        _selectAllButton.text = NSLocalizedString(@"Select All", nil);        
    }
}

- (void)selectAllBlogs
{
    [_selectAllButton removeTarget:self action:@selector(selectAllBlogs) forControlEvents:UIControlEventTouchUpInside];
    [_selectAllButton addTarget:self action:@selector(deselectAllBlogs) forControlEvents:UIControlEventTouchUpInside];
    _selectAllButton.text = NSLocalizedString(@"Deselect All", nil);
    
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
    _selectAllButton.text = NSLocalizedString(@"Select All", nil);
    
    [_selectedBlogs removeAllObjects];
    
    [self toggleButtons];
    [self.tableView reloadData];
}

@end
