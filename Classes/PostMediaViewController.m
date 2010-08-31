//
//  PostMediaViewController.m
//  WordPress
//
//  Created by Chris Boyd on 8/26/10.
//  Copyright 2010 WordPress. All rights reserved.
//

#import "PostMediaViewController.h"

@implementation PostMediaViewController
@synthesize table, addMediaButton, hasPhotos, hasVideos, isAddingMedia, photos, videos, appDelegate;
@synthesize isShowingMediaPickerActionSheet, currentOrientation, isShowingChangeOrientationActionSheet, spinner;
@synthesize currentImage, currentVideo, isLibraryMedia, didChangeOrientationDuringRecord, messageLabel;
@synthesize picker, postDetailViewController, mediaManager, postID, blogURL, mediaTypeControl, mediaUploader;
@synthesize isShowingResizeActionSheet;

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
	
	appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
	mediaUploader = [[WPMediaUploader alloc] initWithNibName:@"WPMediaUploader" bundle:nil];
	mediaManager = [[MediaManager alloc] init];
	photos = [[NSMutableArray alloc] init];
	videos = [[NSMutableArray alloc] init];
	
	self.currentOrientation = [self interpretOrientation:[UIDevice currentDevice].orientation];
	self.picker = [[UIImagePickerController alloc] init];
	self.picker.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	BlogDataManager *dm = [BlogDataManager sharedDataManager];
	self.blogURL = [[dm currentBlog] objectForKey:@"url"];
	if([[[dm currentPost] objectForKey:@"postid"] isEqualToString:@""] == NO)
		self.postID = [[dm currentPost] objectForKey:@"postid"];
	else
		self.postID = @"unsavedpost";
	
	[self refreshMedia];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mediaDidUploadSuccessfully:) name:VideoUploadSuccessful object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mediaDidUploadSuccessfully:) name:ImageUploadSuccessful object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super viewWillDisappear:animated];
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
	switch (mediaTypeControl.selectedSegmentIndex) {
		case 0:
			media = [photos objectAtIndex:indexPath.row];
			cell.imageView.image = [UIImage imageWithData:media.thumbnail];
			if(media.title != nil)
				cell.textLabel.text = media.title;
			else
				cell.textLabel.text = media.filename;
			NSString *filesizeString = nil;
			if([media.filesize floatValue] > 1024)
				filesizeString = [NSString stringWithFormat:@"%.2f MB", ([media.filesize floatValue]/1024)];
			else
				filesizeString = [NSString stringWithFormat:@"%.2f KB", [media.filesize floatValue]];
			
			cell.detailTextLabel.text = [NSString stringWithFormat:@"%d x %d %@", 
										 [media.width intValue], [media.height intValue], filesizeString];
			break;
		case 1:
			media = [videos objectAtIndex:indexPath.row];
			if(cellMP == nil) {
				cellMP = [[[MPMoviePlayerController alloc] initWithContentURL:[NSURL URLWithString:media.localURL]] autorelease];
			}
			cell.imageView.image = [UIImage imageWithData:media.thumbnail];
			if(media.title != nil)
				cell.textLabel.text = media.title;
			else
				cell.textLabel.text = media.filename;
			
			long min = (long)cellMP.duration / 60;    // divide two longs, truncates
			long sec = (long)cellMP.duration % 60;    // remainder of long divide
			cell.detailTextLabel.text = [NSString stringWithFormat:@"Duration: %02d:%02d", min, sec];
			break;
		default:
			break;
	}
	[cell.imageView setBounds:CGRectMake(0, 0, 75, 75)];
	[cell.imageView setClipsToBounds:NO];
	[cell.imageView setFrame:CGRectMake(0, 0, 75, 75)];
	[cell.imageView setContentMode:UIViewContentModeScaleAspectFill];
    
    return cell;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath: (NSIndexPath *) indexPath {
	return 75;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

-(void)tableView:(UITableView*)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath {
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	// If row is deleted, remove it from the list.
	if (editingStyle == UITableViewCellEditingStyleDelete)
	{
		if(mediaTypeControl.selectedSegmentIndex == 0) {
			Media *photo = [photos objectAtIndex:indexPath.row];
			[mediaManager remove:photo];
			[photos removeObjectAtIndex:indexPath.row];
		}
		else if(mediaTypeControl.selectedSegmentIndex == 1) {
			Media *video = [videos objectAtIndex:indexPath.row];
			[mediaManager remove:video];
			[videos removeObjectAtIndex:indexPath.row];
		}
		[self updateMediaCount];
		
		[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationTop];
	}
}

#pragma mark -
#pragma mark Custom methods

- (IBAction)refreshMedia {
	if(isAddingMedia == YES) {
		self.messageLabel.text = @"Adding media...";
		[self.spinner startAnimating];
	}
	else {
		photos = [[mediaManager getForPostID:self.postID andBlogURL:self.blogURL andMediaType:kImage] retain];
		videos = [[mediaManager getForPostID:self.postID andBlogURL:self.blogURL andMediaType:kVideo] retain];
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
					[self pickPhotoFromPhotoLibrary:nil];
				else {
					[actionSheet dismissWithClickedButtonIndex:buttonIndex animated:YES];
					self.isAddingMedia = NO;
				}
				break;
			case 3:
				if(buttonIndex == 0) {
					[self useImage:currentImage];
				}
				else if(buttonIndex == 1) {
					[self useImage:currentImage];
				}
				else {
					[actionSheet dismissWithClickedButtonIndex:buttonIndex animated:YES];
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
						[actionSheet dismissWithClickedButtonIndex:buttonIndex animated:YES];
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
		NSLog(@"set orientation to: %d", self.currentOrientation);
		[self processRecordedVideo];
		[actionSheet dismissWithClickedButtonIndex:buttonIndex animated:YES];
	}
	else if(isShowingResizeActionSheet == YES) {
		switch (buttonIndex) {
			case 0:
				[actionSheet dismissWithClickedButtonIndex:buttonIndex animated:YES];
				[self useImage:[self resizeImage:currentImage toSize:kResizeSmall]];
				break;
			case 1:
				[actionSheet dismissWithClickedButtonIndex:buttonIndex animated:YES];
				[self useImage:[self resizeImage:currentImage toSize:kResizeMedium]];
				break;
			case 2:
				[actionSheet dismissWithClickedButtonIndex:buttonIndex animated:YES];
				[self useImage:[self resizeImage:currentImage toSize:kResizeLarge]];
				break;
			default:
				[actionSheet dismissWithClickedButtonIndex:buttonIndex animated:YES];
				[self useImage:currentImage];
				break;
		}
	}
	else {
        [appDelegate setAlertRunning:NO];
		
        [currentImage release];
        currentImage = nil;
	}
}

- (void)pickPhotoFromCamera:(id)sender {
	self.currentOrientation = [self interpretOrientation:[UIDevice currentDevice].orientation];
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
        [appDelegate.navigationController presentModalViewController:picker animated:YES];
    }
}

- (void)pickVideoFromCamera:(id)sender {
	self.currentOrientation = [self interpretOrientation:[UIDevice currentDevice].orientation];
	picker.sourceType =  UIImagePickerControllerSourceTypeCamera;
	picker.mediaTypes = [NSArray arrayWithObject:(NSString *)kUTTypeMovie];
	[appDelegate.navigationController presentModalViewController:picker animated:YES];
	
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
        [appDelegate.navigationController presentModalViewController:picker animated:YES];
    }
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
	isShowingResizeActionSheet = YES;
	UIActionSheet *resizeActionSheet = [[UIActionSheet alloc] initWithTitle:@"Resize image?" 
																		delegate:self 
															   cancelButtonTitle:@"Use Original" 
														  destructiveButtonTitle:nil 
															   otherButtonTitles:@"Small", @"Medium", @"Large", nil];
	[resizeActionSheet showInView:super.tabBarController.view];
	[resizeActionSheet release];
}

