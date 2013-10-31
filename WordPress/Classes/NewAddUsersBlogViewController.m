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
#import "NSString+XMLExtensions.h"
#import "WordPressComApi.h"
#import "Blog.h"
#import "WPNUXUtility.h"
#import "WPAccount.h"
#import "ContextManager.h"

@interface NewAddUsersBlogViewController () <
    UITableViewDelegate,
    UITableViewDataSource> {
    NSArray *_usersBlogs;
    NSMutableArray *_selectedBlogs;
    WPNUXSecondaryButton *_selectAllButton;
    WPNUXPrimaryButton *_addSelectedButton;
    UIView *_mainTextureView;
    
    CGFloat _viewWidth;
    CGFloat _viewHeight;
}

@property (nonatomic, strong) UITableView *tableView;

@end

@implementation NewAddUsersBlogViewController

CGFloat const AddUsersBlogHeaderHeight = 164.0;
CGFloat const AddUsersBlogStandardOffset = 16.0;
CGFloat const AddUsersBlogTitleVerticalOffset = 23.0;
CGFloat const AddUsersBlogMaxTextWidth = 289.0;
CGFloat const AddUsersBlogBottomBackgroundHeight = 64;


- (id)init
{
    self = [super init];
    if (self) {
        _selectedBlogs = [[NSMutableArray alloc] init];
        _autoAddSingleBlog = YES;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventAddBlogsOpened];
    
    _viewWidth = [self.view formSheetViewWidth];
    _viewHeight = [self.view formSheetViewHeight];
    
    [self addBackgroundTexture];
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

- (NSUInteger)supportedInterfaceOrientations {
    if (IS_IPHONE)
        return UIInterfaceOrientationMaskPortrait;
    
    return UIInterfaceOrientationMaskAll;
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
    cell.isWPCom = self.account.isWpcom;
    
    NSDictionary *blogData = [_usersBlogs objectAtIndex:indexPath.row];
    cell.showTopSeparator = indexPath.row == 0;
    cell.title = [self getCellTitleForIndexPath:indexPath];
    cell.blavatarUrl = [blogData objectForKey:@"url"];
    cell.selected = [_selectedBlogs containsObject:[blogData objectForKey:@"blogid"]];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [AddUsersBlogCell rowHeightWithText:[self getCellTitleForIndexPath:indexPath]];    
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
    [tableView reloadData];
    [self toggleButtons];
}

#pragma mark - Private Methods

- (void)addBackgroundTexture
{
    _mainTextureView = [[UIView alloc] initWithFrame:self.view.bounds];
    _mainTextureView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"ui-texture"]];
    [self.view addSubview:_mainTextureView];
    _mainTextureView.userInteractionEnabled = NO;
}

- (void)addTableView
{
    CGRect tableViewFrame = CGRectMake(0, 0, _viewWidth, _viewHeight);
    tableViewFrame.size.height -= AddUsersBlogBottomBackgroundHeight;
    
    self.tableView = [[UITableView alloc] initWithFrame:tableViewFrame style:UITableViewStylePlain];
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.view.backgroundColor = [WPNUXUtility backgroundColor];
    self.tableView.tableHeaderView = [self headerView];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.view addSubview:self.tableView];
}

