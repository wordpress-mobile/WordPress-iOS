#import "MediaBrowserViewController.h"
#import "Blog.h"
#import "MediaBrowserCell.h"
#import "Media.h"
#import "MediaSearchFilterHeaderView.h"
#import "EditMediaViewController.h"
#import "UIImage+Resize.h"
#import "WordPressAppDelegate.h"
#import "WPLoadingView.h"
#import "WPNoResultsView.h"
#import "Post.h"
#import "WPAlertView.h"
#import <ImageIO/ImageIO.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>
#import "ContextManager.h"
#import "BlogService.h"

static NSString *const MediaCellIdentifier = @"media_cell";
static NSUInteger const MediaTypeActionSheetVideo = 1;
static CGFloat const ScrollingVelocityThreshold = 30.0f;

NSString *const MediaShouldInsertBelowNotification = @"MediaShouldInsertBelowNotification";
NSString *const MediaFeaturedImageSelectedNotification = @"MediaFeaturedImageSelectedNotification";

@interface MediaBrowserViewController () <UICollectionViewDataSource, UICollectionViewDelegate, MediaBrowserCellMultiSelectDelegate, UIAlertViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate, NSFetchedResultsControllerDelegate, WPNoResultsViewDelegate>

@property (nonatomic, strong) AbstractPost *post;
@property (weak, nonatomic) IBOutlet MediaSearchFilterHeaderView *filterHeaderView;
@property (nonatomic, strong) NSArray *filteredMedia, *allMedia;
@property (nonatomic, strong) NSArray *mediaTypeFilterOptions, *dateFilteringOptions;
@property (nonatomic, strong) NSMutableDictionary *selectedMedia;
@property (nonatomic, weak) UIRefreshControl *refreshHeaderView;
@property (nonatomic, weak) UIActionSheet *currentActionSheet, *changeOrientationActionSheet, *resizeActionSheet;
@property (nonatomic, strong) UIImagePickerController *picker;
@property (nonatomic, strong) UIPopoverController *addPopover;
@property (nonatomic, strong) NSString *currentSearchText;
@property (nonatomic, strong) NSDate *currentFilterMonth;
@property (nonatomic, strong) WPLoadingView *loadingView;
@property (nonatomic, weak) WPNoResultsView *noMediaView;
@property (nonatomic, assign) BOOL videoPressEnabled, selectingFeaturedImage, selectingDeviceFromLibrary, selectingMediaForPost;
@property (nonatomic, strong) NSMutableDictionary *currentVideo;
@property (nonatomic, strong) UIImage *currentImage;
@property (nonatomic, strong) NSDictionary *currentImageMetadata;
@property (nonatomic, assign) MediaOrientation currentOrientation;
@property (nonatomic, strong) WPAlertView *customSizeAlert;
@property (nonatomic, assign) CGFloat lastScrollOffset;
@property (nonatomic, assign) BOOL isScrollingFast;
@property (nonatomic, strong) NSFetchedResultsController *resultsController;
@property (nonatomic, assign) BOOL shouldUpdateFromContextChange, mediaInserted;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) NSArray *generatedMonthFilters;

@property (weak, nonatomic) IBOutlet UIToolbar *multiselectToolbar;

@end

@implementation MediaBrowserViewController

- (void)dealloc
{
    self.collectionView.delegate = nil;
}

- (id)initWithPost:(AbstractPost *)post {
    self = [super init];
    if (self) {
        _post = post;
        _blog = post.blog;
        _selectingFeaturedImage = NO;
        _selectingMediaForPost = NO;
    }
    return self;
}

- (id)initWithPost:(AbstractPost *)post selectingMediaForPost:(BOOL)selectingMediaForPost {
    self = [self initWithPost:post];
    if (self) {
        _selectingMediaForPost = selectingMediaForPost;
    }
    return self;
}

