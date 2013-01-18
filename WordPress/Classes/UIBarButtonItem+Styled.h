//
//  UIBarButtonItem+Styled.h
//  WordPress
//
//  Created by Jorge Bernal on 7/12/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIBarButtonItem (Styled)

+ (void)styleButtonAsPrimary:(UIBarButtonItem *)buttonItem;
+ (void)restoreDefaultButtonStyle:(UIBarButtonItem *)buttonItem;

@end
