//
//  NewerAddUsersBlogViewController.m
//  WordPress
//
//  Created by Sendhil Panchadsaram on 7/24/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <WordPressApi/WordPressApi.h>
#import "WordPressComApi.h"
#import <SVProgressHUD/SVProgressHUD.h>
#import "NewerAddUsersBlogViewController.h"
#import "AddUsersBlogCell.h"
#import "WPNUXPrimaryButton.h"
#import "WPNUXSecondaryButton.h"
#import "WPAccount.h"
#import "NSString+XMLExtensions.h"
#import "WordPressAppDelegate.h"

@interface NewerAddUsersBlogViewController () <UITableViewDataSource, UITableViewDelegate> {
    UIView *_mainTextureView;

    NSArray *_usersBlogs;
    NSMutableArray *_selectedBlogs;

}

@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet WPNUXSecondaryButton *selectAll;
@property (nonatomic, strong) IBOutlet WPNUXPrimaryButton *addSelected;


@end

@implementation NewerAddUsersBlogViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        _selectedBlogs = [[NSMutableArray alloc] init];
        _autoAddSingleBlog = YES;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    self.titleLabel.text = NSLocalizedString(@"Select the sites you want to add", nil);
    self.titleLabel.font = [UIFont fontWithName:@"OpenSans-Light" size:29.0];
    
    [self.selectAll setTitle:NSLocalizedString(@"Select All", nil) forState:UIControlStateNormal];
    [self.selectAll addTarget:self action:@selector(selectAllBlogs) forControlEvents:UIControlEventTouchUpInside];
    [self.addSelected setTitle:NSLocalizedString(@"Add Selected", nil) forState:UIControlStateNormal];
        
    [self addTextureView];
    
    [self.tableView registerClass:[AddUsersBlogCell class] forCellReuseIdentifier:@"Cell"];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self refreshBlogs];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
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
    AddUsersBlogCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.isWPCom = self.account.isWpcom;
    
    NSDictionary *blogData = [_usersBlogs objectAtIndex:indexPath.row];
    cell.showTopSeparator = indexPath.row == 0;
    cell.title = [self cellTitleForIndexPath:indexPath];
    cell.blavatarUrl = [blogData objectForKey:@"url"];
    cell.selected = [_selectedBlogs containsObject:[blogData objectForKey:@"blogid"]];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [AddUsersBlogCell rowHeightWithText:[self cellTitleForIndexPath:indexPath]];
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

- (void)addTextureView
{
    _mainTextureView = [[UIView alloc] initWithFrame:self.view.bounds];
    _mainTextureView.translatesAutoresizingMaskIntoConstraints = NO;
    _mainTextureView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"ui-texture"]];
    [self.view addSubview:_mainTextureView];
    [self.view sendSubviewToBack:_mainTextureView];
    _mainTextureView.userInteractionEnabled = NO;
    
    NSDictionary *views = NSDictionaryOfVariableBindings(_mainTextureView);
    NSArray *horizontalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_mainTextureView]|" options:0 metrics:0 views:views];
    NSArray *verticalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_mainTextureView]|" options:0 metrics:0 views:views];
    
    [self.view addConstraints:horizontalConstraints];
    [self.view addConstraints:verticalConstraints];
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

- (IBAction)createBlogs
{
    NSDictionary *properties = @{@"number_of_blogs": [NSNumber numberWithInt:[_selectedBlogs count]]};
    [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventAddBlogsClickedAddSelected properties:properties];
    
    self.addSelected.enabled = NO;
    
    for (NSDictionary *blog in _usersBlogs) {
		if([_selectedBlogs containsObject:[blog valueForKey:@"blogid"]]) {
			[self createBlog:blog withAccount:self.account];
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

- (void)createBlog:(NSDictionary *)blogInfo withAccount:(WPAccount *)account
{
    WPLog(@"creating blog: %@", blogInfo);
    Blog *blog = [account findOrCreateBlogFromDictionary:blogInfo withContext:account.managedObjectContext];
	blog.geolocationEnabled = true;
	[blog dataSave];
    [blog syncBlogWithSuccess:^{
        if( ! [blog isWPcom] )
            [[WordPressComApi sharedApi] syncPushNotificationInfo];
    }
                      failure:nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"BlogsRefreshNotification" object:nil];
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

- (void)toggleButtons
{
    self.addSelected.enabled = [_selectedBlogs count] > 0;
    [self.addSelected setTitle:[NSString stringWithFormat:@"%@ (%d)", NSLocalizedString(@"Add Selected", nil), [_selectedBlogs count]] forState:UIControlStateNormal];
    self.selectAll.enabled = [_usersBlogs count] != 0;
    if ([_selectedBlogs count] == [_usersBlogs count]) {
        [self.selectAll setTitle:NSLocalizedString(@"Deselect All", nil) forState:UIControlStateNormal];
    } else {
        [self.selectAll setTitle:NSLocalizedString(@"Select All", nil) forState:UIControlStateNormal];
    }
}

- (void)selectAllBlogs
{
    [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventAddBlogsClickedSelectAll];
    
    [self.selectAll removeTarget:self action:@selector(selectAllBlogs) forControlEvents:UIControlEventTouchUpInside];
    [self.selectAll addTarget:self action:@selector(deselectAllBlogs) forControlEvents:UIControlEventTouchUpInside];
    [self.selectAll setTitle:NSLocalizedString(@"Deselect All", nil) forState:UIControlStateNormal];
    
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
    
    [self.selectAll removeTarget:self action:@selector(deselectAllBlogs) forControlEvents:UIControlEventTouchUpInside];
    [self.selectAll addTarget:self action:@selector(selectAllBlogs) forControlEvents:UIControlEventTouchUpInside];
    [self.selectAll setTitle:NSLocalizedString(@"Select All", nil) forState:UIControlStateNormal];
    
    [_selectedBlogs removeAllObjects];
    
    [self toggleButtons];
    [self.tableView reloadData];
}

- (NSString *)cellTitleForIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *blogData = [_usersBlogs objectAtIndex:indexPath.row];
    if ([[[blogData objectForKey:@"blogName"] trim] length] == 0)
        return [blogData objectForKey:@"url"];
    else
        return [blogData objectForKey:@"blogName"];
}

@end
