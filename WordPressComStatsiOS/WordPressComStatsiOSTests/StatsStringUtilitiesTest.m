//
//  StatsStringUtilitiesTest.m
//  WordPressCom-Stats-iOS
//
//  Created by Sergio Estevao on 07/10/2016.
//  Copyright © 2016 Automattic Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "StatsStringUtilities.h"

@interface StatsStringUtilitiesTest : XCTestCase

@property (nonatomic, strong) StatsStringUtilities *subject;

@end

@implementation StatsStringUtilitiesTest

- (void)setUp {
    [super setUp];
    self.subject = [[StatsStringUtilities alloc] init];
}

- (void)tearDown {
    self.subject = nil;
    [super tearDown];
}

- (void)testSanitizePostTitleEmptyString {
    NSString *result = [self.subject sanitizePostTitle:@""];
    XCTAssertEqualObjects(result, @"");
}

- (void)testSanitizePostTitleWhitespaceString {
    NSString *result = [self.subject sanitizePostTitle:@" "];
    XCTAssertEqualObjects(result, @"");
}

- (void)testSanitizePostTitleNonCharacterString {
    NSString *result = [self.subject sanitizePostTitle:@"_"];
    XCTAssertEqualObjects(result, @"_");
}

- (void)testSanitizePostTitleHTMLEntityString{
    NSString *result = [self.subject sanitizePostTitle:@"&amp;"];
    XCTAssertEqualObjects(result, @"&");
}

- (void)testSanitizePostTitleComplexHTMLEntityString {
    NSString *result = [self.subject sanitizePostTitle:@"This &#8220;has&#8221; special &amp; characters"];
    XCTAssertEqualObjects(result, @"This “has” special & characters");
}

- (void)testDisplayablePostTitle {
    NSString *result = [self.subject displayablePostTitle:@"This &#8220;has&#8221; special &amp; characters"];
    XCTAssertEqualObjects(result, @"This “has” special & characters");
}

- (void)testDisplayablePostTitleWithEmptyTitle {
    NSString *result = [self.subject displayablePostTitle:@""];
    NSString *expected = NSLocalizedString(@"(no title)", @"");
    XCTAssertEqualObjects(result, expected);

    NSString *result2 = [self.subject displayablePostTitle:@" "];
    NSString *expected2 = NSLocalizedString(@"(no title)", @"");
    XCTAssertEqualObjects(result2, expected2);
}

@end
