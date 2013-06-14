//
//  AccountMigrationTest.m
//  WordPress
//
//  Created by Jorge Bernal on 6/13/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "CoreDataTestHelper.h"
#import "WPAccount.h"
#import "Blog.h"
#import "SFHFKeychainUtils.h"
#import <NSURL+IDN/NSURL+IDN.h>

@interface AccountMigrationTest : SenTestCase

@end

@implementation AccountMigrationTest

- (void)setUp
{
    [[CoreDataTestHelper sharedHelper] setModelName:@"WordPress 11"];
    [[CoreDataTestHelper sharedHelper] reset];
    [[CoreDataTestHelper sharedHelper] registerDefaultContext];
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
    STAssertNil([[[self model] entitiesByName] objectForKey:@"Account"], nil);
    [self migrate];
    STAssertNotNil([[[self model] entitiesByName] objectForKey:@"Account"], nil);
}

- (void)testWpcomAccountMigrated
{
    Blog *blog = (Blog *)[[CoreDataTestHelper sharedHelper] insertEntityWithName:@"Blog"];
    blog.xmlrpc = @"http://test.wordpress.com/xmlrpc.php";
    blog.url = @"http://test.wordpress.com/";
    [blog setValue:@"com-user" forKey:@"username"];
    [blog dataSave];

    [SFHFKeychainUtils storeUsername:@"com-user" andPassword:@"com-pass" forServiceName:@"WordPress.com" updateExisting:YES error:nil];

    [self migrate];

    NSArray *accounts = [[CoreDataTestHelper sharedHelper] allObjectsForEntityName:@"Account"];
    STAssertNil([WPAccount defaultWordPressComAccount], nil);
    STAssertEquals([accounts count], 1u, nil);
    WPAccount *account = [accounts lastObject];
    STAssertEquals([[account blogs] count], 1u, nil);
    Blog *accountBlog = [account.blogs anyObject];
    STAssertEqualObjects([blog.objectID URIRepresentation], [accountBlog.objectID URIRepresentation], nil);
}

- (void)testDefaultWpcomAccountMigrated
{
    Blog *blog = (Blog *)[[CoreDataTestHelper sharedHelper] insertEntityWithName:@"Blog"];
    blog.xmlrpc = @"http://test.wordpress.com/xmlrpc.php";
    blog.url = @"http://test.wordpress.com/";
    [blog setValue:@"comd-user" forKey:@"username"];
    [blog dataSave];

    [SFHFKeychainUtils storeUsername:@"comd-user" andPassword:@"comd-pass" forServiceName:@"WordPress.com" updateExisting:YES error:nil];
    [[NSUserDefaults standardUserDefaults] setObject:@"comd-user" forKey:@"wpcom_username_preference"];

    [self migrate];

    NSArray *accounts = [[CoreDataTestHelper sharedHelper] allObjectsForEntityName:@"Account"];
    STAssertNotNil([WPAccount defaultWordPressComAccount], nil);
    STAssertEquals([accounts count], 1u, nil);
    WPAccount *account = [accounts lastObject];
    STAssertEquals([[account blogs] count], 1u, nil);
    Blog *accountBlog = [account.blogs anyObject];
    STAssertEqualObjects([blog.objectID URIRepresentation], [accountBlog.objectID URIRepresentation], nil);
}

- (void)testSelfHostedAccountMigrated
{
    Blog *blog = (Blog *)[[CoreDataTestHelper sharedHelper] insertEntityWithName:@"Blog"];
    blog.xmlrpc = @"http://test.blog/xmlrpc.php";
    blog.url = @"http://test.blog/";
    [blog setValue:@"sh-user" forKey:@"username"];
    [blog dataSave];

    [SFHFKeychainUtils storeUsername:@"sh-user" andPassword:@"sh-pass" forServiceName:[self hostUrlForBlog:blog] updateExisting:YES error:nil];

    [self migrate];

    NSArray *accounts = [[CoreDataTestHelper sharedHelper] allObjectsForEntityName:@"Account"];
    STAssertNil([WPAccount defaultWordPressComAccount], nil);
    STAssertEquals([accounts count], 1u, nil);
    WPAccount *account = [accounts lastObject];
    STAssertEquals([account.jetpackBlogs count], 0u, nil);
    Blog *accountBlog = [account.blogs anyObject];
    STAssertEqualObjects([blog.objectID URIRepresentation], [accountBlog.objectID URIRepresentation], nil);
    STAssertEqualObjects(account.username, @"sh-user", nil);
    STAssertEqualObjects(account.password, @"sh-pass", nil);
}

- (void)testJetpackAccountMigrated
{
    Blog *blog = (Blog *)[[CoreDataTestHelper sharedHelper] insertEntityWithName:@"Blog"];
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

    NSArray *accounts = [[CoreDataTestHelper sharedHelper] allObjectsForEntityName:@"Account"];
    STAssertNil([WPAccount defaultWordPressComAccount], nil);
    STAssertEquals([accounts count], 2u, nil);
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
    STAssertTrue([jetpackAccount.jetpackBlogs containsObject:migratedBlog], nil);
    STAssertTrue([blogAccount.blogs containsObject:migratedBlog], nil);
    STAssertEquals(migratedBlog.account, blogAccount, nil);
    STAssertEquals(migratedBlog.jetpackAccount, jetpackAccount, nil);

    STAssertEqualObjects(blogAccount.username, @"jp-user", nil);
    STAssertEqualObjects(blogAccount.password, @"jp-pass", nil);
    STAssertEqualObjects(jetpackAccount.username, @"com-jpuser", nil);
    STAssertEqualObjects(jetpackAccount.password, @"com-jppass", nil);
}

- (void)migrate
{
    STAssertTrue([[CoreDataTestHelper sharedHelper] migrateToModelName:@"WordPress 12"], nil);
    [[CoreDataTestHelper sharedHelper] registerDefaultContext];
}

- (NSManagedObjectModel *)model
{
    return [[[[CoreDataTestHelper sharedHelper] managedObjectContext] persistentStoreCoordinator] managedObjectModel];
}

- (NSString *)hostUrlForBlog:(NSManagedObject *)blog {
    NSString *url = [blog valueForKey:@"url"];
    NSError *error = NULL;
    NSRegularExpression *protocol = [NSRegularExpression regularExpressionWithPattern:@"http(s?)://" options:NSRegularExpressionCaseInsensitive error:&error];
    NSString *result = [NSString stringWithFormat:@"%@", [protocol stringByReplacingMatchesInString:[NSURL IDNDecodedHostname:url] options:0 range:NSMakeRange(0, [[NSURL IDNDecodedHostname:url] length]) withTemplate:@""]];

    if([result hasSuffix:@"/"])
        result = [result substringToIndex:[result length] - 1];

    return result;
}

@end
