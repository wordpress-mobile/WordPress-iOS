/*
 * ThemeSearchFilterHeaderView.m
 *
 * Copyright (c) 2013 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import "ThemeSearchFilterHeaderView.h"
#import "ThemeBrowserViewController.h"
#import "WPStyleGuide.h"

static CGFloat const SortButtonWidth = 130.0f;

@interface ThemeSearchFilterHeaderView () <UISearchBarDelegate>

@property (nonatomic, weak) UIView *sortOptionsView;
@property (nonatomic, weak) UISearchBar *searchBar;
@property (nonatomic, weak) UIButton *sortButton;
@property (nonatomic, strong) UIImage *sortArrow, *sortArrowActive;

@end

@implementation ThemeSearchFilterHeaderView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [WPStyleGuide readGrey];
        UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width - SortButtonWidth, self.bounds.size.height)];
        _searchBar = searchBar;
        _searchBar.placeholder = NSLocalizedString(@"Search", @"");
        _searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _searchBar.delegate = self;
        [_searchBar setTintColor:[WPStyleGuide readGrey]];
        _searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
        _searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
        [self addSubview:_searchBar];
    }
    return self;
}

- (void)layoutSubviews {
    // Adjust sort button due to hack below since auto resizing is not effective anymore
    _sortButton.frame = (CGRect) {
        .origin = CGPointMake(self.frame.size.width - SortButtonWidth, _sortButton.frame.origin.y),
        .size = _sortButton.frame.size
    };
    _sortOptionsView.frame = (CGRect) {
        .origin = CGPointMake(_sortButton.frame.origin.x, _sortOptionsView.frame.origin.y),
        .size = _sortOptionsView.frame.size
    };
}

- (void)setDelegate:(ThemeBrowserViewController *)delegate {
    _delegate = delegate;
    
    UIView *sortOptions = self.sortOptionsView;

    // Adding the options/button to the collection view instead of this header
    // due to the cells being drawn after
    // This causes the taps for the sort options to be grabbed by the cell instead
    id collectionView = nil;
    for (id view in _delegate.view.subviews) {
        if ([view isKindOfClass:[UICollectionView class]]) {
            collectionView = view;
            [view addSubview:sortOptions];
            break;
        }
    }
    
    UIButton *sortButton = self.sortButton;
    [collectionView addSubview:sortButton];
}

- (UIButton*)sortOptionButtonWithTitle:(NSString*)title {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitle:title forState:UIControlStateNormal];
    [button addTarget:self action:@selector(optionPressed:) forControlEvents:UIControlEventTouchUpInside];
    button.exclusiveTouch = YES;
    button.titleLabel.font = [WPStyleGuide regularTextFont];
    return button;
}

- (UIView *)sortOptionsView {
    UIView *optionsContainer = [[UIView alloc] init];
    _sortOptionsView = optionsContainer;
    _sortOptionsView.backgroundColor = [WPStyleGuide allTAllShadeGrey];
    _sortOptionsView.alpha = 0;
    _sortOptionsView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    CGFloat yOffset = 0;
    for (NSUInteger i = 0; i < [_delegate themeSortingOptions].count; i++) {
        UIButton *option = [self sortOptionButtonWithTitle:[_delegate themeSortingOptions][i]];
        option.frame = CGRectMake(0, yOffset, SortButtonWidth, self.bounds.size.height);
        option.tag = i;
        yOffset += option.frame.size.height;
        [_sortOptionsView addSubview:option];
    }
    _sortOptionsView.frame = CGRectMake(_searchBar.frame.size.width, -yOffset, SortButtonWidth, yOffset);
    return _sortOptionsView;
}

- (UIButton *)sortButton {
    _sortArrow = [UIImage imageNamed:@"icon-themes-dropdown-arrow"];
    _sortArrowActive = [UIImage imageWithCGImage:_sortArrow.CGImage scale:_sortArrow.scale orientation:UIImageOrientationDown];
    
    UIButton *sort = [UIButton buttonWithType:UIButtonTypeCustom];
    _sortButton = sort;
    [_sortButton setBackgroundColor:[WPStyleGuide allTAllShadeGrey]];
    [_sortButton setTitle:[_delegate themeSortingOptions][0] forState:UIControlStateNormal];
    _sortButton.titleLabel.font = [WPStyleGuide regularTextFont];
    [_sortButton setImage:_sortArrow forState:UIControlStateNormal];
    [_sortButton setImage:_sortArrowActive forState:UIControlStateHighlighted];
    _sortButton.imageEdgeInsets = UIEdgeInsetsMake(0, 108, 0, 0);
    _sortButton.titleEdgeInsets = UIEdgeInsetsMake(0, -5, 0, 28);
    _sortButton.frame = CGRectMake(_searchBar.frame.size.width, 0, SortButtonWidth, self.bounds.size.height);
    [_sortButton addTarget:self action:@selector(sortPressed) forControlEvents:UIControlEventTouchUpInside];
    return _sortButton;
}

- (void)sortPressed {
    CGFloat yOffset = _sortOptionsView.frame.origin.y < 0 ? self.bounds.size.height : -_sortOptionsView.frame.size.height;
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        _sortOptionsView.alpha = yOffset > 0 ? 1.0f : 0;
        _sortOptionsView.frame = (CGRect) {
            .origin = CGPointMake(_sortOptionsView.frame.origin.x, yOffset),
            .size = CGSizeMake(SortButtonWidth, _sortOptionsView.bounds.size.height)
        };
        [_sortButton setImage:(yOffset > 0 ? _sortArrowActive : _sortArrow) forState:UIControlStateNormal];
    } completion:nil];
}

- (void)optionPressed:(UIButton*)sender {
    [_sortButton setTitle:[_delegate themeSortingOptions][sender.tag] forState:UIControlStateNormal];
    
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        _sortOptionsView.frame = (CGRect) {
            .origin = CGPointMake(_sortOptionsView.frame.origin.x, -_sortOptionsView.frame.size.height),
            .size = CGSizeMake(SortButtonWidth, _sortOptionsView.bounds.size.height)
        };
        _sortOptionsView.alpha = 0;
        [_sortButton setImage:_sortArrow forState:UIControlStateNormal];
    } completion:nil];
    
    [_delegate selectedSortIndex:sender.tag];
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

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [_delegate applyFilterWithSearchText:searchBar.text];
    [self reenableCancelButton:searchBar];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [_delegate clearSearchFilter];
    searchBar.text = @"";
    [searchBar setShowsCancelButton:NO animated:YES];
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

- (BOOL)isFirstResponder {
    return _searchBar.isFirstResponder;
}

- (BOOL)becomeFirstResponder {
    return [_searchBar becomeFirstResponder];
}

- (BOOL)resignFirstResponder {
    return [_searchBar resignFirstResponder];
}

@end