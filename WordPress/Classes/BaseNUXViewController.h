//
//  BaseNUXViewController.h
//  WordPress
//
//  Created by Sendhil Panchadsaram on 7/30/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BaseNUXViewController : UIViewController

- (UIView *)topViewToCenterAgainst;
- (UIView *)bottomViewToCenterAgainst;
- (CGFloat)heightToUseForCentering;
- (NSLayoutConstraint *)verticalCenteringConstraint;

@end
