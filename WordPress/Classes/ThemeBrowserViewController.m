/*
 * ThemeBrowserViewController.m
 *
 * Copyright (c) 2013 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import "ThemeBrowserViewController.h"
#import "Theme.h"
#import "WordPressAppDelegate.h"
#import "ThemeBrowserCell.h"
#import "ThemeDetailsViewController.h"
#import "Blog.h"
#import "WPStyleGuide.h"

static NSString *const ThemeCellIdentifier = @"theme";
static NSString *const SearchFilterCellIdentifier = @"search_filter";

@interface ThemeBrowserViewController () <UICollectionViewDelegate, UICollectionViewDataSource>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (nonatomic, strong) NSArray *sortingOptions, *resultSortAttributes; // 'nice' sort names and the corresponding model attributes
@property (nonatomic, strong) NSString *currentResultsSort;
@property (nonatomic, strong) NSArray *allThemes, *filteredThemes;
@property (nonatomic, weak) UIRefreshControl *refreshHeaderView;
@property (nonatomic, strong) NSIndexPath *currentTheme, *selectedTheme;

@end

@implementation ThemeBrowserViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"Themes", @"Title for Themes browser");
        _currentResultsSort = @"trendingRank";
        _resultSortAttributes = @[@"trendingRank", @"launchDate", @"popularityRank"];
        _sortingOptions = @[NSLocalizedString(@"Trending", @"Theme filter"),
                            NSLocalizedString(@"Newest", @"Theme filter"),
                            NSLocalizedString(@"Popular", @"Theme filter")];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    self.collectionView.backgroundColor = TABLE_VIEW_BACKGROUND_COLOR;
    [self.collectionView registerClass:[ThemeBrowserCell class] forCellWithReuseIdentifier:ThemeCellIdentifier];
    [self.collectionView registerClass:[ThemeSearchFilterHeaderView class]
            forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:SearchFilterCellIdentifier];
    
    UIRefreshControl *refreshHeaderView = [[UIRefreshControl alloc] initWithFrame:CGRectMake(0.0f, 0.0f - self.collectionView.bounds.size.height, self.collectionView.frame.size.width, self.collectionView.bounds.size.height)];
    _refreshHeaderView = refreshHeaderView;
    [_refreshHeaderView addTarget:self action:@selector(refreshControlTriggered:) forControlEvents:UIControlEventValueChanged];
    _refreshHeaderView.tintColor = [WPStyleGuide whisperGrey];
    [self.collectionView addSubview:_refreshHeaderView];
    
    [self loadThemesFromCache];
    [self reloadThemes];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (_currentTheme && _selectedTheme && ![self.currentTheme isEqual:self.selectedTheme]) {
        [self.collectionView reloadItemsAtIndexPaths:@[_currentTheme, _selectedTheme]];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    self.allThemes = nil;
    self.filteredThemes = nil;
}

- (void)loadThemesFromCache {
    NSError *error;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([Theme class])];
    [fetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:_currentResultsSort ascending:true]]];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"blog == %@", self.blog]];
    fetchRequest.fetchBatchSize = 10;
    NSArray *allThemes = [[WordPressAppDelegate sharedWordPressApplicationDelegate].managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (error) {
        WPFLog(@"Failed to fetch themes with error %@", error);
        _allThemes = _filteredThemes = nil;
        return;
    }
    _allThemes = _filteredThemes = allThemes;
    [self.collectionView reloadData];
}

#pragma mark - UICollectionViewDelegate/DataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.filteredThemes.count;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        ThemeSearchFilterHeaderView *header = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:SearchFilterCellIdentifier forIndexPath:indexPath];
        if (!header.delegate) {
            header.delegate = self;
        }
        return header;
    }
    return nil;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ThemeBrowserCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:ThemeCellIdentifier forIndexPath:indexPath];
    Theme *theme = self.filteredThemes[indexPath.row];
    cell.theme = theme;
    if ([theme.themeId isEqualToString:self.blog.currentThemeId]) {
        self.currentTheme = indexPath;
    }
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    Theme *theme = self.filteredThemes[indexPath.row];
    self.selectedTheme = indexPath;
    ThemeDetailsViewController *details = [[ThemeDetailsViewController alloc] initWithTheme:theme];
    [self.navigationController pushViewController:details animated:true];
}

#pragma mark - Collection view flow layout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return IS_IPAD ? CGSizeMake(300, 255) : CGSizeMake(272, 234);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return IS_IPAD ? 20.0f : 7.0f;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return IS_IPAD ? 25.0f : 10.0f;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    CGFloat iPadInset = UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation]) ? 35.0f : 70.0f;
    return IS_IPAD ? UIEdgeInsetsMake(30, iPadInset, 30, iPadInset) : UIEdgeInsetsMake(7, 7, 7, 7);
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self.collectionView performBatchUpdates:nil completion:nil];
}

- (void)reloadThemes {
    [_refreshHeaderView beginRefreshing];
    [Theme fetchAndInsertThemesForBlog:self.blog success:^{
        [self loadThemesFromCache];
        [_refreshHeaderView endRefreshing];
    } failure:^(NSError *error) {
        [_refreshHeaderView endRefreshing];
        [WPError showAlertWithError:error];
    }];
}

#pragma mark - Setters

- (void)setFilteredThemes:(NSArray *)filteredThemes {
    _filteredThemes = filteredThemes;
    
    [self.collectionView reloadData];
}

- (void)applyCurrentSort {
    NSString *key = [@"self." stringByAppendingString:_currentResultsSort];
    self.filteredThemes = [_filteredThemes sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:key ascending:true]]];
}

#pragma mark - ThemeSearchFilterDelegate

- (NSArray *)themeSortingOptions {
    return _sortingOptions;
}

- (void)selectedSortIndex:(NSUInteger)sortIndex {
    _currentResultsSort = _resultSortAttributes[sortIndex];
    [self applyCurrentSort];
}

- (void)applyFilterWithSearchText:(NSString *)searchText {
    self.filteredThemes = [_allThemes filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self.themeId CONTAINS[cd] %@", searchText]];
    [self applyCurrentSort];
}

- (void)clearSearchFilter {
    self.filteredThemes = _allThemes;
    [self applyCurrentSort];
}

#pragma mark - UIRefreshControl

- (void)refreshControlTriggered:(UIRefreshControl*)refreshControl {
    if (refreshControl.isRefreshing) {
        [self reloadThemes];
    }
}

@end
