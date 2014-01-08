//
//  PostMediaViewController.m
//  WordPress
//
//  Created by Chris Boyd on 8/26/10.
//  Code is poetry.
//

#import "PostMediaViewController.h"
#import "EditPostViewController_Internal.h"
#import "Post.h"
#import <ImageIO/ImageIO.h>
#import "ContextManager.h"

#define TAG_ACTIONSHEET_PHOTO 1
#define TAG_ACTIONSHEET_VIDEO 2
#define TAG_ACTIONSHEET_PHOTO_SELECTION_PROMPT 3
#define NUMBERS	@"0123456789"


@interface PostMediaViewController ()

@property (nonatomic, strong) AbstractPost *apost;
@property (nonatomic, weak) UIActionSheet *addMediaActionSheet;

- (void)getMetadataFromAssetForURL:(NSURL *)url;
- (UITableViewCell *)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;

@end

@implementation PostMediaViewController {
    CGRect actionSheetRect;
    UIAlertView *currentAlert;
    
    BOOL _dismissOnCancel;
    BOOL _hasPromptedToAddPhotos;
}


#pragma mark -
#pragma mark Lifecycle Methods

- (void)dealloc {
    _picker.delegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithPost:(AbstractPost *)aPost {
    self = [super init];
    if (self) {
        self.apost = aPost;
        [self initObjects];
    }
    return self;
}

- (void)initObjects {
	self.photos = [[NSMutableArray alloc] init];
	self.videos = [[NSMutableArray alloc] init];
    actionSheetRect = CGRectZero;
}

- (void)viewDidLoad {
    DDLogInfo(@"%@ %@", self, NSStringFromSelector(_cmd));
    [super viewDidLoad];
    
    self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 10)];

    self.title = NSLocalizedString(@"Media", nil);
	
	self.currentOrientation = [self interpretOrientation:[UIDevice currentDevice].orientation];
		
	[self initObjects];
	self.videoEnabled = YES;
    [self checkVideoPressEnabled];
    [self addNotifications];
    
    UIImage *image = [UIImage imageNamed:@"icon-posts-add"];
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, image.size.width, image.size.height)];
    [button setImage:image forState:UIControlStateNormal];
    [button addTarget:self action:@selector(tappedAddButton) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithCustomView:button];
    
    [WPStyleGuide setRightBarButtonItemWithCorrectSpacing:addButton forNavigationItem:self.navigationItem];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!_hasPromptedToAddPhotos) {
        id <NSFetchedResultsSectionInfo> sectionInfo = nil;
        sectionInfo = [[self.resultsController sections] objectAtIndex:0];
        if ([sectionInfo numberOfObjects] == 0) {
            _dismissOnCancel = YES;;
            [self tappedAddButton];
        }
    }
    _hasPromptedToAddPhotos = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (_currentActionSheet) {
        [_currentActionSheet dismissWithClickedButtonIndex:_currentActionSheet.cancelButtonIndex animated:YES];
    }
    
    [[[CPopoverManager instance] currentPopoverController] dismissPopoverAnimated:YES];
}

- (NSString *)statsPrefix {
    if (_statsPrefix == nil)
        return @"Post Detail";
    else
        return _statsPrefix;
}

- (void)tappedAddButton {
    if (_addMediaActionSheet != nil || self.isShowingResizeActionSheet == YES)
        return;

    if (_addPopover != nil) {
        [_addPopover dismissPopoverAnimated:YES];
        [[CPopoverManager instance] setCurrentPopoverController:nil];
        _addPopover = nil;
    }
    
    UIActionSheet *addMediaActionSheet;
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        if ([self isDeviceSupportVideoAndVideoPressEnabled]) {
            addMediaActionSheet = [[UIActionSheet alloc] initWithTitle:@"" delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Add Photo From Library", nil), NSLocalizedString(@"Take Photo", nil), NSLocalizedString(@"Add Video from Library", @""), NSLocalizedString(@"Record Video", @""),nil];
            _addMediaActionSheet = addMediaActionSheet;
            
        } else {
            addMediaActionSheet = [[UIActionSheet alloc] initWithTitle:@"" delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Add Photo From Library", nil), NSLocalizedString(@"Take Photo", nil), nil];
            _addMediaActionSheet = addMediaActionSheet;
        }
    } else {
        addMediaActionSheet = [[UIActionSheet alloc] initWithTitle:@"" delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Add Photo From Library", nil), nil];
        _addMediaActionSheet = addMediaActionSheet;
    }
    
    _addMediaActionSheet.tag = TAG_ACTIONSHEET_PHOTO_SELECTION_PROMPT;
    if (IS_IPAD) {
        [_addMediaActionSheet showFromBarButtonItem:[self.navigationItem.rightBarButtonItems objectAtIndex:1] animated:YES];
    } else {
        [_addMediaActionSheet showInView:self.view];
    }
}

- (void)addNotifications {
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mediaDidUploadSuccessfully:) name:VideoUploadSuccessfulNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mediaDidUploadSuccessfully:) name:ImageUploadSuccessfulNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mediaUploadFailed:) name:VideoUploadFailedNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mediaUploadFailed:) name:ImageUploadFailedNotification object:nil];
}