- (id)initWithPost:(AbstractPost *)post selectingFeaturedImage:(BOOL)selectingFeaturedImage {
    self = [self initWithPost:post];
    if (self) {
        _selectingFeaturedImage = selectingFeaturedImage;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self updateTitle];
    
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    self.collectionView.alwaysBounceVertical = YES;
    [self.collectionView registerClass:[MediaBrowserCell class] forCellWithReuseIdentifier:MediaCellIdentifier];
    [self.collectionView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"header"];
    
    [self.collectionView addSubview:_filterHeaderView];
    _filterHeaderView.delegate = self;
    
    UIRefreshControl *refreshHeaderView = [[UIRefreshControl alloc] initWithFrame:CGRectMake(0.0f, 0.0f - self.collectionView.bounds.size.height, self.collectionView.frame.size.width, self.collectionView.bounds.size.height)];
    _refreshHeaderView = refreshHeaderView;
    [_refreshHeaderView addTarget:self action:@selector(refreshControlTriggered:) forControlEvents:UIControlEventValueChanged];
    _refreshHeaderView.tintColor = [WPStyleGuide whisperGrey];
    [self.collectionView addSubview:_refreshHeaderView];
    
    UIBarButtonItem *addMediaButton;
    UIImage *image = [UIImage imageNamed:@"icon-posts-add"];
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, image.size.width, image.size.height)];
    [button setImage:image forState:UIControlStateNormal];
    [button addTarget:self action:@selector(addMediaButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    addMediaButton = [[UIBarButtonItem alloc] initWithCustomView:button];
    
    [WPStyleGuide setRightBarButtonItemWithCorrectSpacing:addMediaButton forNavigationItem:self.navigationItem];
    
    [self.view addSubview:self.multiselectToolbar];
    
    self.multiselectToolbar.barTintColor = [WPStyleGuide littleEddieGrey];
    self.multiselectToolbar.translucent = NO;
    
    self.multiselectToolbar.frame = (CGRect) {
        .origin = CGPointMake(self.multiselectToolbar.frame.origin.x, CGRectGetMaxY(self.collectionView.frame)),
        .size = self.multiselectToolbar.frame.size
    };
    
    if (![self showAttachedMedia]) {
        self.resultsController.delegate = self;
        [self.resultsController performFetch:nil];
        self.filteredMedia = _allMedia = _resultsController.fetchedObjects;
    }
    
    [self refresh];
   
    [self checkVideoPressEnabled];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (_currentActionSheet) {
        [_currentActionSheet dismissWithClickedButtonIndex:_currentActionSheet.cancelButtonIndex animated:YES];
    }
    if (_addPopover) {
        [_addPopover dismissPopoverAnimated:YES];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if ([self showAttachedMedia]) {
        _allMedia = self.post.media.allObjects;
        self.filteredMedia = _allMedia;
    }
    
    [self applyMonthFilterForMonth:_currentFilterMonth];
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

- (void)updateTitle {
    if ([self showAttachedMedia]) {
        self.title = NSLocalizedString(@"Post Media", @"");
    } else {
        self.title = NSLocalizedString(@"Media Library", @"");
    }
    
    NSString *count = [NSString stringWithFormat:@" (%d)", _filteredMedia.count];
    self.title = [self.title stringByAppendingString:count];
}

- (BOOL)showAttachedMedia {
    return self.post && !_selectingFeaturedImage && !_selectingMediaForPost;
}

- (void)refresh {
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:context];
    
    [blogService syncMediaLibraryForBlog:self.blog success:^{
        [_refreshHeaderView endRefreshing];
        [self setUploadButtonEnabled:YES];
    } failure:^(NSError *error) {
        DDLogError(@"Failed to refresh media library %@", error);
        [WPError showNetworkingAlertWithError:error];
        if (error.code == 401) {
            [self setUploadButtonEnabled:NO];
        }
        [_refreshHeaderView endRefreshing];
    }];
}

- (void)setUploadButtonEnabled:(BOOL)enabled {
    ((UIButton*)[self.navigationItem.rightBarButtonItems[1] customView]).enabled = enabled;
}

- (NSFetchedResultsController *)resultsController {
    if (!_resultsController) {
        NSManagedObjectContext *context = self.blog.managedObjectContext;
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([Media class])];
        fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"blog == %@", self.blog];
        if (_selectingFeaturedImage) {
            NSPredicate *mediaTypePredicate = [NSPredicate predicateWithFormat:@"mediaTypeString == %@", [Media mediaTypeForFeaturedImage]];
            predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate, mediaTypePredicate]];
        }
        fetchRequest.predicate = predicate;
        fetchRequest.fetchBatchSize = 10;
        _resultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:context sectionNameKeyPath:nil cacheName:nil];
    }
    return _resultsController;
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

- (NSDateFormatter *)dateFormatter {
    if (_dateFormatter) {
        return _dateFormatter;
    }
    
    _dateFormatter = [[NSDateFormatter alloc] init];
    _dateFormatter.locale = [NSLocale currentLocale];
    return _dateFormatter;
}

- (void)toggleNoMediaView:(BOOL)show {
    if (!show) {
        [_noMediaView removeFromSuperview];
    }
    if (!_noMediaView && show) {
        NSString *title = NSLocalizedString(@"No media has been added to your library", nil);
        if ([self showAttachedMedia]) {
            title = NSLocalizedString(@"No media has been attached to your post", nil);
        } else if (_currentSearchText || _currentFilterMonth) {
            title = NSLocalizedString(@"Nothing matches that search", nil);
        }
        UIImageView *mediaThumbnail = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"media_image"]];
        WPNoResultsView *noMediaView = [WPNoResultsView noResultsViewWithTitle:title message:nil accessoryView:mediaThumbnail buttonTitle:NSLocalizedString(@"Add Media", nil)];
        _noMediaView = noMediaView;
        _noMediaView.delegate = self;
        [self.collectionView addSubview:_noMediaView];
    }
}

