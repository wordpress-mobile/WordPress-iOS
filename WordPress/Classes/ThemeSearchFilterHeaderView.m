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

CGFloat const FilterBarWidth = 120.0f;

@interface ThemeSearchFilterHeaderView ()

@property (nonatomic, weak) UIView *sortOptionsView;
@property (nonatomic, weak) UISearchBar *searchBar;
@property (nonatomic, weak) UIButton *sortButton;

@end

@implementation ThemeSearchFilterHeaderView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [WPStyleGuide readGrey];
        UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width - FilterBarWidth, self.bounds.size.height)];
        _searchBar = searchBar;
        _searchBar.text = NSLocalizedString(@"Search", @"");
        _searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [self addSubview:_searchBar];
    }
    return self;
}

- (void)setDelegate:(ThemeBrowserViewController *)delegate {
    _delegate = delegate;
    
    _searchBar.delegate = _delegate;
    
    UIView *optionsDropdown = [self setupSortOptionsDropdown];
    self.sortOptionsView = optionsDropdown;
//    [self addSubview:self.sortOptionsView];
    [_delegate.view addSubview:self.sortOptionsView]; //temp hack to make sure buttons are tappable. collectionview cells are on top
    
    UIButton *sort = [UIButton buttonWithType:UIButtonTypeCustom];
    self.sortButton = sort;
    [self.sortButton setBackgroundColor:[WPStyleGuide baseLightBlue]];
    [self.sortButton setTitle:[_delegate themeSortingOptions][0] forState:UIControlStateNormal];
    self.sortButton.frame = CGRectMake(_searchBar.frame.size.width, 0, FilterBarWidth, self.bounds.size.height);
    [self.sortButton addTarget:self action:@selector(sortPressed) forControlEvents:UIControlEventTouchUpInside];
    self.sortButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [self addSubview:self.sortButton];
}

- (UIButton*)sortOptionButtonWithTitle:(NSString*)title {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitle:title forState:UIControlStateNormal];
    [button addTarget:self action:@selector(optionPressed:) forControlEvents:UIControlEventTouchUpInside];
    button.exclusiveTouch = true;
    return button;
}

- (UIView *)setupSortOptionsDropdown {
    UIView *optionsContainer = [[UIView alloc] init];
    _sortOptionsView = optionsContainer;
    _sortOptionsView.backgroundColor = [WPStyleGuide baseLightBlue];
    _sortOptionsView.hidden = true;
    _sortOptionsView.opaque = true;
    _sortOptionsView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    CGFloat yOffset = 0;
    for (NSUInteger i = 0; i < [_delegate themeSortingOptions].count; i++) {
        UIButton *option = [self sortOptionButtonWithTitle:[_delegate themeSortingOptions][i]];
        option.frame = CGRectMake(0, yOffset, FilterBarWidth, self.bounds.size.height);
        option.tag = i;
        yOffset += option.frame.size.height;
        [_sortOptionsView addSubview:option];
    }
    _sortOptionsView.frame = CGRectMake(_searchBar.frame.size.width, -yOffset, FilterBarWidth, yOffset);
    return _sortOptionsView;
}

- (void)sortPressed {
    CGFloat yOffset = self.sortOptionsView.frame.origin.y < 0 ? self.bounds.size.height : -_sortOptionsView.frame.size.height;
    _sortOptionsView.hidden = false;
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        _sortOptionsView.frame = CGRectMake(_sortOptionsView.frame.origin.x, yOffset, FilterBarWidth, _sortOptionsView.bounds.size.height);
    } completion:^(BOOL c){
        _sortOptionsView.hidden = yOffset < 0;
    }];
}

- (void)optionPressed:(UIButton*)sender {
    [self.sortButton setTitle:[_delegate themeSortingOptions][sender.tag] forState:UIControlStateNormal];
    
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        _sortOptionsView.frame = CGRectMake(_sortOptionsView.frame.origin.x, -_sortOptionsView.frame.size.height, FilterBarWidth, _sortOptionsView.bounds.size.height);
    } completion:^(BOOL c){
        _sortOptionsView.hidden = true;
    }];
    
    [_delegate selectedSortIndex:sender.tag];
}

@end