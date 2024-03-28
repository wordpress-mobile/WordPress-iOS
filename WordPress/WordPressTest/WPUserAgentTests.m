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

- (NSString *)currentUserAgentFromWebView
{
    return [WKWebView userAgent];
}

- (void)testWordPressUserAgent
{
    NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *defaultUserAgent = [WPUserAgent defaultUserAgent];
    NSString *expectedUserAgent = [NSString stringWithFormat:@"%@ wp-iphone/%@", defaultUserAgent, appVersion];

    XCTAssertEqualObjects([WPUserAgent wordPressUserAgent], expectedUserAgent);
}

- (NSRegularExpression *)webkitUserAgentRegex
{
    NSError *error = nil;
    NSRegularExpression *regex = [[NSRegularExpression alloc] initWithPattern:@"^Mozilla/5\\.0 \\([a-zA-Z]+; CPU [\\sa-zA-Z]+ [_0-9]+ like Mac OS X\\) AppleWebKit/605\\.1\\.15 \\(KHTML, like Gecko\\) Mobile/15E148$" options:0 error:&error];
    XCTAssertNil(error);
    return regex;
}

- (void)testUserAgentFormat
{
    NSRegularExpression *regex = [self webkitUserAgentRegex];
    NSString *userAgent = [WPUserAgent webViewUserAgent];
    XCTAssertEqual([regex numberOfMatchesInString:userAgent options:0 range:NSMakeRange(0, userAgent.length)], 1);
}

// If this test fails, it may mean `WKWebView` uses a user agent with an unexpected format (see `webkitUserAgentRegex`)
// and we may need to adjust `UserAgent.webkitUserAgent`'s implementation to match `WKWebView`'s user agent.
- (void)testWKWebViewUserAgentFormat
{
    NSRegularExpression *regex = [self webkitUserAgentRegex];
    // Please note: WKWebView's user agent may be different on different test device types.
    NSString *userAgent = [self currentUserAgentFromWebView];
    XCTAssertEqual([regex numberOfMatchesInString:userAgent options:0 range:NSMakeRange(0, userAgent.length)], 1);
}

- (void)testUseWordPressUserAgentInWebViews
{
    NSString *defaultUA = [WPUserAgent defaultUserAgent];
    NSString *wordPressUA = [WPUserAgent wordPressUserAgent];

    [[NSUserDefaults standardUserDefaults] removeObjectForKey:WPUserAgentKeyUserAgent];
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{WPUserAgentKeyUserAgent: defaultUA}];

    XCTAssertEqualObjects([self currentUserAgentFromUserDefaults], defaultUA);
    XCTAssertEqualObjects([self currentUserAgentFromWebView], defaultUA);

    if (@available(iOS 17, *)) {
        XCTSkip("In iOS 17, WKWebView no longer reads User Agent from UserDefaults. Skipping while working on an alternative setup.");
    }

    [WPUserAgent useWordPressUserAgentInWebViews];
    XCTAssertEqualObjects([self currentUserAgentFromUserDefaults], wordPressUA);
    XCTAssertEqualObjects([self currentUserAgentFromWebView], wordPressUA);
}

- (void)testThatOriginalRemovalOfWPUseKeyUserAgentDoesntWork {
    if (@available(iOS 17, *)) {
        XCTSkip("In iOS 17, WKWebView no longer reads User Agent from UserDefaults. Skipping while working on an alternative setup.");
    }

    // get the original user agent
    NSString *originalUserAgentInWebView = [self currentUserAgentFromWebView];
    NSLog(@"OriginalUserAgent (WebView): %@", originalUserAgentInWebView);
    
    // set a new one
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{WPUserAgentKeyUserAgent: @"new user agent"}];
    
    NSString *changedUserAgentInWebView = [self currentUserAgentFromWebView];
    NSLog(@"changedUserAgent (WebView): %@", changedUserAgentInWebView);

    // try to remove it using old method
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{}];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:WPUserAgentKeyUserAgent];
    
    NSString *shouldBeOriginalInWebView = [self currentUserAgentFromWebView];
    NSLog(@"shouldBeOriginal (WebView): %@", shouldBeOriginalInWebView);
    
    XCTAssertNotEqualObjects(originalUserAgentInWebView, shouldBeOriginalInWebView);
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