- (void)didTapNoResultsView:(WPNoResultsView *)noResultsView {
    [self addMediaButtonPressed];
}


#pragma mark - Setters

- (void)setFilteredMedia:(NSArray *)filteredMedia {
    _filteredMedia = filteredMedia;
    
    [self applyFilterForSelectedMedia];
    
    [self toggleNoMediaView:(_filteredMedia.count == 0)];
    
    [self updateTitle];
    [self.collectionView reloadData];
}


#pragma mark - MediaSearchFilterDelegate

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
    
    NSArray *mediaToFilter = _currentFilterMonth ? _filteredMedia : _allMedia;
    _currentSearchText = searchText;
    self.filteredMedia = [mediaToFilter filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self.title CONTAINS[cd] %@ OR self.caption CONTAINS[cd] %@ OR self.desc CONTAINS[cd] %@", searchText, searchText, searchText]];
}

- (void)applyMonthFilterForMonth:(NSDate *)month {
    if (!month) {
        [self clearMonthFilter];
        return;
    }
    NSRange daysInMonth = [[NSCalendar currentCalendar] rangeOfUnit:NSDayCalendarUnit inUnit:NSMonthCalendarUnit forDate:month];
    NSDate *filterMonthEnd = [month dateByAddingTimeInterval:daysInMonth.length*24*60*60];
    
    NSArray *mediaToFilter = _currentSearchText ? _filteredMedia : _allMedia;
    _currentFilterMonth = month;
    self.filteredMedia = [mediaToFilter filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(creationDate >= %@) AND (creationDate <= %@)", month, filterMonthEnd]];
}

- (void)clearSearchFilter {
    _currentSearchText = nil;
    self.filteredMedia = _allMedia;
    if (_currentFilterMonth) {
        [self applyMonthFilterForMonth:_currentFilterMonth];
    }
}

- (void)clearMonthFilter {
    _currentFilterMonth = nil;
    [self.filterHeaderView resetFilters];
    self.filteredMedia = _allMedia;
    if (_currentSearchText) {
        [self applyFilterWithSearchText:_currentSearchText];
    }
}

- (NSArray *)possibleMonthsAndYears {
    if (_generatedMonthFilters) {
        return _generatedMonthFilters;
    }
    
    NSMutableOrderedSet *monthsYearsSet = [NSMutableOrderedSet orderedSet];
    NSArray *monthNames = [self.dateFormatter standaloneMonthSymbols];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    [_allMedia enumerateObjectsUsingBlock:^(Media *obj, NSUInteger idx, BOOL *stop) {
        NSDateComponents *components = [calendar components:NSMonthCalendarUnit|NSYearCalendarUnit fromDate:obj.creationDate];
        NSString *monthYear = [NSString stringWithFormat:@"%@ %d", monthNames[components.month-1], components.year];
        [monthsYearsSet addObject:monthYear];
    }];
    _generatedMonthFilters = monthsYearsSet.array;
    return _generatedMonthFilters;
}

- (void)clearGeneratedMonthFilters {
    _generatedMonthFilters = nil;
}

- (void)selectedMonthPickerIndex:(NSInteger)index {
    self.dateFormatter.dateFormat = @"MMMM yyyy";
    self.dateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
    NSDate *filterMonthStart = [self.dateFormatter dateFromString:_generatedMonthFilters[index]];
    [self applyMonthFilterForMonth:filterMonthStart];
}


#pragma mark - CollectionViewDelegate/DataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return [self showAttachedMedia] ? 1 : [self.resultsController sections].count;
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
    cell.hideCheckbox = _selectingFeaturedImage || _selectingMediaForPost;
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
            [WPAnalytics track:WPAnalyticsStatEditorAddedPhotoViaLocalLibrary];
        } failure:^(NSError *error) {
            [WPError showAlertWithTitle:NSLocalizedString(@"Upload failed", nil) message:error.localizedDescription];
        }];
    } else if (cell.media.remoteStatus == MediaRemoteStatusProcessing || cell.media.remoteStatus == MediaRemoteStatusPushing) {
        [cell.media cancelUpload];
    } else if (cell.media.remoteStatus == MediaRemoteStatusLocal || cell.media.remoteStatus == MediaRemoteStatusSync) {
        if (cell.media.remoteStatus == MediaRemoteStatusLocal) {
            [WPAnalytics track:WPAnalyticsStatEditorAddedPhotoViaLocalLibrary];
        } else {
            [WPAnalytics track:WPAnalyticsStatEditorAddedPhotoViaWPMediaLibrary];
        }
        if (_selectingFeaturedImage) {
            [self.post setFeaturedImage:cell.media];
            [[NSNotificationCenter defaultCenter] postNotificationName:MediaFeaturedImageSelectedNotification object:cell.media];
            [self.navigationController popViewControllerAnimated:YES];
        } else if (_selectingMediaForPost) {
            [self.post.media addObject:cell.media];
            [[NSNotificationCenter defaultCenter] postNotificationName:MediaShouldInsertBelowNotification object:cell.media];
            [self.navigationController popViewControllerAnimated:YES];
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
        message = NSLocalizedString(@"Are you sure you wish to remove these items from the post?", nil);
        destructiveButtonTitle = NSLocalizedString(@"Remove", @"");
    } else {
        message = NSLocalizedString(@"Are you sure you wish to permanently delete the selected items?", nil);
        destructiveButtonTitle = NSLocalizedString(@"Delete", @"");
    }
    UIAlertView *confirmation = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Delete Media", nil) message:message delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"") otherButtonTitles:destructiveButtonTitle, nil];
    [confirmation show];
}

