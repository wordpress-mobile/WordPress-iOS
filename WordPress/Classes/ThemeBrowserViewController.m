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
    cell.theme = self.filteredThemes[indexPath.row];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    Theme *theme = self.filteredThemes[indexPath.row];
    ThemeDetailsViewController *details = [[ThemeDetailsViewController alloc] initWithTheme:theme];
    [self.navigationController pushViewController:details animated:true];
}

- (void)reloadThemes {
    if (_refreshHeaderView.isRefreshing) {
        return;
    }
    
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

#pragma mark - ThemeSearchFilterDelegate

- (NSArray *)themeSortingOptions {
    return _sortingOptions;
}

- (void)selectedSortIndex:(NSUInteger)sortIndex {
    _currentResultsSort = _resultSortAttributes[sortIndex];
    
    NSString *key = [@"self." stringByAppendingString:_currentResultsSort];
    self.filteredThemes = [_allThemes sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:key ascending:true]]];
}

- (void)applyFilterWithSearchText:(NSString *)searchText {
    self.filteredThemes = [_allThemes filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self.themeId CONTAINS %@", searchText]];
}

- (void)clearSearchFilter {
    self.filteredThemes = _allThemes;
}

#pragma mark - UIRefreshControl

- (void)refreshControlTriggered:(UIRefreshControl*)refreshControl {
    if (refreshControl.isRefreshing) {
        [self reloadThemes];
    }
}

@end
