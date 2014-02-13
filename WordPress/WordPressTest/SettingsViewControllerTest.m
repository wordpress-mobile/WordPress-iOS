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
#import "AsyncTestHelper.h"
#import "ContextManager.h"

@interface SettingsViewControllerTest : XCTestCase

@end

@implementation SettingsViewControllerTest

- (void)setUp
{
    [super setUp];

    if ([WPAccount defaultWordPressComAccount]) {
        ATHStart();
        [WPAccount removeDefaultWordPressComAccountWithContext:[ContextManager sharedInstance].mainContext];
        ATHEnd();
    }
}

- (void)tearDown
{
    [super tearDown];
    [[CoreDataTestHelper sharedHelper] reset];
}

- (void)testWpcomSection
{    
    XCTAssertNil([WPAccount defaultWordPressComAccount], @"There should be no default account");
    
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
    ATHStart();
    WPAccount *account = [WPAccount createOrUpdateWordPressComAccountWithUsername:@"jacksparrow" password:@"piratesobrave" authToken:nil context:[ContextManager sharedInstance].mainContext];
    ATHEnd();
    
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

    ATHStart();
    Blog *blog = [account findOrCreateBlogFromDictionary:@{@"url": @"blog1.com", @"xmlrpc": @"http://blog1.com/xmlrpc.php"} withContext:account.managedObjectContext];
    [[ContextManager sharedInstance] saveContext:account.managedObjectContext];
    ATHEnd();
    
    [table reloadData];

    /*
     Signed In, Notifications enabled, 1 blogs

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
    
    ATHStart();
    blog = [account findOrCreateBlogFromDictionary:@{@"url": @"blog2.com", @"xmlrpc": @"http://blog2.com/xmlrpc.php"} withContext:account.managedObjectContext];
    [[ContextManager sharedInstance] saveContext:account.managedObjectContext];
    ATHEnd();
    
    [table reloadData];

    /*
     Signed In, Notifications enabled, 2 blogs

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

    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kApnsDeviceTokenPrefKey];
    [table reloadData];

    /*
     Signed In, Notifications disabled, 2 blogs

     - Username     jacksparrow
     - Sign Out
     */
    XCTAssertEqual(2, [table numberOfRowsInSection:0]);
    cell = [self tableView:table cellForRow:0];
    XCTAssertEqualObjects(@"wpcom-username", cell.accessibilityIdentifier);
    cell = [self tableView:table cellForRow:1];
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