- (IBAction)multiselectDeselectAllPressed:(id)sender {
    [_selectedMedia removeAllObjects];
    [self showMultiselectOptions];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        // Remove items from post only, in attached media state
        if ([self showAttachedMedia]) {
            [_selectedMedia enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"ShouldRemoveMedia" object:obj];
                [self.post.media removeObject:obj];
            }];
            _allMedia = self.post.media.allObjects;
            self.filteredMedia = _allMedia;
            [self toggleNoMediaView:(self.post.media.count == 0)];
            [_selectedMedia removeAllObjects];
            [self showMultiselectOptions];
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
            [self.loadingView hide];
            [self.loadingView removeFromSuperview];
            
            for (id subview in self.view.subviews) {
                if ([subview respondsToSelector:@selector(setUserInteractionEnabled:)]) {
                    [subview setUserInteractionEnabled:YES];
                }
            }
            
        } failure:^(NSError *error, NSArray *failures) {
            DDLogError(@"Failed to delete media %@ with error %@", failures, error);
            
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
    _isScrollingFast = NO;
    [self.collectionView.visibleCells enumerateObjectsUsingBlock:^(MediaBrowserCell *obj, NSUInteger idx, BOOL *stop) {
        [obj loadThumbnail];
    }];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    _isScrollingFast = fabsf(self.collectionView.contentOffset.y - _lastScrollOffset) > ScrollingVelocityThreshold;
    _lastScrollOffset = self.collectionView.contentOffset.y;
}

#pragma mark - FetchedResultsController

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    _shouldUpdateFromContextChange = (type == NSFetchedResultsChangeDelete || type == NSFetchedResultsChangeInsert || type == NSFetchedResultsChangeMove);
    if (type == NSFetchedResultsChangeDelete || type == NSFetchedResultsChangeInsert) {
        [self clearGeneratedMonthFilters];
    }
    _mediaInserted = (type == NSFetchedResultsChangeInsert);
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    // Apply the filters IFF we didn't insert. Having a filter selected for
    // a month other than the current, results in no visual for the upload
    if (_shouldUpdateFromContextChange) {
        _allMedia = controller.fetchedObjects;
        self.filteredMedia = _allMedia;
        if (_mediaInserted) {
            [self clearMonthFilter];
            [self clearSearchFilter];
        } else {
            [self applyFilterWithSearchText:_currentSearchText];
            [self applyMonthFilterForMonth:_currentFilterMonth];
        }
    }
}

#pragma mark - Add Media

- (void)checkVideoPressEnabled {
    self.videoPressEnabled = self.blog.videoPressEnabled;
    
    // Check IFF the blog doesn't already have it enabled
    // The blog's transient property will last only for an in-memory session
    if (!self.blog.videoPressEnabled) {
        NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
        BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:context];
        
        [blogService checkVideoPressEnabledForBlog:self.blog success:^(BOOL enabled) {
            self.videoPressEnabled = enabled;
            self.blog.videoPressEnabled = enabled;
        } failure:^(NSError *error) {
            DDLogWarn(@"checkVideoPressEnabled failed: %@", [error localizedDescription]);
            self.videoPressEnabled = NO;
            self.blog.videoPressEnabled = NO;
        }];
    }
}

