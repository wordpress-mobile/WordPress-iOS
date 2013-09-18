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

static CGFloat const DateButtonWidth = 130.0f;

@interface MediaSearchFilterHeaderView () <UISearchBarDelegate>

@property (nonatomic, weak) UISearchBar *searchBar;
@property (nonatomic, weak) UIButton *filterDatesButton;

@end

@implementation MediaSearchFilterHeaderView

- (void)setDelegate:(MediaBrowserViewController *)delegate {
    _delegate = delegate;
    
    [_delegate.collectionView addSubview:self.searchBar];
    [_delegate.collectionView addSubview:self.filterDatesButton];
    
}

- (UIButton *)filterDatesButton {
    UIButton *sort = [UIButton buttonWithType:UIButtonTypeCustom];
    [sort setBackgroundColor:[WPStyleGuide allTAllShadeGrey]];
    [sort setTitle:NSLocalizedString(@"All Dates", @"") forState:UIControlStateNormal];
    sort.titleLabel.font = [WPStyleGuide regularTextFont];

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

//- (UIDatePicker *)datePicker {
//    UIDatePicker *datePicker = [[UIDatePicker alloc] init];
//    _datePicker = datePicker;
//    [_datePicker setDatePickerMode:UIDatePickerModeDate];
//    [_datePicker setDate:[NSDate date]];
//    [_datePicker setCalendar:nil];
//    
//    
//    return _datePicker;
//}

- (void)filterDatesPressed {
    //Bring up some custom date picker view
    
}

#pragma mark - UISearchBarDelegate

- (void)resetSearch {
    [self searchBarCancelButtonClicked:_searchBar];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if ([searchText isEqualToString:@""]) {
        [self searchBarCancelButtonClicked:searchBar];
    }
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
