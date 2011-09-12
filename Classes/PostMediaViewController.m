//
//  PostMediaViewController.m
//  WordPress
//
//  Created by Chris Boyd on 8/26/10.
//  Code is poetry.
//

#import "PostMediaViewController.h"
#import "EditPostViewController.h"
#import "ImageIO/CGImageSource.h"
#import "ImageIO/CGImageDestination.h"


#define TAG_ACTIONSHEET_PHOTO 1
#define TAG_ACTIONSHEET_VIDEO 2
#define NUMBERS	@"0123456789"


@interface PostMediaViewController (Private)
-(void)getMetadataFromAssetForURL:(NSURL *)url;
@end

@implementation PostMediaViewController
@synthesize table, addMediaButton, hasPhotos, hasVideos, isAddingMedia, photos, videos, addPopover, picker, customSizeAlert;
@synthesize isShowingMediaPickerActionSheet, currentOrientation, isShowingChangeOrientationActionSheet, spinner, pickerContainer;
@synthesize currentImage, currentImageMetadata, currentVideo, isLibraryMedia, didChangeOrientationDuringRecord, messageLabel;
@synthesize postDetailViewController, postID, blogURL, bottomToolbar;
@synthesize isShowingResizeActionSheet, isShowingCustomSizeAlert, videoEnabled, currentUpload, videoPressCheckBlogURL, isCheckingVideoCapability, uniqueID;

#pragma mark -
#pragma mark View lifecycle

- (void)initObjects {
	photos = [[NSMutableArray alloc] init];
	videos = [[NSMutableArray alloc] init];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
		[self initObjects];
    }
	
    return self;
}

- (void)viewDidLoad {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [super viewDidLoad];
    [FlurryAPI logEvent:@"PostMedia"];
	
	self.currentOrientation = [self interpretOrientation:[UIDevice currentDevice].orientation];
	
	picker = [[WPImagePickerController alloc] init];
	picker.delegate = self;
	picker.allowsEditing = NO;
	
	[self initObjects];
	self.videoEnabled = YES;
	[self performSelectorInBackground:@selector(checkVideoPressEnabled) withObject:nil];
	
    [self addNotifications];
}


- (void)addNotifications {
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mediaDidUploadSuccessfully:) name:VideoUploadSuccessful object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mediaDidUploadSuccessfully:) name:ImageUploadSuccessful object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mediaUploadFailed:) name:VideoUploadFailed object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mediaUploadFailed:) name:ImageUploadFailed object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dismissAlertViewKeyboard:) name:@"DismissAlertViewKeyboard" object:nil];
}

- (void)removeNotifications{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}

- (void)viewDidUnload {
    [self removeNotifications];
    picker.delegate = nil;
	[super viewDidUnload];
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
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
	}
    
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

    if (media.remoteStatus == MediaRemoteStatusPushing) {
        cell.detailTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Uploading: %.1f%%. Tap to cancel.", @""), media.progress * 100.0];
    } else if (media.remoteStatus == MediaRemoteStatusFailed) {
        cell.detailTextLabel.text = NSLocalizedString(@"Upload failed - tap to retry.", @"");
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

	[cell.imageView setBounds:CGRectMake(0, 0, 75, 75)];
	[cell.imageView setClipsToBounds:NO];
	[cell.imageView setFrame:CGRectMake(0, 0, 75, 75)];
	[cell.imageView setContentMode:UIViewContentModeScaleAspectFill];
	filesizeString = nil;
    
    return cell;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath: (NSIndexPath *) indexPath {
	return 75;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Media *media = [self.resultsController objectAtIndexPath:indexPath];

    if (media.remoteStatus == MediaRemoteStatusFailed) {
        [media upload];
    } else if (media.remoteStatus == MediaRemoteStatusPushing) {
        [media cancelUpload];
    } else {
        MediaObjectViewController *mediaView = [[MediaObjectViewController alloc] initWithNibName:@"MediaObjectView" bundle:nil];
        [mediaView setMedia:media];

        WordPressAppDelegate *appDelegate = (WordPressAppDelegate*)[[UIApplication sharedApplication] delegate];
        if(DeviceIsPad() == YES) {
			mediaView.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
			mediaView.modalPresentationStyle = UIModalPresentationFormSheet;
			
            [self presentModalViewController:mediaView animated:YES];
		}
        else
            [appDelegate.navigationController pushViewController:mediaView animated:YES];
        [mediaView release];
    }

	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

-(void)tableView:(UITableView*)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath {
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	// If row is deleted, remove it from the list.
	if (editingStyle == UITableViewCellEditingStyleDelete)
	{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ShouldRemoveMedia" object:[self.resultsController objectAtIndexPath:indexPath]];
        Media *media = [self.resultsController objectAtIndexPath:indexPath];
        [media remove];
        [media save];
	}
}

-(NSString *)tableView:(UITableView*)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
	return NSLocalizedString(@"Remove", @"");
}

#pragma mark -
#pragma mark Custom methods

- (void)scaleAndRotateImage:(UIImage *)image {
	NSLog(@"scaling and rotating image...");
}

- (IBAction)showVideoPickerActionSheet:(id)sender {
    isShowingMediaPickerActionSheet = YES;
	isAddingMedia = YES;
	
	UIActionSheet *actionSheet;
	if([self isDeviceSupportVideoAndVideoPressEnabled]) {
		actionSheet = [[UIActionSheet alloc] initWithTitle:@"" 
												  delegate:self 
										 cancelButtonTitle:NSLocalizedString(@"Cancel", @"") 
									destructiveButtonTitle:nil 
										 otherButtonTitles:NSLocalizedString(@"Add Video from Library", @""),NSLocalizedString(@"Record Video", @""),nil];
	} 
	else { //device has video recording capability but VideoPress could be not enabled on
       /* isShowingMediaPickerActionSheet = NO;
        [self pickPhotoFromPhotoLibrary:sender];
        return;*/
		isShowingMediaPickerActionSheet = NO;
		NSString *faultString = NSLocalizedString(@"You can upload videos to your blog with VideoPress. Would you like to learn more about VideoPress now?", @"");
		UIAlertView *uploadAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"VideoPress", @"") 
												 message:faultString 
												delegate:self
									   cancelButtonTitle:NSLocalizedString(@"No", @"") otherButtonTitles:nil];
		[uploadAlert addButtonWithTitle:NSLocalizedString(@"Yes", @"")];
		uploadAlert.tag = 101;
		[uploadAlert show];
		[uploadAlert release];		
		return;
	}
	
    actionSheet.tag = TAG_ACTIONSHEET_VIDEO;
    actionSheet.actionSheetStyle = UIActionSheetStyleDefault;
	[actionSheet showInView:postDetailViewController.view];
    WordPressAppDelegate *appDelegate = (WordPressAppDelegate*)[[UIApplication sharedApplication] delegate];
    [appDelegate setAlertRunning:YES];
	
    [actionSheet release];
}

