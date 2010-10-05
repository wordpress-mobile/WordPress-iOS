//
//  PostMediaViewController.m
//  WordPress
//
//  Created by Chris Boyd on 8/26/10.
//  Code is poetry.
//

#import "PostMediaViewController.h"

@implementation PostMediaViewController
@synthesize table, addMediaButton, hasPhotos, hasVideos, isAddingMedia, photos, videos, appDelegate, dm, addPopover;
@synthesize isShowingMediaPickerActionSheet, currentOrientation, isShowingChangeOrientationActionSheet, spinner;
@synthesize currentImage, currentVideo, isLibraryMedia, didChangeOrientationDuringRecord, messageLabel, topToolbar;
@synthesize postDetailViewController, mediaManager, postID, blogURL, mediaTypeControl, mediaUploader, bottomToolbar;
@synthesize isShowingResizeActionSheet, videoEnabled, uploadID, videoPressCheckBlogURL, isCheckingVideoCapability, uniqueID;

#pragma mark -
#pragma mark View lifecycle

- (void)initObjects {
	if(DeviceIsPad() == YES)
		mediaUploader = [[WPMediaUploader alloc] initWithNibName:@"WPMediaUploader-iPad" bundle:nil];
	else
		mediaUploader = [[WPMediaUploader alloc] initWithNibName:@"WPMediaUploader" bundle:nil];
	
	dm = [BlogDataManager sharedDataManager];
	appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
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
	
	self.currentOrientation = [self interpretOrientation:[UIDevice currentDevice].orientation];
	[self initObjects];
	[self refreshProperties];
	[self performSelectorInBackground:@selector(checkVideoEnabled) withObject:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mediaDidUploadSuccessfully:) name:VideoUploadSuccessful object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mediaDidUploadSuccessfully:) name:ImageUploadSuccessful object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mediaUploadFailed:) name:VideoUploadFailed object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mediaUploadFailed:) name:ImageUploadFailed object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(shouldDeleteMedia:) name:@"ShouldDeleteMedia"	object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
	[self removemediaUploader:nil finished:YES context:nil];
	[super viewWillDisappear:animated];
}

- (void)viewDidUnload {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	if(interfaceOrientation == UIInterfaceOrientationPortrait)
		return YES;
	else
		return NO;
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
	MPMoviePlayerController *cellMP = nil;
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
	}
    
	Media *media = nil;
	NSString *filesizeString = nil;
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	NSString *filepath;
	
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
			if(cellMP == nil) {
				filepath = [documentsDirectory stringByAppendingPathComponent:media.filename];
				cellMP = [[[MPMoviePlayerController alloc] initWithContentURL:[NSURL URLWithString:filepath]] autorelease];
			}
			cell.imageView.image = [UIImage imageWithData:media.thumbnail];
			if(media.title != nil)
				cell.textLabel.text = media.title;
			else
				cell.textLabel.text = media.filename;
			
			long min = (long)cellMP.duration / 60;    // divide two longs, truncates
			long sec = (long)cellMP.duration % 60;    // remainder of long divide
			
			if([media.filesize floatValue] > 1024)
				filesizeString = [NSString stringWithFormat:@"%.2f MB", ([media.filesize floatValue]/1024)];
			else
				filesizeString = [NSString stringWithFormat:@"%.2f KB", [media.filesize floatValue]];
			
			cell.detailTextLabel.text = [NSString stringWithFormat:@"%02d:%02d %@", min, sec, filesizeString];
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
	int foo = 0;
	MediaObjectViewController *mediaView = [[MediaObjectViewController alloc] initWithNibName:@"MediaObjectView" bundle:nil];
	switch (mediaTypeControl.selectedSegmentIndex) {
		case 0:
			foo = indexPath.row;
			Media *photo = [photos objectAtIndex:indexPath.row];
			mediaView.media = photo;
			break;
		case 1:
			foo = indexPath.row;
			Media *video = [videos objectAtIndex:indexPath.row];
			mediaView.media = video;
			break;
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
	}
	[self updateMediaCount];
    [self.table reloadData];
	[self.spinner stopAnimating];
}

