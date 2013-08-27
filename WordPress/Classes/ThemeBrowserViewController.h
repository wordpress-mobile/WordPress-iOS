/*
 * ThemeBrowserViewController.h
 *
 * Copyright (c) 2013 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import "ThemeSearchFilterHeaderView.h"

@class Blog;

@interface ThemeBrowserViewController : UIViewController <ThemeSearchFilterDelegate, UISearchBarDelegate>

@property (nonatomic, strong) Blog *blog;

@end
