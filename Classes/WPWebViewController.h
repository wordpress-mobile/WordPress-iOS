//
//  WPWebViewController.h
//  WordPress
//
//  Created by Jorge Bernal on 6/16/11.
//  Copyright 2011 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WPWebViewController : UIViewController<UIWebViewDelegate, UIActionSheetDelegate, MFMailComposeViewControllerDelegate> {
    BOOL isLoading;
    IBOutlet UIWebView *webView;
    // This timer checks the nav buttons every 0.5 seconds, and updates them
	NSTimer *statusTimer;
}
@property (nonatomic,retain) NSURL *url;
@property (nonatomic,retain) NSString *username;
@property (nonatomic,retain) NSString *password;
@property (nonatomic,retain) IBOutlet UIWebView *webView;
@property (nonatomic,retain) IBOutlet UIToolbar *toolbar;
@property (nonatomic,retain) IBOutlet UIView *loadingView;
@property (nonatomic,retain) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic,retain) IBOutlet UILabel *loadingLabel;
@property (nonatomic,assign) BOOL needsLogin;
@property (nonatomic,assign) BOOL isReader;
@property (nonatomic, retain) IBOutlet UINavigationBar *iPadNavBar;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *backButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *forwardButton;
@property (retain, nonatomic) NSTimer *statusTimer;

- (IBAction)showLinkOptions;
- (IBAction)dismiss;
- (IBAction)goForward;
- (IBAction)goBack;
- (NSString*) getDocumentPermalink;
- (NSString*) getDocumentTitle;
- (void)setNavButtonsStatus:(NSTimer*)timer;
- (BOOL) setMFMailFieldAsFirstResponder:(UIView*)view mfMailField:(NSString*)field;

@end