- (void)imagePickerController:(UIImagePickerController *)myPicker didFinishPickingMediaWithInfo:(NSDictionary *)info {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	if([[info valueForKey:@"UIImagePickerControllerMediaType"] isEqualToString:@"public.movie"]) {
		[self refreshMedia];
		self.currentVideo = [info retain];
		if(self.didChangeOrientationDuringRecord == YES)
			[self showOrientationChangedActionSheet];
		else if(self.isLibraryMedia == NO)
			[self processRecordedVideo];
		else
			[self processLibraryVideo];
	}
	else if([[info valueForKey:@"UIImagePickerControllerMediaType"] isEqualToString:@"public.image"]) {
		UIImage *image = [info valueForKey:@"UIImagePickerControllerOriginalImage"];
		if (myPicker.sourceType == UIImagePickerControllerSourceTypeCamera)
			UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
		currentImage = [image retain];
		
		NSNumberFormatter *nf = [[NSNumberFormatter alloc] init];
		[nf setNumberStyle:NSNumberFormatterDecimalStyle];
		NSNumber *resizePreference = [nf numberFromString:[[NSUserDefaults standardUserDefaults] objectForKey:@"media_resize_preference"]];
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
	[picker dismissModalViewControllerAnimated:YES];
}

- (void)processRecordedVideo {
	[self.currentVideo setValue:[NSNumber numberWithInt:currentOrientation] forKey:@"orientation"];
	NSString *tempVideoPath = [(NSURL *)[currentVideo valueForKey:UIImagePickerControllerMediaURL] absoluteString];
	tempVideoPath = [[tempVideoPath substringFromIndex:16] retain];
	if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(tempVideoPath))
		UISaveVideoAtPathToSavedPhotosAlbum(tempVideoPath, self, @selector(video:didFinishSavingWithError:contextInfo:), tempVideoPath);
	[tempVideoPath release];
	
	[self refreshMedia];
}