- (void)updateMediaCount {
	int mediaCount = 0;
	NSString *mediaTypeString = [[NSString alloc] init];
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
	
	UIActionSheet *actionSheet;
	if([self supportsVideo] == YES) {
		actionSheet = [[UIActionSheet alloc] initWithTitle:@"" 
												  delegate:self 
										 cancelButtonTitle:@"Cancel" 
									destructiveButtonTitle:nil 
										 otherButtonTitles:@"Add Media from Library",@"Take Photo",@"Record Video",nil];
	}
	else if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
		actionSheet = [[UIActionSheet alloc] initWithTitle:@"" 
												  delegate:self 
										 cancelButtonTitle:@"Cancel" 
									destructiveButtonTitle:nil 
										 otherButtonTitles:@"Add Media from Library",@"Take Photo",nil];
	}
	else {
		actionSheet = [[UIActionSheet alloc] initWithTitle:@"" 
												  delegate:self 
										 cancelButtonTitle:@"Cancel" 
									destructiveButtonTitle:nil 
										 otherButtonTitles:@"Add Media from Library",nil];
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
	UIImagePickerController *picker = [[UIImagePickerController alloc] init];
	picker.delegate = self;
	picker.allowsEditing = YES;
	self.currentOrientation = [self interpretOrientation:[UIDevice currentDevice].orientation];
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
		picker.mediaTypes = [NSArray arrayWithObject:(NSString *)kUTTypeImage];
        [appDelegate.navigationController presentModalViewController:picker animated:YES];
    }
	[picker release];
}

- (void)pickVideoFromCamera:(id)sender {
	UIImagePickerController *picker = [[UIImagePickerController alloc] init];
	picker.delegate = self;
	picker.allowsEditing = YES;
	self.currentOrientation = [self interpretOrientation:[UIDevice currentDevice].orientation];
	picker.sourceType =  UIImagePickerControllerSourceTypeCamera;
	picker.mediaTypes = [NSArray arrayWithObject:(NSString *)kUTTypeMovie];
	picker.videoQuality = UIImagePickerControllerQualityTypeLow;
	[appDelegate.navigationController presentModalViewController:picker animated:YES];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(deviceDidRotate:)
												 name:@"UIDeviceOrientationDidChangeNotification" object:nil];
	[picker release];
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
	UIImagePickerController *picker = [[UIImagePickerController alloc] init];
	picker.delegate = self;
	picker.allowsEditing = YES;
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
		NSArray *availableMediaTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
		[picker setMediaTypes:availableMediaTypes];
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
		isLibraryMedia = YES;
		
		if(DeviceIsPad() == YES) {
			addPopover = [[UIPopoverController alloc] initWithContentViewController:picker];
			[addPopover presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
		}
		else
			[appDelegate.navigationController presentModalViewController:picker animated:YES];
    }
	[picker release];
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
		UIActionSheet *resizeActionSheet = [[UIActionSheet alloc] initWithTitle:@"Choose Image Size" 
																	   delegate:self 
															  cancelButtonTitle:@"Original" 
														 destructiveButtonTitle:nil 
															  otherButtonTitles:@"Small", @"Medium", @"Large", nil];
		if(DeviceIsPad() == YES)
			[resizeActionSheet showInView:appDelegate.splitViewController.view];
		else
			[resizeActionSheet showInView:super.tabBarController.view];
		[resizeActionSheet release];
	}
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
	if([[info valueForKey:@"UIImagePickerControllerMediaType"] isEqualToString:@"public.movie"]) {
		[self refreshMedia];
		self.currentVideo = [info retain];
		NSLog(@"currentVideo: %@", currentVideo);
		if(self.didChangeOrientationDuringRecord == YES)
			[self showOrientationChangedActionSheet];
		else if(self.isLibraryMedia == NO)
			[self processRecordedVideo];
		else
			[self processLibraryVideo];
		
		if(DeviceIsPad() == YES)
			[addPopover dismissPopoverAnimated:YES];
		else
			[appDelegate.navigationController dismissModalViewControllerAnimated:YES];
	}
	else if([[info valueForKey:@"UIImagePickerControllerMediaType"] isEqualToString:@"public.image"]) {
		UIImage *image = [info valueForKey:@"UIImagePickerControllerOriginalImage"];
		if (picker.sourceType == UIImagePickerControllerSourceTypeCamera)
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
				[self useImage:[self resizeImage:currentImage toSize:kResizeOriginal]];
				break;
			default:
				[self showResizeActionSheet];
				break;
		}
		if(DeviceIsPad() == YES)
			[addPopover dismissPopoverAnimated:YES];
		else
			[appDelegate.navigationController dismissModalViewControllerAnimated:YES];
	}
}

- (void)processRecordedVideo {
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
	if([[currentVideo valueForKey:UIImagePickerControllerMediaURL] absoluteString] != nil) {
		float osVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
		[self.currentVideo setValue:[NSNumber numberWithInt:currentOrientation] forKey:@"orientation"];
		
		// Determine the video's library path
		NSString *videoPath = [(NSURL *)[currentVideo valueForKey:UIImagePickerControllerMediaURL] absoluteString];
		videoPath = [[videoPath substringFromIndex:16] retain];
		NSURL *contentURL = [NSURL fileURLWithPath:videoPath];
		
		// If we're using iOS 3.2 or greater, we can grab a thumbnail using this method
		UIImage *thumbnail;
		if(osVersion >= 3.2) {
			MPMoviePlayerController *mp = [[MPMoviePlayerController alloc] initWithContentURL:contentURL];
			thumbnail = [mp thumbnailImageAtTime:(NSTimeInterval)2.0 timeOption:MPMovieTimeOptionNearestKeyFrame];
		}
		else {
			// If not, we'll just use the default thumbnail for now.
			thumbnail = [UIImage imageNamed:@"video_thumbnail"];
		}
		
		[self useVideo:videoPath withThumbnail:thumbnail];
		self.currentVideo = nil;
		self.isLibraryMedia = NO;
		[self refreshMedia];
		
		[videoPath release];
	}
}

- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(NSString *)contextInfo {
	float osVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
	NSURL *contentURL = [NSURL fileURLWithPath:videoPath];
	UIImage *thumbnail = nil;
	
	// If we're using iOS 3.2 or greater, we can grab a thumbnail using this method
	if(osVersion >= 3.2) {
		MPMoviePlayerController *mp = [[MPMoviePlayerController alloc] initWithContentURL:contentURL];
		thumbnail = [mp thumbnailImageAtTime:(NSTimeInterval)2.0 timeOption:MPMovieTimeOptionNearestKeyFrame];
	}
	else {
		// If not, we'll just use the default thumbnail for now.
		thumbnail = [UIImage imageNamed:@"video_thumbnail"];
	}
	
	[self useVideo:videoPath withThumbnail:thumbnail];
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
			if([[UIDevice currentDevice] platformString] == IPHONE_4G_NAMESTRING)
				originalSize = CGSizeMake(2592, 1936);
			else if([[UIDevice currentDevice] platformString] == IPHONE_3GS_NAMESTRING)
				originalSize = CGSizeMake(2048, 1536);
			else
				originalSize = CGSizeMake(1600, 1200);
			break;
		case UIImageOrientationLeft:
		case UIImageOrientationLeftMirrored:
		case UIImageOrientationRight:
		case UIImageOrientationRightMirrored:
			smallSize = CGSizeMake(180, 240);
			mediumSize = CGSizeMake(360, 480);
			largeSize = CGSizeMake(480, 640);
			if([[UIDevice currentDevice] platformString] == IPHONE_4G_NAMESTRING)
				originalSize = CGSizeMake(1936, 2592);
			else if([[UIDevice currentDevice] platformString] == IPHONE_3GS_NAMESTRING)
				originalSize = CGSizeMake(1536, 2048);
			else
				originalSize = CGSizeMake(1200, 1600);
	}
	
	// Resize the image using the selected dimensions
	UIImage *resizedImage = original;
	switch (resize) {
		case kResizeSmall:
			resizedImage = [original resizedImageWithContentMode:UIViewContentModeScaleAspectFill 
														  bounds:smallSize 
											interpolationQuality:kCGInterpolationHigh];
			break;
		case kResizeMedium:
			resizedImage = [original resizedImageWithContentMode:UIViewContentModeScaleAspectFill 
														  bounds:mediumSize 
											interpolationQuality:kCGInterpolationHigh];
			break;
		case kResizeLarge:
			resizedImage = [original resizedImageWithContentMode:UIViewContentModeScaleAspectFill 
														  bounds:largeSize 
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

- (UIImage *)generateThumbnailFromImage:(UIImage *)theImage andSize:(CGSize)targetSize {
	return [theImage thumbnailImage:75 transparentBorder:0 cornerRadius:0 interpolationQuality:kCGInterpolationHigh];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
	[appDelegate.navigationController dismissModalViewControllerAnimated:YES];
    //[self refreshMedia];
}

- (void)useImage:(UIImage *)theImage {
	Media *imageMedia = [mediaManager get:nil];
	NSDictionary *currentBlog = [dm currentBlog];
	NSData *imageData = UIImageJPEGRepresentation(theImage, 0.90);
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

- (void)useVideo:(NSString *)videoURL withThumbnail:(UIImage *)thumbnail {
	Media *videoMedia = [mediaManager get:nil];
	NSDictionary *currentBlog = [dm currentBlog];
	UIImage *videoThumbnail = [self generateThumbnailFromImage:thumbnail andSize:CGSizeMake(75, 75)];
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"yyyyMMdd-hhmmss"];
	
	// Save to local file
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	NSString *filename = [NSString stringWithFormat:@"%@.mov", [formatter stringFromDate:[NSDate date]]];
	NSString *filepath = [documentsDirectory stringByAppendingPathComponent:filename];
	
	// Copy the video from temp to blog directory
	NSDictionary *attributes;
	NSError *error = nil;
	BOOL copySuccess;
	if ((attributes = [fileManager fileAttributesAtPath:videoURL traverseLink:YES]) != nil) {
		if([fileManager isReadableFileAtPath:videoURL] == YES)
			copySuccess = [fileManager copyItemAtPath:videoURL toPath:filepath error:&error];
	}
	
	if(copySuccess == YES) {
		// Save to local database
		videoMedia.postID = self.postID;
		videoMedia.blogID = [currentBlog valueForKey:@"blogid"];
		videoMedia.blogURL = self.blogURL;
		if(currentOrientation == kLandscape)
			videoMedia.orientation = @"landscape";
		else
			videoMedia.orientation = @"portrait";
		videoMedia.creationDate = [NSDate date];
		videoMedia.filename = filename;
		videoMedia.localURL = filepath;
		videoMedia.filesize = [NSNumber numberWithInt:([[attributes objectForKey: NSFileSize] intValue]/1024)];
		videoMedia.mediaType = @"video";
		videoMedia.thumbnail = UIImageJPEGRepresentation(videoThumbnail, 1.0);
		[mediaManager save:videoMedia];
		CGImageRef cgVideoThumbnail = thumbnail.CGImage;
		NSUInteger videoWidth = CGImageGetWidth(cgVideoThumbnail);
		NSUInteger videoHeight = CGImageGetHeight(cgVideoThumbnail);
		videoMedia.width = [NSNumber numberWithInt:videoWidth];
		videoMedia.height = [NSNumber numberWithInt:videoHeight];
		NSLog(@"video thumbnail dimensions - width: %@ height: %@", videoMedia.width, videoMedia.height);
		
		// Save to remote server
		self.uploadID = videoMedia.uniqueID;
		[self uploadMedia:nil withFilename:filename andLocalURL:videoMedia.localURL andMediaType:kVideo];
		
		//[self updatePhotosBadge];
		
		self.mediaTypeControl.selectedSegmentIndex = 1;
		isAddingMedia = NO;
		[formatter release];
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
		CGRect iPadFrameStart = CGRectMake(30, self.view.frame.size.height, bottomToolbar.frame.size.width-300, bottomToolbar.frame.size.height);
		CGRect iPadFrameEnd = CGRectMake(30, self.view.frame.size.height - 44, bottomToolbar.frame.size.width-300, bottomToolbar.frame.size.height);
		
		NSFileManager *fileManager = [NSFileManager defaultManager];
		
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
		NSLog(@"Video save failed with exception: %@", ex);
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
	NSLog(@"successfully uploaded to server...");
	if(self.uploadID != nil) {
		NSDictionary *mediaData = [notification userInfo];
		NSLog(@"mediaData: %@", mediaData);
		Media *media = [mediaManager get:self.uploadID];
		media.remoteURL = [mediaData objectForKey:@"url"];
		media.shortcode = [mediaData objectForKey:@"shortcode"];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"ShouldInsertMediaBelow" object:media];
		[mediaManager update:media];
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
	[UIView beginAnimations:@"Removing mediaUploader" context:nil];
	[UIView setAnimationDuration:4.0];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(removemediaUploader:finished:context:)];
	[mediaUploader.view setFrame:CGRectMake(0, 480, 320, 40)];
	[UIView commitAnimations];
	self.isAddingMedia = NO;
	[self refreshMedia];
}

- (void)removemediaUploader:(NSString *)animationID finished:(BOOL)finished context:(void *)context {
	[mediaUploader.view removeFromSuperview];
	[mediaUploader reset];
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
				NSArray *args = [NSArray arrayWithObjects:[[[BlogDataManager sharedDataManager] currentBlog] valueForKey:kBlogId],
								 [[[BlogDataManager sharedDataManager] currentBlog] valueForKey:@"username"],
								 [[BlogDataManager sharedDataManager] getPasswordFromKeychainInContextOfCurrentBlog:[[BlogDataManager sharedDataManager] currentBlog]], nil];
				
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
		
		for(NSNumber *index in videoIndexesToRemove) {
			[mediaManager remove:[videos objectAtIndex:[index intValue]]];
			[videos removeObjectAtIndex:[index intValue]];
		}
		
		NSLog(@"deleted media.");
	}
}

- (void)shouldDeleteMedia:(NSNotification *)notification {
	[self deleteMedia:[notification object]];
}

- (void)refreshProperties {
	self.blogURL = [dm.currentBlog objectForKey:@"url"];
	
	if((([dm.currentPost objectForKey:@"postid"] != nil)) && ([[dm.currentPost objectForKey:@"postid"] isEqualToString:@""] == NO))
		self.postID = [dm.currentPost objectForKey:@"postid"];
	else if((([dm.currentPage objectForKey:@"page_id"] != nil)) && ([[dm.currentPage objectForKey:@"page_id"] isEqualToString:@""] == NO))
		self.postID = [dm.currentPage objectForKey:@"page_id"];
	else if(appDelegate.postID != nil)
		self.postID = appDelegate.postID;
	else
		self.postID = @"unsavedpost";
	
	[self refreshMedia];
}

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark Dealloc

- (void)dealloc {
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

