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
#import "WPPopoverBackgroundView.h"
#import "UIImage+Resize.h"
#import "WordPressAppDelegate.h"
#import "WPLoadingView.h"
#import "PanelNavigationConstants.h"
#import "WPInfoView.h"
#import "Post.h"
#import "CPopoverManager.h"
#import "WPAlertView.h"
#import <ImageIO/ImageIO.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>

#define TAG_ACTIONSHEET_PHOTO 1
#define TAG_ACTIONSHEET_VIDEO 2

static NSString *const MediaCellIdentifier = @"media_cell";

static NSUInteger const MultiselectToolbarDeleteTag = 1;
static NSUInteger const MultiselectToolbarGalleryTag = 2;
static NSUInteger const MultiselectToolbarDeselectTag = 3;

static CGFloat const ScrollingVelocityThreshold = 30.0f;

@interface MediaBrowserViewController () <UICollectionViewDataSource, UICollectionViewDelegate, MediaBrowserCellMultiSelectDelegate, UIAlertViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate>

@property (nonatomic, strong) AbstractPost *apost;

@property (weak, nonatomic) IBOutlet MediaSearchFilterHeaderView *filterHeaderView;
@property (nonatomic, strong) NSArray *filteredMedia, *allMedia;
@property (nonatomic, strong) NSArray *mediaTypeFilterOptions, *dateFilteringOptions;
@property (nonatomic, strong) NSMutableDictionary *selectedMedia;
@property (nonatomic, weak) UIRefreshControl *refreshHeaderView;
@property (nonatomic, weak) UIActionSheet *currentActionSheet, *changeOrientationActionSheet, *resizeActionSheet;
@property (nonatomic, strong) UIImagePickerController *picker;
@property (nonatomic, strong) UIPopoverController *addPopover;
@property (nonatomic, assign) BOOL isFilteringByDate;
@property (nonatomic, strong) NSString *currentSearchText;
@property (nonatomic, strong) WPLoadingView *loadingView;
@property (nonatomic, strong) NSDate *startDate, *endDate;
@property (nonatomic, weak) UIView *firstResponderOnSidebarOpened;
@property (nonatomic, weak) WPInfoView *noMediaView;
@property (nonatomic, assign) BOOL videoPressEnabled, isPickingFeaturedImage, isLibraryMedia, isSelectingMediaForPost;
@property (nonatomic, strong) NSMutableDictionary *currentVideo;
@property (nonatomic, strong) UIImage *currentImage;
@property (nonatomic, strong) NSDictionary *currentImageMetadata;
@property (nonatomic, assign) MediaOrientation currentOrientation;
@property (nonatomic, strong) WPAlertView *customSizeAlert;
@property (nonatomic, assign) CGFloat lastScrollOffset;
@property (nonatomic, assign) BOOL isScrollingFast;

@property (weak, nonatomic) IBOutlet UIToolbar *multiselectToolbar;

@end

@implementation MediaBrowserViewController

- (id)initWithPost:(AbstractPost *)aPost {
    return [self initWithPost:aPost settingFeaturedImage:false];
}

- (id)initWithPost:(AbstractPost *)aPost selectingMediaForPost:(BOOL)isSelectingMediaForPost {
    self = [self initWithPost:aPost];
    if (self) {
        _isSelectingMediaForPost = isSelectingMediaForPost;
    }
    return self;
}

- (id)initWithPost:(AbstractPost *)aPost settingFeaturedImage:(BOOL)isSettingFeaturedImage {
    self = [super init];
    if (self) {
        self.apost = aPost;
        self.blog = aPost.blog;
        _isPickingFeaturedImage = isSettingFeaturedImage;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (_apost) {
        self.title = NSLocalizedString(@"Post Media", @"");
    } else {
        self.title = NSLocalizedString(@"Media Library", @"");
    }
    
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    self.collectionView.alwaysBounceVertical = true;
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
    
    if (IS_IOS7) {
        self.multiselectToolbar.barTintColor = [WPStyleGuide littleEddieGrey];
    }
    self.multiselectToolbar.translucent = false;
    
    self.multiselectToolbar.frame = (CGRect) {
        .origin = CGPointMake(self.multiselectToolbar.frame.origin.x, CGRectGetMaxY(self.collectionView.frame)),
        .size = self.multiselectToolbar.frame.size
    };
    
    if (!_apost) {
        NSMutableArray *toolbarItems = [NSMutableArray arrayWithArray:self.multiselectToolbar.items];
        NSUInteger index = [toolbarItems indexOfObjectPassingTest:^BOOL(UIBarButtonItem *obj, NSUInteger idx, BOOL *stop) {
            return obj.tag == MultiselectToolbarGalleryTag;
        }];
        [toolbarItems removeObjectAtIndex:index];
        self.multiselectToolbar.items = [NSArray arrayWithArray:toolbarItems];
    }
    
    [self refresh];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sidebarOpened) name:SidebarOpenedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sidebarClosed) name:SidebarClosedNotification object:nil];
    
    [self checkVideoPressEnabled];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (_currentActionSheet) {
        [_currentActionSheet dismissWithClickedButtonIndex:_currentActionSheet.cancelButtonIndex animated:YES];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self loadFromCache];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    UIBarButtonItem *addMediaButton;
    if (IS_IOS7) {
        UIImage *image = [UIImage imageNamed:@"icon-posts-add"];
        UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, image.size.width, image.size.height)];
        [button setImage:image forState:UIControlStateNormal];
        [button addTarget:self action:@selector(addMediaButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        addMediaButton = [[UIBarButtonItem alloc] initWithCustomView:button];
    } else {
        addMediaButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"navbar_add"]
                                                                                  style:[WPStyleGuide barButtonStyleForBordered]
                                                                                 target:self
                                                                                 action:@selector(addMediaButtonPressed:)];
        addMediaButton.tintColor = [UIColor UIColorFromHex:0x333333];
    }
    
    [WPStyleGuide setRightBarButtonItemWithCorrectSpacing:addMediaButton forNavigationItem:self.navigationItem];

    [self applyDateFilterForStartDate:_startDate andEndDate:_endDate];
    [self applyFilterWithSearchText:_currentSearchText];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    // Save context for all thumbnails downloaded
    if ([self.blog.managedObjectContext hasChanges]) {
        [self.blog.managedObjectContext save:nil];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    _selectedMedia = nil;
}

- (BOOL)showAttachedMedia {
    return _apost && !_isPickingFeaturedImage && !_isSelectingMediaForPost;
}

- (Post *)post {
    if ([self.apost isKindOfClass:[Post class]]) {
        return (Post *)self.apost;
    }
    return nil;
}

- (void)sidebarOpened {
    _firstResponderOnSidebarOpened = nil;
    for (id subview in self.collectionView.subviews) {
        if ([subview isFirstResponder]) {
            [subview resignFirstResponder];
            _firstResponderOnSidebarOpened = subview;
            return;
        }
    }
}

- (void)sidebarClosed {
    if (_firstResponderOnSidebarOpened) {
        [_firstResponderOnSidebarOpened becomeFirstResponder];
    }
}

- (void)refresh {
    [_refreshHeaderView beginRefreshing];
    [self.blog syncMediaLibraryWithSuccess:^{
        [self loadFromCache];
        [_refreshHeaderView endRefreshing];
        [self setUploadButtonEnabled:true];
    } failure:^(NSError *error) {
        WPFLog(@"Failed to refresh media library %@", error);
        [WPError showAlertWithError:error];
        if (error.code == 401) {
            [self setUploadButtonEnabled:false];
        }
        [_refreshHeaderView endRefreshing];
    }];
}

