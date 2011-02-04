//
//  PostMediaViewController.m
//  WordPress
//
//  Created by Chris Boyd on 8/26/10.
//  Code is poetry.
//

#import "PostMediaViewController.h"

@implementation PostMediaViewController
@synthesize table, addMediaButton, hasPhotos, hasVideos, isAddingMedia, photos, videos, appDelegate, dm, addPopover, picker;
@synthesize isShowingMediaPickerActionSheet, currentOrientation, isShowingChangeOrientationActionSheet, spinner, pickerContainer;
@synthesize currentImage, currentVideo, isLibraryMedia, didChangeOrientationDuringRecord, messageLabel, topToolbar;
@synthesize postDetailViewController, mediaManager, postID, blogURL, mediaTypeControl, mediaUploader, bottomToolbar;
@synthesize isShowingResizeActionSheet, isShowingCustomSizeAlert, videoEnabled, uploadID, videoPressCheckBlogURL, isCheckingVideoCapability, uniqueID;

#define NUMBERS	@"0123456789"

#pragma mark -
#pragma mark View lifecycle

- (void)initObjects {
	mediaManager = [[MediaManager alloc] init];
	photos = [[NSMutableArray alloc] init];
	videos = [[NSMutableArray alloc] init];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
		[self initObjects];
		[self refreshProperties];
    }
	
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [FlurryAPI logEvent:@"PostMedia"];
	
	self.currentOrientation = [self interpretOrientation:[UIDevice currentDevice].orientation];
	
	dm = [BlogDataManager sharedDataManager];
	appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
	picker = [[WPImagePickerController alloc] init];
	picker.delegate = self;
	picker.allowsEditing = NO;
	
	[self initObjects];
	[self refreshProperties];
	[self performSelectorInBackground:@selector(checkVideoEnabled) withObject:nil];
	
    [self addNotifications];
}


