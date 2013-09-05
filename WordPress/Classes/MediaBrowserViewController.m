/*
 * MediaBrowserViewController.m
 *
 * Copyright (c) 2013 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import "MediaBrowserViewController.h"
#import "Blog.h"
#import "MediaBrowserCell.h"
#import "Media.h"
#import "MediaSearchFilterHeaderView.h"

static NSString *const MediaCellIdentifier = @"media_cell";

@interface MediaBrowserViewController () <UICollectionViewDataSource, UICollectionViewDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet MediaSearchFilterHeaderView *filterHeaderView;
@property (nonatomic, strong) NSArray *filteredMedia;
@property (nonatomic, strong) NSArray *mediaTypeFilterOptions, *dateFilteringOptions;

@end

@implementation MediaBrowserViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"Media Library", @"");
        
        _mediaTypeFilterOptions = @[NSLocalizedString(@"All", @""),
                                    NSLocalizedString(@"Images", @""),
                                    NSLocalizedString(@"Unattached", @"")];
        _dateFilteringOptions = @[NSLocalizedString(@"Show All Dates", @""),
                                  NSLocalizedString(@"Sept 2013", @""),
                                  NSLocalizedString(@"Aug 2013", @""),
                                  NSLocalizedString(@"Jul 2013", @"")];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    [self.collectionView registerClass:[MediaBrowserCell class] forCellWithReuseIdentifier:MediaCellIdentifier];
    
    _filterHeaderView.delegate = self;
    
    [self.blog syncMediaLibraryWithSuccess:^{
        [self.collectionView reloadData];
    } failure:^(NSError *error) {
        
    }];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    // Save context for all thumbnails downloaded
    [self.blog.managedObjectContext save:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.blog.media.allObjects.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    MediaBrowserCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:MediaCellIdentifier forIndexPath:indexPath];
    cell.media = self.blog.media.allObjects[indexPath.item];
    return cell;
}

#pragma mark - Setters

- (void)setFilteredMedia:(NSArray *)filteredMedia {
    _filteredMedia = filteredMedia;
    [self.collectionView reloadData];
}

- (void)applyCurrentSort {
//    NSString *key = [@"self." stringByAppendingString:_currentResultsSort];
//    self.filteredThemes = [_filteredMedia sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:key ascending:true]]];
}

#pragma mark - MediaSearchFilterDelegate

- (NSArray *)mediaTypeFilterOptions {
    return _mediaTypeFilterOptions;
}

- (NSArray *)dateFilteringOptions {
    return _dateFilteringOptions;
}

- (void)selectedDateSortIndex:(NSUInteger)filterIndex {
    
}

- (void)selectedMediaSortIndex:(NSUInteger)filterIndex {
    
}

- (void)applyFilterWithSearchText:(NSString *)searchText {
    
}

- (void)clearSearchFilter {
    
}

@end
