//
//  WebSignupViewController.h
//  WordPress
//
//  Created by Dan Roundhill on 5/6/10.
//  
//

#import <UIKit/UIKit.h>
#import "WordPressAppDelegate.h"

@interface WebSignupViewController : UIViewController <UIWebViewDelegate>{
	IBOutlet UIWebView *webView;
	UIActivityIndicatorView *spinner;
}

@property (nonatomic, retain) UIWebView *webView;
@property (nonatomic, retain) UIActivityIndicatorView *spinner;

@end
