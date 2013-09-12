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
#import "WordPressAppDelegate.h"

static NSString *const MediaCellIdentifier = @"media_cell";

@interface MediaBrowserViewController () <UICollectionViewDataSource, UICollectionViewDelegate, MediaBrowserCellMultiSelectDelegate, UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet MediaSearchFilterHeaderView *filterHeaderView;
@property (nonatomic, strong) NSArray *filteredMedia, *allMedia;
@property (nonatomic, strong) NSArray *mediaTypeFilterOptions, *dateFilteringOptions;
@property (nonatomic, strong) NSMutableDictionary *selectedMedia;
@property (nonatomic, strong) NSArray *multiselectToolbarItems;
@property (nonatomic, weak) UIRefreshControl *refreshHeaderView;
@property (nonatomic, weak) UIActionSheet *currentActionSheet;
@property (nonatomic, strong) NSString *currentSearchText;

@property (weak, nonatomic) IBOutlet UIToolbar *multiselectToolbar;

@end

@implementation MediaBrowserViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"Media Library", @"");
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

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (_currentActionSheet) {
        [_currentActionSheet dismissWithClickedButtonIndex:_currentActionSheet.cancelButtonIndex animated:YES];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"media_navbar_add_new"] style:UIBarButtonItemStylePlain target:self action:@selector(addMediaButtonPressed:)];
    
    [self loadFromCache];
    [self applyFilterWithSearchText:_currentSearchText];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    // Save context for all thumbnails downloaded
    [self.blog.managedObjectContext save:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    _selectedMedia = nil;
}

- (void)refresh {
    [_refreshHeaderView beginRefreshing];
    [self.blog syncMediaLibraryWithSuccess:^{
        [self loadFromCache];
        [_refreshHeaderView endRefreshing];
    } failure:^(NSError *error) {
        WPFLog(@"Failed to refresh media library");
        [WPError showAlertWithError:error];
        [_refreshHeaderView endRefreshing];
    }];
}

- (void)loadFromCache {
    NSError *error;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([Media class])];
    [fetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:true]]];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"blog == %@", self.blog]];
    fetchRequest.fetchBatchSize = 10;
    NSArray *allMedia = [[WordPressAppDelegate sharedWordPressApplicationDelegate].managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (error) {
        WPFLog(@"Failed to fetch themes with error %@", error);
        _allMedia = self.filteredMedia = nil;
        return;
    }
    _allMedia = self.filteredMedia = allMedia;
    [self.collectionView reloadData];
}

#pragma mark - Setters

- (void)setFilteredMedia:(NSArray *)filteredMedia {
    _filteredMedia = filteredMedia;
    [self.collectionView reloadData];
}

#pragma mark - MediaSearchFilterDelegate

- (void)applyDateFilterForStartDate:(NSDate *)start andEndDate:(NSDate *)end {
    self.filteredMedia = [_allMedia filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self.date <= %@ AND self.date >= %@", end, start]];
}

- (void)applyFilterWithSearchText:(NSString *)searchText {
    if (!searchText) {
        [self clearSearchFilter];
        return;
    }
    
    NSArray *mediaToFilter = _isFilteringByDate ? self.filteredMedia : self.allMedia;
    
    self.filteredMedia = [mediaToFilter filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self.title CONTAINS[cd] %@ OR self.caption CONTAINS[cd] %@ OR self.desc CONTAINS[cd] %@", searchText, searchText, searchText]];
    
    _currentSearchText = searchText;
}

- (void)clearSearchFilter {
    self.filteredMedia = _allMedia;
    _currentSearchText = nil;
}

#pragma mark - CollectionViewDelegate/DataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.filteredMedia.count;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        return [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"header" forIndexPath:indexPath];
    }
    return nil;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    MediaBrowserCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:MediaCellIdentifier forIndexPath:indexPath];
    cell.media = self.filteredMedia[indexPath.item];
    cell.isSelected = ([_selectedMedia objectForKey:cell.media.mediaID] != nil);
    cell.delegate = self;
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
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
    BOOL isLandscape = UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation]);
    CGFloat iPadInset = isLandscape ? 35.0f : 60.0f;
    if (IS_IPAD) {
        return UIEdgeInsetsMake(30, iPadInset, 30, iPadInset);
    }
    return isLandscape ? UIEdgeInsetsMake(30, 35, 30, 35) : UIEdgeInsetsMake(7, 10, 7, 10);
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self.collectionView performBatchUpdates:nil completion:nil];
}

#pragma mark - MediaCellSelectionDelegate

- (void)mediaCellSelected:(Media *)media {
    if (!_selectedMedia) {
        _selectedMedia = [NSMutableDictionary dictionary];
    }
    
    if (!_selectedMedia[media.mediaID]) {
        [_selectedMedia setObject:media forKey:media.mediaID];
    }
    [self showMultiselectOptions];
}

- (void)mediaCellDeselected:(Media *)media {
    [_selectedMedia removeObjectForKey:media.mediaID];
    [self showMultiselectOptions];
}

#pragma mark - Multiselect options

- (IBAction)multiselectViewPressed:(id)sender {
    EditMediaViewController *vc = [[EditMediaViewController alloc] initWithMedia:[_selectedMedia allValues][0] showEditMode:NO];
    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)multiselectEditPressed:(id)sender {
    EditMediaViewController *vc = [[EditMediaViewController alloc] initWithMedia:[_selectedMedia allValues][0] showEditMode:YES];
    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)multiselectDeletePressed:(id)sender {
    UIAlertView *confirmation = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Delete Media", @"") message:NSLocalizedString(@"Are you sure you wish to delete the selected items?", @"") delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"") otherButtonTitles:NSLocalizedString(@"Delete", @""), nil];
    [confirmation show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        [Media bulkDeleteMedia:[_selectedMedia allValues] withSuccess:^(NSArray *successes) {
            NSLog(@"Successfully deleted %@", successes);
            
            [self loadFromCache];
        } failure:^(NSError *error, NSArray *failures) {
            WPFLog(@"Failed to delete media %@ with error %@", failures, error);
        }];
        
        [_selectedMedia removeAllObjects];
        [self showMultiselectOptions];
    }
}

- (IBAction)multiselectCreateGalleryPressed:(id)sender {
    // TODO
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
    [_selectedMedia removeAllObjects];
    [self showMultiselectOptions];
    if (refreshControl.isRefreshing) {
        [self refresh];
    }
}

#pragma mark - Add Media

- (IBAction)addMediaButtonPressed:(id)sender {
    
    if (_currentActionSheet) {
        return;
    }
    UIActionSheet *chooseMedia = [[UIActionSheet alloc] initWithTitle:@"" delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"") destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Take a Photo", @""), NSLocalizedString(@"Capture a Video", @""), NSLocalizedString(@"Choose from Library", @""), nil];
    _currentActionSheet = chooseMedia;
    
    if (IS_IPAD) {
        [_currentActionSheet showFromBarButtonItem:self.navigationItem.rightBarButtonItem animated:YES];
    } else {
        [_currentActionSheet showInView:self.view];
    }
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