- (void)removeNotifications{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (Post *)post {
    if ([self.apost isKindOfClass:[Post class]]) {
        return (Post *)self.apost;
    }
    return nil;
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[self.resultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = nil;
    sectionInfo = [[self.resultsController sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
	}
    
    [self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}

- (UITableViewCell *)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
	Media *media = [self.resultsController objectAtIndexPath:indexPath];
    cell.imageView.image = [UIImage imageWithData:media.thumbnail];
	NSString *filesizeString = nil;
    if([media.filesize floatValue] > 1024)
        filesizeString = [NSString stringWithFormat:@"%.2f MB", ([media.filesize floatValue]/1024)];
    else
        filesizeString = [NSString stringWithFormat:@"%.2f KB", [media.filesize floatValue]];
    
    if(media.title != nil)
        cell.textLabel.text = media.title;
    else
        cell.textLabel.text = media.filename;

    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    if (media.remoteStatus == MediaRemoteStatusPushing) {
        CGFloat mediaProgress = media.progress * 100.0;
        if ([@(mediaProgress) floatValue] < 100.0) {
            cell.detailTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%.1f%%. [Cancel]", @"Uploading message with percentage displayed when an image is uploading, tapping cancels."), mediaProgress];
        } else {
            cell.detailTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Processing...", @"Uploading message displayed when an image has finished uploading."), mediaProgress];
        }
    } else if (media.remoteStatus == MediaRemoteStatusProcessing) {
        cell.detailTextLabel.text = NSLocalizedString(@"Preparing...", @"Uploading message when an image is about to be uploaded.");
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    } else if (media.remoteStatus == MediaRemoteStatusFailed) {
        cell.detailTextLabel.text = NSLocalizedString(@"Upload failed. [Retry]", @"Uploading message when a media upload has failed, tapping retries.");
    } else {
        if ([media.mediaType isEqualToString:@"image"]) {
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%dx%d %@", 
                                         [media.width intValue], [media.height intValue], filesizeString];        
        } else if ([media.mediaType isEqualToString:@"video"]) {
            NSNumber *valueForDisplay = [NSNumber numberWithDouble:[media.length doubleValue]];
            NSNumber *days = [NSNumber numberWithDouble:
                              ([valueForDisplay doubleValue] / 86400)];
            NSNumber *hours = [NSNumber numberWithDouble:
                               (([valueForDisplay doubleValue] / 3600) -
                                ([days intValue] * 24))];
            NSNumber *minutes = [NSNumber numberWithDouble:
                                 (([valueForDisplay doubleValue] / 60) -
                                  ([days intValue] * 24 * 60) -
                                  ([hours intValue] * 60))];
            NSNumber *seconds = [NSNumber numberWithInt:([valueForDisplay intValue] % 60)];
            
            if([media.filesize floatValue] > 1024)
                filesizeString = [NSString stringWithFormat:@"%.2f MB", ([media.filesize floatValue]/1024)];
            else
                filesizeString = [NSString stringWithFormat:@"%.2f KB", [media.filesize floatValue]];
            
            cell.detailTextLabel.text = [NSString stringWithFormat:
                                         @"%02d:%02d:%02d %@",
                                         [hours intValue],
                                         [minutes intValue],
                                         [seconds intValue], 
                                         filesizeString];
        }
    }

	[cell.imageView setBounds:CGRectMake(0.0f, 0.0f, 75.0f, 75.0f)];
	[cell.imageView setClipsToBounds:YES];
	[cell.imageView setFrame:CGRectMake(0.0f, 0.0f, 75.0f, 75.0f)];
	[cell.imageView setContentMode:UIViewContentModeScaleAspectFill];
    
	filesizeString = nil;
    
    [WPStyleGuide configureTableViewCell:cell];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 75.0f;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Media *media = [self.resultsController objectAtIndexPath:indexPath];

    if (media.remoteStatus == MediaRemoteStatusFailed) {
        [media uploadWithSuccess:^{
            if (([media isDeleted])) {
                DDLogWarn(@"Media deleted while uploading (%@)", media);
                return;
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ShouldInsertMediaBelow" object:media];
            [media save];
        } failure:^(NSError *error) {
            // User canceled upload
            if (error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled) {
                return;
            }
            [WPError showNetworkingAlertWithError:error title:NSLocalizedString(@"Upload failed", @"")];
        }];
    } else if (media.remoteStatus == MediaRemoteStatusPushing) {
        [media cancelUpload];
    } else if (media.remoteStatus == MediaRemoteStatusProcessing) {
        // Do nothing. See trac #1508
    } else {
        MediaObjectViewController *mediaView = [[MediaObjectViewController alloc] initWithNibName:@"MediaObjectView" bundle:nil];
        [mediaView setMedia:media];

        if(IS_IPAD) {
			mediaView.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
			mediaView.modalPresentationStyle = UIModalPresentationFormSheet;
			
            [self presentViewController:mediaView animated:YES completion:nil];
		}
        else {
            [self.navigationController pushViewController:mediaView animated:YES];
        }
    }

	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (editingStyle == UITableViewCellEditingStyleDelete)
	{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ShouldRemoveMedia" object:[self.resultsController objectAtIndexPath:indexPath]];
        Media *media = [self.resultsController objectAtIndexPath:indexPath];
        [media remove];
	}
}

- (NSString *)tableView:(UITableView*)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
	return NSLocalizedString(@"Remove", @"");
}

//Hide unnecessary row dividers. See http://ios.trac.wordpress.org/ticket/1264
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if ([self numberOfSectionsInTableView:tableView] == (section+1)){
        return [UIView new];
    }
    return nil;
}

#pragma mark -
#pragma mark Custom methods

- (void)scaleAndRotateImage:(UIImage *)image {
	DDLogVerbose(@"scaling and rotating image...");
}

- (void)resetStatusBarColor {
    // On iOS7 Beta 6 the image picker seems to override our preferred setting so we force the status bar color back.
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
}

#pragma mark -
#pragma mark UIPopover Delegate Methods

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    [self resetStatusBarColor]; // incase the popover is dismissed after the image picker is presented.
    _addPopover.delegate = nil;
    _addPopover = nil;
}


