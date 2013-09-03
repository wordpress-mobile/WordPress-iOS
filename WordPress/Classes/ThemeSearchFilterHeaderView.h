/*
 * ThemeSearchFilterHeaderView.h
 *
 * Copyright (c) 2013 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import <UIKit/UIKit.h>

@class ThemeBrowserViewController;

@protocol ThemeSearchFilterDelegate <NSObject>

/// Provide an array of nice strings. First is considered the default
- (NSArray*)themeSortingOptions;

/// Index of themeFilterOptions
- (void)selectedSortIndex:(NSUInteger)filterIndex;

/// Update the filter for search
- (void)applyFilterWithSearchText:(NSString*)searchText;
- (void)clearSearchFilter;

@end

@interface ThemeSearchFilterHeaderView : UICollectionReusableView

@property (nonatomic, weak) ThemeBrowserViewController *delegate;

- (void)resetSearch;

@end
