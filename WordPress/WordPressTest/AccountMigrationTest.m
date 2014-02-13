//
//  AccountMigrationTest.m
//  WordPress
//
//  Created by Jorge Bernal on 6/13/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CoreDataTestHelper.h"
#import "WPAccount.h"
#import "Blog.h"
#import "SFHFKeychainUtils.h"
#import <NSURL+IDN/NSURL+IDN.h>

@interface AccountMigrationTest : XCTestCase

@end

@implementation AccountMigrationTest

- (void)setUp
{
    [[CoreDataTestHelper sharedHelper] setModelName:@"WordPress 11"];
    [[CoreDataTestHelper sharedHelper] reset];
    
    [WPAccount removeDefaultWordPressComAccount];
    NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
}

- (void)tearDown
{
    [super tearDown];
}

- (void)testMigration
{
    // Set up Default WordPress.com account
    XCTAssertNil([[[self model] entitiesByName] objectForKey:@"Account"]);
    [self migrate];
    XCTAssertNotNil([[[self model] entitiesByName] objectForKey:@"Account"]);
}

- (void)testWpcomAccountMigrated
{
    Blog *blog = (Blog *)[[CoreDataTestHelper sharedHelper] insertEntityIntoMainContextWithName:@"Blog"];
    blog.xmlrpc = @"http://test.wordpress.com/xmlrpc.php";
    blog.url = @"http://test.wordpress.com/";
    [blog setValue:@"com-user" forKey:@"username"];
    [blog dataSave];

    [SFHFKeychainUtils storeUsername:@"com-user" andPassword:@"com-pass" forServiceName:@"WordPress.com" updateExisting:YES error:nil];

    [self migrate];

    NSArray *accounts = [[CoreDataTestHelper sharedHelper] allObjectsInMainContextForEntityName:@"Account"];
    XCTAssertNil([WPAccount defaultWordPressComAccount]);
    XCTAssertEqual([accounts count], 1u);
    WPAccount *account = [accounts lastObject];
    XCTAssertEqual([[account blogs] count], 1u);
    Blog *accountBlog = [account.blogs anyObject];
    XCTAssertEqualObjects([blog.objectID URIRepresentation], [accountBlog.objectID URIRepresentation]);
}

- (void)testDefaultWpcomAccountMigrated
{
    Blog *blog = (Blog *)[[CoreDataTestHelper sharedHelper] insertEntityIntoMainContextWithName:@"Blog"];
    blog.xmlrpc = @"http://test.wordpress.com/xmlrpc.php";
    blog.url = @"http://test.wordpress.com/";
    [blog setValue:@"comd-user" forKey:@"username"];
    [blog dataSave];

    [SFHFKeychainUtils storeUsername:@"comd-user" andPassword:@"comd-pass" forServiceName:@"WordPress.com" updateExisting:YES error:nil];
    [[NSUserDefaults standardUserDefaults] setObject:@"comd-user" forKey:@"wpcom_username_preference"];

    [self migrate];

    NSArray *accounts = [[CoreDataTestHelper sharedHelper] allObjectsInMainContextForEntityName:@"Account"];
    XCTAssertNotNil([WPAccount defaultWordPressComAccount]);
    XCTAssertEqual([accounts count], 1u);
    WPAccount *account = [accounts lastObject];
    XCTAssertEqual([[account blogs] count], 1u);
    Blog *accountBlog = [account.blogs anyObject];
    XCTAssertEqualObjects([blog.objectID URIRepresentation], [accountBlog.objectID URIRepresentation]);
}

- (void)testSelfHostedAccountMigrated
{
    Blog *blog = (Blog *)[[CoreDataTestHelper sharedHelper] insertEntityIntoMainContextWithName:@"Blog"];
    blog.xmlrpc = @"http://test.blog/xmlrpc.php";
    blog.url = @"http://test.blog/";
    [blog setValue:@"sh-user" forKey:@"username"];
    [blog dataSave];

    [SFHFKeychainUtils storeUsername:@"sh-user" andPassword:@"sh-pass" forServiceName:[self hostUrlForBlog:blog] updateExisting:YES error:nil];

    [self migrate];

    NSArray *accounts = [[CoreDataTestHelper sharedHelper] allObjectsInMainContextForEntityName:@"Account"];
    XCTAssertNil([WPAccount defaultWordPressComAccount]);
    XCTAssertEqual([accounts count], 1u);
    WPAccount *account = [accounts lastObject];
    XCTAssertEqual([account.jetpackBlogs count], 0u);
    Blog *accountBlog = [account.blogs anyObject];
    XCTAssertEqualObjects([blog.objectID URIRepresentation], [accountBlog.objectID URIRepresentation]);
    XCTAssertEqualObjects(account.username, @"sh-user");
    XCTAssertEqualObjects(account.password, @"sh-pass");
}

