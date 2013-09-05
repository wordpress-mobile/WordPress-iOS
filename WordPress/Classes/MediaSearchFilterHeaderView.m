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

@interface OptionSelectView : UITableView <UITableViewDataSource, UITableViewDelegate>

- (id)initWithFrame:(CGRect)frame options:(NSArray*)options;
- (void)addTargetForOptionSelected:(id)target selector:(SEL)selector;

@end

@interface MediaSearchFilterHeaderView () <UISearchBarDelegate>

@property (nonatomic, weak) OptionSelectView *sortMediaView;
@property (nonatomic, weak) OptionSelectView *sortDatesView;
@property (nonatomic, weak) UISearchBar *searchBar;
@property (nonatomic, weak) UIButton *sortMediaButton;
@property (nonatomic, weak) UIButton *sortDatesButton;
@property (nonatomic, strong) UIImage *sortArrow, *sortArrowActive;

@end

@implementation MediaSearchFilterHeaderView

- (void)setDelegate:(MediaBrowserViewController *)delegate {
    _delegate = delegate;
    
    [self addSubview:self.searchBar];
    [_delegate.view addSubview:self.sortMediaView];
    [_delegate.view addSubview:self.sortDatesView];
    [_delegate.view addSubview:self.sortMediaButton];
    [_delegate.view addSubview:self.sortDatesButton];
    
    _sortMediaView.autoresizingMask = _sortMediaButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
    _sortDatesView.autoresizingMask = _sortDatesButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin;
}

- (UIView *)sortMediaView {
    OptionSelectView *sortMediaView = [[OptionSelectView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width/2, 0) options:[_delegate mediaTypeFilterOptions]];
    _sortMediaView = sortMediaView;
    _sortMediaView.frame = (CGRect) {
        .origin = CGPointMake(_sortMediaView.frame.origin.x, -_sortMediaView.frame.size.height),
        .size = _sortMediaView.frame.size
    };
    _sortMediaView.backgroundColor = [WPStyleGuide allTAllShadeGrey];
    [_sortMediaView addTargetForOptionSelected:self selector:@selector(sortMediaOptionSelected:)];
    return _sortMediaView;
}

- (UIView *)sortDatesView {
    OptionSelectView *sortDatesView = [[OptionSelectView alloc] initWithFrame:CGRectMake(CGRectGetMidX(self.frame), 0, self.frame.size.width/2, 0) options:[_delegate dateFilteringOptions]];
    _sortDatesView = sortDatesView;
    _sortDatesView.frame = (CGRect) {
        .origin = CGPointMake(_sortDatesView.frame.origin.x, -_sortDatesView.frame.size.height),
        .size = _sortDatesView.frame.size
    };
    _sortDatesView.backgroundColor = [WPStyleGuide allTAllShadeGrey];
    [_sortDatesView addTargetForOptionSelected:self selector:@selector(sortDateOptionSelected:)];
    return _sortDatesView;
}

- (UIButton *)sortMediaButton {
    _sortArrow = [UIImage imageNamed:@"icon-themes-dropdown-arrow"];
    _sortArrowActive = [UIImage imageWithCGImage:_sortArrow.CGImage scale:_sortArrow.scale orientation:UIImageOrientationDown];
    
    UIButton *sort = [self dropdownButtonWithTitle:[_delegate mediaTypeFilterOptions][0]];
    sort.frame = CGRectMake(0, 0, self.bounds.size.width/2, 44.0f);
    [sort addTarget:self action:@selector(sortMediaPressed) forControlEvents:UIControlEventTouchUpInside];
    _sortMediaButton = sort;
    return _sortMediaButton;
}

- (UIButton *)sortDatesButton {
    UIButton *sort = [self dropdownButtonWithTitle:[_delegate dateFilteringOptions][0]];
    _sortDatesButton = sort;
    _sortDatesButton.frame = CGRectMake(self.frame.size.width/2, 0, self.frame.size.width/2, 44.0f);
    [_sortDatesButton addTarget:self action:@selector(sortDatesPressed) forControlEvents:UIControlEventTouchUpInside];
    return _sortDatesButton;
}

