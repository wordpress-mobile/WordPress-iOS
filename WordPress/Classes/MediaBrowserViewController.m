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

static NSString *const MediaCellIdentifier = @"media_cell";

@interface MediaBrowserViewController () <UICollectionViewDataSource, UICollectionViewDelegate, MediaBrowserCellMultiSelectDelegate, UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet MediaSearchFilterHeaderView *filterHeaderView;
@property (nonatomic, strong) NSArray *filteredMedia, *allMedia;
@property (nonatomic, strong) NSArray *mediaTypeFilterOptions, *dateFilteringOptions;
@property (nonatomic, strong) NSMutableDictionary *selectedMedia;
@property (nonatomic, weak) UIRefreshControl *refreshHeaderView;
@property (nonatomic, weak) UIActionSheet *currentActionSheet;
@property (nonatomic, strong) UIImagePickerController *picker;
@property (nonatomic, strong) UIPopoverController *addPopover;
@property (nonatomic, assign) BOOL isFilteringByDate;
@property (nonatomic, strong) NSString *currentSearchText;
@property (nonatomic, strong) WPLoadingView *loadingView;
@property (nonatomic, strong) NSDate *startDate, *endDate;
@property (nonatomic, weak) UIView *firstResponderOnSidebarOpened;

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

    if (IS_IOS7) {
        self.multiselectToolbar.barTintColor = [WPStyleGuide littleEddieGrey];
    }
    self.multiselectToolbar.translucent = false;
    
    self.multiselectToolbar.frame = (CGRect) {
        .origin = CGPointMake(self.multiselectToolbar.frame.origin.x, CGRectGetMaxY(self.collectionView.frame)),
        .size = self.multiselectToolbar.frame.size
    };
    
    [self refresh];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sidebarOpened) name:SidebarOpenedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sidebarClosed) name:SidebarClosedNotification object:nil];
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
    [self applyDateFilterForStartDate:_startDate andEndDate:_endDate];
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
    } failure:^(NSError *error) {
        WPFLog(@"Failed to refresh media library");
        [WPError showAlertWithError:error];
        [_refreshHeaderView endRefreshing];
    }];
}

- (void)loadFromCache {
    NSError *error;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([Media class])];
    [fetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:false]]];
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

- (UIView *)loadingView {
    if (!_loadingView) {
        CGFloat side = 100.0f;
        WPLoadingView *loadingView = [[WPLoadingView alloc] initWithSide:side];
        loadingView.center = CGPointMake(self.view.center.x, self.view.center.y - side);
        _loadingView = loadingView;
    }
    return _loadingView;
}

#pragma mark - Setters

- (void)setFilteredMedia:(NSArray *)filteredMedia {
    _filteredMedia = filteredMedia;
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
    if (_filteredMedia) {
        return ((Media*)_filteredMedia[0]).creationDate;
    }
    return nil;
}

