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

@interface ThemeSearchFilterHeaderView () <UISearchBarDelegate>

@property (nonatomic, weak) UISearchBar *searchBar;
@property (nonatomic, strong) UIImage *sortArrow, *sortArrowActive;

@end

@implementation ThemeSearchFilterHeaderView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [WPStyleGuide readGrey];
        UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height)];
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

- (void)setDelegate:(ThemeBrowserViewController *)delegate {
    _delegate = delegate;
    
    // Adding the options/button to the collection view instead of this header
    // due to the cells being drawn after
    // This causes the taps for the sort options to be grabbed by the cell instead
}

- (UIButton*)sortOptionButtonWithTitle:(NSString*)title {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitle:title forState:UIControlStateNormal];
    [button addTarget:self action:@selector(optionPressed:) forControlEvents:UIControlEventTouchUpInside];
    button.exclusiveTouch = YES;
    button.titleLabel.font = [WPStyleGuide regularTextFont];
    return button;
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