//
//  WPWebViewController.h
//  WordPress
//
//  Created by Jorge Bernal on 6/16/11.
//  Copyright 2011 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MFMailComposeViewController.h>
#import "WPWebAppViewController.h"

@interface WPWebViewController : UIViewController <UIWebViewDelegate, UIActionSheetDelegate, MFMailComposeViewControllerDelegate> {
    BOOL isLoading, needsLogin, hasLoadedContent;
    UIWebView *webView;
	NSTimer *statusTimer;   // This timer checks the nav buttons every 0.75 seconds, and updates them
}
@property (nonatomic,retain) NSURL *url;
@property (nonatomic,retain) NSURL *wpLoginURL;
@property (nonatomic,retain) NSString *username;
@property (nonatomic,retain) NSString *password;
@property (nonatomic,retain) IBOutlet UIWebView *webView;
@property (nonatomic,retain) IBOutlet UIToolbar *toolbar;
@property (nonatomic,retain) IBOutlet UIView *loadingView;
@property (nonatomic,retain) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic,retain) IBOutlet UILabel *loadingLabel;
@property (nonatomic, retain) IBOutlet UINavigationBar *iPadNavBar;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *backButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *forwardButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *refreshButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *optionsButton;
@property (retain, nonatomic) NSTimer *statusTimer;

//reader variables
@property (nonatomic,retain) NSString *detailContent;
@property (nonatomic,retain) NSString *detailHTML;
@property (nonatomic,retain) NSString *readerAllItems;

- (IBAction) showLinkOptions;
- (IBAction) dismiss;
- (IBAction) goForward;
- (IBAction) goBack;
- (IBAction) reload;
@end