- (void)addNotifications {
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mediaDidUploadSuccessfully:) name:VideoUploadSuccessful object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mediaDidUploadSuccessfully:) name:ImageUploadSuccessful object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mediaUploadFailed:) name:VideoUploadFailed object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mediaUploadFailed:) name:ImageUploadFailed object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(shouldDeleteMedia:) name:@"ShouldDeleteMedia"	object:nil];
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
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super viewDidUnload];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    int result = 0;
	switch (mediaTypeControl.selectedSegmentIndex) {
		case 0:
			if(photos != nil)
				result = photos.count;
			break;
		case 1:
			if(videos != nil)
				result = videos.count;
			break;
		default:
			break;
	}
	return result;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
	}
    
	Media *media = nil;
	NSString *filesizeString = nil;
	
	switch (mediaTypeControl.selectedSegmentIndex) {
		case 0:
			media = [photos objectAtIndex:indexPath.row];
			cell.imageView.image = [UIImage imageWithData:media.thumbnail];
			if(media.title != nil)
				cell.textLabel.text = media.title;
			else
				cell.textLabel.text = media.filename;
			if([media.filesize floatValue] > 1024)
				filesizeString = [NSString stringWithFormat:@"%.2f MB", ([media.filesize floatValue]/1024)];
			else
				filesizeString = [NSString stringWithFormat:@"%.2f KB", [media.filesize floatValue]];
			
			cell.detailTextLabel.text = [NSString stringWithFormat:@"%dx%d %@", 
										 [media.width intValue], [media.height intValue], filesizeString];
			break;
		case 1:
			media = [videos objectAtIndex:indexPath.row];
			cell.imageView.image = [UIImage imageWithData:media.thumbnail];
			if(media.title != nil)
				cell.textLabel.text = media.title;
			else
				cell.textLabel.text = media.filename;
			
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
			break;
		default:
			break;
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
	
	MediaObjectViewController *mediaView = [[MediaObjectViewController alloc] initWithNibName:@"MediaObjectView" bundle:nil];
	switch (mediaTypeControl.selectedSegmentIndex) {
		case 0:
        {
			Media *photo = [photos objectAtIndex:indexPath.row];
			[mediaView setMedia:photo];
			break;
        }
		case 1:
        {
			Media *video = [videos objectAtIndex:indexPath.row];
			[mediaView setMedia:video];
			break;
        }
		default:
			break;
	}
	if(DeviceIsPad() == YES)
		[appDelegate.splitViewController presentModalViewController:mediaView animated:YES];
	else
		[appDelegate.navigationController pushViewController:mediaView animated:YES];
	[mediaView release];
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

-(void)tableView:(UITableView*)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath {
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	// If row is deleted, remove it from the list.
	if (editingStyle == UITableViewCellEditingStyleDelete)
	{
		if(mediaTypeControl.selectedSegmentIndex == 0) {
			[[NSNotificationCenter defaultCenter] postNotificationName:@"ShouldRemoveMedia" object:[photos objectAtIndex:indexPath.row]];
			[self deleteMedia:[photos objectAtIndex:indexPath.row]];
		}
		else if(mediaTypeControl.selectedSegmentIndex == 1) {
			[[NSNotificationCenter defaultCenter] postNotificationName:@"ShouldRemoveMedia" object:[videos objectAtIndex:indexPath.row]];
			[self deleteMedia:[videos objectAtIndex:indexPath.row]];
		}
		
		[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationTop];
	}
	[self refreshMedia];
}

#pragma mark -
#pragma mark Custom methods

- (IBAction)refreshMedia {
	if(isAddingMedia == YES) {
		self.messageLabel.text = @"Adding media...";
		[self.spinner startAnimating];
	}
	else {
		photos = [[mediaManager getForPostID:self.uniqueID andBlogURL:self.blogURL andMediaType:kImage] retain];
		videos = [[mediaManager getForPostID:self.uniqueID andBlogURL:self.blogURL andMediaType:kVideo] retain];
		
		if(photos.count == 0)
			photos = [[mediaManager getForBlogURL:self.blogURL andMediaType:kImage] retain];
		if(videos.count == 0)
			videos = [[mediaManager getForBlogURL:self.blogURL andMediaType:kVideo] retain];
	}
	[self updateMediaCount];
    [self.table reloadData];
	[self.spinner stopAnimating];
}

- (void)updateMediaCount {
	int mediaCount = 0;
	NSString *mediaTypeString;
	switch (mediaTypeControl.selectedSegmentIndex) {
		case 0:
			mediaCount = photos.count;
			mediaTypeString = @"photo";
			break;
		case 1:
			mediaCount = videos.count;
			mediaTypeString = @"video";
			break;
		default:
            mediaTypeString = @"";
			break;
	}
	
	switch (mediaCount) {
		case 0:
			self.messageLabel.text = [NSString stringWithFormat:@"No %@s.", mediaTypeString];
			break;
		case 1:
			self.messageLabel.text = [NSString stringWithFormat:@"%d %@.", mediaCount, mediaTypeString];
			break;
		default:
			self.messageLabel.text = [NSString stringWithFormat:@"%d %@s.", mediaCount, mediaTypeString];
			break;
	}
}

- (void)scaleAndRotateImage:(UIImage *)image {
	NSLog(@"scaling and rotating image...");
}

- (IBAction)showPhotoPickerActionSheet {
    isShowingMediaPickerActionSheet = YES;
	isAddingMedia = YES;
	
	NSString *addMedia;
	if (mediaTypeControl.selectedSegmentIndex == 1)
		addMedia = @"Add Video from Library";
    else
        addMedia = @"Add Photo from Library";

	
	UIActionSheet *actionSheet;
	if([self supportsVideo] == YES) {
		actionSheet = [[UIActionSheet alloc] initWithTitle:@"" 
												  delegate:self 
										 cancelButtonTitle:@"Cancel" 
									destructiveButtonTitle:nil 
										 otherButtonTitles:addMedia,@"Take Photo",@"Record Video",nil];
	}
	else if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
		actionSheet = [[UIActionSheet alloc] initWithTitle:@"" 
												  delegate:self 
										 cancelButtonTitle:@"Cancel" 
									destructiveButtonTitle:nil 
										 otherButtonTitles:addMedia,@"Take Photo",nil];
	}
	else {
		actionSheet = [[UIActionSheet alloc] initWithTitle:@"" 
												  delegate:self 
										 cancelButtonTitle:@"Cancel" 
									destructiveButtonTitle:nil 
										 otherButtonTitles:addMedia,nil];
	}
	
    actionSheet.actionSheetStyle = UIActionSheetStyleDefault;
	[actionSheet showInView:super.tabBarController.view];
    [appDelegate setAlertRunning:YES];
	
    [actionSheet release];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	if(isShowingMediaPickerActionSheet == YES) {
		switch (actionSheet.numberOfButtons) {
			case 2:
				if(buttonIndex == 0)
					[self pickPhotoFromPhotoLibrary:self];
				else {
					self.isAddingMedia = NO;
				}
				break;
			case 3:
				if(buttonIndex == 0) {
					[self pickPhotoFromPhotoLibrary:self];
				}
				else if(buttonIndex == 1) {
					[self pickPhotoFromCamera:self];
				}
				else {
					self.isAddingMedia = NO;
				}
				break;
			case 4:
				switch (buttonIndex) {
					case 0:
						[self pickPhotoFromPhotoLibrary:self];
						break;
					case 1:
						[self pickPhotoFromCamera:self];
						break;
					case 2:
						[self pickVideoFromCamera:self];
						break;
					default:
						self.isAddingMedia = NO;
						break;
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
		
		switch (actionSheet.numberOfButtons) {
			case 5: //@"Small", @"Medium", @"Large", @"Original", @"Custom",
				switch (buttonIndex) {
					case 0:
						[self useImage:[self resizeImage:currentImage toSize:kResizeSmall]];
						break;
					case 1:
						[self useImage:[self resizeImage:currentImage toSize:kResizeMedium]];
						break;
					case 2:
						[self useImage:[self resizeImage:currentImage toSize:kResizeLarge]];
						break;
					case 3:
						[self useImage:[self resizeImage:currentImage toSize:kResizeOriginal]];
						break;
					case 4:
						[self showCustomSizeAlert];
						break;
				}
				break;
			case 4: //@"Small", @"Medium", @"Original", @"Custom",
				switch (buttonIndex) {
					case 0:
						[self useImage:[self resizeImage:currentImage toSize:kResizeSmall]];
						break;
					case 1:
						[self useImage:[self resizeImage:currentImage toSize:kResizeMedium]];
						break;
					case 2:
						[self useImage:[self resizeImage:currentImage toSize:kResizeOriginal]];
						break;
					case 3:
						[self showCustomSizeAlert];
						break;
				}
				break;
			case 3: //@"Small", @"Original", @"Custom",
				switch (buttonIndex) {
					case 0:
						[self useImage:[self resizeImage:currentImage toSize:kResizeSmall]];
						break;
					case 1:
						[self useImage:[self resizeImage:currentImage toSize:kResizeOriginal]];
						break;
					case 2:
						[self showCustomSizeAlert];
						break;
				}
				break;
			case 2: //@"Original", @"Custom",
				switch (buttonIndex) {
					case 0:
						[self useImage:[self resizeImage:currentImage toSize:kResizeOriginal]];
						break;
					case 1:
						[self showCustomSizeAlert];
						break;
				}
			break;
				
			default:
				break;		
		}		
		
		self.isShowingResizeActionSheet = NO;
		
	}
	else {
        [appDelegate setAlertRunning:NO];
		
        [currentImage release];
        currentImage = nil;
	}
	[actionSheet dismissWithClickedButtonIndex:buttonIndex animated:YES];
}

- (void)pickPhotoFromCamera:(id)sender {
	self.currentOrientation = [self interpretOrientation:[UIDevice currentDevice].orientation];
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
		picker.mediaTypes = [NSArray arrayWithObject:(NSString *)kUTTypeImage];
		
		if(pickerContainer == nil)
			pickerContainer = [[UIViewController alloc] init];
		
		pickerContainer.view.frame = CGRectMake(0, 0, 320, 480);
		[appDelegate.navigationController.view addSubview:pickerContainer.view];
		[appDelegate.navigationController.view bringSubviewToFront:pickerContainer.view];
		[pickerContainer presentModalViewController:picker animated:YES];
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
	
	if(pickerContainer == nil)
		pickerContainer = [[UIViewController alloc] init];
	
	pickerContainer.view.frame = CGRectMake(0, 0, 320, 480);
	[appDelegate.navigationController.view addSubview:pickerContainer.view];
	[appDelegate.navigationController.view bringSubviewToFront:pickerContainer.view];
	[pickerContainer presentModalViewController:picker animated:YES];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(deviceDidRotate:)
												 name:@"UIDeviceOrientationDidChangeNotification" object:nil];
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
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
		NSArray *availableMediaTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
		[picker setMediaTypes:availableMediaTypes];
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
		isLibraryMedia = YES;
		
		if(DeviceIsPad() == YES) {
            if (addPopover == nil) {
                addPopover = [[UIPopoverController alloc] initWithContentViewController:picker];
                addPopover.delegate = self;
                [addPopover presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
            }
		}
		else {
			if(pickerContainer == nil)
				pickerContainer = [[UIViewController alloc] init];
			
			pickerContainer.view.frame = CGRectMake(0, 0, 320, 480);
			[appDelegate.navigationController.view addSubview:pickerContainer.view];
			[appDelegate.navigationController.view bringSubviewToFront:pickerContainer.view];
			[pickerContainer presentModalViewController:picker animated:YES];
		}
    }
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    [addPopover release];
    addPopover = nil;
	if (DeviceIsPad())
		[picker popToRootViewControllerAnimated:YES];
}

- (void)showOrientationChangedActionSheet {
	isShowingChangeOrientationActionSheet = YES;
	UIActionSheet *orientationActionSheet = [[UIActionSheet alloc] initWithTitle:@"Orientation changed during recording. Please choose which orientation to use for this video." 
																		delegate:self 
															   cancelButtonTitle:@"Portrait" 
														  destructiveButtonTitle:nil 
															   otherButtonTitles:@"Landscape", nil];
	[orientationActionSheet showInView:super.tabBarController.view];
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
			resizeActionSheet = [[UIActionSheet alloc] initWithTitle:@"Choose Image Size" 
															delegate:self 
												   cancelButtonTitle:nil 
											  destructiveButtonTitle:nil 
												   otherButtonTitles:@"Small", @"Medium", @"Large", @"Original", @"Custom", nil];
			
		} else if(currentImage.size.width > mediumSize.width  && currentImage.size.height > mediumSize.height) {
			resizeActionSheet = [[UIActionSheet alloc] initWithTitle:@"Choose Image Size" 
															delegate:self 
												   cancelButtonTitle:nil 
											  destructiveButtonTitle:nil 
												   otherButtonTitles:@"Small", @"Medium", @"Original", @"Custom", nil];
			
		} else if(currentImage.size.width > smallSize.width  && currentImage.size.height > smallSize.height) {
			resizeActionSheet = [[UIActionSheet alloc] initWithTitle:@"Choose Image Size" 
															delegate:self 
												   cancelButtonTitle:nil 
											  destructiveButtonTitle:nil 
												   otherButtonTitles:@"Small", @"Original", @"Custom", nil];

		} else {
			resizeActionSheet = [[UIActionSheet alloc] initWithTitle:@"Choose Image Size" 
															delegate:self 
												   cancelButtonTitle:nil 
											  destructiveButtonTitle:nil 
												   otherButtonTitles: @"Original", @"Custom", nil];
		}
		
		[resizeActionSheet showInView:super.tabBarController.view];
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

		
		UIAlertView *customSizeAlert = [[UIAlertView alloc] initWithTitle:@"Custom Size" 
														 message:lineBreaks // IMPORTANT
														delegate:self 
											   cancelButtonTitle:@"Cancel" 
											   otherButtonTitles:@"OK", nil];
		
		labelWidth = [[UILabel alloc] initWithFrame:CGRectMake(12.0, 50.0, 125.0, 25.0)];
		labelWidth.backgroundColor = [UIColor clearColor];
		labelWidth.textColor = [UIColor whiteColor];
		labelWidth.text = @"Width";
		[customSizeAlert addSubview:labelWidth];
		
		textWidth = [[UITextField alloc] initWithFrame:CGRectMake(12.0, 80.0, 125.0, 25.0)]; 
		[textWidth setBackgroundColor:[UIColor whiteColor]];
		[textWidth setPlaceholder:@"Width"];
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
		labelHeight.text = @"Height";
		[customSizeAlert addSubview:labelHeight];
		
		textHeight = [[UITextField alloc] initWithFrame:CGRectMake(145.0, 80.0, 125.0, 25.0)]; 
		[textHeight setBackgroundColor:[UIColor whiteColor]];
		[textHeight setPlaceholder:@"Height"];
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
		[customSizeAlert release];
		
		[textWidth becomeFirstResponder];
	}
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (alertView.tag == kVideoPressAlertTag) {
		if(buttonIndex == 1) {
			[[UIApplication sharedApplication] openURL:[NSURL URLWithString: @"http://videopress.com"]];
		}
	}
	else {
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
}

