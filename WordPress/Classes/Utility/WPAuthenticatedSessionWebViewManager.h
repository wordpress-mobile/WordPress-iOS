#import <Foundation/Foundation.h>

@protocol WPAuthenticatedSessionWebViewManagerDelegate <NSObject>

- (NSString *)username;
- (NSString *)password;
- (NSURL *)destinationURL;
- (NSURL *)loginURL;

@end

// Manages authenticated web sessions for UIWebViews. This implements parts of the UIWebViewDelegate,
// and will vend the correct URL Requests to use for the authenticated session.
//
// To implement, use the URLRequest provided by this class whenever you want to direct a UIWebView
// to an authenticated destination.
//
// You must also assign or integrate this object into the UIWebViewDelegate chain for the UIWebView.
//
// NOTE: This object may redirect the UIWebView, if necessary.

@interface WPAuthenticatedSessionWebViewManager : NSObject <UIWebViewDelegate>

- (instancetype)initWithDelegate:(id<WPAuthenticatedSessionWebViewManagerDelegate>)delegate; // designated initializer

- (NSURLRequest *)URLRequestForAuthenticatedSession;

@end