#pragma mark -
#pragma mark Action Sheet Delegate Methods

- (void)didPresentActionSheet:(UIActionSheet *)actionSheet {
    self.currentActionSheet = actionSheet;
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {

    _addMediaActionSheet = nil;
    
    if (actionSheet.tag == TAG_ACTIONSHEET_PHOTO_SELECTION_PROMPT) {
        [self processPhotoPickerActionSheet:actionSheet didDismissWithButtonIndex:buttonIndex];
        return;
    }
    
	if(_isShowingMediaPickerActionSheet == YES) {
		switch (actionSheet.numberOfButtons) {
			case 2:
				if(buttonIndex == 0)
					[self pickPhotoFromPhotoLibrary:actionSheet];
				else {
					self.isAddingMedia = NO;
				}
				break;
			case 3:
				if(buttonIndex == 0) {
					[self pickPhotoFromPhotoLibrary:actionSheet];
				}
				else if(buttonIndex == 1) {
                    if (actionSheet.tag == TAG_ACTIONSHEET_VIDEO) {
                        [self pickVideoFromCamera:actionSheet];
                    } else {
                        [self pickPhotoFromCamera:actionSheet];
                    }
				}
				else {
					self.isAddingMedia = NO;
				}
				break;
			default:
				break;
		}
		self.isShowingMediaPickerActionSheet = NO;
	}
	else if(_isShowingChangeOrientationActionSheet == YES) {
		switch (buttonIndex) {
			case 0:
				self.currentOrientation = MediaOrientationPortrait;
				break;
			case 1:
				self.currentOrientation = MediaOrientationLandscape;
				break;
			default:
				self.currentOrientation = MediaOrientationPortrait;
				break;
		}
		[self processRecordedVideo];
		self.isShowingChangeOrientationActionSheet = NO;
	} else if(_isShowingResizeActionSheet == YES) {
        if (actionSheet.cancelButtonIndex != buttonIndex) {
            switch (buttonIndex) {
                case 0:
                    if (actionSheet.numberOfButtons == 3)
                        [self useImage:[self resizeImage:_currentImage toSize:MediaResizeOriginal]];
                    else
                        [self useImage:[self resizeImage:_currentImage toSize:MediaResizeSmall]];
                    break;
                case 1:
                    if (actionSheet.numberOfButtons == 3)
                        [self showCustomSizeAlert];
                    else if (actionSheet.numberOfButtons == 4)
                        [self useImage:[self resizeImage:_currentImage toSize:MediaResizeOriginal]];
                    else
                        [self useImage:[self resizeImage:_currentImage toSize:MediaResizeMedium]];
                    break;
                case 2:
                    if (actionSheet.numberOfButtons == 4)
                        [self showCustomSizeAlert];
                    else if (actionSheet.numberOfButtons == 5)
                        [self useImage:[self resizeImage:_currentImage toSize:MediaResizeOriginal]];
                    else
                        [self useImage:[self resizeImage:_currentImage toSize:MediaResizeLarge]];
                    break;
                case 3:
                    if (actionSheet.numberOfButtons == 5)
                        [self showCustomSizeAlert];
                    else
                        [self useImage:[self resizeImage:_currentImage toSize:MediaResizeOriginal]];
                    break;
                case 4: 
                    [self showCustomSizeAlert]; 
                    break;
            }
        }
		self.isShowingResizeActionSheet = NO;
	}
    
    self.currentActionSheet = nil;
}

- (void)processPhotoPickerActionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    
    UIActionSheet *savedCurrentActionSheet = _currentActionSheet;
    self.currentActionSheet = nil;
    NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    
    if ([buttonTitle isEqualToString:NSLocalizedString(@"Cancel", nil)] && _dismissOnCancel) {
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }

    if ([buttonTitle isEqualToString:NSLocalizedString(@"Add Photo From Library", nil)]) {
        [WPMobileStats flagProperty:StatsPropertyPostDetailClickedAddPhoto forEvent:[self formattedStatEventString:StatsEventPostDetailClosedEditor]];
        [self pickPhotoFromPhotoLibrary:nil];
    } else if ([buttonTitle isEqualToString:NSLocalizedString(@"Take Photo", nil)]) {
        [WPMobileStats flagProperty:StatsPropertyPostDetailClickedAddPhoto forEvent:[self formattedStatEventString:StatsEventPostDetailClosedEditor]];
        [self pickPhotoFromCamera:nil];
    } else if ([buttonTitle isEqualToString:NSLocalizedString(@"Add Video from Library", nil)]) {
        [WPMobileStats flagProperty:StatsPropertyPostDetailClickedAddVideo forEvent:[self formattedStatEventString:StatsEventPostDetailClosedEditor]];
        actionSheet.tag = TAG_ACTIONSHEET_VIDEO;
        [self pickPhotoFromPhotoLibrary:actionSheet];
    } else if ([buttonTitle isEqualToString:NSLocalizedString(@"Record Video", nil)]) {
        [WPMobileStats flagProperty:StatsPropertyPostDetailClickedAddVideo forEvent:[self formattedStatEventString:StatsEventPostDetailClosedEditor]];
        [self pickVideoFromCamera:actionSheet];
    } else {
        //
        self.currentActionSheet = savedCurrentActionSheet;
    }
    _dismissOnCancel = NO;
}