- (UISearchBar *)searchBar {
    UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, self.bounds.size.height/2, self.bounds.size.width, self.bounds.size.height/2)];
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

- (UIButton*)dropdownButtonWithTitle:(NSString*)title {
    UIButton *sort = [UIButton buttonWithType:UIButtonTypeCustom];
    [sort setBackgroundColor:[WPStyleGuide allTAllShadeGrey]];
    [sort setTitle:title forState:UIControlStateNormal];
    sort.titleLabel.font = [WPStyleGuide regularTextFont];
    [sort setImage:_sortArrow forState:UIControlStateNormal];
    [sort setImage:_sortArrowActive forState:UIControlStateHighlighted];
    sort.imageEdgeInsets = UIEdgeInsetsMake(0, 120, 0, 0);
    sort.titleEdgeInsets = UIEdgeInsetsMake(0, -5, 0, 28);
    return sort;
}

- (void)sortMediaPressed {
    CGFloat yOffset = _sortMediaView.frame.origin.y < 0 ? _sortMediaButton.frame.size.height : -_sortMediaView.frame.size.height;
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        _sortMediaView.alpha = yOffset > 0 ? 1.0f : 0;
        _sortMediaView.frame = (CGRect) {
            .origin = CGPointMake(_sortMediaView.frame.origin.x, yOffset),
            .size = _sortMediaView.frame.size
        };
        [_sortMediaButton setImage:(yOffset > 0 ? _sortArrowActive : _sortArrow) forState:UIControlStateNormal];
    } completion:nil];
}

- (void)sortDatesPressed {
    CGFloat yOffset = _sortDatesView.frame.origin.y < 0 ? _sortDatesButton.frame.size.height : -_sortDatesView.frame.size.height;
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        _sortDatesView.alpha = yOffset > 0 ? 1.0f : 0;
        _sortDatesView.frame = (CGRect) {
            .origin = CGPointMake(_sortDatesView.frame.origin.x, yOffset),
            .size = _sortDatesView.frame.size
        };
        [_sortDatesButton setImage:(yOffset > 0 ? _sortArrowActive : _sortArrow) forState:UIControlStateNormal];
    } completion:nil];
}

- (void)sortMediaOptionSelected:(NSNumber*)option {
    [_sortMediaButton setTitle:[_delegate mediaTypeFilterOptions][option.integerValue] forState:UIControlStateNormal];
    [_delegate selectedMediaSortIndex:option.integerValue];
    [self sortMediaPressed];
}

- (void)sortDateOptionSelected:(NSNumber*)option {
    [_sortDatesButton setTitle:[_delegate dateFilteringOptions][option.integerValue] forState:UIControlStateNormal];
    [_delegate selectedDateSortIndex:option.integerValue];
    [self sortDatesPressed];
}

#pragma mark - UISearchBarDelegate

- (void)resetSearch {
    [_delegate clearSearchFilter];
    
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [_delegate applyFilterWithSearchText:searchBar.text];
}

@end

@interface OptionSelectView ()

@property (nonatomic, strong) NSArray *options;
@property (nonatomic, weak) id target;
@property (nonatomic, assign) SEL selector;

@end

@implementation OptionSelectView

- (id)initWithFrame:(CGRect)frame options:(NSArray *)options {
    self = [super initWithFrame:frame style:UITableViewStylePlain];
    if (self) {
        [self registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
        _options = options;
        self.frame = (CGRect) {
            .origin = self.frame.origin,
            .size = CGSizeMake(self.frame.size.width, MIN(_options.count * 44.0f, 3 * 44.0f))
        };
        self.delegate = self;
        self.dataSource = self;
        self.separatorStyle = UITableViewCellSeparatorStyleNone;
    }
    return self;
}

- (void)addTargetForOptionSelected:(id)target selector:(SEL)selector {
    _target = target;
    _selector = selector;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _options.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    cell.textLabel.text = _options[indexPath.row];
    cell.textLabel.font = [WPStyleGuide regularTextFont];
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.backgroundColor = [UIColor clearColor];
    cell.selectionStyle = UITableViewCellSelectionStyleGray;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [_target performSelector:_selector withObject:@(indexPath.row)];
#pragma clang diagnostic pop
}

@end