#pragma mark -

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex{
	addPopover = nil;
}

- (void)imagePickerController:(UIImagePickerController *)thePicker didFinishPickingMediaWithInfo:(NSDictionary *)info {
	if([[info valueForKey:@"UIImagePickerControllerMediaType"] isEqualToString:@"public.movie"]) {
		[self refreshMedia];
		self.currentVideo = [info retain];
		if(self.didChangeOrientationDuringRecord == YES)
			[self showOrientationChangedActionSheet];
		else if(self.isLibraryMedia == NO)
			[self processRecordedVideo];
		else
			[self performSelectorOnMainThread:@selector(processLibraryVideo) withObject:nil waitUntilDone:NO];
		
		if(DeviceIsPad() == YES){
			[addPopover dismissPopoverAnimated:YES];
			addPopover = nil;
			[picker popToRootViewControllerAnimated:YES];
		}
	}
	else if([[info valueForKey:@"UIImagePickerControllerMediaType"] isEqualToString:@"public.image"]) {
		
		if(DeviceIsPad() == YES){
			[addPopover dismissPopoverAnimated:YES];
			addPopover = nil;
		}
		else {
			[pickerContainer dismissModalViewControllerAnimated:NO];
			pickerContainer.view.frame = CGRectMake(0, 2000, 0, 0);
		}
		
		UIImage *image = [info valueForKey:@"UIImagePickerControllerOriginalImage"];
		if (thePicker.sourceType == UIImagePickerControllerSourceTypeCamera)
			UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
		currentImage = [image retain];
		
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
				[self useImage:currentImage];
				break;
			default:
				[self showResizeActionSheet];
				break;
		}
	}
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
	[pickerContainer dismissModalViewControllerAnimated:NO];
	pickerContainer.view.frame = CGRectMake(0, 2000, 0, 0);
}