#pragma mark -
#pragma mark Picker Methods

- (UIImagePickerController *)resetImagePicker {
    _picker.delegate = nil;
    self.picker = [[UIImagePickerController alloc] init];
    _picker.navigationBar.translucent = NO;
	_picker.delegate = self;
	_picker.allowsEditing = NO;
    _picker.navigationBar.barStyle = UIBarStyleBlack;
    return _picker;
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

- (void)pickPhotoFromPhotoLibrary:(id)sender {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        if (IS_IPAD && _addPopover != nil) {
            [_addPopover dismissPopoverAnimated:YES];
        }        
        [self resetImagePicker];
        _picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
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
        } else {
            _picker.mediaTypes = [NSArray arrayWithObject:(NSString *)kUTTypeImage];
        }
		self.isLibraryMedia = YES;
		
		if(IS_IPAD) {
            if (_addPopover == nil) {
                self.addPopover = [[UIPopoverController alloc] initWithContentViewController:_picker];
                _addPopover.delegate = self;
            }

            if (!CGRectIsEmpty(actionSheetRect)) {
//                [addPopover presentPopoverFromRect:actionSheetRect inView:self.postDetailViewController.postSettingsViewController.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
                [_addPopover presentPopoverFromRect:actionSheetRect inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
            } else {
                // We insert a spacer into the barButtonItems so we need to grab the actual
                // bar button item otherwise there is a crash.
                UIBarButtonItem *barButton = [self.navigationItem.rightBarButtonItems objectAtIndex:1];
                [_addPopover presentPopoverFromBarButtonItem:barButton permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
            }
            [[CPopoverManager instance] setCurrentPopoverController:_addPopover];
		}
		else {
            [self.navigationController presentViewController:_picker animated:YES completion:nil];
		}
    }
}

- (MediaOrientation)interpretOrientation:(UIDeviceOrientation)theOrientation {
	MediaOrientation result = MediaOrientationPortrait;
	switch (theOrientation) {
		case UIDeviceOrientationPortrait:
			result = MediaOrientationPortrait;
			break;
		case UIDeviceOrientationPortraitUpsideDown:
			result = MediaOrientationPortrait;
			break;
		case UIDeviceOrientationLandscapeLeft:
			result = MediaOrientationLandscape;
			break;
		case UIDeviceOrientationLandscapeRight:
			result = MediaOrientationLandscape;
			break;
		case UIDeviceOrientationFaceUp:
			result = MediaOrientationPortrait;
			break;
		case UIDeviceOrientationFaceDown:
			result = MediaOrientationPortrait;
			break;
		case UIDeviceOrientationUnknown:
			result = MediaOrientationPortrait;
			break;
	}
	
	return result;
}

- (void)showOrientationChangedActionSheet {
    if (_currentActionSheet || _addPopover) {
        return;
    }
    
	self.isShowingChangeOrientationActionSheet = YES;
	UIActionSheet *orientationActionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Orientation changed during recording. Please choose which orientation to use for this video.", @"") 
																		delegate:self 
															   cancelButtonTitle:nil 
														  destructiveButtonTitle:nil 
															   otherButtonTitles:NSLocalizedString(@"Portrait", @""), NSLocalizedString(@"Landscape", @""), nil];
	[orientationActionSheet showInView:self.view];
}

