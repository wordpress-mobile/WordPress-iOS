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
	UIBarButtonItem *cancelBtn;
	IBOutlet UIActivityIndicatorView *activityIndicator;
	
}

@property (nonatomic, retain) UIWebView *webView;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *cancelBtn;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *activityIndicator;

-(IBAction)cancel:(id) sender;

@end
