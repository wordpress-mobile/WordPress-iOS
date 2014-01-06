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
#import "InputViewButton.h"

static CGFloat const DateButtonWidth = 44.0f;

@interface MediaSearchFilterHeaderView () <UISearchBarDelegate, UIPickerViewDataSource, UIPickerViewDelegate, UIPickerViewAccessibilityDelegate>

@property (nonatomic, weak) UISearchBar *searchBar;
@property (nonatomic, weak) UIButton *filterDatesButton;
@property (nonatomic, weak) UIPickerView *monthPickerView;

@end

@implementation MediaSearchFilterHeaderView

- (void)setDelegate:(MediaBrowserViewController *)delegate {
    _delegate = delegate;
    [_delegate.collectionView addSubview:self.searchBar];
    [_delegate.collectionView addSubview:self.filterDatesButton];
}

- (UIButton *)filterDatesButton {
    UIButton *filterDate = [UIButton buttonWithType:UIButtonTypeCustom];
    [filterDate setBackgroundColor:[WPStyleGuide allTAllShadeGrey]];
    [filterDate setImage:[UIImage imageNamed:@"date_picker_unselected"] forState:UIControlStateNormal];
    
    _filterDatesButton = filterDate;
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

- (void)filterDatesPressed {
    CGFloat pickerViewHeight = 216.0f;
    if (_monthPickerView) {
        [UIView animateWithDuration:0.4 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            _monthPickerView.frame = (CGRect) {
                .origin = CGPointMake(0, self.delegate.collectionView.frame.size.height + pickerViewHeight),
                .size = _monthPickerView.frame.size
            };
        } completion:^(BOOL finished) {
            [_monthPickerView removeFromSuperview];
        }];
        return;
    }
    
    UIPickerView *pickerView = [[UIPickerView alloc] initWithFrame:CGRectMake(0, self.delegate.collectionView.frame.size.height + pickerViewHeight, self.frame.size.width, pickerViewHeight)];
    pickerView.delegate = self;
    pickerView.dataSource = self;
    pickerView.showsSelectionIndicator = YES;
    pickerView.backgroundColor = [WPStyleGuide itsEverywhereGrey];
    _monthPickerView = pickerView;
    [self.delegate.collectionView addSubview:_monthPickerView];
    
    [UIView animateWithDuration:0.4 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        _monthPickerView.frame = (CGRect) {
            .origin = CGPointMake(0, self.delegate.view.frame.size.height - pickerViewHeight),
            .size = _monthPickerView.frame.size
        };
    } completion:nil];
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


#pragma mark - UIPickerView delegate

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return [self.delegate possibleMonthsAndYears].count + 1;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    if (row == 0) {
        return NSLocalizedString(@"All Media Items", nil);
    }
    return [self.delegate possibleMonthsAndYears][row-1];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if (row == 0) {
        [self.delegate clearMonthFilter];
        return;
    }
    [self.delegate selectedMonthPickerIndex:row-1];
}

- (NSString *)pickerView:(UIPickerView *)pickerView accessibilityLabelForComponent:(NSInteger)component {
    return NSLocalizedString(@"Month and year to filter media items by", @"Accessibility label for filtering media by month");
}

- (NSString *)pickerView:(UIPickerView *)pickerView accessibilityHintForComponent:(NSInteger)component {
    return NSLocalizedString(@"Selecting an option shows media items only from that month and year.", @"Accessibility hint for filtering media by month");
}

@end
