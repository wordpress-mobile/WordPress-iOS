//
//  AccountTest.m
//  WordPress
//
//  Created by Jorge Bernal on 6/13/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "CoreDataTestHelper.h"
#import "WPAccount.h"

@interface AccountTest : SenTestCase

@end

@implementation AccountTest

- (void)setUp
{
    [super setUp];
    [[CoreDataTestHelper sharedHelper] registerDefaultContext];
    // The default account is cached before we get a chance to replace the delegate's context
    [WPAccount removeDefaultWordPressComAccount];
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
    [[CoreDataTestHelper sharedHelper] reset];
}

- (void)testNewAccountDoesntSetDefaultAccount
{
    STAssertNil([WPAccount defaultWordPressComAccount], nil);
    WPAccount *_account = [WPAccount createOrUpdateWordPressComAccountWithUsername:@"user" password:@"pass" authToken:@"token"];
    STAssertNil([WPAccount defaultWordPressComAccount], nil);
    [WPAccount setDefaultWordPressComAccount:_account];
    STAssertNotNil([WPAccount defaultWordPressComAccount], nil);
    STAssertEqualObjects([WPAccount defaultWordPressComAccount], _account, nil);
    WPAccount *_account2 = [WPAccount createOrUpdateWordPressComAccountWithUsername:@"user" password:@"pass" authToken:@"token"];
    STAssertNotNil(_account2, nil);
    STAssertEqualObjects([WPAccount defaultWordPressComAccount], _account, nil);
}

- (void)testNewSelfHostedDoesntSetDefaultAccount
{
    STAssertNil([WPAccount defaultWordPressComAccount], nil);
    WPAccount *_account = [WPAccount createOrUpdateSelfHostedAccountWithXmlrpc:@"http://test/xmlprc.php" username:@"user" andPassword:@"pass"];
    STAssertNotNil(_account, nil);
    STAssertNil([WPAccount defaultWordPressComAccount], nil);
}

@end
