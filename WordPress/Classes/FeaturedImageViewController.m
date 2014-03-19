//
//  FeaturedImageViewController.m
//  WordPress
//
//  Created by Eric Johnson on 1/28/14.
//  Copyright (c) 2014 WordPress. All rights reserved.
//

#import "FeaturedImageViewController.h"

#import "Post.h"
#import "Media.h"
#import "UIImageView+AFNetworking.h"
#import "UIImage+Resize.h"
#import "WPAlertView.h"
#import <ImageIO/ImageIO.h>
#import <AssetsLibrary/AssetsLibrary.h>

typedef enum {
    ActionSheetTagPhoto = 0,
    ActionSheetTagResizePhoto,
    ActionSheetTagRemoveFeaturedImage
} ActionSheetTag;

@interface FeaturedImageViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIPopoverControllerDelegate, UIActionSheetDelegate>

@property (nonatomic, strong) UIBarButtonItem *photoButton;
@property (nonatomic, strong) UIBarButtonItem *deleteButton;
@property (nonatomic, strong) Post *post;
@property (nonatomic, strong) UIBarButtonItem *activityItem;
@property (nonatomic, strong) UIPopoverController *popover;
@property (nonatomic, strong) UIImage *previousImage;

@property (nonatomic, strong) NSDictionary *currentImageMetadata;
@property (nonatomic, assign) BOOL isShowingResizeActionSheet;
@property (nonatomic, assign) BOOL hasShownPicker;
@property (nonatomic, assign) BOOL loadingFeaturedImage;
@property (nonatomic, strong) UIImage *currentImage;
@property (nonatomic, strong) WPAlertView *customSizeAlert;

@end

@implementation FeaturedImageViewController

#pragma mark - Life Cycle Methods

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithPost:(Post *)post {
    self = [super init];
    if (self) {
        self.post = post;
        self.extendedLayoutIncludesOpaqueBars = YES;
        self.automaticallyAdjustsScrollViewInsets = NO;
        if (post.featuredImageURL) {
            self.url = [NSURL URLWithString:post.featuredImageURL];
        }
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self setupToolbar];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showFeaturedImageUploader:) name:@"UploadingFeaturedImage" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(featuredImageUploadSucceeded:) name:FeaturedImageUploadSuccessfulNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(featuredImageUploadFailed:) name:FeaturedImageUploadFailedNotification object:nil];

    if (self.navigationController.toolbarHidden) {
        [self.navigationController setToolbarHidden:NO animated:YES];
    }
    
    for (UIView *view in self.navigationController.toolbar.subviews) {
        [view setExclusiveTouch:YES];
    }
    
    // Super class will hide the status bar by default
    [self hideBars:NO animated:NO];

    // Called here to be sure the view is complete in case we need to present a popover from the toolbar.
    [self loadImageOrShowPicker];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.navigationController.navigationBar.translucent = NO;
    self.navigationController.toolbar.translucent = NO;
}

- (void)loadImageOrShowPicker {
    
    // Show the picker if it hasn't been shown, and there is no featured image.
    if (!self.post.post_thumbnail && !self.hasShownPicker) {
        [self showPhotoPicker];
        return;
    }
    
    if (self.url) {
        [self loadImage];
        
    } else if (self.post.featuredImageURL) {
        self.url = [NSURL URLWithString:self.post.featuredImageURL];
        [self loadImage];
        
    } else if (self.post.post_thumbnail) {
        [self getFeaturedImageShowingActivity:YES
                                      success:^{
                                          [self loadImageOrShowPicker];
                                      } failure:^(NSError *error) {
                                          DDLogError(@"Error getting featured image: %@", error);
                                      }];
    } else {
        // Should never reach this point.
    }
}

- (void)getFeaturedImageShowingActivity:(BOOL)showActivity success:(void (^)())success failure:(void (^)(NSError *error))failure {
    if (self.loadingFeaturedImage) {
        return;
    }
    self.loadingFeaturedImage = YES;
    [self showActivityView:showActivity];
    [self.post getFeaturedImageURLWithSuccess:^{
        self.loadingFeaturedImage = NO;
        [self showActivityView:NO];
        if(success) {
            success();
        }
        
    } failure:^(NSError *error) {
        self.loadingFeaturedImage = NO;
        [self showActivityView:NO];
        if(failure) {
            failure(error);
        }
    }];
}