- (IBAction)showPhotoPickerActionSheet:(id)sender {
    isShowingMediaPickerActionSheet = YES;
	isAddingMedia = YES;
	
	UIActionSheet *actionSheet;
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
		actionSheet = [[UIActionSheet alloc] initWithTitle:@"" 
												  delegate:self 
										 cancelButtonTitle:NSLocalizedString(@"Cancel", @"") 
									destructiveButtonTitle:nil 
										 otherButtonTitles:NSLocalizedString(@"Add Photo from Library", @""),NSLocalizedString(@"Take Photo", @""),nil];
	}
	else {
        isShowingMediaPickerActionSheet = NO;
        [self pickPhotoFromPhotoLibrary:sender];
        return;
	}
	
    actionSheet.tag = TAG_ACTIONSHEET_PHOTO;
    actionSheet.actionSheetStyle = UIActionSheetStyleDefault;
	[actionSheet showInView:postDetailViewController.view];
    WordPressAppDelegate *appDelegate = (WordPressAppDelegate*)[[UIApplication sharedApplication] delegate];
    [appDelegate setAlertRunning:YES];
	
    [actionSheet release];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	if(isShowingMediaPickerActionSheet == YES) {
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
		isShowingMediaPickerActionSheet = NO;
	}
	else if(isShowingChangeOrientationActionSheet == YES) {
		switch (buttonIndex) {
			case 0:
				self.currentOrientation = kPortrait;
				break;
			case 1:
				self.currentOrientation = kLandscape;
				break;
			default:
				self.currentOrientation = kPortrait;
				break;
		}
		[self processRecordedVideo];
		self.isShowingChangeOrientationActionSheet = NO;
	}
	else if(isShowingResizeActionSheet == YES) {
		switch (buttonIndex) {
			case 0:
				if (actionSheet.numberOfButtons == 2)
					[self useImage:[self resizeImage:currentImage toSize:kResizeOriginal]];
				else 
					[self useImage:[self resizeImage:currentImage toSize:kResizeSmall]];
				break;
			case 1:
				if (actionSheet.numberOfButtons == 2)
					[self showCustomSizeAlert];
				else if (actionSheet.numberOfButtons == 3)
					[self useImage:[self resizeImage:currentImage toSize:kResizeOriginal]];
				else
					[self useImage:[self resizeImage:currentImage toSize:kResizeMedium]];
				break;
			case 2:
				if (actionSheet.numberOfButtons == 3)
					[self showCustomSizeAlert];
				else if (actionSheet.numberOfButtons == 4)
					[self useImage:[self resizeImage:currentImage toSize:kResizeOriginal]];
				else
					[self useImage:[self resizeImage:currentImage toSize:kResizeLarge]];
				break;
			case 3:
				if (actionSheet.numberOfButtons == 4)
					[self showCustomSizeAlert];
				else
					[self useImage:[self resizeImage:currentImage toSize:kResizeOriginal]];
				break;
			case 4: 
				[self showCustomSizeAlert]; 
				break;
		}
		self.isShowingResizeActionSheet = NO;
	}
    
    WordPressAppDelegate *appDelegate = (WordPressAppDelegate*)[[UIApplication sharedApplication] delegate];
    [appDelegate setAlertRunning:NO];
	[actionSheet dismissWithClickedButtonIndex:buttonIndex animated:YES];
}

- (void)pickPhotoFromCamera:(id)sender {
	self.currentOrientation = [self interpretOrientation:[UIDevice currentDevice].orientation];
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
		picker.mediaTypes = [NSArray arrayWithObject:(NSString *)kUTTypeImage];
		
		if(pickerContainer == nil)
			pickerContainer = [[UIViewController alloc] init];
		
		if(DeviceIsPad() == YES) {
			UIBarButtonItem *barButton = postDetailViewController.photoButton;
			if (addPopover == nil) {
				addPopover = [[UIPopoverController alloc] initWithContentViewController:picker];
				addPopover.delegate = self;
			}
			
			[addPopover presentPopoverFromBarButtonItem:barButton permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
			[[CPopoverManager instance] setCurrentPopoverController:addPopover];
		}
		else {			
			pickerContainer.view.frame = CGRectMake(0, 0, 320, 480);
			WordPressAppDelegate *appDelegate = (WordPressAppDelegate*)[[UIApplication sharedApplication] delegate];
			[appDelegate.navigationController.view addSubview:pickerContainer.view];
			[appDelegate.navigationController.view bringSubviewToFront:pickerContainer.view];
			[pickerContainer presentModalViewController:picker animated:YES];
		}
    }
}

