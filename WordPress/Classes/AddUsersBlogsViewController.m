/*
 * AddUsersBlogsViewController.m
 *
 * Copyright (c) 2013 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import <QuartzCore/QuartzCore.h>
#import "AddUsersBlogsViewController.h"
#import "CreateWPComBlogViewController.h"
#import "NSString+XMLExtensions.h"
#import "WordPressComApi.h"
#import "ReachabilityUtils.h"
#import "UIImageView+Gravatar.h"
#import "WPAccount.h"
#import "SupportViewController.h"
#import "WPTableViewCell.h"
#import "WordPressAppDelegate.h"
#import "Blog.h"
#import "WPcomLoginViewController.h"

@interface AddUsersBlogsViewController () <CreateWPComBlogViewControllerDelegate, UITableViewDelegate>

@property (nonatomic, strong) UIView *noblogsView;
@property (nonatomic, weak) IBOutlet UIToolbar *toolbar;
@property (nonatomic, weak) WPAccount *account;
@property (nonatomic, assign) BOOL hideBackButton, hideSignInButton;
@property (nonatomic, assign) BOOL hasCompletedGetUsersBlogs;
@property (nonatomic, strong) NSMutableArray *selectedBlogs;
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *buttonAddSelected, *buttonSelectAll, *topAddSelectedButton;
@property (nonatomic, strong) UIAlertView *failureAlertView;

@end

@implementation AddUsersBlogsViewController

- (AddUsersBlogsViewController *)initWithAccount:(WPAccount *)account {
    self = [super init];
    if (self) {
        _account = account;
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    _failureAlertView.delegate = nil;
}

- (void)viewDidLoad {
    DDLogInfo(@"%@ %@", self, NSStringFromSelector(_cmd));
    [super viewDidLoad];

	self.navigationItem.title = NSLocalizedString(@"Select Blogs", @"");
	self.selectedBlogs = [NSMutableArray array];
    
    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
    
    if (IS_IOS7) {
        self.toolbar.barTintColor = [WPStyleGuide littleEddieGrey];        
    }
    NSShadow *shadow = [[NSShadow alloc] init];
    [_buttonSelectAll setTitleTextAttributes:@{
                                              NSFontAttributeName: [WPStyleGuide regularTextFont],
                                              NSForegroundColorAttributeName : [UIColor whiteColor],
                                              NSShadowAttributeName: shadow}
                                   forState:UIControlStateNormal];

    [_buttonAddSelected setTitleTextAttributes:@{
                                              NSFontAttributeName: [WPStyleGuide regularTextFont],
                                              NSForegroundColorAttributeName : [UIColor whiteColor],
                                              NSShadowAttributeName: shadow}
                                   forState:UIControlStateNormal];
    [_buttonAddSelected setTitleTextAttributes:@{
                                                NSFontAttributeName: [WPStyleGuide regularTextFont],
                                                NSForegroundColorAttributeName : [UIColor grayColor],
                                                NSShadowAttributeName: shadow}
                                     forState:UIControlStateDisabled];

    
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cancelAddWPcomBlogs) 
												 name:@"didCancelWPcomLogin" object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    
    if (self.hideBackButton) {
        [self.navigationItem setHidesBackButton:YES animated:NO];
    }

	if (self.usersBlogs.count == 0) {
		_buttonSelectAll.enabled = NO;
	}

	if (self.isWPcom && (![WordPressAppDelegate sharedWordPressApplicationDelegate].isWPcomAuthenticated)) {
        WPcomLoginViewController *wpComLogin = [[WPcomLoginViewController alloc] initWithStyle:UITableViewStyleGrouped];
        [self.navigationController presentViewController:wpComLogin animated:YES completion:nil];
	}
	
	if (IS_IPAD) {
		UIBarButtonItem *topAddSelectedButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Add Selected", @"")
																				 style:[WPStyleGuide barButtonStyleForDone]
																				target:self 
																				action:@selector(saveSelectedBlogs:)];
		self.navigationItem.rightBarButtonItem = topAddSelectedButton;
        self.topAddSelectedButton = self.navigationItem.rightBarButtonItem;
		self.topAddSelectedButton.enabled = NO;
	}
	
    self.buttonAddSelected.title = NSLocalizedString(@"Add Selected", @"");
    self.buttonSelectAll.title = NSLocalizedString(@"Select All", @"");
	self.buttonAddSelected.enabled = NO;
	
	[self checkAddSelectedButtonStatus];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (self.isWPcom) {
		if (!self.usersBlogs && ([[NSUserDefaults standardUserDefaults] objectForKey:@"WPcomUsersBlogs"] != nil)) {
			self.usersBlogs = [[NSUserDefaults standardUserDefaults] objectForKey:@"WPcomUsersBlogs"];
		} else if (!self.usersBlogs) {
			[self refreshBlogs];
		} else if ([self.usersBlogs count] == 0){
            [self refreshBlogs]; //Maybe just returning from creating a blog
            [self hideNoBlogsView];
        }
	}
	else if (!self.usersBlogs) {
        [self refreshBlogs];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.usersBlogs.count;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
	CGRect footerFrame = CGRectMake(0, 0, self.view.frame.size.width, 50);
	UIView *footerView = [[UIView alloc] initWithFrame:footerFrame];
    CGRect footerSpinnerFrame = CGRectMake(0, 26.0f, 20, 20);
    CGRect footerTextFrame = CGRectMake(0, 0, self.view.frame.size.width, 20);
    if (self.usersBlogs.count == 0 && !self.hasCompletedGetUsersBlogs) {
        UIActivityIndicatorView *footerSpinner = [[UIActivityIndicatorView alloc] initWithFrame:footerSpinnerFrame];
        footerSpinner.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
        [footerSpinner startAnimating];
        footerSpinner.center = CGPointMake(self.view.center.x, footerSpinner.center.y);
        [footerView addSubview:footerSpinner];
        
        UILabel *footerText = [[UILabel alloc] initWithFrame:footerTextFrame];
        footerText.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;
        footerText.textAlignment = NSTextAlignmentCenter;
        footerText.backgroundColor = [UIColor clearColor];
        footerText.textColor = [UIColor darkGrayColor];
        footerText.text = NSLocalizedString(@"Loading blogs...", @"");
        [footerView addSubview:footerText];
    } else if (self.usersBlogs.count == 0 && self.hasCompletedGetUsersBlogs) {
        if (!self.isWPcom) {
            UILabel *footerText = [[UILabel alloc] initWithFrame:CGRectMake(110, 0, 200, 20)];
            footerText.backgroundColor = [UIColor clearColor];
            footerText.textColor = [UIColor darkGrayColor];
            footerText.text = NSLocalizedString(@"No blogs found.", @"");
            [footerView addSubview:footerText];
        } else {
            //User has no blogs at WPCom but has signed in successfully, lets finish and take them to the reader
            [[NSNotificationCenter defaultCenter] postNotificationName:@"BlogsRefreshNotification" object:nil];
        }
    }
	return footerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
	if (section == 0 && self.usersBlogs.count == 0) {
		return 60;
    } else {
		return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[WPTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }

    cell.textLabel.textAlignment = NSTextAlignmentLeft;
    
    NSDictionary *blog = self.usersBlogs[indexPath.row];
    if ([self.selectedBlogs containsObject:[blog valueForKey:@"blogid"]]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    cell.textLabel.text = [blog valueForKey:@"blogName"];
    if (!cell.textLabel.text || [cell.textLabel.text isEqualToString:@""]) {
        cell.textLabel.text = [blog valueForKey:@"url"];
    }
    NSURL *blogURL = [NSURL URLWithString:[blog valueForKey:@"url"]];
    [cell.imageView setImageWithBlavatarUrl:[blogURL host] isWPcom:self.isWPcom];
    
    if (indexPath.row == 0) {
        [self maskImageView:cell.imageView corner:UIRectCornerTopLeft];
    } else if (indexPath.row == ([self.tableView numberOfRowsInSection:indexPath.section] -1)) {
        [self maskImageView:cell.imageView corner:UIRectCornerBottomLeft];
    } else {
        cell.imageView.layer.mask = nil;
    }
    [WPStyleGuide configureTableViewCell:cell];
    
    return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *selectedBlog = self.usersBlogs[indexPath.row];
    if (![self.selectedBlogs containsObject:[selectedBlog valueForKey:@"blogid"]]) {
        [self.selectedBlogs addObject:[selectedBlog valueForKey:@"blogid"]];
    } else {
        NSInteger indexToRemove = -1;
        NSInteger count = 0;
        for (NSString *blogID in self.selectedBlogs) {
            if ([blogID isEqual:[selectedBlog valueForKey:@"blogid"]]) {
                indexToRemove = count;
                break;
            }
            count++;
        }
        if (indexToRemove > -1) {
            [self.selectedBlogs removeObjectAtIndex:indexToRemove];
        }
    }
    [tableView reloadData];
    
    if (self.selectedBlogs.count == self.usersBlogs.count) {
        [self selectAllBlogs:self];
    } else if (_selectedBlogs.count == 0) {
        [self deselectAllBlogs:self];
    }
	
	[self checkAddSelectedButtonStatus];

	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark -
#pragma mark Custom methods

- (void)maskImageView:(UIImageView *)imageView corner:(UIRectCorner)corner {
    CGRect frame = CGRectMake(0.0, 0.0, 43.0, 43.0);
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:frame
                                               byRoundingCorners:corner cornerRadii:CGSizeMake(7.0f, 7.0f)];
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.frame = frame;
    maskLayer.path = path.CGPath;
    imageView.layer.mask = maskLayer;
}

- (NSArray *)usersBlogs {
    return [_usersBlogs filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        NSNumber *hidden = [evaluatedObject objectForKey:@"hidden"];
        return (!hidden || [hidden boolValue]);
    }]];
}

- (void)selectAllBlogs:(id)sender {
	[self.selectedBlogs removeAllObjects];
    
	for (NSDictionary *blog in self.usersBlogs) {
		[self.selectedBlogs addObject:[blog valueForKey:@"blogid"]];
	}
	[self.tableView reloadData];
	self.buttonSelectAll.title = NSLocalizedString(@"Deselect All", @"");
	self.buttonSelectAll.action = @selector(deselectAllBlogs:);
	[self checkAddSelectedButtonStatus];
}

- (void)deselectAllBlogs:(id)sender {
	[self.selectedBlogs removeAllObjects];
	[self.tableView reloadData];
	self.buttonSelectAll.title = NSLocalizedString(@"Select All", @"");
	self.buttonSelectAll.action = @selector(selectAllBlogs:);
	[self checkAddSelectedButtonStatus];
}

- (void)refreshBlogs {
    if (![ReachabilityUtils isInternetReachable]) {
        __weak AddUsersBlogsViewController *weakSelf = self;
        [ReachabilityUtils showAlertNoInternetConnectionWithRetryBlock:^{
            [weakSelf refreshBlogs];
        }];
        self.hasCompletedGetUsersBlogs = YES;
        [self.tableView reloadData];
        return;
    }
    
    NSURL *xmlrpc;
    NSString *username, *password;
    if (self.isWPcom) {
        xmlrpc = [NSURL URLWithString:@"https://wordpress.com/xmlrpc.php"];
        WPAccount *account = [WPAccount defaultWordPressComAccount];
        username = account.username;
        password = account.password;
    } else {
        xmlrpc = [NSURL URLWithString:_url];
        username = self.account.username;
        password = self.account.password;
    }
    
    WPXMLRPCClient *api = [WPXMLRPCClient clientWithXMLRPCEndpoint:xmlrpc];
    [api callMethod:@"wp.getUsersBlogs"
         parameters:[NSArray arrayWithObjects:username, password, nil]
            success:^(AFHTTPRequestOperation *operation, id responseObject) {
                self.usersBlogs = responseObject;
                self.hasCompletedGetUsersBlogs = YES;
                if (self.usersBlogs.count > 0) {
                    self.buttonSelectAll.enabled = YES;
                    [self.usersBlogs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                        NSString *title = [obj valueForKey:@"blogName"];
                        title = [title stringByDecodingXMLCharacters];
                        [obj setValue:title forKey:@"blogName"];
                    }];
                    self.usersBlogs = [self.usersBlogs sortedArrayUsingComparator:^(id obj1, id obj2){
                        NSString *title1 = [obj1 valueForKey:@"blogName"];
                        NSString *title2 = [obj2 valueForKey:@"blogName"];
                        return [title1 localizedCaseInsensitiveCompare:title2];
                    }];
                    
                    if (self.usersBlogs.count > 1) {
                        [self hideNoBlogsView];
                        [self.tableView reloadData];
                    } else {
                        [self.selectedBlogs removeAllObjects];
                        for (NSDictionary *blog in self.usersBlogs) {
                            [self.selectedBlogs addObject:[blog valueForKey:@"blogid"]];
                        }
                        [self saveSelectedBlogs];
                    }
                } else {
                    // User blogs count == 0.  Prompt the user to create a blog.
                    [self showNoBlogsView];
                    [self.tableView reloadData];
                    
                }
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                DDLogError(@"Failed getting user blogs: %@", [error localizedDescription]);
                [self hideNoBlogsView];
                self.hasCompletedGetUsersBlogs = YES;
                [self.tableView reloadData];
                if (self.failureAlertView == nil) {
                    self.failureAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Sorry, can't log in", @"")
                                                                  message:[error localizedDescription]
                                                                 delegate:self
                                                        cancelButtonTitle:NSLocalizedString(@"Need Help?", @"")
                                                        otherButtonTitles:NSLocalizedString(@"OK", @""), nil];
                    self.failureAlertView.tag = 1;
                    [self.failureAlertView show];
                }
            }];
}

- (UIView *)noblogsView {
    if (_noblogsView) {
        return _noblogsView;
    }
    
    CGFloat width = 282.0f;
    CGFloat height = 160.0f;
    CGFloat x = (self.view.frame.size.width / 2.0f) - (width / 2.0f);
    CGFloat y = (self.view.frame.size.height / 2.0f) - (height / 2.0f);
    _noblogsView = [[UIView alloc] initWithFrame:CGRectMake(x, y, width, height)];
    _noblogsView.backgroundColor = [UIColor clearColor];
    
    _noblogsView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin |
    UIViewAutoresizingFlexibleRightMargin |
    UIViewAutoresizingFlexibleTopMargin |
    UIViewAutoresizingFlexibleBottomMargin;
    
    UIColor *textColor = [UIColor colorWithRed:33.0f/255.0f green:33.0f/255.0f blue:33.0f/255.0f alpha:1.0];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.backgroundColor = [UIColor clearColor];
    label.numberOfLines = 0;
    label.lineBreakMode = NSLineBreakByWordWrapping;
    label.font = [UIFont fontWithName:@"Georgia" size:16.0f];
    label.shadowOffset = CGSizeMake(0.0f, 1.0f);
    label.textColor = textColor;
    label.shadowColor = [UIColor whiteColor];
    label.textAlignment = NSTextAlignmentCenter;
    
    if ([[WPAccount defaultWordPressComAccount] username]) {
        label.text = NSLocalizedString(@"You do not seem to have any blogs. Would you like to create one now?", @"");
    } else {
        label.text = NSLocalizedString(@"You do not seem to have any blogs.", @"");
    }
    
    label.frame = CGRectMake(0.0, 0.0, width, 38.0);
    [_noblogsView addSubview:label];
    
    if ([[WPAccount defaultWordPressComAccount] username]) {
        width = 282.0f;
        height = 44.0f;
        x = (_noblogsView.frame.size.width / 2.0f) - (width / 2.0f);
        y = label.frame.size.height + 10.0f;
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(x, y, width, height);
        button.titleLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:15.0];
        [button setTitleColor:textColor forState:UIControlStateNormal];
        [button setTitleShadowColor:[UIColor whiteColor] forState:UIControlStateNormal];
        button.titleLabel.shadowOffset = CGSizeMake(0.0f, 1.0f);
        [button setImage:[UIImage imageNamed:@"welcome_button_asterisk.png"] forState:UIControlStateNormal];
        [button setContentEdgeInsets:UIEdgeInsetsMake(0.0f, 15.0f, 0.0f, 0.0f)];
        [button setTitleEdgeInsets:UIEdgeInsetsMake(0.0f, 10.0f, 0.0f, 0.0f)];
        [button setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
        [button setBackgroundImage:[UIImage imageNamed:@"welcome_button_bg_full"] forState:UIControlStateNormal];
        [button setBackgroundImage:[UIImage imageNamed:@"welcome_button_bg_full_highlighted.png"] forState:UIControlStateHighlighted];
        [button setTitle:NSLocalizedString(@"Create WordPress.com Blog", @"") forState:UIControlStateNormal];
        [button addTarget:self action:@selector(handleCreateBlogTapped:) forControlEvents:UIControlEventTouchUpInside];
        
        [_noblogsView addSubview:button];
    }
    return _noblogsView;
}

- (void)showNoBlogsView {
    [self.view addSubview:self.noblogsView];
    
    self.buttonSelectAll.enabled = NO;
    self.noblogsView.alpha = 0.0;
    self.noblogsView.hidden = NO;
    _hideSignInButton = YES;
    [self.tableView reloadData];
    
    [UIView animateWithDuration:0.3f animations:^{
        self.noblogsView.alpha = 1.0f;
    }];
}

- (void)hideNoBlogsView {
    _hideSignInButton = NO;
    [self.tableView reloadData];
    
    if (!self.noblogsView) {
        return;
    }
    
    self.noblogsView.hidden = YES;
    self.buttonSelectAll.enabled = YES;
}

- (void)handleCreateBlogTapped:(id)sender {
    CreateWPComBlogViewController *viewController = [[CreateWPComBlogViewController alloc] initWithStyle:UITableViewStyleGrouped];
    viewController.delegate = self;
    [self.navigationController pushViewController:viewController animated:YES];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        SupportViewController *supportViewController = [[SupportViewController alloc] init];

        if (IS_IPAD) {
            [self.navigationController pushViewController:supportViewController animated:YES];
        } else {
            UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:supportViewController];
            navController.modalPresentationStyle = UIModalPresentationFormSheet;
            navController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
            navController.navigationBar.translucent = NO;
            [self presentViewController:navController animated:YES completion:nil];
        }
    }

    if (self.failureAlertView == alertView) {
        self.failureAlertView = nil;
    }
}

- (IBAction)saveSelectedBlogs:(id)sender {
    [self saveSelectedBlogs];
}

- (void)saveSelectedBlogs {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"refreshCommentsRequired"];
	
    NSManagedObjectContext *backgroundMOC = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    backgroundMOC.parentContext = [WordPressAppDelegate sharedWordPressApplicationDelegate].managedObjectContext;
    
    [backgroundMOC performBlock:^{
        for (NSDictionary *blog in self.usersBlogs) {
            if ([self.selectedBlogs containsObject:[blog valueForKey:@"blogid"]]) {
                [self createBlog:blog withContext:backgroundMOC];
            }
        }
        
        NSError *error;
        if(![backgroundMOC save:&error]) {
            WPFLog(@"Core data context save error on adding blogs: %@", error);
            #if DEBUG
            exit(-1);
            #endif
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.navigationController popToRootViewControllerAnimated:YES];
            [[WordPressComApi sharedApi] syncPushNotificationInfo];
        });
    }];
}

- (void)createBlog:(NSDictionary *)blogInfo withContext:(NSManagedObjectContext *)context {
    DDLogInfo(@"creating blog: %@", blogInfo);
    
    Blog *blog = [_account findOrCreateBlogFromDictionary:blogInfo withContext:context];
    blog.geolocationEnabled = self.geolocationEnabled;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [blog syncBlogWithSuccess:^{
            if( ![blog isWPcom] )
                [[WordPressComApi sharedApi] syncPushNotificationInfo];
        }
                          failure:nil];
    });
}

- (void)checkAddSelectedButtonStatus {
	//disable the 'Add Selected' button if they have selected 0 blogs, trac #521
	if (self.selectedBlogs.count == 0) {
		self.buttonAddSelected.enabled = NO;
		if (IS_IPAD) {
			self.topAddSelectedButton.enabled = NO;
        }
        // iOS 7 Beta 6 doesn't seem to be respecting the title text attributes for UIControlStateDisabled
        // so we have to engage in this hack until apple fixes it.
        [self.buttonAddSelected setTitleTextAttributes:@{
                                                    NSFontAttributeName: [WPStyleGuide regularTextFont],
                                                    NSForegroundColorAttributeName : [WPStyleGuide whisperGrey    ],
                                                    NSShadowAttributeName: [[NSShadow alloc] init]}
                                         forState:UIControlStateNormal];
	} else {
		self.buttonAddSelected.enabled = YES;
		if (IS_IPAD) {
			self.topAddSelectedButton.enabled = YES;
        }
        // iOS 7 Beta 6 doesn't seem to be respecting the title text attributes for UIControlStateDisabled
        // so we have to engage in this hack until apple fixes it.
        [self.buttonAddSelected setTitleTextAttributes:@{
                                                    NSFontAttributeName: [WPStyleGuide regularTextFont],
                                                    NSForegroundColorAttributeName : [UIColor whiteColor],
                                                    NSShadowAttributeName: [[NSShadow alloc] init]}
                                         forState:UIControlStateNormal];
	}
	
}

#pragma mark - CreateWPComBlogViewControllerDelegate

- (void)createdBlogWithDetails:(NSDictionary *)blogDetails
{
    [self.navigationController popToRootViewControllerAnimated:YES];
}

@end