- (void)showResizeActionSheet {
	if (!self.isShowingResizeActionSheet) {
		self.isShowingResizeActionSheet = YES;
        
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
        NSString *originalSizeStr = [NSString stringWithFormat:NSLocalizedString(@"Original Size (%@)", @"Original Size (width x height)"), [NSString stringWithFormat:@"%ix%i", (int)originalSize.width, (int)originalSize.height]];
        
		UIActionSheet *resizeActionSheet;
		
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
		
        if (IS_IPAD) {
            [resizeActionSheet showFromBarButtonItem:[self.navigationItem.rightBarButtonItems objectAtIndex:1] animated:YES];
        } else {
            [resizeActionSheet showInView:self.view];
        }
	}
}

#pragma mark -
#pragma mark custom image size methods

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
	//check the inserted characters: the user can use cut-and-paste instead of using the keyboard, and can insert letters and spaces
	NSCharacterSet *cs = [[NSCharacterSet characterSetWithCharactersInString:NUMBERS] invertedSet];
    NSString *filtered = [[string componentsSeparatedByCharactersInSet:cs] componentsJoinedByString:@""];
    if( [string isEqualToString:filtered] == NO ) return NO; 
	
    NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];
	
	if (textField.tag == 123) {
		if ([newString intValue] > _currentImage.size.width  ) {
			return NO;
		}
	} else {
		if ([newString intValue] > _currentImage.size.height) {
			return NO;
		}
	}
    return YES;
}