- (void)restorePreviousImage {
    if (self.previousImage) {
        self.image = self.previousImage;
        self.previousImage = nil;
        [self loadImage];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark - Appearance Related Methods

- (void)setupToolbar {
    UIToolbar *toolbar = self.navigationController.toolbar;
    toolbar.barTintColor = [WPStyleGuide littleEddieGrey];
    toolbar.translucent = NO;
    toolbar.barStyle = UIBarStyleDefault;
    
    if ([self.toolbarItems count] > 0) {
        return;
    }
    
    self.deleteButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon-comments-trash"] style:UIBarButtonItemStylePlain target:self action:@selector(removeFeaturedImage)];
    self.photoButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon-posts-editor-media"] style:UIBarButtonItemStylePlain target:self action:@selector(showPhotoPicker)];
    
    self.deleteButton.tintColor = [WPStyleGuide readGrey];
    self.photoButton.tintColor = [WPStyleGuide readGrey];
 
    UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [activityView startAnimating];
    self.activityItem = [[UIBarButtonItem alloc] initWithCustomView:activityView];
    
    [self showActivityView:NO];
}

- (void)hideBars:(BOOL)hide animated:(BOOL)animated {
    [super hideBars:hide animated:animated];
    
    if(self.navigationController.navigationBarHidden != hide) {
        [self.navigationController setNavigationBarHidden:hide animated:animated];
    }
    
    if (self.navigationController.toolbarHidden != hide) {
        [self.navigationController setToolbarHidden:hide animated:animated];
    }

    [self centerImage];
    [UIView animateWithDuration:0.3 animations:^{
        if (hide) {
            self.view.backgroundColor = [UIColor blackColor];
        } else {
            self.view.backgroundColor = [UIColor whiteColor];
        }
    }];
}

- (void)showActivityView:(BOOL)show {
    UIBarButtonItem *leftFixedSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    UIBarButtonItem *rightFixedSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    UIBarButtonItem *centerFlexSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    leftFixedSpacer.width = -2.0f;
    rightFixedSpacer.width = -5.0f;
    
    if (show){
        self.toolbarItems = @[leftFixedSpacer, self.deleteButton, centerFlexSpacer, self.activityItem, rightFixedSpacer];
    } else {
        self.toolbarItems = @[leftFixedSpacer, self.deleteButton, centerFlexSpacer, self.photoButton, rightFixedSpacer];
    }
}

#pragma mark - Action Methods

- (void)handleImageTapped:(UITapGestureRecognizer *)tgr {
    BOOL hide = !self.navigationController.navigationBarHidden;
    [self hideBars:hide animated:YES];
}

- (void)removeFeaturedImage {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Remove this Featured Image?", @"Prompt when removing a featured image from a post")
                                                             delegate:self
                                                    cancelButtonTitle:NSLocalizedString(@"Cancel", "Cancel a prompt")
                                               destructiveButtonTitle:NSLocalizedString(@"Remove", @"Remove an image/posts/etc")
                                                    otherButtonTitles:nil];
    actionSheet.tag = ActionSheetTagRemoveFeaturedImage;
    [actionSheet showFromBarButtonItem:self.deleteButton animated:YES];
}


- (void)showPhotoPicker {
    UIActionSheet *photoActionSheet;
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
		photoActionSheet = [[UIActionSheet alloc] initWithTitle:@""
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
                                         destructiveButtonTitle:nil
                                              otherButtonTitles:NSLocalizedString(@"Add Photo from Library", @""),NSLocalizedString(@"Take Photo", @""),nil];
        photoActionSheet.tag = ActionSheetTagPhoto;
        photoActionSheet.actionSheetStyle = UIActionSheetStyleDefault;
        [photoActionSheet showFromBarButtonItem:self.photoButton animated:YES];
	} else {
        [self pickPhotoFromLibrary];
	}
    self.hasShownPicker = YES;
}

