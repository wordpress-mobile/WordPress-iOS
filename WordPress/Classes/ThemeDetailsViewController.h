/*
 * ThemeDetailsViewController.h
 *
 * Copyright (c) 2013 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import <UIKit/UIKit.h>

@class Theme;

@interface ThemeDetailsViewController : UIViewController

- (id)initWithTheme:(Theme*)theme;

@end
