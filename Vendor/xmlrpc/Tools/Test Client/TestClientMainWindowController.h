#import <Cocoa/Cocoa.h>

@interface TestClientMainWindowController : NSWindowController<XMLRPCConnectionDelegate> {
    XMLRPCResponse *myResponse;
    IBOutlet NSTextField *myRequestURL;
	IBOutlet NSTextField *myMethod;
    IBOutlet NSTextField *myParameter;
	IBOutlet NSProgressIndicator *myProgressIndicator;
    IBOutlet NSTextField *myActiveConnection;
    IBOutlet NSButton *mySendRequest;
    IBOutlet NSTextView *myRequestBody;
    IBOutlet NSTextView *myResponseBody;
    IBOutlet NSOutlineView *myParsedResponse;
}

+ (TestClientMainWindowController *)sharedController;

#pragma mark -

- (void)showTestClientWindow: (id)sender;

- (void)hideTestClientWindow: (id)sender;

#pragma mark -

- (void)toggleTestClientWindow: (id)sender;

#pragma mark -

- (void)sendRequest: (id)sender;

@end

#pragma mark -

@interface TestClientMainWindowController (XMLRPCConnectionDelegate)

- (void)request: (XMLRPCRequest *)request didReceiveResponse: (XMLRPCResponse *)response;

- (void)request: (XMLRPCRequest *)request didFailWithError: (NSError *)error;

- (void)request: (XMLRPCRequest *)request didReceiveAuthenticationChallenge: (NSURLAuthenticationChallenge *)challenge;

- (void)request: (XMLRPCRequest *)request didCancelAuthenticationChallenge: (NSURLAuthenticationChallenge *)challenge;

- (BOOL)request: (XMLRPCRequest *)request canAuthenticateAgainstProtectionSpace: (NSURLProtectionSpace *)protectionSpace;

@end