- (void)testJetpackAccountMigrated
{
    Blog *blog = (Blog *)[[CoreDataTestHelper sharedHelper] insertEntityIntoMainContextWithName:@"Blog"];
    blog.xmlrpc = @"http://test.blog/xmlrpc.php";
    blog.url = @"http://test.blog/";
    blog.options = @{@"jetpack_version": @{
                             @"value": @"1.8.2",
                             @"desc": @"stub",
                             @"readonly": @YES,
                             },
                     @"jetpack_client_id": @{
                             @"value": @"1",
                             @"desc": @"stub",
                             @"readonly": @YES,
                             },
                     };
    [blog setValue:@"jp-user" forKey:@"username"];
    [blog dataSave];

    [SFHFKeychainUtils storeUsername:@"jp-user" andPassword:@"jp-pass" forServiceName:[self hostUrlForBlog:blog] updateExisting:YES error:nil];

    NSString *blogDefaultsKey = [NSString stringWithFormat:@"jetpackblog-%@", blog.url];
    [[NSUserDefaults standardUserDefaults] setObject:@"com-jpuser" forKey:blogDefaultsKey];
    [SFHFKeychainUtils storeUsername:@"com-jpuser" andPassword:@"com-jppass" forServiceName:@"WordPress.com" updateExisting:YES error:nil];

    [self migrate];

    NSArray *accounts = [[CoreDataTestHelper sharedHelper] allObjectsInMainContextForEntityName:@"Account"];
    XCTAssertNil([WPAccount defaultWordPressComAccount]);
    XCTAssertEqual([accounts count], 2u);
    __block WPAccount *blogAccount, *jetpackAccount;
    [accounts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([(WPAccount *)obj isWpcom]) {
            jetpackAccount = obj;
        } else {
            blogAccount = obj;
        }
    }];
    NSManagedObjectID *blogId = [[[CoreDataTestHelper sharedHelper] persistentStoreCoordinator] managedObjectIDForURIRepresentation:[[blog objectID] URIRepresentation]];
    Blog *migratedBlog = (Blog *)[[[CoreDataTestHelper sharedHelper] managedObjectContext] objectWithID:blogId];
    XCTAssertTrue([jetpackAccount.jetpackBlogs containsObject:migratedBlog]);
    XCTAssertTrue([blogAccount.blogs containsObject:migratedBlog]);
    XCTAssertEqual(migratedBlog.account, blogAccount);
    XCTAssertEqual(migratedBlog.jetpackAccount, jetpackAccount);

    XCTAssertEqualObjects(blogAccount.username, @"jp-user");
    XCTAssertEqualObjects(blogAccount.password, @"jp-pass");
    XCTAssertEqualObjects(jetpackAccount.username, @"com-jpuser");
    XCTAssertEqualObjects(jetpackAccount.password, @"com-jppass");
}

- (void)migrate
{
    XCTAssertTrue([[CoreDataTestHelper sharedHelper] migrateToModelName:@"WordPress 12"]);
}

- (NSManagedObjectModel *)model
{
    return [[[[CoreDataTestHelper sharedHelper] managedObjectContext] persistentStoreCoordinator] managedObjectModel];
}

- (NSString *)hostUrlForBlog:(NSManagedObject *)blog {
    NSString *url = [blog valueForKey:@"url"];
    NSError *error = nil;
    NSRegularExpression *protocol = [NSRegularExpression regularExpressionWithPattern:@"http(s?)://" options:NSRegularExpressionCaseInsensitive error:&error];
    NSString *result = [NSString stringWithFormat:@"%@", [protocol stringByReplacingMatchesInString:[NSURL IDNDecodedHostname:url] options:0 range:NSMakeRange(0, [[NSURL IDNDecodedHostname:url] length]) withTemplate:@""]];

    if([result hasSuffix:@"/"])
        result = [result substringToIndex:[result length] - 1];

    return result;
}

@end
