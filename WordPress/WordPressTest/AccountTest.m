//
//  AccountTest.m
//  WordPress
//
//  Created by Jorge Bernal on 6/13/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CoreDataTestHelper.h"
#import "WPAccount.h"
#import "ContextManager.h"
#import "AsyncTestHelper.h"

@interface AccountTest : XCTestCase

@end

@implementation AccountTest

- (void)setUp
{
    [super setUp];
    
    // We need to remove the account, but not through core data as the PSCs have changed between
    // setUp and CoreDataTestHelper reset.
    [WPAccount removeDefaultWordPressComAccountWithContext:nil];
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
    [[CoreDataTestHelper sharedHelper] reset];
}

- (void)testNewAccountDoesntSetDefaultAccount
{
    XCTAssertNil([WPAccount defaultWordPressComAccount]);
    
    ATHStart();
    WPAccount *_account = [WPAccount createOrUpdateWordPressComAccountWithUsername:@"user" password:@"pass" authToken:@"token" context:[ContextManager sharedInstance].mainContext];
    ATHEnd();
    
    XCTAssertNil([WPAccount defaultWordPressComAccount]);
    [WPAccount setDefaultWordPressComAccount:_account];
    
    XCTAssertNotNil([WPAccount defaultWordPressComAccount]);
    XCTAssertEqualObjects([WPAccount defaultWordPressComAccount], _account);
    
    ATHStart();
    WPAccount *_account2 = [WPAccount createOrUpdateWordPressComAccountWithUsername:@"user" password:@"pass" authToken:@"token" context:[ContextManager sharedInstance].mainContext];
    ATHEnd();
    
    XCTAssertNotNil(_account2);
    
    XCTAssertEqualObjects([WPAccount defaultWordPressComAccount], _account);
}

- (void)testNewSelfHostedDoesntSetDefaultAccount
{
    XCTAssertNil([WPAccount defaultWordPressComAccount]);
    
    ATHStart();
    WPAccount *_account = [WPAccount createOrUpdateSelfHostedAccountWithXmlrpc:@"http://test/xmlprc.php" username:@"user" andPassword:@"pass"];
    ATHEnd();
   
    XCTAssertNotNil(_account);
    XCTAssertNil([WPAccount defaultWordPressComAccount]);
}

@end
