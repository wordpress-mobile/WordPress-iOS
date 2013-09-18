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

/// Update the filter for search
- (void)applyFilterWithSearchText:(NSString*)searchText;
- (void)applyDateFilterForStartDate:(NSDate *)start andEndDate:(NSDate *)end;
- (void)clearSearchFilter;
- (NSDate *)mediaDateRangeStart;
- (NSDate *)mediaDateRangeEnd;

@end

@interface MediaSearchFilterHeaderView : UICollectionReusableView

@property (nonatomic, weak) MediaBrowserViewController *delegate;

- (void)resetSearch;


@end