- (void)processRecordedVideo {
	if(DeviceIsPad() == YES)
		[addPopover dismissPopoverAnimated:YES];
	else {
		//NSLog(@"pickerContainer: %@", pickerContainer);
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
	
	[self refreshMedia];
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
			thumbnail = [UIImage imageNamed:@"video_thumbnail"];
		}
		
		[self useVideo:videoPath withThumbnail:thumbnail andDuration:duration];
		self.currentVideo = nil;
		self.isLibraryMedia = NO;
		[self refreshMedia];
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
		thumbnail = [UIImage imageNamed:@"video_thumbnail"];
	}
	
	[self useVideo:videoPath withThumbnail:thumbnail andDuration:duration];
	currentVideo = nil;
}


// FIXME: we should use a more performat function
-(UIImage *)fixImageOrientation:(UIImage *)image {
	
	UIImageOrientation imageOrientation = [image imageOrientation];
    if (imageOrientation == UIImageOrientationUp || imageOrientation == UIImageOrientationLeft || imageOrientation == UIImageOrientationRight)
        return image;
	
	UIImageView *imageView = [[UIImageView alloc] init];
	
	UIImage *imageCopy = [[UIImage alloc] initWithCGImage:image.CGImage];
	
	
	switch (imageOrientation) {
		case UIImageOrientationLeft:
			imageView.transform = CGAffineTransformMakeRotation(3.0 * M_PI / 2.0);
			break;
		case UIImageOrientationRight:
			imageView.transform = CGAffineTransformMakeRotation(M_PI / 2.0);
			break;
		case UIImageOrientationDown: //EXIF = 3
			imageView.transform = CGAffineTransformMakeRotation(M_PI);
			break;
		default:
			return image; //return the original image
			break;
	}
	
	imageView.image = imageCopy;
	return (imageView.image);
}