- (BOOL)deviceSupportsVideo {
	return (([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) &&
            ([[UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera] containsObject:(NSString *)kUTTypeMovie]));
}

- (BOOL)deviceSupportsVideoAndVideoEnabled {
	return ([self deviceSupportsVideo] && (self.videoPressEnabled || !self.blog.isWPcom));
}

- (IBAction)addMediaButtonPressed {
    if ([self showAttachedMedia]) {
        MediaBrowserViewController *vc = [[MediaBrowserViewController alloc] initWithPost:self.post selectingMediaForPost:YES];
        [self.navigationController pushViewController:vc animated:YES];
    } else {
        if (_currentActionSheet) {
            return;
        }
        
        UIActionSheet *addMediaActionSheet;
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
            if ([self deviceSupportsVideoAndVideoEnabled]) {
                addMediaActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Add Photo From Library", nil), NSLocalizedString(@"Take Photo", nil), NSLocalizedString(@"Add Video from Library", @""), NSLocalizedString(@"Record Video", @""),nil];
                
            } else {
                addMediaActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Add Photo From Library", nil), NSLocalizedString(@"Take Photo", nil), nil];
            }
        } else {
            addMediaActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Add Photo From Library", nil), nil];
        }
        
        _currentActionSheet = addMediaActionSheet;
        
        if (IS_IPAD) {
            UIBarButtonItem *barButtonItem = self.navigationItem.rightBarButtonItems[1];
            [_currentActionSheet showFromBarButtonItem:barButtonItem animated:YES];
        } else {
            if (self.presentingViewController) {
                [_currentActionSheet showInView:self.view];
            } else {
                [_currentActionSheet showFromTabBar:[WordPressAppDelegate sharedWordPressApplicationDelegate].tabBarController.tabBar];
            }
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
        [self pickMediaFromLibrary:actionSheet];
    
    } else if ([buttonTitle isEqualToString:NSLocalizedString(@"Take Photo", nil)]) {
       [self pickPhotoFromCamera:nil];
    
    } else if ([buttonTitle isEqualToString:NSLocalizedString(@"Add Video from Library", nil)]) {
       actionSheet.tag = MediaTypeActionSheetVideo;
       [self pickMediaFromLibrary:actionSheet];
    
    } else if ([buttonTitle isEqualToString:NSLocalizedString(@"Record Video", nil)]) {
       [self pickVideoFromCamera:actionSheet];
    }
}

- (void)processResizeSelection:(NSUInteger)buttonIndex actionSheet:(UIActionSheet*)actionSheet {
    if (actionSheet.cancelButtonIndex == buttonIndex) {
        return;
    }
    
    // 6 button: small, medium, large, original, custom, cancel
    // 5 buttons: small, medium, original, custom, cancel
    // 4 buttons: small, original, custom, cancel
    // 3 buttons: original, custom, cancel
    // The last three buttons are always the same, so we can count down, then count up and avoid alot of branching.
    if (buttonIndex == actionSheet.numberOfButtons - 1) {
        // cancel button. Noop.
    } else if (buttonIndex == actionSheet.numberOfButtons - 2) {
        // custom
        [self showCustomSizeAlert];
    } else if (buttonIndex == actionSheet.numberOfButtons - 3) {
        // original
        [self useImage:[self resizeImage:_currentImage toSize:MediaResizeOriginal]];
    } else if (buttonIndex == 0) {
        // small
        [self useImage:[self resizeImage:_currentImage toSize:MediaResizeSmall]];
    } else if (buttonIndex == 1) {
        // medium
        [self useImage:[self resizeImage:_currentImage toSize:MediaResizeMedium]];
    } else if (buttonIndex == 2) {
        // large
        [self useImage:[self resizeImage:_currentImage toSize:MediaResizeLarge]];
    }
}

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
    
        [self.view addSubview:alertView];
    
    [UIView animateWithDuration:0.2 animations:^{
        alertView.alpha = 1.0;
    }];
    
    self.customSizeAlert = alertView;
}

- (void)showResizeActionSheet {
	if (!_resizeActionSheet) {
        Blog *currentBlog = self.blog;
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
		if (_currentImage.size.width > largeSize.width  && _currentImage.size.height > largeSize.height) {
			resizeActionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Choose Image Size", @"")
															delegate:self
												   cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
											  destructiveButtonTitle:nil
												   otherButtonTitles:resizeSmallStr, resizeMediumStr, resizeLargeStr, originalSizeStr, NSLocalizedString(@"Custom", @""), nil];
			
		} else if (_currentImage.size.width > mediumSize.width  && _currentImage.size.height > mediumSize.height) {
			resizeActionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Choose Image Size", @"")
															delegate:self
												   cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
											  destructiveButtonTitle:nil
												   otherButtonTitles:resizeSmallStr, resizeMediumStr, originalSizeStr, NSLocalizedString(@"Custom", @""), nil];
			
		} else if (_currentImage.size.width > smallSize.width  && _currentImage.size.height > smallSize.height) {
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
        
        if (IS_IPAD) {
            [resizeActionSheet showFromBarButtonItem:[self.navigationItem.rightBarButtonItems objectAtIndex:1] animated:YES];
        } else {
            if (self.presentingViewController) {
                [resizeActionSheet showInView:self.view];
            } else {
                [resizeActionSheet showFromTabBar:[WordPressAppDelegate sharedWordPressApplicationDelegate].tabBarController.tabBar];
            }
        }
	}
}

