/*
 * MediaSearchFilterHeaderView.m
 *
 * Copyright (c) 2013 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import "MediaSearchFilterHeaderView.h"
#import "MediaBrowserViewController.h"
#import "WPStyleGuide.h"
#import "DateRangePickerView.h"
#import "InputViewButton.h"


static CGFloat const DateButtonWidth = 44.0f;

@interface MediaSearchFilterHeaderView () <UISearchBarDelegate>

@property (nonatomic, weak) UISearchBar *searchBar;
@property (nonatomic, weak) UIButton *filterDatesButton;
@property (nonatomic, weak) DateRangePickerView *dateRangePickerView;
@property (nonatomic, assign) BOOL isDisplayingDatePicker;

@end

@implementation MediaSearchFilterHeaderView

- (void)setDelegate:(MediaBrowserViewController *)delegate {
    _delegate = delegate;
    
    [_delegate.collectionView addSubview:self.searchBar];
    [_delegate.collectionView addSubview:self.filterDatesButton];
    [_delegate.collectionView addSubview:self.dateRangePickerView];
    
}

- (UIButton *)filterDatesButton {
    UIButton *sort = [UIButton buttonWithType:UIButtonTypeCustom];
    [sort setBackgroundColor:[WPStyleGuide allTAllShadeGrey]];
    [sort setImage:[UIImage imageNamed:@"date_picker_unselected"] forState:UIControlStateNormal];
    
    _filterDatesButton = sort;
    _filterDatesButton.frame = CGRectMake(_searchBar.frame.size.width, 0, DateButtonWidth, 44.0f);
    [_filterDatesButton addTarget:self action:@selector(filterDatesPressed) forControlEvents:UIControlEventTouchUpInside];
    [_filterDatesButton setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin];
    return _filterDatesButton;
}

- (UISearchBar *)searchBar {
    UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width - DateButtonWidth, 44.0f)];
    _searchBar = searchBar;
    _searchBar.backgroundColor = [WPStyleGuide readGrey];
    _searchBar.placeholder = NSLocalizedString(@"Search", @"");
    _searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _searchBar.delegate = self;
    [_searchBar setTintColor:[WPStyleGuide readGrey]];
    _searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
    return _searchBar;
}

- (DateRangePickerView *)dateRangePickerView {
    DateRangePickerView *dateRangePickerView = [[DateRangePickerView alloc] initWithFrame:CGRectMake(0, 44.0f, self.bounds.size.width, 44.0f)];
    [dateRangePickerView setAlpha:0];
    dateRangePickerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [dateRangePickerView setDateRangeMin:[_delegate mediaDateRangeStart] andMax:[_delegate mediaDateRangeEnd]];
    _dateRangePickerView = dateRangePickerView;
    return _dateRangePickerView;
}

- (void)filterDatesPressed {
    [_dateRangePickerView setDateRangeMin:[_delegate mediaDateRangeStart] andMax:[_delegate mediaDateRangeEnd]];
    if (!_isDisplayingDatePicker) {
        [UIView animateWithDuration:0.3f animations:^{
            [_filterDatesButton setImage:[UIImage imageNamed:@"date_picker_selected"] forState:UIControlStateNormal];
            _dateRangePickerView.alpha = 1;
        } completion:^(BOOL finished) {
            _isDisplayingDatePicker = YES;
        }];
    }
    else {
        [UIView animateWithDuration:0.3f animations:^{
            _dateRangePickerView.alpha = 0;
            [_filterDatesButton setImage:[UIImage imageNamed:@"date_picker_unselected"] forState:UIControlStateNormal];
            [_dateRangePickerView.startDate resignFirstResponder];
            [_dateRangePickerView.endDate resignFirstResponder];
        } completion:^(BOOL finished) {
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.dateFormat = @"yyyy-MM-dd";
            [_delegate applyDateFilterForStartDate: [formatter dateFromString:_dateRangePickerView.startDate.titleLabel.text]  andEndDate:[formatter dateFromString:_dateRangePickerView.endDate.titleLabel.text]];
            _isDisplayingDatePicker = NO;
        }];
    }
}

#pragma mark - UISearchBarDelegate

- (void)resetSearch {
    [self searchBarCancelButtonClicked:_searchBar];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [searchBar setShowsCancelButton:YES animated:YES];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    if (!searchBar.text || [searchBar.text isEqualToString:@""]) {
        [searchBar setShowsCancelButton:NO animated:YES];
        [_delegate clearSearchFilter];
    }
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [_delegate clearSearchFilter];
    searchBar.text = @"";
    [searchBar setShowsCancelButton:NO animated:YES];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [_delegate applyFilterWithSearchText:searchBar.text];
    [self reenableCancelButton:searchBar];
}

- (void)reenableCancelButton:(UISearchBar *)searchBar {
    for (UIView *v in searchBar.subviews) {
        for (id subview in v.subviews) {
            if ([subview isKindOfClass:[UIButton class]]) {
                [subview setEnabled:YES];
                return;
            }
        }
    }
}

@end