- (void)addBottomPanel
{
    UIView *bottomPanel = [[UIView alloc] init];
    bottomPanel.backgroundColor = [WPNUXUtility bottomPanelBackgroundColor];
    bottomPanel.frame = CGRectMake(0, CGRectGetMaxY(self.tableView.frame), _viewWidth, AddUsersBlogBottomBackgroundHeight);
    [self.view addSubview:bottomPanel];
    
    UIView *bottomPanelLine = [[UIView alloc] init];
    bottomPanelLine.backgroundColor = [UIColor colorWithRed:17.0/255.0 green:17.0/255.0 blue:17.0/255.0 alpha:0.95];
    bottomPanelLine.frame = CGRectMake(0, CGRectGetMinY(bottomPanel.frame), _viewWidth, 1);
    [self.view addSubview:bottomPanel];
    
    UIView *bottomPanelTextureView = [[UIView alloc] initWithFrame:bottomPanel.frame];
    bottomPanelTextureView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"ui-texture"]];
    bottomPanelTextureView.userInteractionEnabled = NO;
    [self.view addSubview:bottomPanelTextureView];
    
    _selectAllButton = [[WPNUXSecondaryButton alloc] init];
    [_selectAllButton setTitle:NSLocalizedString(@"Select All", nil) forState:UIControlStateNormal];
    _selectAllButton.titleLabel.adjustsFontSizeToFitWidth = YES;
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
    _addSelectedButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    // Calculate the space with the largest possible text width before setting the text back to normal. We calculate this
    // ahead of time so that way we don't have flickering as the text changes result in the button size changing. This also
    // ensures we don't have to re-layout the button as the text changes as well.
    [_addSelectedButton setTitle:[NSString stringWithFormat:@"%@ (100)", NSLocalizedString(@"Add Selected", nil)] forState:UIControlStateNormal];
    [_addSelectedButton sizeToFit];
    [_addSelectedButton setTitle:[NSString stringWithFormat:@"%@ (1)", NSLocalizedString(@"Add Selected", nil)] forState:UIControlStateNormal];
    [_addSelectedButton addTarget:self action:@selector(createBlogs) forControlEvents:UIControlEventTouchUpInside];
    [bottomPanel addSubview:_addSelectedButton];

    // For some locales, these strings can be long so we try to balance the widths.
    CGFloat availableWidth = _viewWidth - 3 * AddUsersBlogStandardOffset;
    CGFloat widthRatio = availableWidth / (CGRectGetWidth(_addSelectedButton.frame) + CGRectGetWidth(selectAllFrame));

    CGFloat maxWidth = CGRectGetWidth(_selectAllButton.frame) * widthRatio;
    CGFloat x,y;
    x = AddUsersBlogStandardOffset;
    y = AddUsersBlogStandardOffset;
    _selectAllButton.frame = CGRectIntegral(CGRectMake(x, y, MIN(CGRectGetWidth(_selectAllButton.frame), maxWidth), CGRectGetHeight(_selectAllButton.frame)));

    maxWidth = CGRectGetWidth(_addSelectedButton.frame) * widthRatio;
    CGFloat addSelectedButtonWidth = MIN(CGRectGetWidth(_addSelectedButton.frame), maxWidth);
    x = _viewWidth - addSelectedButtonWidth - AddUsersBlogStandardOffset;
    y = AddUsersBlogStandardOffset;
    _addSelectedButton.frame = CGRectIntegral(CGRectMake(x, y, addSelectedButtonWidth, CGRectGetHeight(_addSelectedButton.frame)));
}

- (UIView *)headerView
{
    CGFloat x, y;
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, _viewWidth, AddUsersBlogHeaderHeight)];
    headerView.backgroundColor = [UIColor clearColor];
        
    UILabel *title = [[UILabel alloc] init];
    title.backgroundColor = [UIColor clearColor];
    title.textAlignment = NSTextAlignmentCenter;
    title.lineBreakMode = NSLineBreakByWordWrapping;
    title.font = [UIFont fontWithName:@"OpenSans-Light" size:29.0];
    title.text = NSLocalizedString(@"Select the sites you want to add", nil);
    title.shadowColor = [WPNUXUtility textShadowColor];
    title.shadowOffset = CGSizeMake(0.0, 1.0);
    title.textColor = [UIColor whiteColor];
    title.numberOfLines = 0;
    CGSize titleSize = [title.text sizeWithFont:title.font constrainedToSize:CGSizeMake(AddUsersBlogMaxTextWidth, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
    x = (_viewWidth - titleSize.width)/2.0;
    y = CGRectGetHeight(headerView.frame) - titleSize.height - AddUsersBlogTitleVerticalOffset;
    title.frame = CGRectMake(x, y, titleSize.width, titleSize.height);
    [headerView addSubview:title];
    
    return headerView;
}

- (UIView *)checkmarkAccessoryView
{
    UIImage *image = [UIImage imageNamed:@"addBlogsSelectedImage"];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    return imageView;
}

- (void)refreshBlogs
{
    NSURL *xmlrpc = [NSURL URLWithString:self.account.xmlrpc];
    NSString *username = self.account.username;
    NSString *password = self.account.password;
    
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
                    [self selectAppropriateBlog];
                    
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
                DDLogError(@"Failed getting user blogs: %@", [error localizedDescription]);
                if (self.onErrorLoading) {
                    self.onErrorLoading(self, error);
                }
            }];
}

- (void)selectAppropriateBlog
{
    if (self.siteUrl == nil) {
        [self selectFirstBlog];
    } else {
        // This strips out any leading http:// or https:// making for an easier string match.
        NSString *desiredBlogUrl = [[NSURL URLWithString:self.siteUrl] absoluteString];
        
        __block BOOL blogFound = NO;
        __block NSUInteger indexOfBlog;
        [_usersBlogs enumerateObjectsUsingBlock:^(id blogInfo, NSUInteger index, BOOL *stop){
            NSString *blogUrl = [blogInfo objectForKey:@"url"];
            if ([blogUrl rangeOfString:desiredBlogUrl options:NSCaseInsensitiveSearch].location != NSNotFound) {
                blogFound = YES;
                [_selectedBlogs addObject:[blogInfo objectForKey:@"blogid"]];
                indexOfBlog = index;
                *stop = YES;
            }
        }];
        
        if (!blogFound) {
            [self selectFirstBlog];
        } else {
            // Let's make sure the blog we selected is at the top of the list the user sees.
            NSMutableArray *rearrangedUsersBlogs = [NSMutableArray arrayWithArray:_usersBlogs];
            NSDictionary *selectedBlogInfo = [rearrangedUsersBlogs objectAtIndex:indexOfBlog];
            [rearrangedUsersBlogs removeObjectAtIndex:indexOfBlog];
            [rearrangedUsersBlogs insertObject:selectedBlogInfo atIndex:0];
            _usersBlogs = rearrangedUsersBlogs;
        }
    }
}

