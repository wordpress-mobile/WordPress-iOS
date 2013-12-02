//
//  WelcomeViewController.m
//  WordPress
//
//  Created by Sendhil Panchadsaram on 9/4/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "WelcomeViewController.h"
#import "WordPressAppDelegate.h"
#import "AddSiteViewController.h"
#import "WPcomLoginViewController.h"
#import "CreateWPComAccountViewController.h"
#import "CreateWPComBlogViewController.h"
#import "AddUsersBlogsViewController.h"
#import "WordPressComApi.h"
#import "WPAccount.h"
#import "WPTableViewSectionHeaderView.h"

@interface WelcomeViewController () <
    WPcomLoginViewControllerDelegate,
    CreateWPComAccountViewControllerDelegate,
    CreateWPComBlogViewControllerDelegate> {
        NSArray *_buttonTitles;
        NSArray *_sectionHeaderTitles;
        WordPressAppDelegate *__weak _appDelegate;
}

@end

@implementation WelcomeViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        _buttonTitles = @[@[NSLocalizedString(@"Add Self-Hosted Site", nil), NSLocalizedString(@"Add WordPress.com Site", nil)], @[NSLocalizedString(@"Create WordPress.com Site", nil)]];
        _sectionHeaderTitles = @[NSLocalizedString(@"Add an existing Site:", nil), NSLocalizedString(@"Start a new Site:", nil)];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    _appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];

    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];

    [self.tableView registerClass:[WPTableViewCell class] forCellReuseIdentifier:@"Cell"];
}

#pragma mark - Table view data source

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    WPTableViewSectionHeaderView *header = [[WPTableViewSectionHeaderView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 0)];
    header.title = [self titleForHeaderInSection:section];
    return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    NSString *title = [self titleForHeaderInSection:section];
    return [WPTableViewSectionHeaderView heightForTitle:title andWidth:CGRectGetWidth(self.view.bounds)];
}

- (NSString *)titleForHeaderInSection:(NSInteger)section
{
    return _sectionHeaderTitles[section];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return [_buttonTitles count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [_buttonTitles[section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    cell.textLabel.text = _buttonTitles[indexPath.section][indexPath.row];
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    cell.textLabel.font = [WPStyleGuide tableviewTextFont];
    cell.textLabel.textColor = [WPStyleGuide tableViewActionColor];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self isIndexPathForAddSelfHostedBlog:indexPath]) {
        [self handleAddSelfHostedBlog];
    } else if ([self isIndexPathForAddWordPressDotComBlog:indexPath]) {
        [self handleAddWordPressDotComBlog];
    } else if ([self isIndexPathForCreateWordPressDotComBlog:indexPath]) {
        [self handleCreateWordPressDotComBlog];
    }
}

#pragma mark - Private Methods

- (BOOL)isIndexPathForAddSelfHostedBlog:(NSIndexPath *)indexPath
{
    return indexPath.section == 0 && indexPath.row == 0;
}

- (BOOL)isIndexPathForAddWordPressDotComBlog:(NSIndexPath *)indexPath
{
    return indexPath.section == 0 && indexPath.row == 1;
}

- (BOOL)isIndexPathForCreateWordPressDotComBlog:(NSIndexPath *)indexPath
{
    return indexPath.section == 1 && indexPath.row == 0;
}

- (void)handleAddSelfHostedBlog
{
    [WPMobileStats trackEventForWPCom:StatsEventWelcomeViewControllerClickedAddSelfHostedBlog];
    
    AddSiteViewController *addSiteView = [[AddSiteViewController alloc] initWithNibName:nil bundle:nil];
    [self.navigationController pushViewController:addSiteView animated:YES];
}


- (void)handleAddWordPressDotComBlog
{
    [WPMobileStats trackEventForWPCom:StatsEventWelcomeViewControllerClickedAddWordpressDotComBlog];
    
    if(_appDelegate.isWPcomAuthenticated) {
        AddUsersBlogsViewController *addUsersBlogsView = [[AddUsersBlogsViewController alloc] initWithAccount:[WPAccount defaultWordPressComAccount]];
        addUsersBlogsView.isWPcom = YES;
        [self.navigationController pushViewController:addUsersBlogsView animated:YES];
    }
    else {
        WPcomLoginViewController *wpLoginView = [[WPcomLoginViewController alloc] initWithStyle:UITableViewStyleGrouped];
        wpLoginView.delegate = self;
        [self.navigationController pushViewController:wpLoginView animated:YES];
    }
}

- (void)handleCreateWordPressDotComBlog
{
    [WPMobileStats trackEventForWPCom:StatsEventWelcomeViewControllerClickedCreateWordpressDotComBlog];
    
    if ([WordPressComApi sharedApi].hasCredentials) {
        CreateWPComBlogViewController *viewController = [[CreateWPComBlogViewController alloc] initWithStyle:UITableViewStyleGrouped];
        viewController.delegate = self;
        [self.navigationController pushViewController:viewController animated:YES];
    } else {
        CreateWPComAccountViewController *viewController = [[CreateWPComAccountViewController alloc] initWithStyle:UITableViewStyleGrouped];
        viewController.delegate = self;
        [self.navigationController pushViewController:viewController animated:YES];
    }
}

#pragma mark - WPcomLoginViewControllerDelegate

- (void)loginControllerDidDismiss:(WPcomLoginViewController *)loginController {
    [self.navigationController popViewControllerAnimated:YES];
}


- (void)loginController:(WPcomLoginViewController *)loginController didAuthenticateWithAccount:(WPAccount *)account {
    [self.navigationController popViewControllerAnimated:NO];
    [self handleAddWordPressDotComBlog];
}

#pragma mark - CreateWPComAccountViewControllerDelegate

- (void)createdAndSignedInAccountWithUserName:(NSString *)userName
{
    [self.navigationController popViewControllerAnimated:NO];
    [self handleAddWordPressDotComBlog];
}

- (void)createdAccountWithUserName:(NSString *)userName
{
    // In this case the user was able to create an account but for some reason was unable to sign in.
    // Just present the login controller in this case with the data prefilled and give the user the chance to sign in again
    [self.navigationController popViewControllerAnimated:NO];
    WPcomLoginViewController *wpLoginView = [[WPcomLoginViewController alloc] initWithStyle:UITableViewStyleGrouped];
    wpLoginView.delegate = self;
    wpLoginView.predefinedUsername = userName;
    [self.navigationController pushViewController:wpLoginView animated:YES];
}

#pragma mark - CreateWPComBlogViewControllerDelegate

- (void)createdBlogWithDetails:(NSDictionary *)blogDetails
{
    [self.navigationController popToRootViewControllerAnimated:YES];
}


@end
