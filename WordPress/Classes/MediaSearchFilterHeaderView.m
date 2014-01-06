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

@interface MediaSearchFilterHeaderView () <UISearchBarDelegate, UIPickerViewDataSource, UIPickerViewDelegate, UIPickerViewAccessibilityDelegate,
                                            UIPopoverControllerDelegate>

@property (nonatomic, weak) UISearchBar *searchBar;
@property (nonatomic, weak) UIButton *filterDatesButton;
@property (nonatomic, weak) UIPickerView *monthPickerView;
@property (nonatomic, assign) NSUInteger lastSelectedMonthFilter;
@property (nonatomic, strong) UIPopoverController *popover;

@end

@implementation MediaSearchFilterHeaderView

- (void)awakeFromNib {
    _lastSelectedMonthFilter = 0;
}

- (void)layoutSubviews {
    if (_popover) {
        // Re-present for rotation changes
        [_popover presentPopoverFromRect:_filterDatesButton.frame inView:self permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
}

- (void)setDelegate:(MediaBrowserViewController *)delegate {
    _delegate = delegate;
    [_delegate.collectionView addSubview:self.searchBar];
    [_delegate.collectionView addSubview:self.filterDatesButton];
}

- (UIButton *)filterDatesButton {
    UIButton *filterDate = [UIButton buttonWithType:UIButtonTypeCustom];
    _filterDatesButton = filterDate;
    [_filterDatesButton setBackgroundColor:[WPStyleGuide allTAllShadeGrey]];
    [_filterDatesButton setImage:[UIImage imageNamed:@"date_picker_unselected"] forState:UIControlStateNormal];
    _filterDatesButton.frame = CGRectMake(_searchBar.frame.size.width, 0, DateButtonWidth, 44.0f);
    [_filterDatesButton addTarget:self action:@selector(filterDatesPressed) forControlEvents:UIControlEventTouchUpInside];
    [_filterDatesButton setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin];
    _filterDatesButton.accessibilityHint = NSLocalizedString(@"Filters items by month and year with a picker", @"Accessibility hint for month filter button in media browser");
    _filterDatesButton.accessibilityLabel = NSLocalizedString(@"Filter by month", @"Accessibility label for month filter button in media browser");
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
    if (_monthPickerView || _popover) {
        if (IS_IPAD) {
            [_popover dismissPopoverAnimated:YES];
            [_monthPickerView removeFromSuperview];
            _popover = nil;
        } else {
            [UIView animateWithDuration:0.4 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                _monthPickerView.frame = (CGRect) {
                    .origin = CGPointMake(0, self.delegate.collectionView.frame.size.height + pickerViewHeight),
                    .size = _monthPickerView.frame.size
                };
            } completion:^(BOOL finished) {
                [_monthPickerView removeFromSuperview];
                _monthPickerView = nil;
            }];
        }
        return;
    }
    
    UIPickerView *pickerView = [[UIPickerView alloc] initWithFrame:CGRectMake(0, self.delegate.collectionView.frame.size.height + pickerViewHeight, 320.0f, pickerViewHeight)];
    _monthPickerView = pickerView;
    _monthPickerView.delegate = self;
    _monthPickerView.dataSource = self;
    _monthPickerView.showsSelectionIndicator = YES;
    _monthPickerView.backgroundColor = [WPStyleGuide itsEverywhereGrey];
    [_monthPickerView selectRow:_lastSelectedMonthFilter inComponent:0 animated:NO];
    
    if (IS_IPAD) {
        UIViewController *popoverContent = [[UIViewController alloc] init];
        popoverContent.preferredContentSize = CGSizeMake(320.0f, pickerViewHeight);
        _monthPickerView.frame = (CGRect) {
            .origin = CGPointZero,
            .size = _monthPickerView.frame.size
        };
        [popoverContent.view addSubview:_monthPickerView];
        _popover = [[UIPopoverController alloc] initWithContentViewController:popoverContent];
        _popover.delegate = self;
        [_popover setPopoverContentSize:CGSizeMake(320.0f, _monthPickerView.frame.size.height)];
        [_popover presentPopoverFromRect:_filterDatesButton.frame inView:self permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    } else {
        [self.delegate.collectionView addSubview:_monthPickerView];
        [UIView animateWithDuration:0.4 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            _monthPickerView.frame = (CGRect) {
                .origin = CGPointMake(0, self.delegate.view.frame.size.height - pickerViewHeight),
                .size = _monthPickerView.frame.size
            };
        } completion:nil];
    }
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    _popover = nil;
    _monthPickerView = nil;
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
    _lastSelectedMonthFilter = row;
    if (row == 0) {
        [self.delegate clearMonthFilter];
        [_filterDatesButton setImage:[UIImage imageNamed:@"date_picker_unselected"] forState:UIControlStateNormal];
        return;
    }
    [_filterDatesButton setImage:[UIImage imageNamed:@"date_picker_selected"] forState:UIControlStateNormal];
    [self.delegate selectedMonthPickerIndex:row-1];
}

- (NSString *)pickerView:(UIPickerView *)pickerView accessibilityLabelForComponent:(NSInteger)component {
    return NSLocalizedString(@"Month and year to filter media items by", @"Accessibility label for filtering media by month");
}

- (NSString *)pickerView:(UIPickerView *)pickerView accessibilityHintForComponent:(NSInteger)component {
    return NSLocalizedString(@"Selecting an option shows media items only from that month and year.", @"Accessibility hint for filtering media by month");
}

@end