#pragma mark - Image Picker Methods

- (void)pickPhotoFromLibrary {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
	picker.delegate = self;
	picker.allowsEditing = NO;
    picker.navigationBar.translucent = NO;
    picker.modalPresentationStyle = UIModalPresentationCurrentContext;
    picker.navigationBar.barStyle = UIBarStyleBlack;
    
    if (IS_IPAD) {
        self.popover = [[UIPopoverController alloc] initWithContentViewController:picker];
        self.popover.delegate = self;
        [self.popover presentPopoverFromBarButtonItem:self.photoButton permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    } else {
        [self.navigationController presentViewController:picker animated:YES completion:nil];
    }
}

- (void)pickPhotoFromCamera {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
	picker.delegate = self;
	picker.allowsEditing = NO;
    picker.navigationBar.translucent = NO;
    picker.modalPresentationStyle = UIModalPresentationCurrentContext;
    
    [self.navigationController presentViewController:picker animated:YES completion:nil];
}

#pragma mark - Featured Image Notification Handlers

- (void)featuredImageUploadFailed:(NSNotification *)notificationInfo {
    [self showActivityView:NO];
}

- (void)featuredImageUploadSucceeded:(NSNotification *)notificationInfo {
    Media *media = (Media *)[notificationInfo object];
    [self showActivityView:NO];
    if (media) {
        if (![self.post isDeleted] && [self.post managedObjectContext]) {
            
            self.post.post_thumbnail = media.mediaID;
            // Be nice and preload the featuredImageURL
            [self getFeaturedImageShowingActivity:NO
                                          success:^{
                                              self.url = [NSURL URLWithString:self.post.featuredImageURL];
                                          } failure:^(NSError *error) {
                                              DDLogError(@"Failed to update FeaturedImage URL: %@", error);
                                          }];
        }
    }
}

- (void)showFeaturedImageUploader:(NSNotification *)notificationInfo {
    [self showActivityView:YES];
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)acSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (acSheet.tag == ActionSheetTagPhoto) {
        [self processPhotoTypeActionSheet:acSheet thatDismissedWithButtonIndex:buttonIndex];
    } else if (acSheet.tag == ActionSheetTagResizePhoto) {
        [self processPhotoResizeActionSheet:acSheet thatDismissedWithButtonIndex:buttonIndex];
    } else {
        if (buttonIndex == 0) {
            self.post.post_thumbnail = nil;
            self.post.featuredImageURL = nil;
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
}

- (void)processPhotoTypeActionSheet:(UIActionSheet *)acSheet thatDismissedWithButtonIndex:(NSInteger)buttonIndex {
    NSString *buttonTitle = [acSheet buttonTitleAtIndex:buttonIndex];
    if ([buttonTitle isEqualToString:NSLocalizedString(@"Add Photo from Library", nil)]) {
        [self pickPhotoFromLibrary];
    } else if ([buttonTitle isEqualToString:NSLocalizedString(@"Take Photo", nil)]) {
        [self pickPhotoFromCamera];
    } else if (acSheet.cancelButtonIndex == buttonIndex) {
        if (!self.post.post_thumbnail) {
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
}

- (void)processPhotoResizeActionSheet:(UIActionSheet *)acSheet thatDismissedWithButtonIndex:(NSInteger)buttonIndex {
    if (acSheet.cancelButtonIndex == buttonIndex) {
        [self restorePreviousImage];
    }
    
    // 6 button: small, medium, large, original, custom, cancel
    // 5 buttons: small, medium, original, custom, cancel
    // 4 buttons: small, original, custom, cancel
    // 3 buttons: original, custom, cancel
    // The last three buttons are always the same, so we can count down, then count up and avoid alot of branching.
    if (buttonIndex == acSheet.numberOfButtons - 1) {
        // cancel button. Noop.
    } else if (buttonIndex == acSheet.numberOfButtons - 2) {
        // custom
        [self showCustomSizeAlert];
    } else if (buttonIndex == acSheet.numberOfButtons - 3) {
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
    
    _isShowingResizeActionSheet = NO;
}

#pragma mark - Custom Size

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
        [self restorePreviousImage];
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

#pragma mark - UIImagePickerController Delegate Methods

// TODO: Remove duplication with these methods and PostMediaViewController
- (void)imagePickerController:(UIImagePickerController *)thePicker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    // On iOS7 Beta 6 the image picker seems to override our preferred setting so we force the status bar color back.
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    
    UIImage *image = [info valueForKey:@"UIImagePickerControllerOriginalImage"];
    
    if (thePicker.sourceType == UIImagePickerControllerSourceTypeCamera) {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
    }
    
    _currentImage = image;
    
    // show the new image
    self.previousImage = self.imageView.image;
    self.image = image;
    [self loadImage];
    
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
            _currentImageMetadata = mutableMetadata;
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
            // Dispatch async to detal with a rare bug presenting the actionsheet after a memory warning when the
            // view has been recreated.
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
    
    BOOL isPopoverDisplayed = NO;
    if (IS_IPAD) {
        if (thePicker.sourceType == UIImagePickerControllerSourceTypeCamera) {
            isPopoverDisplayed = NO;
        } else {
            isPopoverDisplayed = YES;
        }
    }
    
    if (!showResizeActionSheet) {
        self.previousImage = nil;
    }
    
    if (isPopoverDisplayed) {
        [self.popover dismissPopoverAnimated:YES];
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

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    // On iOS7 Beta 6 the image picker seems to override our preferred setting so we force the status bar color back.
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    
    if (!self.imageView.image) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark - Media and Image Wrangling

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
                       
					   if(!self.post.blog.geolocationEnabled) {
						   //we should remove the GPS info if the blog has the geolocation set to off
						   
						   //get all the metadata in the image
						   [metadataAsMutable removeObjectForKey:@"{GPS}"];
					   }
                       [metadataAsMutable removeObjectForKey:@"Orientation"];
                       [metadataAsMutable removeObjectForKey:@"{TIFF}"];
                       _currentImageMetadata = [NSDictionary dictionaryWithDictionary:metadataAsMutable];
					   
					   CFRelease(source);
				   }
				  failureBlock: ^(NSError *err) {
					  DDLogError(@"can't get asset %@: %@", url, err);
					  _currentImageMetadata = nil;
				  }];
}

- (UIImage *)resizeImage:(UIImage *)original toSize:(MediaResize)resize {
    NSDictionary* predefDim = [self.post.blog getImageResizeDimensions];
    CGSize smallSize =  [[predefDim objectForKey: @"smallSize"] CGSizeValue];
    CGSize mediumSize = [[predefDim objectForKey: @"mediumSize"] CGSizeValue];
    CGSize largeSize =  [[predefDim objectForKey: @"largeSize"] CGSizeValue];
    switch (original.imageOrientation) {
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
    
    CGSize originalSize = CGSizeMake(original.size.width, original.size.height); //The dimensions of the image, taking orientation into account.
	
	// Resize the image using the selected dimensions
	UIImage *resizedImage = original;
	switch (resize) {
		case MediaResizeSmall:
			if(original.size.width > smallSize.width  || original.size.height > smallSize.height) {
				resizedImage = [original resizedImageWithContentMode:UIViewContentModeScaleAspectFit
															  bounds:smallSize
												interpolationQuality:kCGInterpolationHigh];
            } else {
				resizedImage = [original resizedImageWithContentMode:UIViewContentModeScaleAspectFit
															  bounds:originalSize
												interpolationQuality:kCGInterpolationHigh];
            }
			break;
		case MediaResizeMedium:
			if(original.size.width > mediumSize.width  || original.size.height > mediumSize.height) {
				resizedImage = [original resizedImageWithContentMode:UIViewContentModeScaleAspectFit
															  bounds:mediumSize
												interpolationQuality:kCGInterpolationHigh];
            } else {
				resizedImage = [original resizedImageWithContentMode:UIViewContentModeScaleAspectFit
															  bounds:originalSize
												interpolationQuality:kCGInterpolationHigh];
            }
			break;
		case MediaResizeLarge:
			if(original.size.width > largeSize.width || original.size.height > largeSize.height) {
				resizedImage = [original resizedImageWithContentMode:UIViewContentModeScaleAspectFit
															  bounds:largeSize
												interpolationQuality:kCGInterpolationHigh];
            } else {
				resizedImage = [original resizedImageWithContentMode:UIViewContentModeScaleAspectFit
															  bounds:originalSize
												interpolationQuality:kCGInterpolationHigh];
            }
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


- (void)useImage:(UIImage *)theImage {
	Media *imageMedia = [Media newMediaForPost:self.post];
	NSData *imageData = UIImageJPEGRepresentation(theImage, 0.90);
	UIImage *imageThumbnail = [self generateThumbnailFromImage:theImage andSize:CGSizeMake(75, 75)];
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"yyyyMMdd-HHmmss"];
    
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	NSString *filename = [NSString stringWithFormat:@"%@.jpg", [formatter stringFromDate:[NSDate date]]];
	NSString *filepath = [documentsDirectory stringByAppendingPathComponent:filename];
    
	if (_currentImageMetadata != nil) {
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
                CGImageDestinationAddImageFromSource(destination,source,0, (__bridge CFDictionaryRef) _currentImageMetadata);
                
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
			DDLogError(@"***Could not create data from image destination ***");
			//write the data without EXIF to disk
			NSFileManager *fileManager = [NSFileManager defaultManager];
			[fileManager createFileAtPath:filepath contents:imageData attributes:nil];
		} else {
			//write it to disk
			[dest_data writeToFile:filepath atomically:YES];
		}
		//cleanup
        if (destination) {
            CFRelease(destination);
        }
        if (source) {
            CFRelease(source);
        }
    } else {
		NSFileManager *fileManager = [NSFileManager defaultManager];
		[fileManager createFileAtPath:filepath contents:imageData attributes:nil];
	}
    
	if ([self interpretOrientation] == MediaOrientationLandscape) {
		imageMedia.orientation = @"landscape";
    } else {
		imageMedia.orientation = @"portrait";
    }
	imageMedia.creationDate = [NSDate date];
	imageMedia.filename = filename;
	imageMedia.localURL = filepath;
	imageMedia.filesize = [NSNumber numberWithUnsignedInteger:(imageData.length/1024)];
    imageMedia.mediaType = @"featured";
	imageMedia.thumbnail = UIImageJPEGRepresentation(imageThumbnail, 0.90);
	imageMedia.width = [NSNumber numberWithInt:theImage.size.width];
	imageMedia.height = [NSNumber numberWithInt:theImage.size.height];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UploadingFeaturedImage" object:nil];
    
    [imageMedia uploadWithSuccess:^{
        if ([imageMedia isDeleted]) {
            DDLogWarn(@"Media deleted while uploading (%@)", imageMedia);
            return;
        }
        [imageMedia save];
    } failure:^(NSError *error) {
        [WPError showNetworkingAlertWithError:error title:NSLocalizedString(@"Upload failed", @"")];
    }];
}

- (UIImage *)generateThumbnailFromImage:(UIImage *)theImage andSize:(CGSize)targetSize {
    return [theImage thumbnailImage:75 transparentBorder:0 cornerRadius:0 interpolationQuality:kCGInterpolationHigh];
}

- (MediaOrientation)interpretOrientation {
	MediaOrientation result = MediaOrientationPortrait;
	switch ([[UIDevice currentDevice] orientation]) {
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

- (void)showResizeActionSheet {
    if (_isShowingResizeActionSheet) {
        return;
    }

    _isShowingResizeActionSheet = YES;
    
    Blog *currentBlog = self.post.blog;
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
    
    resizeActionSheet.tag = ActionSheetTagResizePhoto;
    [resizeActionSheet showInView:self.view];
}

#pragma mark - Popover Delegate Methods

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController{
    // On iOS7 Beta 6 the image picker seems to override our preferred setting so we force the status bar color back.
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    if(!self.imageView.image) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

@end
