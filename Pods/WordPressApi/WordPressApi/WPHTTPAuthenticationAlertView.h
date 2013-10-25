//
//  WPHTTPAuthenticationAlertView.h
//  WordPress
//
//  Created by Jorge Bernal on 3/15/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WPHTTPAuthenticationAlertView : NSObject <UIAlertViewDelegate>

- (id)initWithChallenge:(NSURLAuthenticationChallenge *)challenge;

- (void)show;

@end