- (void)setUploadButtonEnabled:(BOOL)enabled {
    if (IS_IOS7) {
        ((UIButton*)[self.navigationItem.rightBarButtonItems[1] customView]).enabled = enabled;
    } else {
        self.navigationItem.rightBarButtonItem.enabled = enabled;
    }
}

- (void)loadFromCache {
    if ([self showAttachedMedia]) {
        _allMedia = _apost.media.allObjects;
        self.filteredMedia = _allMedia;
        return;
    }
    __block NSArray *allMedia;
    __block NSError *error;
    NSManagedObjectContext *context = self.blog.managedObjectContext;
    NSFetchRequest *allMediaRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([Media class])];
    [allMediaRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:false]]];
    [allMediaRequest setPredicate:[NSPredicate predicateWithFormat:@"blog == %@", self.blog]];
    allMediaRequest.fetchBatchSize = 10;
    [context performBlock:^{
        allMedia = [context executeFetchRequest:allMediaRequest error:&error];
        if (error) {
            WPFLog(@"Failed to fetch all media with error %@", error);
            _allMedia = self.filteredMedia = nil;
            return;
        }
        _allMedia = self.filteredMedia = allMedia;
    }];
}

- (UIView *)loadingView {
    if (!_loadingView) {
        CGFloat side = 100.0f;
        WPLoadingView *loadingView = [[WPLoadingView alloc] initWithSide:side];
        loadingView.center = CGPointMake(self.view.center.x, self.view.center.y - side);
        _loadingView = loadingView;
    }
    return _loadingView;
}

- (void)toggleNoMediaView:(BOOL)show {
    if (!show) {
        [_noMediaView removeFromSuperview];
        return;
    }
    if (!_noMediaView) {
        _noMediaView = [WPInfoView WPInfoViewWithTitle:@"No media to display" message:nil cancelButton:nil];
    }
    [self.collectionView addSubview:_noMediaView];
}

- (void)viewDidLayoutSubviews {
    [_noMediaView centerInSuperview];
}

#pragma mark - Setters

- (void)setFilteredMedia:(NSArray *)filteredMedia {
    _filteredMedia = filteredMedia;
    
    [self applyFilterForSelectedMedia];
    
    [self toggleNoMediaView:(_filteredMedia.count == 0)];
    [self.collectionView reloadData];
}

#pragma mark - MediaSearchFilterDelegate

- (void)setDateFilters:(NSDate *)start andEndDate:(NSDate *)end {
    _startDate = start;
    _endDate = end;
    _isFilteringByDate = (start && end);
}

- (void)applyDateFilterForStartDate:(NSDate *)start andEndDate:(NSDate *)end {
    [self setDateFilters:start andEndDate:end];
    end = [end dateByAddingTimeInterval:(24*3600)-1]; // 'end' at 11:59:59
    if (start && end) {
        self.filteredMedia = [_allMedia filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(self.creationDate <= %@) AND (self.creationDate >= %@)", end, start]];
        _isFilteringByDate = YES;
    } else {
        self.filteredMedia = _allMedia;
        _isFilteringByDate = NO;
    }
    if (_currentSearchText) {
        [self applyFilterWithSearchText:_currentSearchText];
    }
}

- (void)applyFilterForSelectedMedia {
    if (_selectedMedia.count > 0) {
        NSMutableArray *mediaToRemove = [NSMutableArray arrayWithArray:_allMedia];
        [mediaToRemove removeObjectsInArray:_filteredMedia];
        [mediaToRemove filterUsingPredicate:[NSPredicate predicateWithFormat:@"mediaID IN %@", [_selectedMedia allKeys]]];
        [_selectedMedia removeObjectsForKeys:[mediaToRemove valueForKey:@"mediaID"]];
        [self showMultiselectOptions];
    }
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
    [self applyDateFilterForStartDate:_startDate andEndDate:_endDate];
}

- (NSDate *)mediaDateRangeStart {
    if (_allMedia.count > 0) {
        return [[_allMedia lastObject] creationDate];
    }
    return nil;
}

- (NSDate *)mediaDateRangeEnd {
    if (_filteredMedia.count > 0) {
        NSDate *d = ((Media*)_filteredMedia[0]).creationDate;
        NSCalendar *c = [NSCalendar currentCalendar];
        c.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
        NSDateComponents *components = [c components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:d];
        return [c dateFromComponents:components];
    }
    return nil;
}

#pragma mark - CollectionViewDelegate/DataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _filteredMedia.count;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    return CGSizeMake(collectionView.frame.size.width, 44.0f);
}


- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        UICollectionReusableView *header = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"header" forIndexPath:indexPath];
        return header;
    }
    return nil;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    MediaBrowserCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:MediaCellIdentifier forIndexPath:indexPath];
    cell.hideCheckbox = _isPickingFeaturedImage;
    cell.media = self.filteredMedia[indexPath.item];
    cell.isSelected = ([_selectedMedia objectForKey:cell.media.mediaID] != nil);
    cell.delegate = self;
    
    if (!_isScrollingFast) {
        [cell loadThumbnail];
    }
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    MediaBrowserCell *cell = (MediaBrowserCell*)[collectionView cellForItemAtIndexPath:indexPath];
    if (cell.media.remoteStatus == MediaRemoteStatusFailed) {
        cell.media.remoteStatus = MediaRemoteStatusPushing;
        [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
        [cell.media uploadWithSuccess:^{
            
        } failure:^(NSError *error) {
            [WPError showAlertWithError:error title:NSLocalizedString(@"Upload failed", @"")];
        }];
    } else if (cell.media.remoteStatus == MediaRemoteStatusProcessing || cell.media.remoteStatus == MediaRemoteStatusPushing) {
        [cell.media cancelUpload];
    } else if (cell.media.remoteStatus == MediaRemoteStatusLocal || cell.media.remoteStatus == MediaRemoteStatusSync) {
        if (_isPickingFeaturedImage) {
            [[NSNotificationCenter defaultCenter] postNotificationName:FeaturedImageSelected object:cell.media];
            [self.navigationController popViewControllerAnimated:YES];
        } else if (_isSelectingMediaForPost) {
            [_apost.media addObject:cell.media];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ShouldInsertMediaAbove" object:cell.media];
            [self.navigationController popViewControllerAnimated:true];
        } else {
            EditMediaViewController *viewMedia = [[EditMediaViewController alloc] initWithMedia:cell.media];
            [self.navigationController pushViewController:viewMedia animated:YES];
        }
    }
}

#pragma mark - Collection view layout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return IS_IPAD ? CGSizeMake(200, 225) : CGSizeMake(145, 170);
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
    // iOS6-only fix: crash on rotate due to internal collectionview indices
    if (_filteredMedia.count) {
        [self.collectionView performBatchUpdates:nil completion:nil];
    }
}

#pragma mark - MediaCellSelectionDelegate

- (void)mediaCellSelected:(Media *)media {
    if (!_selectedMedia) {
        _selectedMedia = [NSMutableDictionary dictionary];
    }
    
    if (!_selectedMedia[media.mediaID]) {
        if (media.mediaID) {
            [_selectedMedia setObject:media forKey:media.mediaID];
        }
    }
    
    [self showMultiselectOptions];
}

- (void)mediaCellDeselected:(Media *)media {
    if (media.mediaID) {
        [_selectedMedia removeObjectForKey:media.mediaID];
    }
    [self showMultiselectOptions];
}

#pragma mark - Multiselect options

- (IBAction)multiselectDeletePressed:(id)sender {
    NSString *message, *destructiveButtonTitle;
    if ([self showAttachedMedia]) {
        message = NSLocalizedString(@"Are you sure you wish to remove these items from the post?", @"");
        destructiveButtonTitle = NSLocalizedString(@"Remove", @"");
    } else {
        message = NSLocalizedString(@"Are you sure you wish to delete the selected items?", @"");
        destructiveButtonTitle = NSLocalizedString(@"Delete", @"");
    }
    UIAlertView *confirmation = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Delete Media", @"") message:message delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"") otherButtonTitles:destructiveButtonTitle, nil];
    [confirmation show];
}

