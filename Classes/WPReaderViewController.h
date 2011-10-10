//
//  WPReaderViewController.h
//  WordPress
//
//  Created by Danilo Ercoli on 10/10/11.
//  Copyright 2011 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WPReaderViewController : UIViewController<UIWebViewDelegate, UIActionSheetDelegate, MFMailComposeViewControllerDelegate> {
    BOOL isLoading, needsLogin;
    IBOutlet UIWebView *webView;
    NSTimer *statusTimer;   // This timer checks the nav buttons every 0.75 seconds, and updates them
    NSTimer *refreshTimer; 
    NSDate  *lastWebViewRefreshDate; //used to keep track of the latest refresh datetime. 
}
@property (nonatomic,retain) NSURL *url;
@property (nonatomic,retain) NSString *username;
@property (nonatomic,retain) NSString *password;
@property (nonatomic,retain) NSString *detailContentHTML;
@property (nonatomic,retain) IBOutlet UIWebView *webView;
@property (nonatomic,retain) IBOutlet UIToolbar *toolbar;
@property (nonatomic,retain) IBOutlet UIView *loadingView;
@property (nonatomic,retain) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic,retain) IBOutlet UILabel *loadingLabel;
@property (nonatomic, retain) IBOutlet UINavigationBar *iPadNavBar;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *backButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *forwardButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *optionsButton;
@property (retain, nonatomic) NSTimer *statusTimer;
@property (retain, nonatomic) NSTimer *refreshTimer;
@property (retain, nonatomic) NSDate *lastWebViewRefreshDate;

- (IBAction) showLinkOptions;
- (IBAction) dismiss;
- (IBAction) goForward;
- (IBAction) goBack;    
@end
