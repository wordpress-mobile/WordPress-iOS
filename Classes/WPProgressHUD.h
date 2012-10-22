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

    WordPressAppDelegate *__weak appDelegate;
}

@property (nonatomic) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) UILabel *progressMessage;
@property (nonatomic) UIImageView *backgroundImageView;
@property (nonatomic, weak) WordPressAppDelegate *appDelegate;

- (id)initWithLabel:(NSString *)text;
- (void)dismiss;

@end