- (IBAction)multiselectDeselectAllPressed:(id)sender {
    [_selectedMedia removeAllObjects];
    [self showMultiselectOptions];
    [self.collectionView reloadData];
}

- (IBAction)multiselectCreateGalleryPressed:(id)sender {
    [[[UIAlertView alloc] initWithTitle:@"Coming Soon" message:@"Look forward to creating a gallery in a week or two :)" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        
        // Remove items from post only, in attached media state
        if ([self showAttachedMedia]) {
            [_selectedMedia enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"ShouldRemoveMedia" object:obj];
                [_apost.media removeObject:obj];
            }];
            [self loadFromCache];
            [self toggleNoMediaView:(_apost.media.count == 0)];
            return;
        }
        
        // Disable interaction with other views/buttons
        for (id v in self.view.subviews) {
            if ([v respondsToSelector:@selector(setUserInteractionEnabled:)]) {
                [v setUserInteractionEnabled:NO];
            }
        }
        
        [self.view addSubview:self.loadingView];
        [self.loadingView show];
        
        [Media bulkDeleteMedia:[_selectedMedia allValues] withSuccess:^() {
            [self loadFromCache];
            [self.loadingView hide];
            [self.loadingView removeFromSuperview];
            
            for (id subview in self.view.subviews) {
                if ([subview respondsToSelector:@selector(setUserInteractionEnabled:)]) {
                    [subview setUserInteractionEnabled:YES];
                }
            }
            
        } failure:^(NSError *error, NSArray *failures) {
            WPFLog(@"Failed to delete media %@ with error %@", failures, error);
            
            for (id subview in self.view.subviews) {
                if ([subview respondsToSelector:@selector(setUserInteractionEnabled:)]) {
                    [subview setUserInteractionEnabled:YES];
                }
            }
            
            [self.loadingView hide];
            [self.loadingView removeFromSuperview];
        }];
        
        [_selectedMedia removeAllObjects];
        [self showMultiselectOptions];
    }
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
        [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            self.multiselectToolbar.frame = (CGRect) {
                .origin = CGPointMake(self.multiselectToolbar.frame.origin.x, CGRectGetMaxY(self.collectionView.frame) - 44.0f),
                .size = self.multiselectToolbar.frame.size
            };
        } completion:nil];
    }
}

#pragma mark - Refresh

