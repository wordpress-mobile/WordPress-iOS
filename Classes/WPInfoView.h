//
//  WPInfoView.h
//  WordPress
//
//  Created by Eric Johnson on 8/30/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WPInfoView : UIView 

@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UILabel *messageLabel;
@property (nonatomic, strong) IBOutlet UIButton *cancelButton; 

+ (WPInfoView *)WPInfoViewWithTitle:(NSString *)titleText message:(NSString *)messageText cancelButton:(NSString *)cancelText;

- (IBAction)handleCancelButtonTapped:(id)sender;
- (void)setTitle:(NSString *)titleText message:(NSString *)messageText cancelButton:(NSString *)cancelText;
- (void)showInView:(UIView *)view;

@end