- (void)processLibraryVideo {
	if([[currentVideo valueForKey:UIImagePickerControllerMediaURL] absoluteString] != nil) {
		float osVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
		[self.currentVideo setValue:[NSNumber numberWithInt:currentOrientation] forKey:@"orientation"];
		NSString *videoPath = [(NSURL *)[currentVideo valueForKey:UIImagePickerControllerMediaURL] absoluteString];
		videoPath = [[videoPath substringFromIndex:16] retain];
		NSURL *contentURL = [NSURL fileURLWithPath:videoPath];
		UIImage *thumbnail = nil;
		
		if(osVersion >= 3.2) {
			MPMoviePlayerController *mp = [[MPMoviePlayerController alloc] initWithContentURL:contentURL];
			thumbnail = [mp thumbnailImageAtTime:(NSTimeInterval)2.0 timeOption:MPMovieTimeOptionNearestKeyFrame];
		}
		
		NSData *videoData = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:videoPath]];
		[self useVideo:videoData withThumbnail:thumbnail];
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
	
	NSLog(@"osVersion: %f", osVersion);
	
	if(osVersion >= 3.2) {
		MPMoviePlayerController *mp = [[MPMoviePlayerController alloc] initWithContentURL:contentURL];
		thumbnail = [mp thumbnailImageAtTime:(NSTimeInterval)2.0 timeOption:MPMovieTimeOptionNearestKeyFrame];
	}
	
	NSData *videoData = [NSData dataWithContentsOfURL:contentURL];
	[self useVideo:videoData withThumbnail:thumbnail];
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
	CGSize smallSize, mediumSize, largeSize;
	switch (currentOrientation) {
		case kPortrait:
			smallSize = CGSizeMake(160, 240);
			mediumSize = CGSizeMake(320, 480);
			largeSize = CGSizeMake(640, 960);
			break;
		case kLandscape:
			smallSize = CGSizeMake(240, 160);
			mediumSize = CGSizeMake(480, 320);
			largeSize = CGSizeMake(960, 640);
	}
	
	UIImage *resizedImage = original;
	switch (resize) {
		case kResizeSmall:
			resizedImage = [original resizedImage:smallSize interpolationQuality:kCGInterpolationHigh];
			break;
		case kResizeMedium:
			resizedImage = [original resizedImage:mediumSize interpolationQuality:kCGInterpolationHigh];
			break;
		case kResizeLarge:
			resizedImage = [original resizedImage:largeSize interpolationQuality:kCGInterpolationHigh];
			break;
		default:
			break;
	}
	return resizedImage;
}