- (void)showCustomSizeAlert {
    if (self.customSizeAlert) {
        [self.customSizeAlert dismiss];
        self.customSizeAlert = nil;
    }

    self.isShowingCustomSizeAlert = YES;
    
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
        self.isShowingCustomSizeAlert = NO;
    };
    
    alertView.button2CompletionBlock = ^(WPAlertView *overlayView){
        [overlayView dismiss];
        self.isShowingCustomSizeAlert = NO;
        
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


- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
	if (alertView.tag == 101) { //VideoPress Promo Alert
		switch (buttonIndex) {
			case 0:
				break;
			case 1:
			{
				NSString *buttonTitle = [alertView buttonTitleAtIndex:buttonIndex];
				if ([buttonTitle isEqualToString:NSLocalizedString(@"Yes", @"")]){
					[[UIApplication sharedApplication] openURL:[NSURL URLWithString: @"http://videopress.com"]];
				}
			}		
			default:
				break;
		}
	}

    if (currentAlert == alertView) {
        currentAlert = nil;
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (currentAlert == alertView) {
        currentAlert = nil;
    }
}

- (void)imagePickerController:(UIImagePickerController *)thePicker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [self resetStatusBarColor];

	if([[info valueForKey:@"UIImagePickerControllerMediaType"] isEqualToString:@"public.movie"]) {
		self.currentVideo = [info mutableCopy];
		if(self.didChangeOrientationDuringRecord == YES)
			[self showOrientationChangedActionSheet];
		else if(self.isLibraryMedia == NO)
			[self processRecordedVideo];
		else
			[self performSelectorOnMainThread:@selector(processLibraryVideo) withObject:nil waitUntilDone:NO];
	}
	else if([[info valueForKey:@"UIImagePickerControllerMediaType"] isEqualToString:@"public.image"]) {
		UIImage *image = [info valueForKey:@"UIImagePickerControllerOriginalImage"];
		if (thePicker.sourceType == UIImagePickerControllerSourceTypeCamera)
			UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
		self.currentImage = image;
		
		//UIImagePickerControllerReferenceURL = "assets-library://asset/asset.JPG?id=1000000050&ext=JPG").
        NSURL *assetURL = [info objectForKey:UIImagePickerControllerReferenceURL];
        if (assetURL) {
            [self getMetadataFromAssetForURL:assetURL];
        } else {
            NSDictionary *metadata = [info objectForKey:UIImagePickerControllerMediaMetadata];
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
                [self useImage:[self resizeImage:_currentImage toSize:MediaResizeOriginal]];
				break;
            }
			default:
            {
                showResizeActionSheet = YES;
				break;
            }
		}
		
        if (_addPopover != nil) {
            [_addPopover dismissPopoverAnimated:YES];
            [[CPopoverManager instance] setCurrentPopoverController:nil];
            self.addPopover = nil;
            if (showResizeActionSheet) {
                [self showResizeActionSheet];
            }
        } else {
            [self.navigationController dismissViewControllerAnimated:YES completion:^{
                if (showResizeActionSheet) {
                    [self showResizeActionSheet];
                }
            }];
        }
	}

	if(IS_IPAD){
		[_addPopover dismissPopoverAnimated:YES];
		[[CPopoverManager instance] setCurrentPopoverController:nil];
		self.addPopover = nil;
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
					   
					   DDLogInfo(@"getJPEGFromAssetForURL: default asset representation for %@: uti: %@ size: %lld url: %@ orientation: %d scale: %f metadata: %@",
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
					   source = CGImageSourceCreateWithData((__bridge CFDataRef)imageJPEG, nil);
					   
                       NSDictionary *metadata = (NSDictionary *) CFBridgingRelease(CGImageSourceCopyPropertiesAtIndex(source,0,nil));
                       
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
					  DDLogError(@"can't get asset %@: %@", url, err);
					  self.currentImageMetadata = nil;
				  }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    // On iOS7 Beta 6 the image picker seems to override our preferred setting so we force the status bar color back.
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];

    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
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

- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(NSString *)contextInfo {
	[self useVideo:videoPath];
	self.currentVideo = nil;
}

