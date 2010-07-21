//
//  WPProgressHUD.h
//  WordPress
//
//  Created by Gareth Townsend on 9/07/09.
//

#import <UIKit/UIKit.h>
#import "WordPressAppDelegate.h"

@interface WPProgressHUD : UIAlertView {
    UIActivityIndicatorView *activityIndicator;
    UILabel *progressMessage;
	UIImageView *backgroundImageView;

    WordPressAppDelegate *appDelegate;
}

@property (nonatomic, assign) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, retain) UILabel *progressMessage;
@property (nonatomic, assign) UIImageView *backgroundImageView;
@property (nonatomic, assign) WordPressAppDelegate *appDelegate;

- (id)initWithLabel:(NSString *)text;
- (void)dismiss;

@end