- (UIImage *)generateThumbnailFromImage:(UIImage *)theImage andSize:(CGSize)targetSize {
	return [theImage thumbnailImage:75 transparentBorder:0 cornerRadius:0 interpolationQuality:kCGInterpolationHigh];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)myPicker {
	[[myPicker parentViewController] dismissModalViewControllerAnimated:YES];
    [self refreshMedia];
}

- (void)useImage:(UIImage *)theImage {
	
	Media *imageMedia = [mediaManager get:nil];
	BlogDataManager *dm = [BlogDataManager sharedDataManager];
	NSDictionary *currentBlog = [dm currentBlog];
	NSData *imageData = UIImageJPEGRepresentation(theImage, 1.0);
	UIImage *imageThumbnail = [self generateThumbnailFromImage:theImage andSize:CGSizeMake(75, 75)];
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"yyyyMMdd-hhmmss"];
	
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	NSString *filename = [NSString stringWithFormat:@"%@.jpg", [formatter stringFromDate:[NSDate date]]];
	NSString *filepath = [NSString stringWithFormat:@"%@/%@", [[dm currentBlog] objectForKey:@"url"], filename];
	filepath = [documentsDirectory stringByAppendingPathComponent:filepath];
	[fileManager createFileAtPath:filepath contents:imageData attributes:nil];
	NSLog(@"saved image to file: %@", filepath);
	
	imageMedia.postID = self.postID;
	imageMedia.blogID = [currentBlog valueForKey:@"blogid"];
	imageMedia.blogURL = self.blogURL;
	imageMedia.creationDate = [NSDate date];
	imageMedia.filename = filename;
	imageMedia.filesize = [NSNumber numberWithInt:(imageData.length/1024)];
	imageMedia.localURL = filepath;
	imageMedia.mediaType = @"image";
	imageMedia.thumbnail = UIImageJPEGRepresentation(imageThumbnail, 1.0);
	imageMedia.width = [NSNumber numberWithInt:theImage.size.width];
	imageMedia.height = [NSNumber numberWithInt:theImage.size.height];
	[mediaManager save:imageMedia];
	
	// Save to remote server
	[self uploadMedia:imageData withFilename:filename andMediaType:kImage];
	
	//[self updatePhotosBadge];
	
	self.mediaTypeControl.selectedSegmentIndex = 0;
	isAddingMedia = NO;
	[formatter release];
	[self refreshMedia];
}