/* 
 * this method doesn't work
 
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
*/

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
	
	//rotate the img before the resizing. During the resizing process we lost all the EXIF data...
	original = [self fixImageOrientation:original];
	
	// Resize the image using the selected dimensions
	UIImage *resizedImage = original;
	switch (resize) {
		case kResizeSmall:
			//NSLog(@"%f , %f ",currentImage.size.width, smallSize.width );
			//NSLog(@"%f , %f ",currentImage.size.height , smallSize.height );
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
			//NSLog(@"%f , %f ",currentImage.size.width, mediumSize.width );
			//NSLog(@"%f , %f ",currentImage.size.height , mediumSize.height );
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
			//NSLog(@"%f , %f ",currentImage.size.width, largeSize.width );
			//NSLog(@"%f , %f ",currentImage.size.height , largeSize.height );
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
	Media *imageMedia = [mediaManager get:nil];
	NSDictionary *currentBlog = [dm currentBlog];
	NSData *imageData = UIImageJPEGRepresentation([self fixImageOrientation:theImage], 0.90);
	UIImage *imageThumbnail = [self generateThumbnailFromImage:theImage andSize:CGSizeMake(75, 75)];
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"yyyyMMdd-hhmmss"];
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	NSString *filename = [NSString stringWithFormat:@"%@.jpg", [formatter stringFromDate:[NSDate date]]];
	NSString *filepath = [documentsDirectory stringByAppendingPathComponent:filename];
	[fileManager createFileAtPath:filepath contents:imageData attributes:nil];
	
	imageMedia.postID = self.postID;
	imageMedia.blogID = [currentBlog valueForKey:@"blogid"];
	imageMedia.blogURL = self.blogURL;
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
	[mediaManager save:imageMedia];
	
	// Save to remote server
	self.uploadID = imageMedia.uniqueID;
	[self uploadMedia:imageData withFilename:filename andLocalURL:imageMedia.localURL andMediaType:kImage];
	
	//[self updatePhotosBadge];
	
	self.mediaTypeControl.selectedSegmentIndex = 0;
	isAddingMedia = NO;
	[formatter release];
	[self refreshMedia];
}

- (void)useVideo:(NSString *)videoURL withThumbnail:(UIImage *)thumbnail andDuration:(float)duration {
	BOOL copySuccess = FALSE;
	Media *videoMedia;
	NSDictionary *attributes;
	NSDictionary *currentBlog = [dm currentBlog];
	UIImage *videoThumbnail = [self generateThumbnailFromImage:thumbnail andSize:CGSizeMake(75, 75)];
	
	// Save to local file
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"yyyyMMdd-hhmmss"];	NSFileManager *fileManager = [NSFileManager defaultManager];
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
		[mediaManager doReport];
		videoMedia = [(Media *)[NSEntityDescription insertNewObjectForEntityForName:@"Media" 
															 inManagedObjectContext:appDelegate.managedObjectContext] retain];
		[videoMedia setUniqueID:[[NSProcessInfo processInfo] globallyUniqueString]];
		[mediaManager doReport];
		
		// Save to local database
		videoMedia.postID = self.postID;
		videoMedia.blogID = [currentBlog valueForKey:@"blogid"];
		videoMedia.blogURL = self.blogURL;
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
		
		// Save to db
		[mediaManager doReport];
		NSError *error;
		if (![appDelegate.managedObjectContext save:&error]) {
			NSLog(@"Failed to save to data store: %@", [error localizedDescription]);
			NSArray* detailedErrors = [[error userInfo] objectForKey:NSDetailedErrorsKey];
			if(detailedErrors != nil && [detailedErrors count] > 0) {
				for(NSError* detailedError in detailedErrors) {
					NSLog(@"  DetailedError: %@", [detailedError userInfo]);
				}
			}
			else {
				NSLog(@"  %@", [error userInfo]);
			}
			
			
			UIAlertView *videoAlert = [[UIAlertView alloc] initWithTitle:@"Error Copying Video" 
																 message:@"There was an error copying the video for upload. Please try again."
																delegate:self
													   cancelButtonTitle:@"OK" 
													   otherButtonTitles:nil];
			[videoAlert show];
			[videoAlert release];
		
		} else {
			// Save to remote server
			self.uploadID = videoMedia.uniqueID;
			[self uploadMedia:nil withFilename:filename andLocalURL:videoMedia.localURL andMediaType:kVideo];
		}
		
		[videoMedia release];
		
		//[self updatePhotosBadge];
		self.mediaTypeControl.selectedSegmentIndex = 1;
		isAddingMedia = NO;
		[self refreshMedia];
	}
	else {
		UIAlertView *videoAlert = [[UIAlertView alloc] initWithTitle:@"Error Copying Video" 
															 message:@"There was an error copying the video for upload. Please try again."
															delegate:self
												   cancelButtonTitle:@"OK" 
												   otherButtonTitles:nil];
		[videoAlert show];
		[videoAlert release];
	}
    [formatter release];
    [filename release];
    [filepath release];
}

