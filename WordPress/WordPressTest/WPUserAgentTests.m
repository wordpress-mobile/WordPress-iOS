#import <XCTest/XCTest.h>

#import "WPUserAgent.h"
@import WebKit;

static NSString* const WPUserAgentKeyUserAgent = @"UserAgent";

@interface WPUserAgentTests : XCTestCase
@end

@implementation WPUserAgentTests

- (NSString *)currentUserAgentFromUserDefaults
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:WPUserAgentKeyUserAgent];
}

- (NSString *)currentUserAgentFromUIWebView
{
    return [[[UIWebView alloc] init] stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];
}

- (NSString *)currentUserAgentFromWKWebView
{
    return [[WKWebView new] stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];
}

- (void)testWordPressUserAgent
{
    NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *defaultUserAgent = [WPUserAgent defaultUserAgent];
    NSString *expectedUserAgent = [NSString stringWithFormat:@"%@ wp-iphone/%@", defaultUserAgent, appVersion];

    XCTAssertEqualObjects([WPUserAgent wordPressUserAgent], expectedUserAgent);
}

- (void)testUseWordPressUserAgentInWebViews
{
    NSString *defaultUA = [WPUserAgent defaultUserAgent];
    NSString *wordPressUA = [WPUserAgent wordPressUserAgent];

    [[NSUserDefaults standardUserDefaults] removeObjectForKey:WPUserAgentKeyUserAgent];
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{WPUserAgentKeyUserAgent: defaultUA}];

    XCTAssertEqualObjects([self currentUserAgentFromUserDefaults], defaultUA);
    XCTAssertEqualObjects([self currentUserAgentFromUIWebView], defaultUA);
    XCTAssertEqualObjects([self currentUserAgentFromWKWebView], defaultUA);

    [WPUserAgent useWordPressUserAgentInWebViews];
    
    XCTAssertEqualObjects([self currentUserAgentFromUserDefaults], wordPressUA);
    XCTAssertEqualObjects([self currentUserAgentFromUIWebView], wordPressUA);
    XCTAssertEqualObjects([self currentUserAgentFromWKWebView], wordPressUA);
}

- (void)testThatOriginalRemovalOfWPUseKeyUserAgentDoesntWork {
    // get the original user agent
    NSString *originalUserAgentInUIWebView = [self currentUserAgentFromUIWebView];
    NSLog(@"OriginalUserAgent (UIWebView): %@", originalUserAgentInUIWebView);
    
    NSString *originalUserAgentInWKWebView = [self currentUserAgentFromWKWebView];
    NSLog(@"OriginalUserAgent (WKWebView): %@", originalUserAgentInWKWebView);
    
    // set a new one
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{WPUserAgentKeyUserAgent: @"new user agent"}];
    
    NSString *changedUserAgentInUIWebView = [self currentUserAgentFromUIWebView];
    NSLog(@"changedUserAgent (UIWebView): %@", changedUserAgentInUIWebView);
    
    NSString *changedUserAgentInWKWebView = [self currentUserAgentFromWKWebView];
    NSLog(@"changedUserAgent (WKWebView): %@", changedUserAgentInWKWebView);

    // try to remove it using old method
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{}];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:WPUserAgentKeyUserAgent];
    
    NSString *shouldBeOriginalInUIWebView = [self currentUserAgentFromUIWebView];
    NSLog(@"shouldBeOriginal (UIWebView): %@", shouldBeOriginalInUIWebView);
    
    XCTAssertNotEqualObjects(originalUserAgentInUIWebView, shouldBeOriginalInUIWebView, "This agent should be the same");
    
    NSString *shouldBeOriginalInWKWebView = [self currentUserAgentFromWKWebView];
    NSLog(@"shouldBeOriginal (WKWebView): %@", shouldBeOriginalInWKWebView);
    
    XCTAssertNotEqualObjects(originalUserAgentInWKWebView, shouldBeOriginalInWKWebView, "This agent should be the same");
}

- (void)testThatCallingFromAnotherThreadWorks {
    // get the original user agent
    dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        XCTAssertNoThrow([WPUserAgent wordPressUserAgent], @"Being called from out of main thread should work");
    });
}

- (void)testThatRegistarDefaultJustAdds {
    NSDictionary * registrationDomain = [[NSUserDefaults standardUserDefaults] volatileDomainForName:NSRegistrationDomain];
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{WPUserAgentKeyUserAgent: @(0)}];
    NSDictionary * changedRegistrationDomain = [[NSUserDefaults standardUserDefaults] volatileDomainForName:NSRegistrationDomain];

    XCTAssertTrue((registrationDomain.count == changedRegistrationDomain.count) || ((registrationDomain.count +1) == changedRegistrationDomain.count), "It should add or reset");
}


@end
