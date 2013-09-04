/*
 * MediaSearchFilterHeaderView.h
 *
 * Copyright (c) 2013 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import <UIKit/UIKit.h>

@class MediaBrowserViewController;

@protocol MediaSearchFilterDelegate <NSObject>

/// Provide an array of nice strings. First is considered the default
- (NSArray*)mediaSortingOptions;
- (NSArray*)dateSortingOptions;

/// Index of mediaSortingOptions
- (void)selectedMediaSortIndex:(NSUInteger)filterIndex;

/// Index of dateSortingOptions
- (void)selectedDateSortIndex:(NSUInteger)filterIndex;

/// Update the filter for search
- (void)applyFilterWithSearchText:(NSString*)searchText;
- (void)clearSearchFilter;

@end

@interface MediaSearchFilterHeaderView : UICollectionReusableView

@property (nonatomic, weak) MediaBrowserViewController *delegate;

- (void)resetSearch;


@end