- (UIImagePickerController *)resetImagePicker {
    _picker = [[UIImagePickerController alloc] init];
    _picker.delegate = nil;
    _picker.navigationBar.translucent = NO;
	_picker.delegate = self;
    _picker.allowsEditing = NO;
    return _picker;
}

- (UIImagePickerControllerQualityType)videoQualityPreference {
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"video_quality_preference"]) {
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
    return UIImagePickerControllerQualityTypeMedium;
}

- (void)pickMediaFromLibrary:(id)sender {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        [self resetImagePicker];
        _picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        if (self.videoPressEnabled || ![self.blog isWPcom]) {
            _picker.mediaTypes = [NSArray arrayWithObjects: (NSString *)kUTTypeMovie, (NSString *)kUTTypeImage, nil];
        } else {
            _picker.mediaTypes = [NSArray arrayWithObjects:(NSString *)kUTTypeImage, nil];
        }
        _picker.videoQuality = UIImagePickerControllerQualityTypeMedium;
        _selectingDeviceFromLibrary = YES;
        
        if ([(UIView *)sender tag] == MediaTypeActionSheetVideo) {
            _picker.mediaTypes = [NSArray arrayWithObject:(NSString *)kUTTypeMovie];
			_picker.videoQuality = [self videoQualityPreference];
            _picker.modalPresentationStyle = UIModalPresentationCurrentContext;
        }
        
        if (IS_IPAD) {
            _picker.navigationBar.barStyle = UIBarStyleBlack;
            if (!_addPopover) {
                _addPopover = [[UIPopoverController alloc] initWithContentViewController:_picker];
            }
            UIBarButtonItem *barButtonItem = self.navigationItem.rightBarButtonItems[1];
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
        if (IS_IPAD) {
            [WordPressAppDelegate sharedWordPressApplicationDelegate].tabBarController.tabBar.hidden = YES;
        }
        [self.navigationController presentViewController:_picker animated:YES completion:nil];
    }
}