- (void)refreshControlTriggered:(UIRefreshControl*)refreshControl {
    if (refreshControl.isRefreshing) {
        [self refresh];
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    _isScrollingFast = false;
    [self.collectionView.visibleCells enumerateObjectsUsingBlock:^(MediaBrowserCell *obj, NSUInteger idx, BOOL *stop) {
        [obj loadThumbnail];
    }];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    _isScrollingFast = fabsf(self.collectionView.contentOffset.y - _lastScrollOffset) > ScrollingVelocityThreshold;
    _lastScrollOffset = self.collectionView.contentOffset.y;
}

#pragma mark - Add Media

- (void)checkVideoPressEnabled {
    //    if(self.isCheckingVideoCapability)
    //        return;
    
    //    self.isCheckingVideoCapability = YES;
    [self.blog checkVideoPressEnabledWithSuccess:^(BOOL enabled) {
        self.videoPressEnabled = enabled;
        //        self.isCheckingVideoCapability = NO;
    } failure:^(NSError *error) {
        WPLog(@"checkVideoPressEnabled failed: %@", [error localizedDescription]);
        self.videoPressEnabled = YES;
        //        self.isCheckingVideoCapability = NO;
    }];
}

- (BOOL)isDeviceSupportVideo {
	return (([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) &&
            ([[UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera] containsObject:(NSString *)kUTTypeMovie]));
}

- (BOOL)isDeviceSupportVideoAndVideoPressEnabled{
	return ([self isDeviceSupportVideo] && self.videoPressEnabled);
}

- (IBAction)addMediaButtonPressed:(id)sender {
    if ([self showAttachedMedia]) {
        MediaBrowserViewController *vc = [[MediaBrowserViewController alloc] initWithPost:_apost selectingMediaForPost:true];
        [self.navigationController pushViewController:vc animated:true];
    } else {
        if (_currentActionSheet) {
            return;
        }
        
        UIActionSheet *addMediaActionSheet;
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
            if ([self isDeviceSupportVideoAndVideoPressEnabled]) {
                addMediaActionSheet = [[UIActionSheet alloc] initWithTitle:@"" delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Add Photo From Library", nil), NSLocalizedString(@"Take Photo", nil), NSLocalizedString(@"Add Video from Library", @""), NSLocalizedString(@"Record Video", @""),nil];
                
            } else {
                addMediaActionSheet = [[UIActionSheet alloc] initWithTitle:@"" delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Add Photo From Library", nil), NSLocalizedString(@"Take Photo", nil), nil];
            }
        } else {
            addMediaActionSheet = [[UIActionSheet alloc] initWithTitle:@"" delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Add Photo From Library", nil), nil];
        }
        
        _currentActionSheet = addMediaActionSheet;
        
        if (IS_IPAD) {
            UIBarButtonItem *barButtonItem = IS_IOS7 ? self.navigationItem.rightBarButtonItems[1] : self.navigationItem.rightBarButtonItem;
            [_currentActionSheet showFromBarButtonItem:barButtonItem animated:YES];
        } else {
            [_currentActionSheet showInView:self.view];
        }
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (_resizeActionSheet) {
        [self processResizeSelection:buttonIndex actionSheet:actionSheet];
        _resizeActionSheet = nil;
        return;
    }
    
    NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    
    if ([buttonTitle isEqualToString:NSLocalizedString(@"Add Photo From Library", nil)]) {
        [WPMobileStats flagProperty:StatsPropertyPostDetailClickedAddPhoto forEvent:[self formattedStatEventString:StatsEventPostDetailClosedEditor]];
        [self pickMediaFromLibrary:actionSheet];
    
    } else if ([buttonTitle isEqualToString:NSLocalizedString(@"Take Photo", nil)]) {
       [WPMobileStats flagProperty:StatsPropertyPostDetailClickedAddPhoto forEvent:[self formattedStatEventString:StatsEventPostDetailClosedEditor]];
       [self pickPhotoFromCamera:nil];
    
    } else if ([buttonTitle isEqualToString:NSLocalizedString(@"Add Video from Library", nil)]) {
       [WPMobileStats flagProperty:StatsPropertyPostDetailClickedAddVideo forEvent:[self formattedStatEventString:StatsEventPostDetailClosedEditor]];
       actionSheet.tag = TAG_ACTIONSHEET_VIDEO;
       [self pickMediaFromLibrary:actionSheet];
    
    } else if ([buttonTitle isEqualToString:NSLocalizedString(@"Record Video", nil)]) {
       [WPMobileStats flagProperty:StatsPropertyPostDetailClickedAddVideo forEvent:[self formattedStatEventString:StatsEventPostDetailClosedEditor]];
       [self pickVideoFromCamera:actionSheet];
    }
}

- (void)processResizeSelection:(NSUInteger)buttonIndex actionSheet:(UIActionSheet*)actionSheet {
    if (actionSheet.cancelButtonIndex != buttonIndex) {
        switch (buttonIndex) {
            case 0:
                if (actionSheet.numberOfButtons == 3)
                    [self useImage:[self resizeImage:_currentImage toSize:kResizeOriginal]];
                else
                    [self useImage:[self resizeImage:_currentImage toSize:kResizeSmall]];
                break;
            case 1:
                if (actionSheet.numberOfButtons == 3) {
                    [self showCustomSizeAlert];
                } else if (actionSheet.numberOfButtons == 4)
                    [self useImage:[self resizeImage:_currentImage toSize:kResizeOriginal]];
                else
                    [self useImage:[self resizeImage:_currentImage toSize:kResizeMedium]];
                break;
            case 2:
                if (actionSheet.numberOfButtons == 4) {
                    [self showCustomSizeAlert];
                } else if (actionSheet.numberOfButtons == 5)
                    [self useImage:[self resizeImage:_currentImage toSize:kResizeOriginal]];
                else
                    [self useImage:[self resizeImage:_currentImage toSize:kResizeLarge]];
                break;
            case 3:
                if (actionSheet.numberOfButtons == 5) {
                    [self showCustomSizeAlert];
                } else
                    [self useImage:[self resizeImage:_currentImage toSize:kResizeOriginal]];
                break;
            case 4:
                [self showCustomSizeAlert];
                break;
        }
    }}

- (void)showCustomSizeAlert {
    if (self.customSizeAlert) {
        [self.customSizeAlert dismiss];
        self.customSizeAlert = nil;
    }
    
    // Check for previous width setting
    NSString *widthText = nil;
    if([[NSUserDefaults standardUserDefaults] objectForKey:@"prefCustomImageWidth"] != nil) {
        widthText = [[NSUserDefaults standardUserDefaults] objectForKey:@"prefCustomImageWidth"];
    } else {
        widthText = [NSString stringWithFormat:@"%d", (int)_currentImage.size.width];
    }
    
    NSString *heightText = nil;
    if([[NSUserDefaults standardUserDefaults] objectForKey:@"prefCustomImageHeight"] != nil) {
        heightText = [[NSUserDefaults standardUserDefaults] objectForKey:@"prefCustomImageHeight"];
    } else {
        heightText = [NSString stringWithFormat:@"%d", (int)_currentImage.size.height];
    }
    
    WPAlertView *alertView = [[WPAlertView alloc] initWithFrame:self.view.bounds andOverlayMode:WPAlertViewOverlayModeTwoTextFieldsSideBySideTwoButtonMode];
    
    alertView.overlayTitle = NSLocalizedString(@"Custom Size", @"");
    //    alertView.overlayDescription = NS Localized String(@"Provide a custom width and height for the image.", @"Alert view description for resizing an image with custom size.");
    alertView.overlayDescription = @"";
    alertView.footerDescription = nil;
    alertView.firstTextFieldPlaceholder = NSLocalizedString(@"Width", @"");
    alertView.firstTextFieldValue = widthText;
    alertView.secondTextFieldPlaceholder = NSLocalizedString(@"Height", @"");
    alertView.secondTextFieldValue = heightText;
    alertView.leftButtonText = NSLocalizedString(@"Cancel", @"Cancel button");
    alertView.rightButtonText = NSLocalizedString(@"OK", @"");
    
    alertView.firstTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    alertView.secondTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    alertView.firstTextField.keyboardAppearance = UIKeyboardAppearanceAlert;
    alertView.secondTextField.keyboardAppearance = UIKeyboardAppearanceAlert;
    alertView.firstTextField.keyboardType = UIKeyboardTypeNumberPad;
    alertView.secondTextField.keyboardType = UIKeyboardTypeNumberPad;
    
    alertView.button1CompletionBlock = ^(WPAlertView *overlayView){
        // Cancel
        [overlayView dismiss];
        overlayView = nil;
    };
    alertView.button2CompletionBlock = ^(WPAlertView *overlayView){
        [overlayView dismiss];
        
		NSNumber *width = [NSNumber numberWithInt:[overlayView.firstTextField.text intValue]];
		NSNumber *height = [NSNumber numberWithInt:[overlayView.secondTextField.text intValue]];
		
		if([width intValue] < 10)
			width = [NSNumber numberWithInt:10];
		if([height intValue] < 10)
			height = [NSNumber numberWithInt:10];
		
		overlayView.firstTextField.text = [NSString stringWithFormat:@"%@", width];
		overlayView.secondTextField.text = [NSString stringWithFormat:@"%@", height];
		
		[[NSUserDefaults standardUserDefaults] setObject:overlayView.firstTextField.text forKey:@"prefCustomImageWidth"];
		[[NSUserDefaults standardUserDefaults] setObject:overlayView.secondTextField.text forKey:@"prefCustomImageHeight"];
		
		[self useImage:[self resizeImage:_currentImage width:[width floatValue] height:[height floatValue]]];
    };
    
    alertView.alpha = 0.0;
    
    if (IS_IOS7) {
        [self.view addSubview:alertView];
    } else {
        alertView.hideBackgroundView = YES;
        alertView.firstTextField.keyboardAppearance = UIKeyboardAppearanceDefault;
        alertView.secondTextField.keyboardAppearance = UIKeyboardAppearanceDefault;
        [self.view addSubview:alertView];
    }
    
    [UIView animateWithDuration:0.2 animations:^{
        alertView.alpha = 1.0;
    }];
    
    self.customSizeAlert = alertView;
}

- (void)showResizeActionSheet {
	if(!_resizeActionSheet) {
        Blog *currentBlog = self.apost.blog;
        NSDictionary* predefDim = [currentBlog getImageResizeDimensions];
        CGSize smallSize =  [[predefDim objectForKey: @"smallSize"] CGSizeValue];
        CGSize mediumSize = [[predefDim objectForKey: @"mediumSize"] CGSizeValue];
        CGSize largeSize =  [[predefDim objectForKey: @"largeSize"] CGSizeValue];
        CGSize originalSize = CGSizeMake(_currentImage.size.width, _currentImage.size.height); //The dimensions of the image, taking orientation into account.
        
        switch (_currentImage.imageOrientation) {
            case UIImageOrientationLeft:
            case UIImageOrientationLeftMirrored:
            case UIImageOrientationRight:
            case UIImageOrientationRightMirrored:
                smallSize = CGSizeMake(smallSize.height, smallSize.width);
                mediumSize = CGSizeMake(mediumSize.height, mediumSize.width);
                largeSize = CGSizeMake(largeSize.height, largeSize.width);
                break;
            default:
                break;
        }
        
		NSString *resizeSmallStr = [NSString stringWithFormat:NSLocalizedString(@"Small (%@)", @"Small (width x height)"), [NSString stringWithFormat:@"%ix%i", (int)smallSize.width, (int)smallSize.height]];
   		NSString *resizeMediumStr = [NSString stringWithFormat:NSLocalizedString(@"Medium (%@)", @"Medium (width x height)"), [NSString stringWithFormat:@"%ix%i", (int)mediumSize.width, (int)mediumSize.height]];
        NSString *resizeLargeStr = [NSString stringWithFormat:NSLocalizedString(@"Large (%@)", @"Large (width x height)"), [NSString stringWithFormat:@"%ix%i", (int)largeSize.width, (int)largeSize.height]];
        NSString *originalSizeStr = [NSString stringWithFormat:NSLocalizedString(@"Original (%@)", @"Original (width x height)"), [NSString stringWithFormat:@"%ix%i", (int)originalSize.width, (int)originalSize.height]];
        
		UIActionSheet *resizeActionSheet;
		//NSLog(@"img dimension: %f x %f ",currentImage.size.width, currentImage.size.height );
		
		if(_currentImage.size.width > largeSize.width  && _currentImage.size.height > largeSize.height) {
			resizeActionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Choose Image Size", @"")
															delegate:self
												   cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
											  destructiveButtonTitle:nil
												   otherButtonTitles:resizeSmallStr, resizeMediumStr, resizeLargeStr, originalSizeStr, NSLocalizedString(@"Custom", @""), nil];
			
		} else if(_currentImage.size.width > mediumSize.width  && _currentImage.size.height > mediumSize.height) {
			resizeActionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Choose Image Size", @"")
															delegate:self
												   cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
											  destructiveButtonTitle:nil
												   otherButtonTitles:resizeSmallStr, resizeMediumStr, originalSizeStr, NSLocalizedString(@"Custom", @""), nil];
			
		} else if(_currentImage.size.width > smallSize.width  && _currentImage.size.height > smallSize.height) {
			resizeActionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Choose Image Size", @"")
															delegate:self
												   cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
											  destructiveButtonTitle:nil
												   otherButtonTitles:resizeSmallStr, originalSizeStr, NSLocalizedString(@"Custom", @""), nil];
		} else {
			resizeActionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Choose Image Size", @"")
															delegate:self
												   cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
											  destructiveButtonTitle:nil
												   otherButtonTitles: originalSizeStr, NSLocalizedString(@"Custom", @""), nil];
		}
        
        _resizeActionSheet = resizeActionSheet;
        
        if (IS_IOS7) {
            if (IS_IPAD) {
                [resizeActionSheet showFromBarButtonItem:[self.navigationItem.rightBarButtonItems objectAtIndex:1] animated:YES];
            } else {
                [resizeActionSheet showInView:self.view];
            }
        } else {
            [resizeActionSheet showInView:self.view];
        }
	}
}

- (NSString *)formattedStatEventString:(NSString *)event
{
    // TODO change for general media library OR post detail
    return [NSString stringWithFormat:@"%@ - %@", self.apost ? @"Post Detail" : @"Media Library", event];
}



- (UIImagePickerController *)resetImagePicker {
    _picker = [[UIImagePickerController alloc] init];
    _picker.delegate = nil;
    _picker.navigationBar.translucent = NO;
	_picker.delegate = self;
    _picker.allowsEditing = NO;
    return _picker;
}

- (void)takePhoto {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [self resetImagePicker];
        _picker.sourceType = UIImagePickerControllerSourceTypeCamera;
        _picker.mediaTypes = [NSArray arrayWithObject:(NSString *)kUTTypeImage];
        
        [self.navigationController presentViewController:_picker animated:YES completion:nil];
    }
}

