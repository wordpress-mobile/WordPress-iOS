//
//  WPInfoView.h
//  WordPress
//
//  Created by Eric Johnson on 8/30/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WPNoResultsView : UIView

+ (WPNoResultsView *)noResultsViewWithTitle:(NSString *)titleText message:(NSString *)messageText accessoryView:(UIView *)accessoryView;

- (void)setupWithTitle:(NSString *)titleText message:(NSString *)messageText accessoryView:(UIView *)accessoryView;
- (void)showInView:(UIView *)view;
- (void)centerInSuperview;

- (void)setTitleText:(NSString *)title;
- (void)setMessageText:(NSString *)message;

@end