- (void)pickVideoFromCamera:(id)sender {
	self.currentOrientation = [self interpretOrientation:[UIDevice currentDevice].orientation];
	picker.sourceType =  UIImagePickerControllerSourceTypeCamera;
	picker.mediaTypes = [NSArray arrayWithObject:(NSString *)kUTTypeMovie];
	picker.videoQuality = UIImagePickerControllerQualityTypeMedium;
	
	if([[NSUserDefaults standardUserDefaults] objectForKey:@"video_quality_preference"] != nil) {
		NSString *quality = [[NSUserDefaults standardUserDefaults] objectForKey:@"video_quality_preference"];
		switch ([quality intValue]) {
			case 0:
				picker.videoQuality = UIImagePickerControllerQualityTypeHigh;
				break;
			case 1:
				picker.videoQuality = UIImagePickerControllerQualityTypeMedium;
				break;
			case 2:
				picker.videoQuality = UIImagePickerControllerQualityTypeLow;
				break;
			case 3:
				picker.videoQuality = UIImagePickerControllerQualityType640x480;
				break;
			default:
				picker.videoQuality = UIImagePickerControllerQualityTypeMedium;
				break;
		}
	}
	
	if(DeviceIsPad() == YES) {
		UIBarButtonItem *barButton = postDetailViewController.movieButton;	
		if (addPopover == nil) {
			addPopover = [[UIPopoverController alloc] initWithContentViewController:picker];
			addPopover.delegate = self;
		}
		[addPopover presentPopoverFromBarButtonItem:barButton permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
		[[CPopoverManager instance] setCurrentPopoverController:addPopover];
	}
	else {
		if(pickerContainer == nil)
			pickerContainer = [[UIViewController alloc] init];
		
		pickerContainer.view.frame = CGRectMake(0, 0, 320, 480);
		WordPressAppDelegate *appDelegate = (WordPressAppDelegate*)[[UIApplication sharedApplication] delegate];
		[appDelegate.navigationController.view addSubview:pickerContainer.view];
		[appDelegate.navigationController.view bringSubviewToFront:pickerContainer.view];
		[pickerContainer presentModalViewController:picker animated:YES];
	}
	
	/*[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(deviceDidRotate:)
												 name:@"UIDeviceOrientationDidChangeNotification" object:nil];*/
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

- (void)pickPhotoFromPhotoLibrary:(id)sender {
	UIBarButtonItem *barButton = nil;

    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        if (DeviceIsPad() && addPopover != nil) {
            [addPopover dismissPopoverAnimated:YES];
        }        
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        if ([(UIView *)sender tag] == TAG_ACTIONSHEET_VIDEO) {
			barButton = postDetailViewController.movieButton;
            picker.mediaTypes = [NSArray arrayWithObject:(NSString *)kUTTypeMovie];
			picker.videoQuality = UIImagePickerControllerQualityTypeMedium;
			
			if([[NSUserDefaults standardUserDefaults] objectForKey:@"video_quality_preference"] != nil) {
				NSString *quality = [[NSUserDefaults standardUserDefaults] objectForKey:@"video_quality_preference"];
				switch ([quality intValue]) {
					case 0:
						picker.videoQuality = UIImagePickerControllerQualityTypeHigh;
						break;
					case 1:
						picker.videoQuality = UIImagePickerControllerQualityTypeMedium;
						break;
					case 2:
						picker.videoQuality = UIImagePickerControllerQualityTypeLow;
						break;
					case 3:
						picker.videoQuality = UIImagePickerControllerQualityType640x480;
						break;
					default:
						picker.videoQuality = UIImagePickerControllerQualityTypeMedium;
						break;
				}
			}	
        } else {
			barButton = postDetailViewController.photoButton;
            picker.mediaTypes = [NSArray arrayWithObject:(NSString *)kUTTypeImage];
        }
		isLibraryMedia = YES;
		
		if(DeviceIsPad() == YES) {
            if (addPopover == nil) {
                addPopover = [[UIPopoverController alloc] initWithContentViewController:picker];
                addPopover.delegate = self;
            }
            
            [addPopover presentPopoverFromBarButtonItem:barButton permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
            [[CPopoverManager instance] setCurrentPopoverController:addPopover];
		}
		else {
			if(pickerContainer == nil)
				pickerContainer = [[UIViewController alloc] init];
			
			pickerContainer.view.frame = CGRectMake(0, 0, 320, 480);
            WordPressAppDelegate *appDelegate = (WordPressAppDelegate*)[[UIApplication sharedApplication] delegate];
			[appDelegate.navigationController.view addSubview:pickerContainer.view];
			[appDelegate.navigationController.view bringSubviewToFront:pickerContainer.view];
			[pickerContainer presentModalViewController:picker animated:YES];
		}
    }
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    [addPopover release];
    addPopover = nil;
}

- (void)showOrientationChangedActionSheet {
	isShowingChangeOrientationActionSheet = YES;
	UIActionSheet *orientationActionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Orientation changed during recording. Please choose which orientation to use for this video.", @"") 
																		delegate:self 
															   cancelButtonTitle:nil 
														  destructiveButtonTitle:nil 
															   otherButtonTitles:NSLocalizedString(@"Portrait", @""), NSLocalizedString(@"Landscape", @""), nil];
	[orientationActionSheet showInView:postDetailViewController.view];
	[orientationActionSheet release];
}

- (void)showResizeActionSheet {
	if(self.isShowingResizeActionSheet == NO) {
		isShowingResizeActionSheet = YES;
		
		//the same code used on resize
		CGSize smallSize, mediumSize, largeSize;
		UIImageOrientation orientation = currentImage.imageOrientation; 
		switch (orientation) { 
			case UIImageOrientationUp: 
			case UIImageOrientationUpMirrored:
			case UIImageOrientationDown: 
			case UIImageOrientationDownMirrored:
				smallSize = CGSizeMake(240, 180);
				mediumSize = CGSizeMake(480, 360);
				largeSize = CGSizeMake(640, 480);
				break;
			case UIImageOrientationLeft:
			case UIImageOrientationLeftMirrored:
			case UIImageOrientationRight:
			case UIImageOrientationRightMirrored:
				smallSize = CGSizeMake(180, 240);
				mediumSize = CGSizeMake(360, 480);
				largeSize = CGSizeMake(480, 640);
		}
		
		UIActionSheet *resizeActionSheet;
		//NSLog(@"img dimension: %f x %f ",currentImage.size.width, currentImage.size.height );
		
		if(currentImage.size.width > largeSize.width  && currentImage.size.height > largeSize.height) {
			resizeActionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Choose Image Size", @"") 
															delegate:self 
												   cancelButtonTitle:nil 
											  destructiveButtonTitle:nil 
												   otherButtonTitles:NSLocalizedString(@"Small", @""), NSLocalizedString(@"Medium", @""), NSLocalizedString(@"Large", @""), NSLocalizedString(@"Original", @""), NSLocalizedString(@"Custom", @""), nil];
			
		} else if(currentImage.size.width > mediumSize.width  && currentImage.size.height > mediumSize.height) {
			resizeActionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Choose Image Size", @"") 
															delegate:self 
												   cancelButtonTitle:nil 
											  destructiveButtonTitle:nil 
												   otherButtonTitles:NSLocalizedString(@"Small", @""), NSLocalizedString(@"Medium", @""), NSLocalizedString(@"Original", @""), NSLocalizedString(@"Custom", @""), nil];
			
		} else if(currentImage.size.width > smallSize.width  && currentImage.size.height > smallSize.height) {
			resizeActionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Choose Image Size", @"") 
															delegate:self 
												   cancelButtonTitle:nil 
											  destructiveButtonTitle:nil 
												   otherButtonTitles:NSLocalizedString(@"Small", @""), NSLocalizedString(@"Original", @""), NSLocalizedString(@"Custom", @""), nil];
			
		} else {
			resizeActionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Choose Image Size", @"") 
															delegate:self 
												   cancelButtonTitle:nil 
											  destructiveButtonTitle:nil 
												   otherButtonTitles: NSLocalizedString(@"Original", @""), NSLocalizedString(@"Custom", @""), nil];
		}
		
		[resizeActionSheet showInView:postDetailViewController.view];
		[resizeActionSheet release];
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
		if ([newString intValue] > currentImage.size.width  ) {
			return NO;
		}
	} else {
		if ([newString intValue] > currentImage.size.height) {
			return NO;
		}
	}
    return YES;
}