- (NSString *)getUUID
{
	CFUUIDRef theUUID = CFUUIDCreate(NULL);
	CFStringRef string = CFUUIDCreateString(NULL, theUUID);
	CFRelease(theUUID);
	return [(NSString *)string autorelease];
}

- (void)uploadMedia:(NSData *)bits withFilename:(NSString *)filename andLocalURL:(NSString *)localURL andMediaType:(MediaType)mediaType {
	@try {
		CGRect iPhoneFrameStart = CGRectMake(0, 480, 320, 40);
		CGRect iPhoneFrameEnd = CGRectMake(0, 324, 320, 40);
		CGRect iPadFrameStart = CGRectMake(30, self.view.frame.size.height, bottomToolbar.frame.size.width-60, bottomToolbar.frame.size.height);
		CGRect iPadFrameEnd = CGRectMake(30, self.view.frame.size.height - 44, bottomToolbar.frame.size.width-60, bottomToolbar.frame.size.height);
		
		NSFileManager *fileManager = [NSFileManager defaultManager];
		
		if (mediaUploader == nil){
			if(DeviceIsPad() == YES)
				mediaUploader = [[WPMediaUploader alloc] initWithNibName:@"WPMediaUploader-iPad" bundle:nil];
			else
				mediaUploader = [[WPMediaUploader alloc] initWithNibName:@"WPMediaUploader" bundle:nil];
		}
		
		if(mediaType == kImage) {
			[mediaUploader setBits:bits];
			[mediaUploader setLocalURL:localURL];
		}
		else if(mediaType == kVideo) {
			[mediaUploader setLocalURL:localURL];
		}
		
		[mediaUploader setFilename:filename];
		[mediaUploader setOrientation:currentOrientation];
		[mediaUploader setMediaType:mediaType];
		
		NSDictionary *fileAttributes = [fileManager fileAttributesAtPath:filename traverseLink:YES];
		if(fileAttributes != nil)
			[mediaUploader setFilesize:[[fileAttributes objectForKey:@"NSFileSize"] floatValue]];
		[mediaUploader start];
		
		if(DeviceIsPad() == YES)
			[mediaUploader.view setFrame:iPadFrameStart];
		else
			[mediaUploader.view setFrame:iPhoneFrameStart];
		[UIView beginAnimations:@"Adding mediaUploader" context:nil];
		[UIView setAnimationDuration:0.4];
		if(DeviceIsPad() == YES)
			[mediaUploader.view setFrame:iPadFrameEnd];
		else
			[mediaUploader.view setFrame:iPhoneFrameEnd];
		[self.view addSubview:mediaUploader.view];
		[UIView commitAnimations];
		[[NSNotificationCenter defaultCenter] postNotificationName:VideoSaved object:filename];
	}
	@catch (NSException *ex) {
		[[NSNotificationCenter defaultCenter] postNotificationName:VideoUploadFailed object:nil];
	}
	@finally {
		[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	}
}

- (BOOL)supportsVideo {
	if(([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] == YES) && 
	   ([[UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera] containsObject:(NSString *)kUTTypeMovie]) && 
	   (self.videoEnabled == YES))
		return YES;
	else
		return NO;
}

- (void)mediaDidUploadSuccessfully:(NSNotification *)notification {
	if(self.uploadID != nil) {
		NSDictionary *mediaData = [notification userInfo];
		Media *media = [mediaManager get:self.uploadID];
        if ((media == nil) || (![media.uniqueID isEqualToString:self.uploadID])) {
            // FIXME: media deleted during upload should cancel the upload. In the meantime, we'll try not to crash
            NSLog(@"Media deleted while uploading (%@)", self.uploadID);
            [FlurryAPI logError:@"MediaDeleted"
                        message:[NSString stringWithFormat:@"Media deleted while uploading (%@)", self.uploadID]
                          error:nil];
			//shows a simple message that inform the user something went wrong.
			UIAlertView *videoAlert = [[UIAlertView alloc] initWithTitle:@"Upload failed" 
																 message:@"Please try again."
																delegate:self
													   cancelButtonTitle:@"OK" 
													   otherButtonTitles:nil];
			[videoAlert setTag:kVideoPressAlertTag];
			[videoAlert show];
			[videoAlert release];
        } else {
			media.remoteURL = [mediaData objectForKey:@"url"];
			media.shortcode = [mediaData objectForKey:@"shortcode"];
			
			if(media.shortcode == nil  && media.remoteURL == nil) {
				//shows a simple message that inform the user something went wrong.
				UIAlertView *videoAlert = [[UIAlertView alloc] initWithTitle:@"Upload failed" 
																	 message:@"Please try again."
																	delegate:self
														   cancelButtonTitle:@"OK" 
														   otherButtonTitles:nil];
				[videoAlert setTag:kVideoPressAlertTag];
				[videoAlert show];
				[videoAlert release];
			} else {
				[[NSNotificationCenter defaultCenter] postNotificationName:@"ShouldInsertMediaBelow" object:media];
				[mediaManager update:media];		
			}
		}
		self.uploadID = nil;
	}
	
	[UIView beginAnimations:@"Removing mediaUploader" context:nil];
	[UIView setAnimationDuration:0.4];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(removemediaUploader:finished:context:)];
	[mediaUploader.view setFrame:CGRectMake(0, self.view.frame.size.height + 800, 320, 40)];
	[UIView commitAnimations];
	self.isAddingMedia = NO;
	[self refreshMedia];
}

