//
//  BlogJetpackTest.m
//  WordPress
//
//  Created by Jorge Bernal on 2/12/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <Nocilla/Nocilla.h>
#import "BlogJetpackTest.h"
#import "CoreDataTestHelper.h"
#import "AsyncTestHelper.h"
#import "Blog+Jetpack.h"

@implementation BlogJetpackTest {
    Blog *_blog;
}

- (void)setUp {
    _blog = (Blog *)[[CoreDataTestHelper sharedHelper] insertEntityWithName:@"Blog"];
    _blog.xmlrpc = @"http://test.blog/xmlrpc.php";
    _blog.url = @"http://test.blog/";
    _blog.options = @{@"jetpack_version": @{
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
}

- (void)tearDown {
}

- (void)testAssertionsOnWPcom {
    _blog = (Blog *)[[CoreDataTestHelper sharedHelper] insertEntityWithName:@"Blog"];
    _blog.xmlrpc = @"http://test.wordpress.com/xmlrpc.php";
    _blog.url = @"http://test.wordpress.com/";
    STAssertThrows([_blog hasJetpack], @"WordPress.com blogs don't support Jetpack methods");
    STAssertThrows([_blog jetpackVersion], @"WordPress.com blogs don't support Jetpack methods");
    STAssertThrows([_blog jetpackUsername], @"WordPress.com blogs don't support Jetpack methods");
    STAssertThrows([_blog jetpackPassword], @"WordPress.com blogs don't support Jetpack methods");
    STAssertThrows([_blog jetpackBlogID], @"WordPress.com blogs don't support Jetpack methods");
    STAssertThrows([_blog removeJetpackCredentials], @"WordPress.com blogs don't support Jetpack methods");
    STAssertThrows([_blog validateJetpackUsername:@"test" password:@"test" success:nil failure:nil], @"WordPress.com blogs don't support Jetpack methods");
}

- (void)testHasJetpack {
    STAssertTrue([_blog hasJetpack], nil);
    _blog.options = nil;
    STAssertFalse([_blog hasJetpack], nil);
}

- (void)testJetpackVersion {
    STAssertEqualObjects([_blog jetpackVersion], @"1.8.2", nil);
}

- (void)testJetpackBlogId {
    STAssertEqualObjects([_blog jetpackBlogID], @1, nil);
}

- (void)testJetpackUsername {
    STAssertNil([_blog jetpackUsername], nil);
}

- (void)testJetpackPassword {
    STAssertNil([_blog jetpackPassword], nil);
}

- (void)testValidateCredentials {
    [[LSNocilla sharedInstance] start];

    NSString *correct = [NSString stringWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"get-user-blogs_has-blog" ofType:@"json"] encoding:NSUTF8StringEncoding error:nil];
    NSString *wrong = [NSString stringWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"get-user-blogs_doesnt-have-blog" ofType:@"json"] encoding:NSUTF8StringEncoding error:nil];

    stubRequest(@"GET", @"https://public-api.wordpress.com/get-user-blogs/1.0?f=json").
    withHeader(@"Authorization", @"Basic dGVzdDE6dGVzdDE="). // test1:test1
    andReturn(200).
    withHeader(@"Content-Type", @"application/json").
    withBody(wrong);

    ATHStart();
    [_blog validateJetpackUsername:@"test1" password:@"test1" success:^{
        STFail(@"User test1 shouldn't have access to test.blog");
        ATHNotify();
    } failure:^(NSError *error) {
        STAssertEquals(error.domain, BlogJetpackErrorDomain, nil);
        STAssertEquals(error.code, BlogJetpackErrorCodeNoRecordForBlog, nil);
        ATHNotify();
    }];
    ATHWait();

    stubRequest(@"GET", @"https://public-api.wordpress.com/get-user-blogs/1.0?f=json").
    withHeader(@"Authorization", @"Basic dGVzdDI6dGVzdDI="). // test2:test2
    andReturn(200).
    withHeader(@"Content-Type", @"application/json").
    withBody(correct);

    ATHStart();
    [_blog validateJetpackUsername:@"test2" password:@"test2" success:^{
        ATHNotify();
    } failure:^(NSError *error) {
        STFail(@"User test2 should have access to test.blog");
        ATHNotify();
    }];
    ATHWait();

    [[LSNocilla sharedInstance] stop];
}

@end
