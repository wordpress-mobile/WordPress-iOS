//
//  CNewBlogSignupViewController.h
//  WordPress
//
//  Created by Jonathan Wight on 03/09/10.
//  Copyright 2010 toxicsoftware.com. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface CNewBlogSignupViewController : UIViewController <UIWebViewDelegate> {
	UIWebView *webView;
}

@property (readwrite, nonatomic, retain) IBOutlet UIWebView *webView;

@end
