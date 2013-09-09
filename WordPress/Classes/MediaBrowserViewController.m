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
#import "EditMediaViewController.h"
#import "PostMediaViewController.h"

static NSString *const MediaCellIdentifier = @"media_cell";

@interface MediaBrowserViewController () <UICollectionViewDataSource, UICollectionViewDelegate, MediaBrowserCellMultiSelectDelegate>

@property (weak, nonatomic) IBOutlet MediaSearchFilterHeaderView *filterHeaderView;
@property (nonatomic, strong) NSArray *filteredMedia;
@property (nonatomic, strong) NSArray *mediaTypeFilterOptions, *dateFilteringOptions;
@property (nonatomic, strong) NSMutableArray *selectedMedia;
@property (nonatomic, strong) NSArray *multiselectToolbarItems;
@property (nonatomic, weak) UIRefreshControl *refreshHeaderView;

@property (weak, nonatomic) IBOutlet UIToolbar *multiselectToolbar;

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
    [self.collectionView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"header"];
    
    [self.collectionView addSubview:_filterHeaderView];
    _filterHeaderView.delegate = self;
    
    UIRefreshControl *refreshHeaderView = [[UIRefreshControl alloc] initWithFrame:CGRectMake(0.0f, 0.0f - self.collectionView.bounds.size.height, self.collectionView.frame.size.width, self.collectionView.bounds.size.height)];
    _refreshHeaderView = refreshHeaderView;
    [_refreshHeaderView addTarget:self action:@selector(refreshControlTriggered:) forControlEvents:UIControlEventValueChanged];
    _refreshHeaderView.tintColor = [WPStyleGuide whisperGrey];
    [self.collectionView addSubview:_refreshHeaderView];
    
    [self.view addSubview:self.multiselectToolbar];
    _multiselectToolbarItems = [NSArray arrayWithArray:_multiselectToolbar.items];

    if (IS_IOS7) {
        self.multiselectToolbar.barTintColor = [WPStyleGuide littleEddieGrey];
    }
    self.multiselectToolbar.translucent = false;
    
    self.multiselectToolbar.frame = (CGRect) {
        .origin = CGPointMake(self.multiselectToolbar.frame.origin.x, CGRectGetMaxY(self.collectionView.frame)),
        .size = self.multiselectToolbar.frame.size
    };
    
    [self refresh];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addMediaButtonPressed:)];
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

- (void)refresh {
    [_refreshHeaderView beginRefreshing];
    [self.blog syncMediaLibraryWithSuccess:^{
        [self.collectionView reloadData];
        [_refreshHeaderView endRefreshing];
    } failure:^(NSError *error) {
        WPFLog(@"Failed to refresh media library");
        [WPError showAlertWithError:error];
        [_refreshHeaderView endRefreshing];
    }];
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

#pragma mark - CollectionViewDelegate/DataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.blog.media.allObjects.count;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        return [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"header" forIndexPath:indexPath];
    }
    return nil;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    MediaBrowserCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:MediaCellIdentifier forIndexPath:indexPath];
    cell.media = self.blog.media.allObjects[indexPath.item];
    cell.delegate = self;
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (!_selectedMedia) {
        _selectedMedia = [NSMutableArray array];
    }
    
    MediaBrowserCell *cell = (MediaBrowserCell*)[collectionView cellForItemAtIndexPath:indexPath];
    EditMediaViewController *viewMedia = [[EditMediaViewController alloc] initWithMedia:cell.media showEditMode:NO];
    [self.navigationController pushViewController:viewMedia animated:YES];
}

#pragma mark - Collection view layout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return IS_IPAD ? CGSizeMake(200, 220) : CGSizeMake(145, 165);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return IS_IPAD ? 20.0f : 10.0f;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return IS_IPAD ? 20.0f : 10.0f;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    CGFloat iPadInset = UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation]) ? 35.0f : 60.0f;
    return IS_IPAD ? UIEdgeInsetsMake(30, iPadInset, 30, iPadInset) : UIEdgeInsetsMake(7, 7, 7, 7);
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self.collectionView performBatchUpdates:nil completion:nil];
}

#pragma mark - MediaCellSelectionDelegate

- (void)mediaCellSelected:(Media *)media {
    if (![_selectedMedia containsObject:media]) {
        [_selectedMedia addObject:media];
    }
    [self showMultiselectOptions];
}

- (void)mediaCellDeselected:(Media *)media {
    [_selectedMedia removeObject:media];
    [self showMultiselectOptions];
}

#pragma mark - Multiselect options

- (IBAction)multiselectViewPressed:(id)sender {
    // Open View vc for _selectedMedia[0]
    EditMediaViewController *vc = [[EditMediaViewController alloc] initWithMedia:_selectedMedia[0] showEditMode:NO];
    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)multiselectEditPressed:(id)sender {
    // Open View viewcontroller with edit mode on, for _selectedMedia[0]
    // [[ViewMediaViewController alloc] initWithMedia:_selectedMedia[0] showEditMode:true];
    EditMediaViewController *vc = [[EditMediaViewController alloc] initWithMedia:_selectedMedia[0] showEditMode:YES];
    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)multiselectDeletePressed:(id)sender {
    // [Media deleteRemoteMedia:_selectedMedia];
}

- (IBAction)multiselectCreateGalleryPressed:(id)sender {
    // [[CreateGalleryViewController alloc] initWithMedia:_selectedMedia];
}

- (void)showMultiselectOptions {
    if (_selectedMedia.count == 0) {
        [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            self.multiselectToolbar.frame = (CGRect) {
                .origin = CGPointMake(self.multiselectToolbar.frame.origin.x, CGRectGetMaxY(self.collectionView.frame)),
                .size = self.multiselectToolbar.frame.size
            };
        } completion:nil];
    } else {
        if (_selectedMedia.count == 1) {
            // Show View, Edit, Delete, Create Gallery
            self.multiselectToolbar.items = [self buttonsForSingleItem];
        } else {
            // Show delete, create gallery
            self.multiselectToolbar.items = [self buttonsForMultipleItems];
        }
        
        [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            self.multiselectToolbar.frame = (CGRect) {
                .origin = CGPointMake(self.multiselectToolbar.frame.origin.x, CGRectGetMaxY(self.collectionView.frame) - 44.0f),
                .size = self.multiselectToolbar.frame.size
            };
        } completion:nil];
    }
}

- (NSArray*)buttonsForSingleItem {
    return _multiselectToolbarItems;
}

- (NSArray*)buttonsForMultipleItems {
    return @[_multiselectToolbarItems[0], _multiselectToolbarItems[3], _multiselectToolbarItems[4], _multiselectToolbarItems[5]];
}

#pragma mark - Refresh

- (void)refreshControlTriggered:(UIRefreshControl*)refreshControl {
    if (refreshControl.isRefreshing) {
        [self refresh];
    }
}

#pragma mark - Add Media

- (IBAction)addMediaButtonPressed:(id)sender {
    UIActionSheet *chooseMedia = [[UIActionSheet alloc] initWithTitle:@"" delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"") destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Take a Photo", @""), NSLocalizedString(@"Capture a Video", @""), NSLocalizedString(@"Choose from Library", @""), nil];
    [chooseMedia showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 0:
            // Camera
            break;
        case 1:
            // Take video
            break;
        case 2:
            // Choose from lib
            break;
        default:;
            // Cancelled
    }
}

@end