- (void)showCustomSizeAlert {
	if(self.isShowingCustomSizeAlert == NO) {
		isShowingCustomSizeAlert = YES;
		
		UITextField *textWidth, *textHeight;
		UILabel *labelWidth, *labelHeight;
		
		NSString *lineBreaks;
		
		if (DeviceIsPad())
			lineBreaks = @"\n\n\n\n";
		else 
			lineBreaks = @"\n\n\n";
		
		
		customSizeAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Custom Size", @"") 
																  message:lineBreaks // IMPORTANT
																 delegate:self 
														cancelButtonTitle:NSLocalizedString(@"Cancel", @"") 
														otherButtonTitles:NSLocalizedString(@"OK", @""), nil];
		
		labelWidth = [[UILabel alloc] initWithFrame:CGRectMake(12.0, 50.0, 125.0, 25.0)];
		labelWidth.backgroundColor = [UIColor clearColor];
		labelWidth.textColor = [UIColor whiteColor];
		labelWidth.text = NSLocalizedString(@"Width", @"");
		[customSizeAlert addSubview:labelWidth];
		[labelWidth release];
		
		textWidth = [[UITextField alloc] initWithFrame:CGRectMake(12.0, 80.0, 125.0, 25.0)]; 
		[textWidth setBackgroundColor:[UIColor whiteColor]];
		[textWidth setPlaceholder:NSLocalizedString(@"Width", @"")];
		[textWidth setKeyboardType:UIKeyboardTypeNumberPad];
		[textWidth setDelegate:self];
		[textWidth setTag:123];
		
		// Check for previous width setting
		if([[NSUserDefaults standardUserDefaults] objectForKey:@"prefCustomImageWidth"] != nil)
			[textWidth setText:[[NSUserDefaults standardUserDefaults] objectForKey:@"prefCustomImageWidth"]];
		else
			[textWidth setText:[NSString stringWithFormat:@"%d", (int)currentImage.size.width]];
		
		[customSizeAlert addSubview:textWidth];
		
		labelHeight = [[UILabel alloc] initWithFrame:CGRectMake(145.0, 50.0, 125.0, 25.0)];
		labelHeight.backgroundColor = [UIColor clearColor];
		labelHeight.textColor = [UIColor whiteColor];
		labelHeight.text = NSLocalizedString(@"Height", @"");
		[customSizeAlert addSubview:labelHeight];
		[labelHeight release];
		
		textHeight = [[UITextField alloc] initWithFrame:CGRectMake(145.0, 80.0, 125.0, 25.0)]; 
		[textHeight setBackgroundColor:[UIColor whiteColor]];
		[textHeight setPlaceholder:NSLocalizedString(@"Height", @"")];
		[textHeight setDelegate:self];
		[textHeight setKeyboardType:UIKeyboardTypeNumberPad];
		[textHeight setTag:456];
		
		// Check for previous height setting
		if([[NSUserDefaults standardUserDefaults] objectForKey:@"prefCustomImageHeight"] != nil)
			[textHeight setText:[[NSUserDefaults standardUserDefaults] objectForKey:@"prefCustomImageHeight"]];
		else
			[textHeight setText:[NSString stringWithFormat:@"%d", (int)currentImage.size.height]];
		
		[customSizeAlert addSubview:textHeight];
		
		//fix the dialog position for older devices on iOS 3
		float version = [[[UIDevice currentDevice] systemVersion] floatValue];
		if (version <= 3.1)
		{
			customSizeAlert.transform = CGAffineTransformTranslate(customSizeAlert.transform, 0.0, 100.0);
		}
		
		[customSizeAlert show];
		
		[textWidth becomeFirstResponder];
	}
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
}