- (void)pickVideoFromCamera:(id)sender {
	self.currentOrientation = [self interpretOrientation:[UIDevice currentDevice].orientation];
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [self resetImagePicker];
        _picker.sourceType =  UIImagePickerControllerSourceTypeCamera;
        _picker.mediaTypes = [NSArray arrayWithObject:(NSString *)kUTTypeMovie];
        _picker.videoQuality = [self videoQualityPreference];
        _picker.modalPresentationStyle = UIModalPresentationCurrentContext;
        if (IS_IPAD) {
            [WordPressAppDelegate sharedWordPressApplicationDelegate].tabBarController.tabBar.hidden = YES;
        }
        [self.navigationController presentViewController:_picker animated:YES completion:nil];
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [WordPressAppDelegate sharedWordPressApplicationDelegate].tabBarController.tabBar.hidden = NO;
    if (_addPopover) {
        [_addPopover dismissPopoverAnimated:YES];
    } else {
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    // Keep the status bar consistent during photo library usage...
    // iOS7 beta 6 + bug
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    [WordPressAppDelegate sharedWordPressApplicationDelegate].tabBarController.tabBar.hidden = NO;
    
 	if ([[info valueForKey:@"UIImagePickerControllerMediaType"] isEqualToString:@"public.movie"]) {
		self.currentVideo = [info mutableCopy];
		if (!self.selectingDeviceFromLibrary) {
			[self processRecordedVideo];
        } else {
        [self performSelectorOnMainThread:@selector(processLibraryVideo) withObject:nil waitUntilDone:NO];
        }
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
                if ([self.post isKindOfClass:[Post class]]) {
                    Post *post = (Post *)self.post;
                    if (!gpsData && post.geolocation) {
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
                        CLLocationDegrees latitude = post.geolocation.latitude;
                        CLLocationDegrees longitude = post.geolocation.longitude;
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
        }
		
		NSNumberFormatter *nf = [[NSNumberFormatter alloc] init];
		[nf setNumberStyle:NSNumberFormatterDecimalStyle];
		NSNumber *resizePreference = [NSNumber numberWithInt:-1];
		if([[NSUserDefaults standardUserDefaults] objectForKey:@"media_resize_preference"] != nil)
			resizePreference = [nf numberFromString:[[NSUserDefaults standardUserDefaults] objectForKey:@"media_resize_preference"]];
		BOOL showResizeActionSheet = NO;
		switch ([resizePreference intValue]) {
			case 0:
            {
                showResizeActionSheet = YES;
				break;
            }
			case 1:
            {
				[self useImage:[self resizeImage:_currentImage toSize:MediaResizeSmall]];
				break;
            }
			case 2:
            {
				[self useImage:[self resizeImage:_currentImage toSize:MediaResizeMedium]];
				break;
            }
			case 3:
            {
				[self useImage:[self resizeImage:_currentImage toSize:MediaResizeLarge]];
				break;
            }
			case 4:
            {
				//[self useImage:currentImage];
                [self useImage:[self resizeImage:_currentImage toSize:MediaResizeOriginal]];
				break;
            }
			default:
            {
                showResizeActionSheet = YES;
				break;
            }
		}
		
        if (_addPopover) {
            [_addPopover dismissPopoverAnimated:YES];
            _addPopover = nil;
            [self showResizeActionSheet];
        } else {
            [self.navigationController dismissViewControllerAnimated:YES completion:^{
                if (showResizeActionSheet) {
                    [self showResizeActionSheet];
                }
            }];
        }
        
        if (IS_IPAD){
            [_addPopover dismissPopoverAnimated:YES];
            _addPopover = nil;
        }
        
        [self refresh];
    }
}

- (void)processLibraryVideo {
	NSURL *videoURL = [_currentVideo valueForKey:UIImagePickerControllerMediaURL];
	if(videoURL == nil) {
		videoURL = [_currentVideo valueForKey:UIImagePickerControllerReferenceURL];
    }
	
	if (videoURL != nil) {
		if(IS_IPAD)
			[_addPopover dismissPopoverAnimated:YES];
		else {
            [self.navigationController dismissViewControllerAnimated:YES completion:nil];
		}
		
		[self.currentVideo setValue:[NSNumber numberWithInt:_currentOrientation] forKey:@"orientation"];
		
		[self useVideo:[self videoPathFromVideoUrl:[videoURL absoluteString]]];
		self.currentVideo = nil;
		self.selectingDeviceFromLibrary = NO;
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
    [WPAnalytics track:WPAnalyticsStatEditorAddedPhotoViaLocalLibrary];

    Media *imageMedia;
    if (self.post) {
        imageMedia = [Media newMediaForPost:self.post];
    } else {
        imageMedia = [Media newMediaForBlog:self.blog];
    }
	NSData *imageData = UIImageJPEGRepresentation(theImage, 0.90);
	UIImage *imageThumbnail = [self generateThumbnailFromImage:theImage andSize:CGSizeMake(75, 75)];
	[self.dateFormatter setDateFormat:@"yyyyMMdd-HHmmss"];
    
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	NSString *filename = [NSString stringWithFormat:@"%@.jpg", [self.dateFormatter stringFromDate:[NSDate date]]];
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
                DDLogWarn(@"***Could not create image destination ***");
            }
        } else {
            DDLogWarn(@"***Could not create image source ***");
        }
		
		if(!success) {
            DDLogWarn(@"***Could not create data from image destination ***");
			//write the data without EXIF to disk
			NSFileManager *fileManager = [NSFileManager defaultManager];
			[fileManager createFileAtPath:filepath contents:imageData attributes:nil];
		} else {
			//write it to disk
			[dest_data writeToFile:filepath atomically:YES];
		}
    } else {
		NSFileManager *fileManager = [NSFileManager defaultManager];
		[fileManager createFileAtPath:filepath contents:imageData attributes:nil];
	}
    
	if(self.currentOrientation == MediaOrientationLandscape) {
		imageMedia.orientation = @"landscape";
	} else {
		imageMedia.orientation = @"portrait";
    }
	imageMedia.creationDate = [NSDate date];
	imageMedia.filename = filename;
	imageMedia.localURL = filepath;
	imageMedia.filesize = @(imageData.length/1024);
    if (_selectingFeaturedImage) {
        imageMedia.featured = YES;
    } else {
        imageMedia.mediaType = MediaTypeImage;
    }
	imageMedia.thumbnail = UIImageJPEGRepresentation(imageThumbnail, 0.90);
	imageMedia.width = [NSNumber numberWithInt:theImage.size.width];
	imageMedia.height = [NSNumber numberWithInt:theImage.size.height];
    
    [imageMedia uploadWithSuccess:^{
        if ([imageMedia isDeleted]) {
            NSLog(@"Media deleted while uploading (%@)", imageMedia);
            return;
        }
        if (_selectingFeaturedImage) {
            [self.post setFeaturedImage:imageMedia];
            [[NSNotificationCenter defaultCenter] postNotificationName:MediaFeaturedImageSelectedNotification object:imageMedia];
        } else {
            [[NSNotificationCenter defaultCenter] postNotificationName:MediaShouldInsertBelowNotification object:imageMedia];
        }
        [imageMedia save];
    } failure:^(NSError *error) {
        if (error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled) {
            return;
        }
        
        [WPError showAlertWithTitle:NSLocalizedString(@"Upload failed", nil) message:error.localizedDescription];
    }];
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
	[self.dateFormatter setDateFormat:@"yyyyMMdd-HHmmss"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	NSString *filename = [NSString stringWithFormat:@"%@.mov", [self.dateFormatter stringFromDate:[NSDate date]]];
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
		
		if(_currentOrientation == MediaOrientationLandscape) {
			videoMedia.orientation = @"landscape";
        } else {
			videoMedia.orientation = @"portrait";
        }
		videoMedia.creationDate = [NSDate date];
		[videoMedia setFilename:filename];
		[videoMedia setLocalURL:filepath];
		
		videoMedia.filesize = [NSNumber numberWithInt:([[attributes objectForKey: NSFileSize] intValue]/1024)];
		videoMedia.mediaType = MediaTypeVideo;
		videoMedia.thumbnail = UIImageJPEGRepresentation(videoThumbnail, 1.0);
		videoMedia.length = [NSNumber numberWithFloat:duration];
		CGImageRef cgVideoThumbnail = thumbnail.CGImage;
		NSUInteger videoWidth = CGImageGetWidth(cgVideoThumbnail);
		NSUInteger videoHeight = CGImageGetHeight(cgVideoThumbnail);
		videoMedia.width = @(videoWidth);
		videoMedia.height = @(videoHeight);
        
		[videoMedia uploadWithSuccess:^{
            if ([videoMedia isDeleted]) {
                NSLog(@"Media deleted while uploading (%@)", videoMedia);
                return;
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:MediaShouldInsertBelowNotification object:videoMedia];
            [videoMedia save];
        } failure:^(NSError *error) {
            [WPError showAlertWithTitle:NSLocalizedString(@"Upload failed", nil) message:error.localizedDescription];
        }];
	}
	else {
        [WPError showAlertWithTitle:NSLocalizedString(@"Error Copying Video", nil) message:NSLocalizedString(@"There was an error copying the video for upload. Please try again.", nil)];
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
					   
					   DDLogWarn(@"getJPEGFromAssetForURL: default asset representation for %@: uti: %@ size: %lld url: %@ orientation: %d scale: %f metadata: %@",
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
						   DDLogError(@"error from getBytes: %@", err);
						   
						   return;
					   }
					   NSData *imageJPEG = [NSData dataWithBytesNoCopy:buf length:[rep size]
														  freeWhenDone:YES];  // YES means free malloc'ed buf that backs this when deallocated
					   
					   CGImageSourceRef  source ;
					   source = CGImageSourceCreateWithData((__bridge CFDataRef)imageJPEG, NULL);
					   
                       NSDictionary *metadata = (NSDictionary *) CFBridgingRelease(CGImageSourceCopyPropertiesAtIndex(source,0,NULL));
                       
                       //make the metadata dictionary mutable so we can remove properties to it
                       NSMutableDictionary *metadataAsMutable = [metadata mutableCopy];
                       
					   if (!self.post.blog.geolocationEnabled) {
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
					  DDLogError(@"can't get asset %@: %@", url, err);
					  self.currentImageMetadata = nil;
				  }];
}