- (void)takeVideo {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [self resetImagePicker];
        _picker.sourceType = UIImagePickerControllerSourceTypeCamera;
        _picker.mediaTypes = [NSArray arrayWithObject:(NSString *)kUTTypeMovie];
        _picker.videoQuality = UIImagePickerControllerQualityTypeMedium;
        
        if([[NSUserDefaults standardUserDefaults] objectForKey:@"video_quality_preference"]) {
            NSString *quality = [[NSUserDefaults standardUserDefaults] objectForKey:@"video_quality_preference"];
            switch ([quality intValue]) {
                case 0:
                    _picker.videoQuality = UIImagePickerControllerQualityTypeHigh;
                    break;
                case 1:
                    _picker.videoQuality = UIImagePickerControllerQualityTypeMedium;
                    break;
                case 2:
                    _picker.videoQuality = UIImagePickerControllerQualityTypeLow;
                    break;
                case 3:
                    _picker.videoQuality = UIImagePickerControllerQualityType640x480;
                    break;
                default:
                    _picker.videoQuality = UIImagePickerControllerQualityTypeMedium;
                    break;
            }
        }
        
        [self.navigationController presentViewController:_picker animated:YES completion:nil];
    }
}

- (void)pickMediaFromLibrary:(id)sender {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        [self resetImagePicker];
        _picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        if (self.videoPressEnabled || ![self.blog isWPcom])
            _picker.mediaTypes = [NSArray arrayWithObjects: (NSString *)kUTTypeMovie, (NSString *)kUTTypeImage, nil];
        else
            _picker.mediaTypes = [NSArray arrayWithObjects:(NSString *)kUTTypeImage, nil];
        _picker.videoQuality = UIImagePickerControllerQualityTypeMedium;
        _isLibraryMedia = YES;
        
        if ([(UIView *)sender tag] == TAG_ACTIONSHEET_VIDEO) {
            _picker.mediaTypes = [NSArray arrayWithObject:(NSString *)kUTTypeMovie];
			_picker.videoQuality = UIImagePickerControllerQualityTypeMedium;
            _picker.modalPresentationStyle = UIModalPresentationCurrentContext;
			
			if([[NSUserDefaults standardUserDefaults] objectForKey:@"video_quality_preference"] != nil) {
				NSString *quality = [[NSUserDefaults standardUserDefaults] objectForKey:@"video_quality_preference"];
				switch ([quality intValue]) {
					case 0:
						_picker.videoQuality = UIImagePickerControllerQualityTypeHigh;
						break;
					case 1:
						_picker.videoQuality = UIImagePickerControllerQualityTypeMedium;
						break;
					case 2:
						_picker.videoQuality = UIImagePickerControllerQualityTypeLow;
						break;
					case 3:
						_picker.videoQuality = UIImagePickerControllerQualityType640x480;
						break;
					default:
						_picker.videoQuality = UIImagePickerControllerQualityTypeMedium;
						break;
				}
			}
        }
        //            else {
        //            if (_isPickingFeaturedImage)
        //                barButton = postDetailViewController.settingsButton;
        //            else
        //                barButton = postDetailViewController.photoButton;
        //            _picker.mediaTypes = [NSArray arrayWithObject:(NSString *)kUTTypeImage];
        //        }
        
        if (IS_IPAD) {
            if (!_addPopover) {
                _addPopover = [[UIPopoverController alloc] initWithContentViewController:_picker];
                
                if ([_addPopover respondsToSelector:@selector(popoverBackgroundViewClass)] && !IS_IOS7) {
                    _addPopover.popoverBackgroundViewClass = [WPPopoverBackgroundView class];
                }
            }
            UIBarButtonItem *barButtonItem = IS_IOS7 ? self.navigationItem.rightBarButtonItems[1] : self.navigationItem.rightBarButtonItem;
            [_addPopover presentPopoverFromBarButtonItem:barButtonItem permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        }
        else {
            [self.navigationController presentViewController:_picker animated:YES completion:nil];
        }
    }
}

- (void)pickPhotoFromCamera:(id)sender {
	self.currentOrientation = [self interpretOrientation:[UIDevice currentDevice].orientation];
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [self resetImagePicker];
        _picker.sourceType = UIImagePickerControllerSourceTypeCamera;
		_picker.mediaTypes = [NSArray arrayWithObject:(NSString *)kUTTypeImage];
        _picker.modalPresentationStyle = UIModalPresentationCurrentContext;
		
        [self.navigationController presentViewController:_picker animated:YES completion:nil];
    }
}

- (void)pickVideoFromCamera:(id)sender {
	self.currentOrientation = [self interpretOrientation:[UIDevice currentDevice].orientation];
    [self resetImagePicker];
	_picker.sourceType =  UIImagePickerControllerSourceTypeCamera;
	_picker.mediaTypes = [NSArray arrayWithObject:(NSString *)kUTTypeMovie];
	_picker.videoQuality = UIImagePickerControllerQualityTypeMedium;
    _picker.modalPresentationStyle = UIModalPresentationCurrentContext;
	
	if([[NSUserDefaults standardUserDefaults] objectForKey:@"video_quality_preference"] != nil) {
		NSString *quality = [[NSUserDefaults standardUserDefaults] objectForKey:@"video_quality_preference"];
		switch ([quality intValue]) {
			case 0:
				_picker.videoQuality = UIImagePickerControllerQualityTypeHigh;
				break;
			case 1:
				_picker.videoQuality = UIImagePickerControllerQualityTypeMedium;
				break;
			case 2:
				_picker.videoQuality = UIImagePickerControllerQualityTypeLow;
				break;
			case 3:
				_picker.videoQuality = UIImagePickerControllerQualityType640x480;
				break;
			default:
				_picker.videoQuality = UIImagePickerControllerQualityTypeMedium;
				break;
		}
	}
	
    [self.navigationController presentViewController:_picker animated:YES completion:nil];
}


- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    // On iOS7 Beta 6 the image picker seems to override our preferred setting so we force the status bar color back.
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    
	if([[info valueForKey:@"UIImagePickerControllerMediaType"] isEqualToString:@"public.movie"]) {
		self.currentVideo = [info mutableCopy];
		if(!self.isLibraryMedia)
			[self processRecordedVideo];
		else
        [self performSelectorOnMainThread:@selector(processLibraryVideo) withObject:nil waitUntilDone:NO];
	}
	else if([[info valueForKey:@"UIImagePickerControllerMediaType"] isEqualToString:@"public.image"]) {
		UIImage *image = [info valueForKey:@"UIImagePickerControllerOriginalImage"];
		if (picker.sourceType == UIImagePickerControllerSourceTypeCamera)
			UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
		_currentImage = image;
		
		//UIImagePickerControllerReferenceURL = "assets-library://asset/asset.JPG?id=1000000050&ext=JPG").
        NSURL *assetURL = nil;
        if (&UIImagePickerControllerReferenceURL != NULL) {
            assetURL = [info objectForKey:UIImagePickerControllerReferenceURL];
        }
        if (assetURL) {
            [self getMetadataFromAssetForURL:assetURL];
        } else {
            NSDictionary *metadata = nil;
            if (&UIImagePickerControllerMediaMetadata != NULL) {
                metadata = [info objectForKey:UIImagePickerControllerMediaMetadata];
            }
            if (metadata) {
                NSMutableDictionary *mutableMetadata = [metadata mutableCopy];
                NSDictionary *gpsData = [mutableMetadata objectForKey:@"{GPS}"];
                if (!gpsData && self.post.geolocation) {
                    /*
                     Sample GPS data dictionary
                     "{GPS}" =     {
                     Altitude = 188;
                     AltitudeRef = 0;
                     ImgDirection = "84.19556";
                     ImgDirectionRef = T;
                     Latitude = "41.01333333333333";
                     LatitudeRef = N;
                     Longitude = "0.01666666666666";
                     LongitudeRef = W;
                     TimeStamp = "10:34:04.00";
                     };
                     */
                    CLLocationDegrees latitude = self.post.geolocation.latitude;
                    CLLocationDegrees longitude = self.post.geolocation.longitude;
                    NSDictionary *gps = [NSDictionary dictionaryWithObjectsAndKeys:
                                         [NSNumber numberWithDouble:fabs(latitude)], @"Latitude",
                                         (latitude < 0.0) ? @"S" : @"N", @"LatitudeRef",
                                         [NSNumber numberWithDouble:fabs(longitude)], @"Longitude",
                                         (longitude < 0.0) ? @"W" : @"E", @"LongitudeRef",
                                         nil];
                    [mutableMetadata setObject:gps forKey:@"{GPS}"];
                }
                [mutableMetadata removeObjectForKey:@"Orientation"];
                [mutableMetadata removeObjectForKey:@"{TIFF}"];
                self.currentImageMetadata = mutableMetadata;
            }
        }
		
		NSNumberFormatter *nf = [[NSNumberFormatter alloc] init];
		[nf setNumberStyle:NSNumberFormatterDecimalStyle];
		NSNumber *resizePreference = [NSNumber numberWithInt:-1];
		if([[NSUserDefaults standardUserDefaults] objectForKey:@"media_resize_preference"] != nil)
			resizePreference = [nf numberFromString:[[NSUserDefaults standardUserDefaults] objectForKey:@"media_resize_preference"]];
		BOOL showResizeActionSheet;
		switch ([resizePreference intValue]) {
			case 0:
            {
                showResizeActionSheet = true;
				break;
            }
			case 1:
            {
				[self useImage:[self resizeImage:_currentImage toSize:kResizeSmall]];
				break;
            }
			case 2:
            {
				[self useImage:[self resizeImage:_currentImage toSize:kResizeMedium]];
				break;
            }
			case 3:
            {
				[self useImage:[self resizeImage:_currentImage toSize:kResizeLarge]];
				break;
            }
			case 4:
            {
				//[self useImage:currentImage];
                [self useImage:[self resizeImage:_currentImage toSize:kResizeOriginal]];
				break;
            }
			default:
            {
                showResizeActionSheet = true;
				break;
            }
		}
		
        if (_addPopover) {
            [_addPopover dismissPopoverAnimated:YES];
            [[CPopoverManager instance] setCurrentPopoverController:NULL];
            _addPopover = nil;
            [self showResizeActionSheet];
        } else {
            [self.navigationController dismissViewControllerAnimated:YES completion:^{
                if (showResizeActionSheet) {
                    [self showResizeActionSheet];
                }
            }];
        }
        
        if(IS_IPAD){
            [_addPopover dismissPopoverAnimated:YES];
            [[CPopoverManager instance] setCurrentPopoverController:NULL];
            _addPopover = nil;
        }
        
        [self refresh];
    }
}

- (void)processLibraryVideo {
	NSURL *videoURL = [_currentVideo valueForKey:UIImagePickerControllerMediaURL];
	if(videoURL == nil)
		videoURL = [_currentVideo valueForKey:UIImagePickerControllerReferenceURL];
	
	if(videoURL != nil) {
		if(IS_IPAD)
			[_addPopover dismissPopoverAnimated:YES];
		else {
            [self.navigationController dismissViewControllerAnimated:YES completion:nil];
		}
		
		[self.currentVideo setValue:[NSNumber numberWithInt:_currentOrientation] forKey:@"orientation"];
		
		[self useVideo:[self videoPathFromVideoUrl:[videoURL absoluteString]]];
		self.currentVideo = nil;
		self.isLibraryMedia = NO;
	}
}

- (void)processRecordedVideo {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    
	[self.currentVideo setValue:[NSNumber numberWithInt:_currentOrientation] forKey:@"orientation"];
	NSString *tempVideoPath = [(NSURL *)[_currentVideo valueForKey:UIImagePickerControllerMediaURL] absoluteString];
    tempVideoPath = [self videoPathFromVideoUrl:tempVideoPath];
	if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(tempVideoPath)) {
		UISaveVideoAtPathToSavedPhotosAlbum(tempVideoPath, self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
	}
}

- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(NSString *)contextInfo {
    _currentVideo = nil;
	[self useVideo:videoPath];
}

- (void)useImage:(UIImage *)theImage {
    Media *imageMedia;
    if (_apost) {
        imageMedia = [Media newMediaForPost:_apost];
    } else {
        imageMedia = [Media newMediaForBlog:self.blog];
    }
	NSData *imageData = UIImageJPEGRepresentation(theImage, 0.90);
	UIImage *imageThumbnail = [self generateThumbnailFromImage:theImage andSize:CGSizeMake(75, 75)];
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"yyyyMMdd-HHmmss"];
    
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	NSString *filename = [NSString stringWithFormat:@"%@.jpg", [formatter stringFromDate:[NSDate date]]];
	NSString *filepath = [documentsDirectory stringByAppendingPathComponent:filename];
    
	if (self.currentImageMetadata != nil) {
		// Write the EXIF data with the image data to disk
		CGImageSourceRef  source = NULL;
        CGImageDestinationRef destination = NULL;
		BOOL success = NO;
        //this will be the data CGImageDestinationRef will write into
        NSMutableData *dest_data = [NSMutableData data];
        
		source = CGImageSourceCreateWithData((__bridge CFDataRef)imageData, NULL);
        if (source) {
            CFStringRef UTI = CGImageSourceGetType(source); //this is the type of image (e.g., public.jpeg)
            destination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)dest_data,UTI,1,NULL);
            
            if(destination) {
                //add the image contained in the image source to the destination, copying the old metadata
                CGImageDestinationAddImageFromSource(destination,source,0, (__bridge CFDictionaryRef) self.currentImageMetadata);
                
                //tell the destination to write the image data and metadata into our data object.
                //It will return false if something goes wrong
                success = CGImageDestinationFinalize(destination);
            } else {
                WPFLog(@"***Could not create image destination ***");
            }
        } else {
            WPFLog(@"***Could not create image source ***");
        }
		
		if(!success) {
			WPLog(@"***Could not create data from image destination ***");
			//write the data without EXIF to disk
			NSFileManager *fileManager = [NSFileManager defaultManager];
			[fileManager createFileAtPath:filepath contents:imageData attributes:nil];
		} else {
			//write it to disk
			[dest_data writeToFile:filepath atomically:YES];
		}
		//cleanup