- (void)dismissAlertViewKeyboard: (NSNotification*)notification {
	if(isShowingCustomSizeAlert) {
		UITextField *textWidth = (UITextField *)[self.customSizeAlert viewWithTag:123];
		UITextField *textHeight = (UITextField *)[self.customSizeAlert viewWithTag:456];
		[textWidth resignFirstResponder];
		[textHeight resignFirstResponder];
	}
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {

	if (alertView.tag == 101) { //VideoPress Promo Alert
	
		return;
	}
	
	if(buttonIndex == 1) {
		UITextField *textWidth = (UITextField *)[alertView viewWithTag:123];
		UITextField *textHeight = (UITextField *)[alertView viewWithTag:456];
		
		NSNumber *width = [NSNumber numberWithInt:[textWidth.text intValue]];
		NSNumber *height = [NSNumber numberWithInt:[textHeight.text intValue]];
		
		if([width intValue] < 10)
			width = [NSNumber numberWithInt:10];
		if([height intValue] < 10)
			height = [NSNumber numberWithInt:10];
		
		textWidth.text = [NSString stringWithFormat:@"%@", width];
		textHeight.text = [NSString stringWithFormat:@"%@", height];
		
		//NSLog(@"textWidth.text: %@ textHeight.text: %@", textWidth.text, textHeight.text);
		
		[[NSUserDefaults standardUserDefaults] setObject:textWidth.text forKey:@"prefCustomImageWidth"];
		[[NSUserDefaults standardUserDefaults] setObject:textHeight.text forKey:@"prefCustomImageHeight"];
		
		[self useImage:[self resizeImage:currentImage width:[width floatValue] height:[height floatValue]]];
	}
	
	isShowingCustomSizeAlert = NO;
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex{
	addPopover = nil;
}

- (void)imagePickerController:(UIImagePickerController *)thePicker didFinishPickingMediaWithInfo:(NSDictionary *)info {
	if([[info valueForKey:@"UIImagePickerControllerMediaType"] isEqualToString:@"public.movie"]) {
		self.currentVideo = [info retain];
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
		currentImage = [image retain];
		
		//UIImagePickerControllerReferenceURL = "assets-library://asset/asset.JPG?id=1000000050&ext=JPG").
        NSURL *assetURL = [info objectForKey:UIImagePickerControllerReferenceURL];
        if (assetURL) {
            [self getMetadataFromAssetForURL:assetURL];
        } else {
            NSDictionary *metadata = [info objectForKey:UIImagePickerControllerMediaMetadata];
            if (metadata) {
                NSMutableDictionary *mutableMetadata = [metadata mutableCopy];
                [mutableMetadata removeObjectForKey:@"Orientation"];
                [mutableMetadata removeObjectForKey:@"{TIFF}"];
                self.currentImageMetadata = mutableMetadata;
                [mutableMetadata release];
            }
        }
		
		NSNumberFormatter *nf = [[NSNumberFormatter alloc] init];
		[nf setNumberStyle:NSNumberFormatterDecimalStyle];
		NSNumber *resizePreference = [NSNumber numberWithInt:-1];
		if([[NSUserDefaults standardUserDefaults] objectForKey:@"media_resize_preference"] != nil)
			resizePreference = [nf numberFromString:[[NSUserDefaults standardUserDefaults] objectForKey:@"media_resize_preference"]];
		[nf release];
		
		switch ([resizePreference intValue]) {
			case 0:
				[self showResizeActionSheet];
				break;
			case 1:
				[self useImage:[self resizeImage:currentImage toSize:kResizeSmall]];
				break;
			case 2:
				[self useImage:[self resizeImage:currentImage toSize:kResizeMedium]];
				break;
			case 3:
				[self useImage:[self resizeImage:currentImage toSize:kResizeLarge]];
				break;
			case 4:
				//[self useImage:currentImage];
                [self useImage:[self resizeImage:currentImage toSize:kResizeOriginal]];
				break;
			default:
				[self showResizeActionSheet];
				break;
		}
		
		if(DeviceIsPad() == NO) {
			[pickerContainer dismissModalViewControllerAnimated:NO];
			pickerContainer.view.frame = CGRectMake(0, 2000, 0, 0);
		}
	}
	
	if(DeviceIsPad() == YES){
		[addPopover dismissPopoverAnimated:YES];
		[[CPopoverManager instance] setCurrentPopoverController:NULL];
		addPopover = nil;
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
						   
						   WPLog(@"error from getBytes: %@", err);
						   
						   return;
					   } 
					   NSData *imageJPEG = [NSData dataWithBytesNoCopy:buf length:[rep size] 
														  freeWhenDone:YES];  // YES means free malloc'ed buf that backs this when deallocated
					   
					   CGImageSourceRef  source ;
					   source = CGImageSourceCreateWithData((CFDataRef)imageJPEG, NULL);
					   
                       NSDictionary *metadata = (NSDictionary *) CGImageSourceCopyPropertiesAtIndex(source,0,NULL);
                       
                       //make the metadata dictionary mutable so we can remove properties to it
                       NSMutableDictionary *metadataAsMutable = [metadata mutableCopy];
                       [metadata release];

					   if(!self.postDetailViewController.apost.blog.geolocationEnabled) {
						   //we should remove the GPS info if the blog has the geolocation set to off
						   
						   //get all the metadata in the image
						   [metadataAsMutable removeObjectForKey:@"{GPS}"];
					   }
                       [metadataAsMutable removeObjectForKey:@"Orientation"];
                       [metadataAsMutable removeObjectForKey:@"{TIFF}"];
                       self.currentImageMetadata = [NSDictionary dictionaryWithDictionary:metadataAsMutable];
                       [metadataAsMutable release];
					   
					   CFRelease(source);
				   }
				  failureBlock: ^(NSError *err) {
					  WPLog(@"can't get asset %@: %@", url, err);
					  self.currentImageMetadata = nil;
				  }];
    [assetslibrary release];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
	[pickerContainer dismissModalViewControllerAnimated:NO];
	pickerContainer.view.frame = CGRectMake(0, 2000, 0, 0);
}

