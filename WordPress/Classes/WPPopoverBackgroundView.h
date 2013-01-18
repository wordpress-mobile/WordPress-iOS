//
//  WPPopoverBackgroundView.h
//  WordPress
//
//  Created by Eric Johnson on 7/16/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <UIKit/UIPopoverBackgroundView.h>

@interface WPPopoverBackgroundView : UIPopoverBackgroundView {
    UIPopoverArrowDirection arrowDirection;
    CGFloat arrowOffset;
    UIImageView *borderImageView;
    UIImageView *arrowImageView;
}

@property (nonatomic, readwrite) UIPopoverArrowDirection arrowDirection;
@property (nonatomic, readwrite) CGFloat arrowOffset;
@property (nonatomic, strong) UIImageView *borderImageView;
@property (nonatomic, strong) UIImageView *arrowImageView;

@end