//        if (destination)
//            CFRelease(destination);
//        if (source)
//            CFRelease(source);
    } else {
		NSFileManager *fileManager = [NSFileManager defaultManager];
		[fileManager createFileAtPath:filepath contents:imageData attributes:nil];
	}
    
	if(self.currentOrientation == kLandscape)
		imageMedia.orientation = @"landscape";
	else
		imageMedia.orientation = @"portrait";
	imageMedia.creationDate = [NSDate date];
	imageMedia.filename = filename;
	imageMedia.localURL = filepath;
	imageMedia.filesize = [NSNumber numberWithInt:(imageData.length/1024)];
    if (_isPickingFeaturedImage)
        imageMedia.mediaType = @"featured";
    else
        imageMedia.mediaType = @"image";
	imageMedia.thumbnail = UIImageJPEGRepresentation(imageThumbnail, 0.90);
	imageMedia.width = [NSNumber numberWithInt:theImage.size.width];
	imageMedia.height = [NSNumber numberWithInt:theImage.size.height];
    if (_isPickingFeaturedImage)
        [[NSNotificationCenter defaultCenter] postNotificationName:@"UploadingFeaturedImage" object:nil];
    
    [imageMedia uploadWithSuccess:^{
        if ([imageMedia isDeleted]) {
            NSLog(@"Media deleted while uploading (%@)", imageMedia);
            return;
        }
        if (!_isPickingFeaturedImage) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ShouldInsertMediaBelow" object:imageMedia];
        }
        else {
            
        }
        [imageMedia save];
    } failure:^(NSError *error) {
        if (error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled) {
            return;
        }
        
        [WPError showAlertWithError:error title:NSLocalizedString(@"Upload failed", @"")];
    }];
	
//	isAddingMedia = NO;
	
//    if (!IS_IOS7) {
//        if (_isPickingFeaturedImage)
//            [postDetailViewController switchToSettings];
//        else
//            [postDetailViewController switchToMedia];
//    }
    
    [self loadFromCache];
}


- (void)useVideo:(NSString *)videoURL {
	BOOL copySuccess = NO;
	Media *videoMedia;
	NSDictionary *attributes;
    UIImage *thumbnail = nil;
	NSTimeInterval duration = 0.0;
    NSURL *contentURL = [NSURL fileURLWithPath:videoURL];
    
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:contentURL
                                                options:[NSDictionary dictionaryWithObjectsAndKeys:
                                                         [NSNumber numberWithBool:YES], AVURLAssetPreferPreciseDurationAndTimingKey,
                                                         nil]];
    if (asset) {
        duration = CMTimeGetSeconds(asset.duration);
        AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
        imageGenerator.appliesPreferredTrackTransform = YES;
        
        CMTime midpoint = CMTimeMakeWithSeconds(duration/2.0, 600);
        NSError *error = nil;
        CMTime actualTime;
        CGImageRef halfWayImage = [imageGenerator copyCGImageAtTime:midpoint actualTime:&actualTime error:&error];
        
        if (halfWayImage != NULL) {
            thumbnail = [UIImage imageWithCGImage:halfWayImage];
            // Do something interesting with the image.
            CGImageRelease(halfWayImage);
        }
    }
    
	UIImage *videoThumbnail = [self generateThumbnailFromImage:thumbnail andSize:CGSizeMake(75, 75)];
	
	// Save to local file
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"yyyyMMdd-HHmmss"];	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	NSString *filename = [NSString stringWithFormat:@"%@.mov", [formatter stringFromDate:[NSDate date]]];
	NSString *filepath = [documentsDirectory stringByAppendingPathComponent:filename];
	
	if(videoURL != nil) {
		// Copy the video from temp to blog directory
		NSError *error = nil;
		if ((attributes = [fileManager attributesOfItemAtPath:videoURL error:nil]) != nil) {
			if([fileManager isReadableFileAtPath:videoURL])
				copySuccess = [fileManager copyItemAtPath:videoURL toPath:filepath error:&error];
		}
	}
	
	if(copySuccess) {
		videoMedia = [Media newMediaForBlog:self.blog];
		
		if(_currentOrientation == kLandscape)
			videoMedia.orientation = @"landscape";
		else
			videoMedia.orientation = @"portrait";
		videoMedia.creationDate = [NSDate date];
		[videoMedia setFilename:filename];
		[videoMedia setLocalURL:filepath];
		
		videoMedia.filesize = [NSNumber numberWithInt:([[attributes objectForKey: NSFileSize] intValue]/1024)];
		videoMedia.mediaType = @"video";
		videoMedia.thumbnail = UIImageJPEGRepresentation(videoThumbnail, 1.0);
		videoMedia.length = [NSNumber numberWithFloat:duration];
		CGImageRef cgVideoThumbnail = thumbnail.CGImage;
		NSUInteger videoWidth = CGImageGetWidth(cgVideoThumbnail);
		NSUInteger videoHeight = CGImageGetHeight(cgVideoThumbnail);
		videoMedia.width = [NSNumber numberWithInt:videoWidth];
		videoMedia.height = [NSNumber numberWithInt:videoHeight];
        
		[videoMedia uploadWithSuccess:^{
            if ([videoMedia isDeleted]) {
                NSLog(@"Media deleted while uploading (%@)", videoMedia);
                return;
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ShouldInsertMediaBelow" object:videoMedia];
            [videoMedia save];
        } failure:^(NSError *error) {
            [WPError showAlertWithError:error title:NSLocalizedString(@"Upload failed", @"")];
        }];
//		isAddingMedia = NO;
		
	}
	else {
//        if (currentAlert == nil) {
            UIAlertView *videoAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error Copying Video", @"")
                                                                 message:NSLocalizedString(@"There was an error copying the video for upload. Please try again.", @"")
                                                                delegate:self
                                                       cancelButtonTitle:NSLocalizedString(@"OK", @"")
                                                       otherButtonTitles:nil];
            [videoAlert show];
//            currentAlert = videoAlert;
//        }
	}
}


/*
 * Take Asset URL and set imageJPEG property to NSData containing the
 * associated JPEG, including the metadata we're after.
 */
