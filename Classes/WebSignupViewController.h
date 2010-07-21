//
//  WebSignupViewController.h
//  WordPress
//
//  Created by Dan Roundhill on 5/6/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface WebSignupViewController : UIViewController <UIWebViewDelegate>{
	IBOutlet UIWebView *webView;
	UIActivityIndicatorView *spinner;
}

@property (nonatomic, retain) UIWebView *webView;
@property (nonatomic, retain) UIActivityIndicatorView *spinner;

@end