- (void)mediaUploadFailed:(NSNotification *)notification {
	if (self.uploadID != nil) {
		Media *media = [mediaManager get:self.uploadID];
		[self deleteMedia:media];
	}
	
	if ([notification userInfo] != nil) {
		NSString *errorType = [[notification userInfo] objectForKey:@"err_type"];
		NSString *errorMsg = [[notification userInfo] objectForKey:@"err_msg"];
		if ([errorType isEqualToString: @"err_vp"] || [errorType isEqualToString: @"err_gen"]) {
			NSString *buttonTitle; 
			if ([errorType isEqualToString: @"err_vp"])
				buttonTitle = @"No";
			else
				buttonTitle = @"OK";
			UIAlertView *videoAlert = [[UIAlertView alloc] initWithTitle:@"Upload Error" 
																 message:errorMsg
																delegate:self
													   cancelButtonTitle:buttonTitle 
													   otherButtonTitles:nil];
			if ([errorType isEqualToString: @"err_vp"])
				[videoAlert addButtonWithTitle:@"Yes"];
			[videoAlert setTag:kVideoPressAlertTag];
			[videoAlert show];
			[videoAlert release];
		}
	} else {
		//shows a simple message that inform the user something went wrong. sometimes no error message displayed in case of errors
		UIAlertView *videoAlert = [[UIAlertView alloc] initWithTitle:@"Upload failed" 
															 message:@"Please try again."
															delegate:self
												   cancelButtonTitle:@"OK" 
												   otherButtonTitles:nil];
		[videoAlert setTag:kVideoPressAlertTag];
		[videoAlert show];
		[videoAlert release];
	}
	
	[UIView beginAnimations:@"Removing mediaUploader" context:nil];
	[UIView setAnimationDuration:4.0];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(removemediaUploader:finished:context:)];
	[mediaUploader.view setFrame:CGRectMake(0, self.view.frame.size.height + 800, 320, 40)];
	[UIView commitAnimations];
	self.isAddingMedia = NO;
	[self refreshMedia];
}

- (void)removemediaUploader:(NSString *)animationID finished:(BOOL)finished context:(void *)context {
	[mediaUploader.view removeFromSuperview];
	[mediaUploader reset];
    [mediaUploader release];
	mediaUploader = nil;
}

- (void)deviceDidRotate:(NSNotification *)notification {
	if(isAddingMedia == YES) {
		if(self.currentOrientation != [self interpretOrientation:[[UIDevice currentDevice] orientation]]) {
			self.currentOrientation = [self interpretOrientation:[[UIDevice currentDevice] orientation]];
			didChangeOrientationDuringRecord = YES;
		}
	}
}

