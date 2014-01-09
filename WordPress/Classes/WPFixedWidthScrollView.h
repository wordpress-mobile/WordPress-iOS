//
//  WPPaddedScrollView.h
//  WordPress
//
//  Created by Tom Witkin on 12/20/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WPFixedWidthScrollView : UIScrollView

- (instancetype)initWithRootView:(UIView *)view;

@property (nonatomic, strong) UIView *rootView;
@property (nonatomic) CGFloat contentWidth;

@end