- (NSDate *)mediaDateRangeEnd {
    if (_filteredMedia) {
        return [[_filteredMedia lastObject] creationDate];
    }
    return nil;
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
    EditMediaViewController *viewMedia = [[EditMediaViewController alloc] initWithMedia:cell.media showEditMode:YES];
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
        // Disable interaction with other views/buttons
        for (id v in self.view.subviews) {
            if ([v respondsToSelector:@selector(setUserInteractionEnabled:)]) {
                [v setUserInteractionEnabled:NO];
            }
        }
        
        [self.view addSubview:self.loadingView];
        [self.loadingView show];
        
        [Media bulkDeleteMedia:[_selectedMedia allValues] withSuccess:^(NSArray *successes) {
            NSLog(@"Successfully deleted %@", successes);
            
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
            [self.loadingView hide];
            [self.loadingView removeFromSuperview];
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
            [self takePhoto];
            break;
        case 1:
            [self takeVideo];
            break;
        case 2:
            [self pickMediaFromLibrary];
//            [self.navigationController pushViewController:vc animated:YES];
            break;
        default:;
            // Cancelled
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

- (void)pickMediaFromLibrary {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        [self resetImagePicker];
        _picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        _picker.mediaTypes = [NSArray arrayWithObjects:(NSString *)kUTTypeMovie, (NSString *)kUTTypeImage, nil];
        _picker.videoQuality = UIImagePickerControllerQualityTypeMedium;
        
        if (IS_IPAD) {
            if (!_addPopover) {
                _addPopover = [[UIPopoverController alloc] initWithContentViewController:_picker];
                
                if ([_addPopover respondsToSelector:@selector(popoverBackgroundViewClass)] && !IS_IOS7) {
                    _addPopover.popoverBackgroundViewClass = [WPPopoverBackgroundView class];
                }
            }
            
            [_addPopover presentPopoverFromBarButtonItem:self.navigationItem.rightBarButtonItem permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        }
        else {
            [self.navigationController presentViewController:_picker animated:YES completion:nil];
        }
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    if ([[info valueForKey:@"UIImagePickerControllerMediaType"] isEqualToString:@"public.image"]) {
        //create media item
        UIImage *image;
        if ([info valueForKey:UIImagePickerControllerEditedImage]) {
            image = [info valueForKey:UIImagePickerControllerEditedImage];
        } else {
            image = [info valueForKey:UIImagePickerControllerOriginalImage];
        }
        
        NSData *imageData = UIImageJPEGRepresentation(image, 0.90);
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyyMMdd-HHmmss"];
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *filename = [NSString stringWithFormat:@"%@.jpg", [formatter stringFromDate:[NSDate date]]];
        NSString *filepath = [documentsDirectory stringByAppendingPathComponent:filename];
        
        Media *imageMedia;
        imageMedia.blog = self.blog;
        imageMedia.creationDate = [NSDate date];
        imageMedia.filename = filename;
        imageMedia.localURL = filepath;
        imageMedia.filesize = [NSNumber numberWithInt:(imageData.length/1024)];
        imageMedia.mediaType = @"image";
        imageMedia.width = [NSNumber numberWithInt:image.size.width];
        imageMedia.height = [NSNumber numberWithInt:image.size.height];
        imageMedia.thumbnail = UIImageJPEGRepresentation([image thumbnailImage:75 transparentBorder:0 cornerRadius:0 interpolationQuality:kCGInterpolationHigh], 0.9);
        
        //add media item
        [imageMedia uploadWithSuccess:^{
            if ([imageMedia isDeleted]) {
                NSLog(@"Media deleted while uploading (%@)", imageMedia);
                return;
            }
            [imageMedia save];
        } failure:^(NSError *error) {
            if (error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled) {
                return;
            }
            
            [WPError showAlertWithError:error title:NSLocalizedString(@"Upload failed", @"")];
        }];
    }
//    else if ([[info valueForKey:@"UIImagePickerControllerMediaType"] isEqualToString:@"public.movie"]) {
//        
//        NSString* videoURL;
//        
//        NSURL *contentURL;
//        AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:contentURL options:[NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool:YES], AVURLAssetPreferPreciseDurationAndTimingKey, nil]];
//        
//        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
//        [formatter setDateFormat:@"yyyyMMdd-HHmmss"];
//        NSFileManager *fileManager = [NSFileManager defaultManager];
//        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//        NSString *documentsDirectory = [paths objectAtIndex:0];
//        NSString *filename = [NSString stringWithFormat:@"%@.mov", [formatter stringFromDate:[NSDate date]]];
//        NSString *filepath = [documentsDirectory stringByAppendingPathComponent:filename];
//        
//        Media *videoMedia;
//        videoMedia.blog = self.blog;
//        videoMedia.creationDate = [NSDate date];
//        videoMedia.filename = filename;
//        videoMedia.localURL = filepath;
//
//    }
    
    [self refresh];
}


@end