- (void)selectFirstBlog
{
    NSString *firstBlogId = [[_usersBlogs objectAtIndex:0] objectForKey:@"blogid"];
    if (![_selectedBlogs containsObject:firstBlogId]) {
        [_selectedBlogs addObject:firstBlogId];
    }
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
    _usersBlogs = [_usersBlogs sortedArrayUsingComparator:^(id obj1, id obj2){
        NSString *title1 = [obj1 valueForKey:@"blogName"];
        NSString *title2 = [obj2 valueForKey:@"blogName"];
        return [title1 localizedCaseInsensitiveCompare:title2];
    }];
}

- (void)createBlogs
{
    NSDictionary *properties = @{@"number_of_blogs": [NSNumber numberWithInt:[_selectedBlogs count]]};
    [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventAddBlogsClickedAddSelected properties:properties];

    _addSelectedButton.enabled = NO;
    
    NSManagedObjectContext *context = [[ContextManager sharedInstance] newDerivedContext];
    [context performBlock:^{
        for (NSDictionary *blog in _usersBlogs) {
            if([_selectedBlogs containsObject:[blog valueForKey:@"blogid"]]) {
                [self createBlog:blog withContext:context];
            }
        }
        
        [[ContextManager sharedInstance] saveDerivedContext:context];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.blogAdditionCompleted) {
                self.blogAdditionCompleted(self);
            }
            [[WordPressComApi sharedApi] syncPushNotificationInfo];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"BlogsRefreshNotification" object:nil];
        });
    }];
}

- (void)createBlog:(NSDictionary *)blogInfo withContext:(NSManagedObjectContext *)context
{
    DDLogInfo(@"creating blog: %@", blogInfo);
    Blog *blog = [_account findOrCreateBlogFromDictionary:blogInfo withContext:context];
    blog.geolocationEnabled = YES;

//    [blog syncBlogWithSuccess:nil failure:nil];
}

- (void)toggleButtons
{
    _addSelectedButton.enabled = [_selectedBlogs count] > 0;
    [_addSelectedButton setTitle:[NSString stringWithFormat:@"%@ (%d)", NSLocalizedString(@"Add Selected", nil), [_selectedBlogs count]] forState:UIControlStateNormal];
    _selectAllButton.enabled = [_usersBlogs count] != 0;
    if ([_selectedBlogs count] == [_usersBlogs count]) {
        [self setupDeselectAllButton];
    } else {
        [self setupSelectAllButton];
    }
}

- (void)selectAllBlogs
{
    [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventAddBlogsClickedSelectAll];

    [self setupDeselectAllButton];
    
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
    [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventAddBlogsClickedDeselectAll];

    [self setupSelectAllButton];
    
    [_selectedBlogs removeAllObjects];
    
    [self toggleButtons];
    [self.tableView reloadData];
}

- (void)setupSelectAllButton
{
    [_selectAllButton removeTarget:self action:@selector(deselectAllBlogs) forControlEvents:UIControlEventTouchUpInside];
    [_selectAllButton addTarget:self action:@selector(selectAllBlogs) forControlEvents:UIControlEventTouchUpInside];
    [_selectAllButton setTitle:NSLocalizedString(@"Select All", nil) forState:UIControlStateNormal];
}

- (void)setupDeselectAllButton
{
    [_selectAllButton removeTarget:self action:@selector(selectAllBlogs) forControlEvents:UIControlEventTouchUpInside];
    [_selectAllButton addTarget:self action:@selector(deselectAllBlogs) forControlEvents:UIControlEventTouchUpInside];
    [_selectAllButton setTitle:NSLocalizedString(@"Deselect All", nil) forState:UIControlStateNormal];
}

- (NSString *)getCellTitleForIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *blogData = [_usersBlogs objectAtIndex:indexPath.row];
    if ([[[blogData objectForKey:@"blogName"] trim] length] == 0)
        return [blogData objectForKey:@"url"];
    else
        return [blogData objectForKey:@"blogName"];
}

@end
