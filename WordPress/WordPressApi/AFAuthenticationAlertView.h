//
//  AFAuthenticationAlertView.h
//  WordPress
//
//  Created by Jorge Bernal on 3/15/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AFHTTPRequestOperation.h"

@interface AFAuthenticationAlertView : UIAlertView
- (id)initWithChallenge:(NSURLAuthenticationChallenge *)challenge;
@end