- (void)useVideo:(NSData *)video withThumbnail:(UIImage *)thumbnail {
	Media *videoMedia = [mediaManager get:nil];
	BlogDataManager *dm = [BlogDataManager sharedDataManager];
	NSDictionary *currentBlog = [dm currentBlog];
	UIImage *videoThumbnail = [self generateThumbnailFromImage:thumbnail andSize:CGSizeMake(75, 75)];
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"yyyyMMdd-hhmmss"];
	
	// Save to local file
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	NSString *filename = [NSString stringWithFormat:@"%@.mov", [formatter stringFromDate:[NSDate date]]];
	NSString *filepath = [NSString stringWithFormat:@"%@/%@", [[dm currentBlog] objectForKey:@"url"], filename];
	filepath = [documentsDirectory stringByAppendingPathComponent:filepath];
	[fileManager createFileAtPath:filepath contents:video attributes:nil];
	NSLog(@"saved video to file: %@", filepath);
	
	// Save to local database
	videoMedia.postID = self.postID;
	videoMedia.blogID = [currentBlog valueForKey:@"blogid"];
	videoMedia.blogURL = self.blogURL;
	videoMedia.creationDate = [NSDate date];
	videoMedia.filename = filename;
	videoMedia.filesize = [NSNumber numberWithInt:(video.length/1024)];
	videoMedia.localURL = filepath;
	videoMedia.mediaType = @"video";
	videoMedia.thumbnail = UIImageJPEGRepresentation(videoThumbnail, 1.0);
	[mediaManager save:videoMedia];
	
	// Save to remote server
	[self uploadMedia:video withFilename:filename andMediaType:kVideo];
	
	//[self updatePhotosBadge];
	
	self.mediaTypeControl.selectedSegmentIndex = 1;
	isAddingMedia = NO;
	[formatter release];
	[self refreshMedia];
}

- (NSString *)getUUID
{
	CFUUIDRef theUUID = CFUUIDCreate(NULL);
	CFStringRef string = CFUUIDCreateString(NULL, theUUID);
	CFRelease(theUUID);
	return [(NSString *)string autorelease];
}

- (void)uploadMedia:(NSData *)bits withFilename:(NSString *)filename andMediaType:(MediaType)mediaType {
	@try {
		NSFileManager *fileManager = [NSFileManager defaultManager];
		[mediaUploader setBits:bits];
		[mediaUploader setFilename:filename];
		[mediaUploader setOrientation:currentOrientation];
		[mediaUploader setMediaType:mediaType];
		
		NSDictionary *fileAttributes = [fileManager fileAttributesAtPath:filename traverseLink:YES];
		if(fileAttributes != nil)
			[mediaUploader setFilesize:[[fileAttributes objectForKey:@"NSFileSize"] floatValue]];
		NSLog(@"Starting upload...");
		[mediaUploader start];
		
		[mediaUploader.view setFrame:CGRectMake(0, 480, 320, 40)];
		[UIView beginAnimations:@"Adding mediaUploader" context:nil];
		[UIView setAnimationDuration:0.4];
		[mediaUploader.view setFrame:CGRectMake(0, 324, 320, 40)];
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
	   ([[UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera] containsObject:(NSString *)kUTTypeMovie]))
		return YES;
	else
		return NO;
}

- (void)mediaDidUploadSuccessfully:(NSNotification *)notification {
	[UIView beginAnimations:@"Removing mediaUploader" context:nil];
	[UIView setAnimationDuration:0.4];
	[UIView setAnimationDelegate:mediaUploader.view];
	[UIView setAnimationDidStopSelector:@selector(removemediaUploader:finished:context:)];
	[mediaUploader.view setFrame:CGRectMake(0, 480, 320, 40)];
	[UIView commitAnimations];
	self.isAddingMedia = NO;
	[self refreshMedia];
}

-(void)removemediaUploader:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
	[mediaUploader.view removeFromSuperview];
	[mediaUploader reset];
}

- (void)deviceDidRotate:(NSNotification *)notification {
	if(isAddingMedia == YES) {
		if(self.currentOrientation != [self interpretOrientation:[[UIDevice currentDevice] orientation]]) {
			self.currentOrientation = [self interpretOrientation:[[UIDevice currentDevice] orientation]];
			didChangeOrientationDuringRecord = YES;
			NSLog(@"movie orientation changed to: %d", self.currentOrientation);
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
	[mediaUploader release];
	[mediaTypeControl release];
	[blogURL release];
	[postID release];
	[mediaManager release];
	[picker release];
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