- (MediaOrientation)interpretOrientation:(UIDeviceOrientation)theOrientation {
	MediaOrientation result = MediaOrientationPortrait;
	switch (theOrientation) {
		case UIDeviceOrientationLandscapeLeft:
		case UIDeviceOrientationLandscapeRight:
			result = MediaOrientationLandscape;
			break;
        case UIDeviceOrientationPortraitUpsideDown:
        case UIDeviceOrientationPortrait:
		case UIDeviceOrientationFaceUp:
		case UIDeviceOrientationFaceDown:
		case UIDeviceOrientationUnknown:
			result = MediaOrientationPortrait;
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
    NSDictionary *predefDim = [self.blog getImageResizeDimensions];
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
    
    CGSize originalSize = CGSizeMake(_currentImage.size.width, _currentImage.size.height);
	
	// Resize the image using the selected dimensions
	UIImage *resizedImage = original;
	CGSize resizeToBounds = originalSize;
    
    if (resize == MediaResizeSmall &&
        (_currentImage.size.width > smallSize.width  || _currentImage.size.height > smallSize.height)) {
        resizeToBounds = smallSize;
    }
    else if (resize == MediaResizeMedium &&
               (_currentImage.size.width > mediumSize.width || _currentImage.size.height > mediumSize.height)) {
        resizeToBounds = mediumSize;
    }
    else if (resize == MediaResizeLarge &&
               (_currentImage.size.width > largeSize.width || _currentImage.size.height > largeSize.height)) {
        resizeToBounds = largeSize;
    }
    
    if (!CGSizeEqualToSize(originalSize, resizeToBounds)) {
        resizedImage = [original resizedImageWithContentMode:UIViewContentModeScaleAspectFit
                                                      bounds:resizeToBounds
                                        interpolationQuality:kCGInterpolationHigh];
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
	}
	return resizedImage;
}


@end