- (void)processRecordedVideo {
	if(DeviceIsPad() == YES)
		[addPopover dismissPopoverAnimated:YES];
	else {
		NSLog(@"pickerContainer: %@", pickerContainer);
		[pickerContainer dismissModalViewControllerAnimated:NO];
		pickerContainer.view.frame = CGRectMake(0, 2000, 0, 0);
	}
	
	[self.currentVideo setValue:[NSNumber numberWithInt:currentOrientation] forKey:@"orientation"];
	NSString *tempVideoPath = [(NSURL *)[currentVideo valueForKey:UIImagePickerControllerMediaURL] absoluteString];
	tempVideoPath = [[tempVideoPath substringFromIndex:16] retain];
	if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(tempVideoPath)) {
		UISaveVideoAtPathToSavedPhotosAlbum(tempVideoPath, self, @selector(video:didFinishSavingWithError:contextInfo:), tempVideoPath);
	}
	[tempVideoPath release];	
}

- (void)processLibraryVideo {
	NSURL *videoURL = [[currentVideo valueForKey:UIImagePickerControllerMediaURL] retain];
	if(videoURL == nil)
		videoURL = [currentVideo valueForKey:UIImagePickerControllerReferenceURL];
	
	if(videoURL != nil) {
		if(DeviceIsPad() == YES)
			[addPopover dismissPopoverAnimated:YES];
		else {
			[pickerContainer dismissModalViewControllerAnimated:NO];
			pickerContainer.view.frame = CGRectMake(0, 2000, 0, 0);
		}
		
		float osVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
		[self.currentVideo setValue:[NSNumber numberWithInt:currentOrientation] forKey:@"orientation"];
		
		// Determine the video's library path
		NSString *videoPath = [[[videoURL absoluteString] substringFromIndex:16] retain];
		NSURL *contentURL = [NSURL fileURLWithPath:videoPath];
		
		// If we're using iOS 3.2 or greater, we can grab a thumbnail using this method
		UIImage *thumbnail;
		float duration = 0.0;
		if(osVersion >= 3.2) {
			MPMoviePlayerController *mp = [[MPMoviePlayerController alloc] initWithContentURL:contentURL];
			thumbnail = [mp thumbnailImageAtTime:(NSTimeInterval)2.0 timeOption:MPMovieTimeOptionNearestKeyFrame];
			duration = [mp duration];
            [mp stop];
            [mp release];
		}
		else {
			// If not, we'll just use the default thumbnail for now.
			thumbnail = [UIImage imageNamed:@"video_thumbnail.png"];
		}
		
		[self useVideo:videoPath withThumbnail:thumbnail andDuration:duration];
		self.currentVideo = nil;
		self.isLibraryMedia = NO;
		[videoPath release];
	}
	[videoURL release];
}

- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(NSString *)contextInfo {
	float osVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
	NSURL *contentURL = [NSURL fileURLWithPath:videoPath];
	
	// If we're using iOS 3.2 or greater, we can grab a thumbnail using this method
	UIImage *thumbnail = nil;
	float duration = 0.0;
	if(osVersion >= 3.2) {
		MPMoviePlayerController *mp = [[MPMoviePlayerController alloc] initWithContentURL:contentURL];
		thumbnail = [mp thumbnailImageAtTime:(NSTimeInterval)2.0 timeOption:MPMovieTimeOptionNearestKeyFrame];
		duration = [mp duration];
        [mp stop];
        [mp release];
	}
	else {
		// If not, we'll just use the default thumbnail for now.
		thumbnail = [UIImage imageNamed:@"video_thumbnail.png"];
	}
	
	[self useVideo:videoPath withThumbnail:thumbnail andDuration:duration];
	currentVideo = nil;
}

