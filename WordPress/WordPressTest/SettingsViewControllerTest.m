//
//  SettingsViewControllerTest.m
//  WordPress
//
//  Created by Jorge Bernal on 22/11/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CoreDataTestHelper.h"
#import "WPAccount.h"
#import "Blog.h"
#import "Constants.h"
#import "SettingsViewController.h"

@interface SettingsViewControllerTest : XCTestCase

@end

@implementation SettingsViewControllerTest

- (void)setUp
{
    [super setUp];
    // Put setup code here; it will be run once, before the first test case.
    [[CoreDataTestHelper sharedHelper] registerDefaultContext];
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
    [[CoreDataTestHelper sharedHelper] reset];
}

- (void)testWpcomSection
{
    [WPAccount removeDefaultWordPressComAccount];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kApnsDeviceTokenPrefKey];
    SettingsViewController *controller = [self settingsViewController];
    [self present:controller];

    UITableView *table = controller.tableView;
    UITableViewCell *cell = [self tableView:table cellForRow:0];

    /*
     Signed out

     - Sign In
     */
    XCTAssertEqual(1, [table numberOfRowsInSection:0]);
    XCTAssertEqualObjects(@"wpcom-sign-in", cell.accessibilityIdentifier);


    // Sign In
    WPAccount *account = [WPAccount createOrUpdateWordPressComAccountWithUsername:@"jacksparrow" password:@"piratesobrave" authToken:@"sevenseas"];
    [WPAccount setDefaultWordPressComAccount:account];

    /*
     Signed In, Notifications disabled, 1 blog

     - Username     jacksparrow
     - Sign Out
     */
    XCTAssertEqual(2, [table numberOfRowsInSection:0]);
    cell = [self tableView:table cellForRow:0];
    XCTAssertEqualObjects(@"wpcom-username", cell.accessibilityIdentifier);
    cell = [self tableView:table cellForRow:1];
    XCTAssertEqualObjects(@"wpcom-sign-out", cell.accessibilityIdentifier);

    [[NSUserDefaults standardUserDefaults] setObject:@"aFakeAPNSToken" forKey:kApnsDeviceTokenPrefKey];
    [table reloadData];

    /*
     Signed In, Notifications enabled, 0 blogs

     - Username     jacksparrow
     - Manage Notifications
     - Sign Out
     */
    XCTAssertEqual(3, [table numberOfRowsInSection:0]);
    cell = [self tableView:table cellForRow:0];
    XCTAssertEqualObjects(@"wpcom-username", cell.accessibilityIdentifier);
    cell = [self tableView:table cellForRow:1];
    XCTAssertEqualObjects(@"wpcom-manage-notifications", cell.accessibilityIdentifier);
    cell = [self tableView:table cellForRow:2];
    XCTAssertEqualObjects(@"wpcom-sign-out", cell.accessibilityIdentifier);

    Blog *blog = [account findOrCreateBlogFromDictionary:@{@"url": @"blog1.com"} withContext:account.managedObjectContext];
    [blog dataSave];
    [table reloadData];

    /*
     Signed In, Notifications enabled, 1 blogs

     - Username     jacksparrow
     - Manage Blogs
     - Manage Notifications
     - Sign Out
     */
    XCTAssertEqual(4, [table numberOfRowsInSection:0]);
    cell = [self tableView:table cellForRow:0];
    XCTAssertEqualObjects(@"wpcom-username", cell.accessibilityIdentifier);
    cell = [self tableView:table cellForRow:1];
    XCTAssertEqualObjects(@"wpcom-manage-blogs", cell.accessibilityIdentifier);
    cell = [self tableView:table cellForRow:2];
    XCTAssertEqualObjects(@"wpcom-manage-notifications", cell.accessibilityIdentifier);
    cell = [self tableView:table cellForRow:3];
    XCTAssertEqualObjects(@"wpcom-sign-out", cell.accessibilityIdentifier);
    
    blog = [account findOrCreateBlogFromDictionary:@{@"url": @"blog2.com"} withContext:account.managedObjectContext];
    [blog dataSave];
    [table reloadData];

    /*
     Signed In, Notifications enabled, 2 blogs

     - Username     jacksparrow
     - Manage Blogs
     - Manage Notifications
     - Sign Out
     */
    XCTAssertEqual(4, [table numberOfRowsInSection:0]);
    cell = [self tableView:table cellForRow:0];
    XCTAssertEqualObjects(@"wpcom-username", cell.accessibilityIdentifier);
    cell = [self tableView:table cellForRow:1];
    XCTAssertEqualObjects(@"wpcom-manage-blogs", cell.accessibilityIdentifier);
    cell = [self tableView:table cellForRow:2];
    XCTAssertEqualObjects(@"wpcom-manage-notifications", cell.accessibilityIdentifier);
    cell = [self tableView:table cellForRow:3];
    XCTAssertEqualObjects(@"wpcom-sign-out", cell.accessibilityIdentifier);

    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kApnsDeviceTokenPrefKey];
    [table reloadData];

    /*
     Signed In, Notifications disabled, 2 blogs

     - Username     jacksparrow
     - Manage Blogs
     - Sign Out
     */
    XCTAssertEqual(3, [table numberOfRowsInSection:0]);
    cell = [self tableView:table cellForRow:0];
    XCTAssertEqualObjects(@"wpcom-username", cell.accessibilityIdentifier);
    cell = [self tableView:table cellForRow:1];
    XCTAssertEqualObjects(@"wpcom-manage-blogs", cell.accessibilityIdentifier);
    cell = [self tableView:table cellForRow:2];
    XCTAssertEqualObjects(@"wpcom-sign-out", cell.accessibilityIdentifier);
}

- (SettingsViewController *)settingsViewController {
    SettingsViewController *controller =  [SettingsViewController new];
    // Force view load
    [controller view];
    return controller;
}

- (void)present:(UIViewController *)controller {
    [[[[[UIApplication sharedApplication] delegate] window] rootViewController] presentViewController:controller animated:NO completion:nil];
}

- (void)dismiss:(UIViewController *)controller {
    [[[[[UIApplication sharedApplication] delegate] window] rootViewController] dismissViewControllerAnimated:NO completion:nil];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRow:(NSInteger)row {
    return [tableView.dataSource tableView:tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
}

@end
