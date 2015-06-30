#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "WPURLRequest.h"

@interface WPURLRequestTest : XCTestCase
@end

@implementation WPURLRequestTest


- (void)testWordPressComURLShouldNotIncludePassword
{
    NSURL *redirectURL = [NSURL URLWithString:@"http://example.com"];
    NSURL *loginURL = [NSURL URLWithString:@"https://wordpress.com/"];
    NSString *password = @"Iab5aK9myf3oR9I";
    NSString *token = @"Pog4Byiv6viG9Wy";
    NSURLRequest *request = [WPURLRequest requestForAuthenticationWithURL:loginURL
                                                              redirectURL:redirectURL
                                                                 username:@"username"
                                                                 password:password
                                                              bearerToken:token
                                                                userAgent:@"agent"];
    XCTAssertEqualObjects(request.URL, loginURL);
    XCTAssertNotNil(request.HTTPBody);
    NSString *body = [[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding];
    XCTAssertEqual([body rangeOfString:password].location, NSNotFound, @"password shouldn't be in the request body");
    NSString *authorization = [request valueForHTTPHeaderField:@"Authorization"];
    XCTAssertNotNil(authorization);
    XCTAssertNotEqual([authorization rangeOfString:token].location, NSNotFound, @"token should be in the request body");
}

- (void)testTokenShouldNotBeSentOutsideDotCom
{
    NSURL *redirectURL = [NSURL URLWithString:@"http://example.com"];
    NSURL *loginURL = [NSURL URLWithString:@"http://example.com/"];
    NSString *password = @"Iab5aK9myf3oR9I";
    NSString *token = @"Pog4Byiv6viG9Wy";
    NSURLRequest *request = [WPURLRequest requestForAuthenticationWithURL:loginURL
                                                              redirectURL:redirectURL
                                                                 username:@"username"
                                                                 password:password
                                                              bearerToken:token
                                                                userAgent:@"agent"];
    XCTAssertEqualObjects(request.URL, loginURL);
    XCTAssertNotNil(request.HTTPBody);
    NSString *body = [[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding];
    XCTAssertNotEqual([body rangeOfString:password].location, NSNotFound, @"password should in the request body");
    NSString *authorization = [request valueForHTTPHeaderField:@"Authorization"];
    XCTAssertNil(authorization);
}

@end