- (UIImage *)fixImageOrientation:(UIImage *)img {
    CGSize size = [img size];
	
    UIImageOrientation imageOrientation = [img imageOrientation];
	
    if (imageOrientation == UIImageOrientationUp)
        return img;
	
    CGImageRef imageRef = [img CGImage];
    CGContextRef bitmap = CGBitmapContextCreate(
												nil,
												size.width,
												size.height,
												CGImageGetBitsPerComponent(imageRef),
												4 * size.width,
												CGImageGetColorSpace(imageRef),
												CGImageGetBitmapInfo(imageRef));
	
    CGContextTranslateCTM(bitmap, size.width, size.height);
	
    switch (imageOrientation) {
        case UIImageOrientationDown:
            // rotate 180 degees CCW
            CGContextRotateCTM(bitmap, radians(180.));
            break;
        case UIImageOrientationLeft:
            // rotate 90 degrees CW
            CGContextRotateCTM(bitmap, radians(-90.));
            break;
        case UIImageOrientationRight:
            // rotate 90 degrees5 CCW
            CGContextRotateCTM(bitmap, radians(90.));
            break;
        default:
            break;
    }
	
    CGContextDrawImage(bitmap, CGRectMake(0, 0, size.width, size.height), imageRef);
	
    CGImageRef ref = CGBitmapContextCreateImage(bitmap);
    CGContextRelease(bitmap);
    UIImage *oimg = [UIImage imageWithCGImage:ref];
    CGImageRelease(ref);
	
    return oimg;
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
		case MediaResizeSmall:
			if(_currentImage.size.width > smallSize.width  || _currentImage.size.height > smallSize.height)
				resizedImage = [original resizedImageWithContentMode:UIViewContentModeScaleAspectFit  
															  bounds:smallSize  
												interpolationQuality:kCGInterpolationHigh]; 
			else  
				resizedImage = [original resizedImageWithContentMode:UIViewContentModeScaleAspectFit  
															  bounds:originalSize  
												interpolationQuality:kCGInterpolationHigh];
			break;
		case MediaResizeMedium:
			if(_currentImage.size.width > mediumSize.width  || _currentImage.size.height > mediumSize.height)
				resizedImage = [original resizedImageWithContentMode:UIViewContentModeScaleAspectFit  
															  bounds:mediumSize  
												interpolationQuality:kCGInterpolationHigh]; 
			else  
				resizedImage = [original resizedImageWithContentMode:UIViewContentModeScaleAspectFit  
															  bounds:originalSize  
												interpolationQuality:kCGInterpolationHigh];
			break;
		case MediaResizeLarge:
			if(_currentImage.size.width > largeSize.width || _currentImage.size.height > largeSize.height)
				resizedImage = [original resizedImageWithContentMode:UIViewContentModeScaleAspectFit  
															  bounds:largeSize  
												interpolationQuality:kCGInterpolationHigh]; 
			else  
				resizedImage = [original resizedImageWithContentMode:UIViewContentModeScaleAspectFit  
															  bounds:originalSize  
												interpolationQuality:kCGInterpolationHigh];
			break;
		case MediaResizeOriginal:
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

- (UIImage *)generateThumbnailFromImage:(UIImage *)theImage andSize:(CGSize)targetSize {
    return [theImage thumbnailImage:75 transparentBorder:0 cornerRadius:0 interpolationQuality:kCGInterpolationHigh]; 
}

- (void)useImage:(UIImage *)theImage {
	Media *imageMedia = [Media newMediaForPost:self.apost];
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
		CGImageSourceRef  source = nil;
        CGImageDestinationRef destination = nil;
		BOOL success = NO;
        //this will be the data CGImageDestinationRef will write into
        NSMutableData *dest_data = [NSMutableData data];

		source = CGImageSourceCreateWithData((__bridge CFDataRef)imageData, nil);
        if (source) {
            CFStringRef UTI = CGImageSourceGetType(source); //this is the type of image (e.g., public.jpeg)
            destination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)dest_data,UTI,1,nil);
            
            if(destination) {                
                //add the image contained in the image source to the destination, copying the old metadata
                CGImageDestinationAddImageFromSource(destination,source,0, (__bridge CFDictionaryRef) self.currentImageMetadata);
                
                //tell the destination to write the image data and metadata into our data object.
                //It will return false if something goes wrong
                success = CGImageDestinationFinalize(destination);
            } else {
                DDLogError(@"***Could not create image destination ***");
            }
        } else {
            DDLogError(@"***Could not create image source ***");
        }
		
		if(!success) {
			DDLogInfo(@"***Could not create data from image destination ***");
			//write the data without EXIF to disk
			NSFileManager *fileManager = [NSFileManager defaultManager];
			[fileManager createFileAtPath:filepath contents:imageData attributes:nil];
		} else {
			//write it to disk
			[dest_data writeToFile:filepath atomically:YES];
		}
		//cleanup
        if (destination)
            CFRelease(destination);
        if (source)
            CFRelease(source);
    } else {
		NSFileManager *fileManager = [NSFileManager defaultManager];
		[fileManager createFileAtPath:filepath contents:imageData attributes:nil];
	}

	if(_currentOrientation == MediaOrientationLandscape) {
		imageMedia.orientation = @"landscape";
    }else {
		imageMedia.orientation = @"portrait";
    }
	imageMedia.creationDate = [NSDate date];
	imageMedia.filename = filename;
	imageMedia.localURL = filepath;
	imageMedia.filesize = [NSNumber numberWithInt:(imageData.length/1024)];
    if (isPickingFeaturedImage) {
        imageMedia.mediaType = @"featured";
    } else {
        imageMedia.mediaType = @"image";
    }
	imageMedia.thumbnail = UIImageJPEGRepresentation(imageThumbnail, 0.90);
	imageMedia.width = [NSNumber numberWithInt:theImage.size.width];
	imageMedia.height = [NSNumber numberWithInt:theImage.size.height];
    if (isPickingFeaturedImage) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"UploadingFeaturedImage" object:nil];
    }
    [imageMedia uploadWithSuccess:^{
        if ([imageMedia isDeleted]) {
            DDLogWarn(@"Media deleted while uploading (%@)", imageMedia);
            return;
        }
        if (!isPickingFeaturedImage) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ShouldInsertMediaBelow" object:imageMedia];
        }
        [imageMedia save];
    } failure:^(NSError *error) {
        if (error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled) {
            return;
        }

        [WPError showNetworkingAlertWithError:error title:NSLocalizedString(@"Upload failed", @"")];
    }];
	
	self.isAddingMedia = NO;
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

        if (halfWayImage != nil) {
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
			if([fileManager isReadableFileAtPath:videoURL] == YES)
				copySuccess = [fileManager copyItemAtPath:videoURL toPath:filepath error:&error];
		}
	}
	
	if(copySuccess == YES) {
		videoMedia = [Media newMediaForPost:self.apost];
		
		if(_currentOrientation == MediaOrientationLandscape) {
			videoMedia.orientation = @"landscape";
		} else {
			videoMedia.orientation = @"portrait";
        }
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
                DDLogWarn(@"Media deleted while uploading (%@)", videoMedia);
                return;
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ShouldInsertMediaBelow" object:videoMedia];
            [videoMedia save];
        } failure:^(NSError *error) {
            [WPError showNetworkingAlertWithError:error title:NSLocalizedString(@"Upload failed", @"")];
        }];
		self.isAddingMedia = NO;

	}
	else {
        [WPError showAlertWithTitle:NSLocalizedString(@"Error Copying Video", nil) message:NSLocalizedString(@"There was an error copying the video for upload. Please try again.", nil)];
	}
}

