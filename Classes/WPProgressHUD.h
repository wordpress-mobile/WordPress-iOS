//
//  WPProgressHUD.h
//  WordPress
//
//  Created by Gareth Townsend on 9/07/09.
//  Copyright 2009 Clear Interactive. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WordPressAppDelegate.h"

@interface WPProgressHUD : UIAlertView {
    UIImage *backgroundImage;
    UIActivityIndicatorView *activityIndicator;
    UILabel *progressMessage;

    WordPressAppDelegate *appDelegate;
}

@property (nonatomic, assign) UIImage *backgroundImage;
@property (nonatomic, assign) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, retain) UILabel *progressMessage;
@property (nonatomic, assign) WordPressAppDelegate *appDelegate;

- (id)initWithLabel:(NSString *)text;

@end
