//
//  WebSignupViewController.h
//  WordPress
//
//  Created by Dan Roundhill on 5/6/10.
//  
//

#import <UIKit/UIKit.h>
#import "WordPressAppDelegate.h"

@interface WebSignupViewController : UIViewController <UIWebViewDelegate, UIAlertViewDelegate>{
	IBOutlet UIWebView *webView;
	UIActivityIndicatorView *spinner;
}

@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;

@end