- (void)checkVideoEnabled {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	if(self.isCheckingVideoCapability == NO) {
		self.isCheckingVideoCapability = YES;
		self.videoPressCheckBlogURL = self.blogURL;
		
		@try {
			NSRange textRange = [[self.videoPressCheckBlogURL lowercaseString] rangeOfString:@"wordpress.com"];
			
			if(textRange.location != NSNotFound)
			{
                NSError *error = nil;
				NSString *username = [[[BlogDataManager sharedDataManager] currentBlog] valueForKey:@"username"];
				NSString *password = [SFHFKeychainUtils getPasswordForUsername:username
                                                                andServiceName:@"WordPress.com"
                                                                         error:&error];
				NSArray *args = [NSArray arrayWithObjects:[[[BlogDataManager sharedDataManager] currentBlog] valueForKey:kBlogId],
								 username, password, nil];
								
				NSMutableDictionary *xmlrpcParams = [[NSMutableDictionary alloc] init];
				[xmlrpcParams setObject:[[[BlogDataManager sharedDataManager] currentBlog] valueForKey:@"xmlrpc"] forKey:kURL];
				[xmlrpcParams setObject:@"wpcom.getFeatures" forKey:kMETHOD];
				[xmlrpcParams setObject:args forKey:kMETHODARGS];
				
				XMLRPCRequest *request = [[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:[xmlrpcParams valueForKey:kURL]]];
				[request setMethod:[xmlrpcParams valueForKey:kMETHOD] withObjects:[xmlrpcParams valueForKey:kMETHODARGS]];
				[xmlrpcParams release];
				
				XMLRPCResponse *response = [XMLRPCConnection sendSynchronousXMLRPCRequest:request];
				if(([response.object isKindOfClass:[NSDictionary class]] == YES) && ([response.object objectForKey:@"videopress_enabled"] != nil))
					self.videoEnabled = [[response.object objectForKey:@"videopress_enabled"] boolValue];
				else if(([response.object isKindOfClass:[NSDictionary class]] == YES) && ([response.object objectForKey:@"faultCode"] != nil)) {
					if([[response.object objectForKey:@"faultCode"] intValue] == -32601)
						self.videoEnabled = YES;
					else
						self.videoEnabled = NO;
				}
				else
					self.videoEnabled = YES;
				
				[request release];
			}
			else
				self.videoEnabled = YES;
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

- (void)deleteMedia:(Media *)media {
	// TO DO: Gross.
	if([mediaManager exists:media.uniqueID] == YES) {
		NSMutableArray *photoIndexesToRemove = [[NSMutableArray alloc] init];
		NSMutableArray *videoIndexesToRemove = [[NSMutableArray alloc] init];
		if([media.mediaType isEqualToString:@"image"]) {
			int index = 0;
			for(Media *photo in photos) {
				if([photo.uniqueID isEqualToString:media.uniqueID] == YES) {
					[photoIndexesToRemove addObject:[NSNumber numberWithInt:index]];
				}
				index++;
			}
		}
		else if([media.mediaType isEqualToString:@"video"]) {
			int index = 0;
			for(Media *video in videos) {
				if([video.uniqueID isEqualToString:media.uniqueID] == YES) {
					[videoIndexesToRemove addObject:[NSNumber numberWithInt:index]];
				}
				index++;
			}
		}
		
		for(NSNumber *index in photoIndexesToRemove) {
			[mediaManager remove:[photos objectAtIndex:[index intValue]]];
			[photos removeObjectAtIndex:[index intValue]];
		}
        [photoIndexesToRemove release];
		
		for(NSNumber *index in videoIndexesToRemove) {
			[mediaManager remove:[videos objectAtIndex:[index intValue]]];
			[videos removeObjectAtIndex:[index intValue]];
		}
        [videoIndexesToRemove release];
	}
}

- (void)shouldDeleteMedia:(NSNotification *)notification {
	[FlurryAPI logEvent:@"PostMedia#shouldDeleteMedia"];
	[self deleteMedia:[notification object]];
	[self refreshMedia];
}

- (void)refreshProperties {
	self.blogURL = [dm.currentBlog objectForKey:@"url"];
	NSString *postIDString = nil;
	if([dm.currentPost objectForKey:@"postid"] != nil)
		postIDString = [NSString stringWithFormat:@"%@", [dm.currentPost objectForKey:@"postid"]];
	
	NSString *pageIDString = nil;
	if([dm.currentPost objectForKey:@"page_id"] != nil)
		pageIDString = [NSString stringWithFormat:@"%@", [dm.currentPost objectForKey:@"page_id"]];
	
	if(((postIDString != nil)) && ([postIDString isEqualToString:@""] == NO))
		self.postID = postIDString;
	else if(((pageIDString != nil)) && ([pageIDString isEqualToString:@""] == NO))
		self.postID = pageIDString;
	else if(appDelegate.postID != nil)
		self.postID = appDelegate.postID;
	else
		self.postID = @"unsavedpost";
	
	[self refreshMedia];
}

- (IBAction)cancelPendingUpload:(id)sender {
    if (mediaUploader) {
        [mediaUploader cancelAction:self];
        if (self.uploadID != nil) {
            Media *media = [mediaManager get:self.uploadID];
            [self deleteMedia:media];
            [self refreshMedia];
        }
    }
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
	[uniqueID release];
	[addPopover release];
	[topToolbar release];
	[bottomToolbar release];
	[videoPressCheckBlogURL release];
	[uploadID release];
	[mediaUploader release];
	[mediaTypeControl release];
	[blogURL release];
	[postID release];
	[mediaManager release];
	[messageLabel release];
	[currentVideo release];
	[currentImage release];
	[spinner release];
	[table release];
	[addMediaButton release];
	[photos release];
	[videos release];
	[super dealloc];
}

@end

