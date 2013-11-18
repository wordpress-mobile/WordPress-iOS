//
//  WPTableViewSectionHeaderView.h
//  WordPress
//
//  Created by Sendhil Panchadsaram on 9/5/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WPTableViewSectionHeaderView : UIView

@property (nonatomic, strong) NSString *title;
@property (nonatomic, assign) CGFloat leftMarginPercent;

+ (CGFloat)heightForTitle:(NSString *)title andWidth:(CGFloat)width;

@end