- (BOOL)isDeviceSupportVideo {
	if(([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] == YES) && 
	   ([[UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera] containsObject:(NSString *)kUTTypeMovie]))
		return YES;
	else
		return NO;
}

- (BOOL)isDeviceSupportVideoAndVideoPressEnabled{
	if([self isDeviceSupportVideo] && (self.videoEnabled == YES))
		return YES;
	else
		return NO;
}

- (void)mediaDidUploadSuccessfully:(NSNotification *)notification {
    Media *media = (Media *)[notification object];
    if ((media == nil) || ([media isDeleted])) {
        DDLogWarn(@"Media deleted while uploading (%@)", media);
        return;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ShouldInsertMediaBelow" object:media];
	self.isAddingMedia = NO;
}

- (void)mediaUploadFailed:(NSNotification *)notification {
	self.isAddingMedia = NO;
}

- (void)deviceDidRotate:(NSNotification *)notification {
	if(_isAddingMedia == YES) {
		if(self.currentOrientation != [self interpretOrientation:[[UIDevice currentDevice] orientation]]) {		
			self.currentOrientation = [self interpretOrientation:[[UIDevice currentDevice] orientation]];
			self.didChangeOrientationDuringRecord = YES;
		}
	}
}

- (void)checkVideoPressEnabled {
    if(self.isCheckingVideoCapability)
        return;

    self.isCheckingVideoCapability = YES;
    [self.apost.blog checkVideoPressEnabledWithSuccess:^(BOOL enabled) {
        self.videoEnabled = enabled;
        self.isCheckingVideoCapability = NO;
    } failure:^(NSError *error) {
        DDLogError(@"checkVideoPressEnabled failed: %@", [error localizedDescription]);
        self.videoEnabled = YES;
        self.isCheckingVideoCapability = NO;
    }];
}

#pragma mark -
#pragma mark Results Controller

- (NSFetchedResultsController *)resultsController {
    if (resultsController != nil) {
        return resultsController;
    }

    NSString *cacheName = [NSString stringWithFormat:@"Media-%@-%@",
                           self.apost.blog.hostURL,
                           self.apost.postID];
    
    [NSFetchedResultsController deleteCacheWithName:cacheName];
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Media"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"%@ IN posts AND mediaType != 'featured'", self.apost];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
    
    resultsController = [[NSFetchedResultsController alloc]
                                                      initWithFetchRequest:fetchRequest
                                                      managedObjectContext:[[ContextManager sharedInstance] mainContext]
                                                      sectionNameKeyPath:nil
                                                      cacheName:cacheName];
    resultsController.delegate = self;
    
    NSError *error = nil;
    if (![resultsController performFetch:&error]) {
        DDLogWarn(@"Couldn't fetch media");
        resultsController = nil;
    }
    
    return resultsController;
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
    
    if (type != NSFetchedResultsChangeUpdate) {
        // For anything that is not an update just reload the table.
        [self.tableView reloadData];
        return;
    }
    
    // For updates, update the cell w/o refreshing the whole tableview.
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    if (cell) {
        [self configureCell:cell atIndexPath:indexPath];
    }

}

- (NSString *)videoPathFromVideoUrl:(NSString *)videoUrl {
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

- (NSString *)formattedStatEventString:(NSString *)event {
    return [NSString stringWithFormat:@"%@ - %@", self.statsPrefix, event];
}

@end