- (UIImage *)fixImageOrientation:(UIImage *)img {
    CGSize size = [img size];
	
    UIImageOrientation imageOrientation = [img imageOrientation];
	
    if (imageOrientation == UIImageOrientationUp)
        return img;
	
    CGImageRef imageRef = [img CGImage];
    CGContextRef bitmap = CGBitmapContextCreate(
												NULL,
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
	CGSize smallSize, mediumSize, largeSize, originalSize;
	UIImageOrientation orientation = original.imageOrientation; 
 	switch (orientation) { 
		case UIImageOrientationUp: 
		case UIImageOrientationUpMirrored:
		case UIImageOrientationDown: 
		case UIImageOrientationDownMirrored:
			smallSize = CGSizeMake(240, 180);
			mediumSize = CGSizeMake(480, 360);
			largeSize = CGSizeMake(640, 480);
            break;
		case UIImageOrientationLeft:
		case UIImageOrientationLeftMirrored:
		case UIImageOrientationRight:
		case UIImageOrientationRightMirrored:
			smallSize = CGSizeMake(180, 240);
			mediumSize = CGSizeMake(360, 480);
			largeSize = CGSizeMake(480, 640);
	}
	
	originalSize = CGSizeMake(currentImage.size.width, currentImage.size.height); //The dimensions of the image, taking orientation into account.
	
	// Resize the image using the selected dimensions
	UIImage *resizedImage = original;
	switch (resize) {
		case kResizeSmall:
			if(currentImage.size.width > smallSize.width  && currentImage.size.height > smallSize.height)
				resizedImage = [original resizedImageWithContentMode:UIViewContentModeScaleAspectFill  
															  bounds:smallSize  
												interpolationQuality:kCGInterpolationHigh]; 
			else  
				resizedImage = [original resizedImageWithContentMode:UIViewContentModeScaleAspectFill  
															  bounds:originalSize  
												interpolationQuality:kCGInterpolationHigh];
			break;
		case kResizeMedium:
			if(currentImage.size.width > mediumSize.width  && currentImage.size.height > mediumSize.height) 
				resizedImage = [original resizedImageWithContentMode:UIViewContentModeScaleAspectFill  
															  bounds:mediumSize  
												interpolationQuality:kCGInterpolationHigh]; 
			else  
				resizedImage = [original resizedImageWithContentMode:UIViewContentModeScaleAspectFill  
															  bounds:originalSize  
												interpolationQuality:kCGInterpolationHigh];
			break;
		case kResizeLarge:
			if(currentImage.size.width > largeSize.width && currentImage.size.height > largeSize.height) 
				resizedImage = [original resizedImageWithContentMode:UIViewContentModeScaleAspectFill  
															  bounds:largeSize  
												interpolationQuality:kCGInterpolationHigh]; 
			else  
				resizedImage = [original resizedImageWithContentMode:UIViewContentModeScaleAspectFill  
															  bounds:originalSize  
												interpolationQuality:kCGInterpolationHigh];
			break;
		case kResizeOriginal:
			resizedImage = [original resizedImageWithContentMode:UIViewContentModeScaleAspectFill 
														  bounds:originalSize 
											interpolationQuality:kCGInterpolationHigh];
			break;
	}

	
	return resizedImage;
}

- (UIImage *)resizeImage:(UIImage *)original width:(CGFloat)width height:(CGFloat)height {
	UIImage *resizedImage = original;
	if(currentImage.size.width > width && currentImage.size.height > height) {
		// Resize the image using the selected dimensions
		resizedImage = [original resizedImageWithContentMode:UIViewContentModeScaleAspectFill 
													  bounds:CGSizeMake(width, height) 
										interpolationQuality:kCGInterpolationHigh];
	} else {
		//use the original dimension
		resizedImage = [original resizedImageWithContentMode:UIViewContentModeScaleAspectFill 
													  bounds:CGSizeMake(currentImage.size.width, currentImage.size.height) 
										interpolationQuality:kCGInterpolationHigh];
	}
	
	return resizedImage;
}

- (UIImage *)generateThumbnailFromImage:(UIImage *)theImage andSize:(CGSize)targetSize {
    return [theImage thumbnailImage:75 transparentBorder:0 cornerRadius:0 interpolationQuality:kCGInterpolationHigh]; 
}

- (void)useImage:(UIImage *)theImage {
	Media *imageMedia = [Media newMediaForPost:postDetailViewController.apost];
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
		CGImageSourceRef  source ;
		source = CGImageSourceCreateWithData((CFDataRef)imageData, NULL);
		CFStringRef UTI = CGImageSourceGetType(source); //this is the type of image (e.g., public.jpeg)
		
		//this will be the data CGImageDestinationRef will write into
		NSMutableData *dest_data = [NSMutableData data];
		
		CGImageDestinationRef destination = CGImageDestinationCreateWithData((CFMutableDataRef)dest_data,UTI,1,NULL);
		
		if(!destination) {
			WPLog(@"***Could not create image destination ***");
		}
		
		//add the image contained in the image source to the destination, copying the old metadata
		CGImageDestinationAddImageFromSource(destination,source,0, (CFDictionaryRef) self.currentImageMetadata);
		
		//tell the destination to write the image data and metadata into our data object.
		//It will return false if something goes wrong
		BOOL success = NO;
		success = CGImageDestinationFinalize(destination);
		
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
		CFRelease(destination);
		CFRelease(source);
    } else {
		NSFileManager *fileManager = [NSFileManager defaultManager];
		[fileManager createFileAtPath:filepath contents:imageData attributes:nil];
	}

	if(currentOrientation == kLandscape)
		imageMedia.orientation = @"landscape";
	else
		imageMedia.orientation = @"portrait";
	imageMedia.creationDate = [NSDate date];
	imageMedia.filename = filename;
	imageMedia.localURL = filepath;
	imageMedia.filesize = [NSNumber numberWithInt:(imageData.length/1024)];
	imageMedia.mediaType = @"image";
	imageMedia.thumbnail = UIImageJPEGRepresentation(imageThumbnail, 0.90);
	imageMedia.width = [NSNumber numberWithInt:theImage.size.width];
	imageMedia.height = [NSNumber numberWithInt:theImage.size.height];
    [imageMedia upload];
	
	isAddingMedia = NO;
	
	//switch to the attachment view if we're not already there
	[postDetailViewController switchToMedia];
	
	[formatter release];
    [imageMedia release];
}

- (void)useVideo:(NSString *)videoURL withThumbnail:(UIImage *)thumbnail andDuration:(float)duration {
	BOOL copySuccess = FALSE;
	Media *videoMedia;
	NSDictionary *attributes;
	UIImage *videoThumbnail = [self generateThumbnailFromImage:thumbnail andSize:CGSizeMake(75, 75)];
	
	// Save to local file
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"yyyyMMdd-HHmmss"];	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	NSString *filename = [[NSString stringWithFormat:@"%@.mov", [formatter stringFromDate:[NSDate date]]] retain];
	NSString *filepath = [[documentsDirectory stringByAppendingPathComponent:filename] retain];
	
	if(videoURL != nil) {
		// Copy the video from temp to blog directory
		NSError *error = nil;
		if ((attributes = [fileManager fileAttributesAtPath:videoURL traverseLink:YES]) != nil) {
			if([fileManager isReadableFileAtPath:videoURL] == YES)
				copySuccess = [fileManager copyItemAtPath:videoURL toPath:filepath error:&error];
		}
	}
	
	if(copySuccess == YES) {
		videoMedia = [Media newMediaForPost:postDetailViewController.apost];
		
		if(currentOrientation == kLandscape)
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

		[videoMedia upload];
		isAddingMedia = NO;
		
		//switch to the attachment view if we're not already there 
		[postDetailViewController switchToMedia];
		[videoMedia release];
	}
	else {
		UIAlertView *videoAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error Copying Video", @"") 
															 message:NSLocalizedString(@"There was an error copying the video for upload. Please try again.", @"")
															delegate:self
												   cancelButtonTitle:NSLocalizedString(@"OK", @"") 
												   otherButtonTitles:nil];
		[videoAlert show];
		[videoAlert release];
	}
    [formatter release];
    [filename release];
    [filepath release];
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
        // FIXME: media deleted during upload should cancel the upload. In the meantime, we'll try not to crash
        NSLog(@"Media deleted while uploading (%@)", media);
        [FlurryAPI logError:@"MediaDeleted"
                    message:[NSString stringWithFormat:@"Media deleted while uploading (%@)", currentUpload]
                      error:nil];
        return;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ShouldInsertMediaBelow" object:media];
    [media save];
	self.isAddingMedia = NO;
}