-(void)getMetadataFromAssetForURL:(NSURL *)url {
    ALAssetsLibrary* assetslibrary = [[ALAssetsLibrary alloc] init];
    [assetslibrary assetForURL:url
				   resultBlock: ^(ALAsset *myasset) {
					   ALAssetRepresentation *rep = [myasset defaultRepresentation];
					   
					   WPLog(@"getJPEGFromAssetForURL: default asset representation for %@: uti: %@ size: %lld url: %@ orientation: %d scale: %f metadata: %@",
							 url, [rep UTI], [rep size], [rep url], [rep orientation],
							 [rep scale], [rep metadata]);
					   
					   Byte *buf = malloc([rep size]);  // will be freed automatically when associated NSData is deallocated
					   NSError *err = nil;
					   NSUInteger bytes = [rep getBytes:buf fromOffset:0LL
												 length:[rep size] error:&err];
					   if (err || bytes == 0) {
						   // Are err and bytes == 0 redundant? Doc says 0 return means
						   // error occurred which presumably means NSError is returned.
						   free(buf); // Free up memory so we don't leak.
						   WPLog(@"error from getBytes: %@", err);
						   
						   return;
					   }
					   NSData *imageJPEG = [NSData dataWithBytesNoCopy:buf length:[rep size]
														  freeWhenDone:YES];  // YES means free malloc'ed buf that backs this when deallocated
					   
					   CGImageSourceRef  source ;
					   source = CGImageSourceCreateWithData((__bridge CFDataRef)imageJPEG, NULL);
					   
                       NSDictionary *metadata = (NSDictionary *) CFBridgingRelease(CGImageSourceCopyPropertiesAtIndex(source,0,NULL));
                       
                       //make the metadata dictionary mutable so we can remove properties to it
                       NSMutableDictionary *metadataAsMutable = [metadata mutableCopy];
                       
					   if(!self.apost.blog.geolocationEnabled) {
						   //we should remove the GPS info if the blog has the geolocation set to off
						   
						   //get all the metadata in the image
						   [metadataAsMutable removeObjectForKey:@"{GPS}"];
					   }
                       [metadataAsMutable removeObjectForKey:@"Orientation"];
                       [metadataAsMutable removeObjectForKey:@"{TIFF}"];
                       self.currentImageMetadata = [NSDictionary dictionaryWithDictionary:metadataAsMutable];
					   
					   CFRelease(source);
				   }
				  failureBlock: ^(NSError *err) {
					  WPLog(@"can't get asset %@: %@", url, err);
					  self.currentImageMetadata = nil;
				  }];
}

- (MediaOrientation)interpretOrientation:(UIDeviceOrientation)theOrientation {
	MediaOrientation result = kPortrait;
	switch (theOrientation) {
		case UIDeviceOrientationPortrait:
			result = kPortrait;
			break;
		case UIDeviceOrientationPortraitUpsideDown:
			result = kPortrait;
			break;
		case UIDeviceOrientationLandscapeLeft:
			result = kLandscape;
			break;
		case UIDeviceOrientationLandscapeRight:
			result = kLandscape;
			break;
		case UIDeviceOrientationFaceUp:
			result = kPortrait;
			break;
		case UIDeviceOrientationFaceDown:
			result = kPortrait;
			break;
		case UIDeviceOrientationUnknown:
			result = kPortrait;
			break;
	}
	
	return result;
}

- (NSString *)videoPathFromVideoUrl:(NSString *)videoUrl
{
    // Determine the video's library path.
    // In iOS 6 this returns as file://localhost/private/var/mobile/Applications/73DCDAD0-397C-404D-9456-4C5A360ABE0D/tmp//trim.lmhYmN.MOV
    // In iOS 7 this returns as file:///private/var/mobile/Applications/9946F4C5-5B16-4EA5-850C-DDA701A47E61/tmp/trim.4F72621B-04AE-47F2-A551-068F62E8D16F.MOV
    
    NSError *error;
    NSRegularExpression *regEx = [NSRegularExpression regularExpressionWithPattern:@"(/var.*$)" options:NSRegularExpressionCaseInsensitive error:&error];
    NSString *videoPath = videoUrl;
    NSArray *matches = [regEx matchesInString:videoUrl options:0 range:NSMakeRange(0, [videoUrl length])];
    for (NSTextCheckingResult *result in matches) {
        if ([result numberOfRanges] < 2)
            continue;
        NSRange videoUrlRange = [result rangeAtIndex:1];
        videoPath = [videoUrl substringWithRange:videoUrlRange];
    }
    
    return videoPath;
}

#pragma mark - Image Methods

- (UIImage *)generateThumbnailFromImage:(UIImage *)theImage andSize:(CGSize)targetSize {
    return [theImage thumbnailImage:75 transparentBorder:0 cornerRadius:0 interpolationQuality:kCGInterpolationHigh];
}

- (UIImage *)resizeImage:(UIImage *)original toSize:(MediaResize)resize {
    NSDictionary* predefDim = [self.apost.blog getImageResizeDimensions];
    CGSize smallSize =  [[predefDim objectForKey: @"smallSize"] CGSizeValue];
    CGSize mediumSize = [[predefDim objectForKey: @"mediumSize"] CGSizeValue];
    CGSize largeSize =  [[predefDim objectForKey: @"largeSize"] CGSizeValue];
    switch (_currentImage.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            smallSize = CGSizeMake(smallSize.height, smallSize.width);
            mediumSize = CGSizeMake(mediumSize.height, mediumSize.width);
            largeSize = CGSizeMake(largeSize.height, largeSize.width);
            break;
        default:
            break;
    }
    
    CGSize originalSize = CGSizeMake(_currentImage.size.width, _currentImage.size.height); //The dimensions of the image, taking orientation into account.
	
	// Resize the image using the selected dimensions
	UIImage *resizedImage = original;
	switch (resize) {
		case kResizeSmall:
			if(_currentImage.size.width > smallSize.width  || _currentImage.size.height > smallSize.height)
				resizedImage = [original resizedImageWithContentMode:UIViewContentModeScaleAspectFit
															  bounds:smallSize
												interpolationQuality:kCGInterpolationHigh];
			else
				resizedImage = [original resizedImageWithContentMode:UIViewContentModeScaleAspectFit
															  bounds:originalSize
												interpolationQuality:kCGInterpolationHigh];
			break;
		case kResizeMedium:
			if(_currentImage.size.width > mediumSize.width  || _currentImage.size.height > mediumSize.height)
				resizedImage = [original resizedImageWithContentMode:UIViewContentModeScaleAspectFit
															  bounds:mediumSize
												interpolationQuality:kCGInterpolationHigh];
			else
				resizedImage = [original resizedImageWithContentMode:UIViewContentModeScaleAspectFit
															  bounds:originalSize
												interpolationQuality:kCGInterpolationHigh];
			break;
		case kResizeLarge:
			if(_currentImage.size.width > largeSize.width || _currentImage.size.height > largeSize.height)
				resizedImage = [original resizedImageWithContentMode:UIViewContentModeScaleAspectFit
															  bounds:largeSize
												interpolationQuality:kCGInterpolationHigh];
			else
				resizedImage = [original resizedImageWithContentMode:UIViewContentModeScaleAspectFit
															  bounds:originalSize
												interpolationQuality:kCGInterpolationHigh];
			break;
		case kResizeOriginal:
			resizedImage = [original resizedImageWithContentMode:UIViewContentModeScaleAspectFit
														  bounds:originalSize
											interpolationQuality:kCGInterpolationHigh];
			break;
	}
    
	
	return resizedImage;
}

/* Used in Custom Dimensions Resize */
- (UIImage *)resizeImage:(UIImage *)original width:(CGFloat)width height:(CGFloat)height {
	UIImage *resizedImage = original;
	if(_currentImage.size.width > width || _currentImage.size.height > height) {
		// Resize the image using the selected dimensions
		resizedImage = [original resizedImageWithContentMode:UIViewContentModeScaleAspectFit
													  bounds:CGSizeMake(width, height)
										interpolationQuality:kCGInterpolationHigh];
	} else {
		//use the original dimension
		resizedImage = [original resizedImageWithContentMode:UIViewContentModeScaleAspectFit
													  bounds:CGSizeMake(_currentImage.size.width, _currentImage.size.height)
										interpolationQuality:kCGInterpolationHigh];
	}
	
	return resizedImage;
}


@end