- (void)mediaUploadFailed:(NSNotification *)notification {
    /*Media *media = (Media *)[notification object];
    [media remove];*/
	self.isAddingMedia = NO;
}

- (void)deviceDidRotate:(NSNotification *)notification {
	if(isAddingMedia == YES) {
		if(self.currentOrientation != [self interpretOrientation:[[UIDevice currentDevice] orientation]]) {		
			self.currentOrientation = [self interpretOrientation:[[UIDevice currentDevice] orientation]];
			didChangeOrientationDuringRecord = YES;
		}
	}
}

- (void)checkVideoPressEnabled {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	if(self.isCheckingVideoCapability == NO) {
		self.isCheckingVideoCapability = YES;
		self.videoPressCheckBlogURL = postDetailViewController.apost.blog.url;
		
		@try {
			//removed the check on the blog URL. we should be able to use VideoPress on self hosted blog
			//NSRange textRange = [[self.videoPressCheckBlogURL lowercaseString] rangeOfString:@"wordpress.com"];
			//if(textRange.location != NSNotFound)
			//{
			NSError *error = nil;
			NSString *username = self.postDetailViewController.apost.blog.username;
			NSString *password = [SFHFKeychainUtils getPasswordForUsername:username
															andServiceName:self.postDetailViewController.apost.blog.hostURL
																	 error:&error];
			
			NSArray *args = [NSArray arrayWithObjects:self.postDetailViewController.apost.blog.blogID,username, password, nil];
			
			NSMutableDictionary *xmlrpcParams = [[NSMutableDictionary alloc] init];
			[xmlrpcParams setObject:self.postDetailViewController.apost.blog.xmlrpc forKey:kURL];
			[xmlrpcParams setObject:@"wpcom.getFeatures" forKey:kMETHOD];
			[xmlrpcParams setObject:args forKey:kMETHODARGS];
			
			XMLRPCRequest *request = [[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:[xmlrpcParams valueForKey:kURL]]];
			[request setMethod:[xmlrpcParams valueForKey:kMETHOD] withObjects:[xmlrpcParams valueForKey:kMETHODARGS]];
			[xmlrpcParams release];
			
			XMLRPCResponse *response = [XMLRPCConnection sendSynchronousXMLRPCRequest:request];
			if ([response isKindOfClass:[NSError class]]) {
				self.videoEnabled = YES;
				self.isCheckingVideoCapability = NO;
				WPLog(@"checkVideoEnabled failed: %@", response);
				return;
			}
			if(([response.object isKindOfClass:[NSDictionary class]] == YES) && ([response.object objectForKey:@"videopress_enabled"] != nil))
				self.videoEnabled = [[response.object objectForKey:@"videopress_enabled"] boolValue];
			else if(([response.object isKindOfClass:[NSDictionary class]] == YES) && ([response.object objectForKey:@"faultCode"] != nil)) {
				if([[response.object objectForKey:@"faultCode"] intValue] == -32601) //server error. requested method wpcom.getFeatures does not exist.
					self.videoEnabled = YES;
				else
					self.videoEnabled = NO;
			}
			else
				self.videoEnabled = YES;
			
			[request release];
			//}
			//	else
			//		self.videoEnabled = YES;
		}
		@catch (NSException * e) {
			self.videoEnabled = YES;
		}
		@finally {
			self.isCheckingVideoCapability = NO;
		}
	}
	
	[pool release];
}

#pragma mark -
#pragma mark Results Controller

- (NSFetchedResultsController *)resultsController {
    if (resultsController != nil) {
        return resultsController;
    }
    
    WordPressAppDelegate *appDelegate = (WordPressAppDelegate*)[[UIApplication sharedApplication] delegate];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"Media" inManagedObjectContext:appDelegate.managedObjectContext]];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"%@ IN posts", self.postDetailViewController.apost]];
    NSSortDescriptor *sortDescriptorDate = [[NSSortDescriptor alloc] initWithKey:@"creationDate" ascending:NO];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptorDate, nil];
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    resultsController = [[NSFetchedResultsController alloc]
                                                      initWithFetchRequest:fetchRequest
                                                      managedObjectContext:appDelegate.managedObjectContext
                                                      sectionNameKeyPath:nil
                                                      cacheName:[NSString stringWithFormat:@"Media-%@-%@",
                                                                 self.postDetailViewController.apost.blog.hostURL,
                                                                 self.postDetailViewController.apost.postID]];
    resultsController.delegate = self;
    
    [fetchRequest release];
    [sortDescriptorDate release]; sortDescriptorDate = nil;
    [sortDescriptors release]; sortDescriptors = nil;
    
    NSError *error = nil;
    if (![resultsController performFetch:&error]) {
        NSLog(@"Couldn't fetch media");
        resultsController = nil;
    }
    
    return resultsController;
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
    [table reloadData];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	if (DeviceIsPad())
		return YES;
	
	return NO;
}

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark Dealloc

- (void)dealloc {
	[picker release], picker = nil;
	[customSizeAlert release]; customSizeAlert = nil;
	[uniqueID release];
	[addPopover release];
	[bottomToolbar release];
	[videoPressCheckBlogURL release];
	[currentUpload release];
	[blogURL release];
	[postID release];
	[messageLabel release];
	[currentVideo release];
	[currentImage release];
	self.currentImageMetadata = nil;
	[currentImageMetadata release];
	[spinner release];
	[table release];
	[addMediaButton release];
	[photos release];
	[videos release];
	[super dealloc];
}

@end

