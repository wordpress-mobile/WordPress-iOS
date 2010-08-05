#define PhotoSize 124.0
#define PhotoOffSet 4.0
#define NUM_COLS 4
#define TAG_OFFSET 100

#import "WPPhotosListViewController.h"
#import "BlogDataManager.h"
#import "WordPressAppDelegate.h"

@interface WPPhotosListViewController (privates)

- (void)clearPickerContrller;

@end

@implementation WPPhotosListViewController

static inline double radians(double degrees) {
    return degrees * M_PI / 180;
}

@synthesize postDetailViewController, pageDetailsController, tableView, delegate, videoOrientation, addButton, currentVideo, spinner, messageLabel;
@synthesize isShowingMediaPickerActionSheet, isShowingChangeOrientationActionSheet, didChangeOrientationDuringRecord, isAddingMedia;
@synthesize toolbar, isLibraryMedia;

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Media";
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	
    self.title = @"Media";
    [(NSObject *) delegate performSelector:@selector(updatePhotosBadge)];
	isLibraryMedia = NO;
	
	[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(deviceDidRotate:)
												 name:@"UIDeviceOrientationDidChangeNotification" object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
	self.didChangeOrientationDuringRecord = NO;
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super viewWillDisappear:animated];
}

#pragma mark -
#pragma mark UITableView methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section {
    int count = [[delegate photosDataSource] count];
	return (count / NUM_COLS) + (count % NUM_COLS ? 1 : 0);
}

- (CGFloat)tableView:(UITableView *)aTableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    float psize = (CGRectGetWidth([aTableView frame]) - (PhotoOffSet * (NUM_COLS + 1))) / NUM_COLS;
    return psize + 2 * PhotoOffSet;
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    //WordPressAppDelegate *appController = [[UIApplication sharedApplication] delegate];
    NSString *selectionTableRowCell = [NSString stringWithFormat:@"photsSelectionRow%d", indexPath.row];

    UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:selectionTableRowCell];

    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:selectionTableRowCell] autorelease];
    }

    id array;
    BlogDataManager *dataManager = [BlogDataManager sharedDataManager];

    array = [delegate photosDataSource];

    float psize = (CGRectGetWidth([aTableView frame]) - (PhotoOffSet * (NUM_COLS + 1))) / NUM_COLS;
    int i;
    WPImageView *imageView;

    for (i = 0; i < NUM_COLS; i++) {
        int index = (indexPath.row * NUM_COLS + i);

        imageView = (WPImageView *)[cell viewWithTag:index + TAG_OFFSET];

        if (!imageView && index <[array count]) {
            imageView = [[WPImageView alloc] initWithFrame:CGRectMake(((i + 1) * PhotoOffSet) + (i * psize), PhotoOffSet, psize, psize)];
            imageView.contentMode = UIViewContentModeScaleAspectFit;
            [imageView setDelegate:self operation:@selector(imageViewSelected:)];
            imageView.userInteractionEnabled = YES;
            [cell addSubview:imageView];
            imageView.tag = TAG_OFFSET + index;
            [imageView release];
        }

        if (index <[array count]) {
            imageView.image = [dataManager thumbnailImageNamed:[array objectAtIndex:index] forBlog:dataManager.currentBlog];
            [imageView setBackgroundColor:[UIColor colorWithRed:0.8f green:0.8f blue:0.8f alpha:0.5]];
        } else {
            imageView.image = nil;
            [imageView setBackgroundColor:[UIColor whiteColor]];
        }
    }

    cell.accessoryType = UITableViewCellAccessoryNone;

    return cell;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    return nil;
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
}

#pragma mark -
#pragma mark Custom methods

- (void)imageViewSelected:(WPImageView *)iv {
    int index = [iv tag] - TAG_OFFSET;
    id array = [delegate photosDataSource];
	
    if (index >= 0 && index <[array count]) {
        WPPhotoViewController *photoViewController = [[WPPhotoViewController alloc] initWithNibName:@"WPPhotoViewController" bundle:nil];
        photoViewController.currentPhotoIndex = index;
        photoViewController.photosListViewController = self;
		
        [[(UIViewController *) delegate navigationController] presentModalViewController:photoViewController animated:YES];
        [photoViewController release];
    }
}

- (CGSize)contentSizeForViewInPopover {
	return CGSizeMake(320.0, 275.0);
}

- (IBAction)showPhotoUploadScreen:(id)sender {
    [self showPhotoPickerActionSheet];
}

- (IBAction)addPhotoFromLibraryAction:(id)sender {
    [self pickPhotoFromPhotoLibrary:nil];
}

- (IBAction)addPhotoFromCameraAction:(id)sender {
    [self pickPhotoFromCamera:nil];
}

- (WPImagePickerController *)pickerController {
    if (pickerController == nil) {
        pickerController = [[WPImagePickerController alloc] init];
        pickerController.delegate = self;
        pickerController.allowsImageEditing = NO;
    }
	
    return pickerController;
}

- (void)clearPickerContrller {
    [pickerController release];
    pickerController = nil;
}

- (void)showPhotoPickerActionSheet {
    WordPressAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
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
	else if ([WPImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
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
	WordPressAppDelegate *appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
	
	if(isShowingMediaPickerActionSheet == YES) {
		switch (actionSheet.numberOfButtons) {
			case 2:
				if(buttonIndex == 0)
					[self pickPhotoFromPhotoLibrary:nil];
				else
					[actionSheet dismissWithClickedButtonIndex:buttonIndex animated:YES];
				break;
			case 3:
				if(buttonIndex == 0) {
					[self useImage:currentChoosenImage];
				}
				else if(buttonIndex == 1) {
					[self useImage:currentChoosenImage];
					WPImagePickerController *picker = [self pickerController];
					[[picker parentViewController] dismissModalViewControllerAnimated:YES];
					[self clearPickerContrller];
				}
				else
					[actionSheet dismissWithClickedButtonIndex:buttonIndex animated:YES];
				break;
			case 4:
				switch (buttonIndex) {
					case 0:
						[self pickPhotoFromPhotoLibrary:self];
						break;
					case 1:
						[self pickPhotoFromCamera:self];
					case 2:
						[self pickVideoFromCamera:self];
					default:
						[actionSheet dismissWithClickedButtonIndex:buttonIndex animated:YES];
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
				self.videoOrientation = kPortrait;
				break;
			case 1:
				self.videoOrientation = kLandscape;
			default:
				self.videoOrientation = kPortrait;
				break;
		}
		[self processRecordedVideo];
		[actionSheet dismissWithClickedButtonIndex:buttonIndex animated:YES];
	}
	else {
        [appDelegate setAlertRunning:NO];
		
        [currentChoosenImage release];
        currentChoosenImage = nil;
	}
}

- (void)pickPhotoFromCamera:(id)sender {
    if ([WPImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        WPImagePickerController *picker = [self pickerController];
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
		
        // Picker is displayed asynchronously.
        [[(UIViewController *) delegate navigationController] presentModalViewController:picker animated:YES];
    }
}

- (void)pickVideoFromCamera:(id)sender {
	self.videoOrientation = [self interpretOrientation:[UIDevice currentDevice].orientation];
	UIImagePickerController *picker = [[UIImagePickerController alloc] init];
	picker.sourceType =  UIImagePickerControllerSourceTypeCamera;
	picker.mediaTypes = [NSArray arrayWithObject:(NSString *)kUTTypeMovie];
	picker.delegate = self;
	picker.allowsEditing = YES;
	[[(UIViewController *) delegate navigationController] presentModalViewController:picker animated:YES];
	[picker release];
}

- (VideoOrientation)interpretOrientation:(UIDeviceOrientation)theOrientation {
	VideoOrientation result = kPortrait;
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
    if ([WPImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        WPImagePickerController *picker = [self pickerController];
		NSArray *availableMediaTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
		[picker setMediaTypes:availableMediaTypes];
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
		isLibraryMedia = YES;
		
		if (DeviceIsPad() == YES) {
			if (self.delegate && [self.delegate respondsToSelector:@selector(displayPhotoListImagePicker:)]) {
				[self.delegate displayPhotoListImagePicker:picker];
			}
		} else {
			[[(UIViewController *) delegate navigationController] presentModalViewController:picker animated:YES];
		}
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

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
	if([[info valueForKey:@"UIImagePickerControllerMediaType"] isEqualToString:@"public.movie"]) {
		[self refreshData];
		self.currentVideo = [info retain];
		if(self.didChangeOrientationDuringRecord == YES)
			[self showOrientationChangedActionSheet];
		else if(self.isLibraryMedia == NO)
			[self processRecordedVideo];
		else {
			[self processLibraryVideo];
		}
	}
	else if([[info valueForKey:@"UIImagePickerControllerMediaType"] isEqualToString:@"public.image"]) {
		UIImage *image = [info valueForKey:@"UIImagePickerControllerOriginalImage"];
		if (picker.sourceType == UIImagePickerControllerSourceTypeCamera)
			UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
		
		[self useImage:image];
		
		if (DeviceIsPad() == YES) {
			if (self.delegate && [self.delegate respondsToSelector:@selector(hidePhotoListImagePicker)]) {
				[self.delegate hidePhotoListImagePicker];
			}
		}
	}
	[[picker parentViewController] dismissModalViewControllerAnimated:YES];
}

- (void)processRecordedVideo {
	NSString *tempVideoPath = [(NSURL *)[currentVideo valueForKey:UIImagePickerControllerMediaURL] absoluteString];
	tempVideoPath = [[tempVideoPath substringFromIndex:16] retain];
	if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(tempVideoPath))
		UISaveVideoAtPathToSavedPhotosAlbum(tempVideoPath, self, @selector(video:didFinishSavingWithError:contextInfo:), tempVideoPath);
	[tempVideoPath release];
	
	[self clearPickerContrller];
	[self refreshData];
}

- (void)processLibraryVideo {
	NSString *tempVideoPath = [(NSURL *)[currentVideo valueForKey:UIImagePickerControllerMediaURL] absoluteString];
	tempVideoPath = [[tempVideoPath substringFromIndex:16] retain];
	NSData *videoData = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:tempVideoPath]];
	[self useVideo:videoData withThumbnail:@""];
	self.currentVideo = nil;
	[tempVideoPath release];
	
	self.isLibraryMedia = NO;
	[self clearPickerContrller];
	[self refreshData];
}

- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(NSString *)contextInfo {
	NSLog(@"didFinishSavingWithError--videoPath in camera roll:%@", videoPath);
	NSLog(@"didFinishSavingWithError--videoPath in temp directory:%@", contextInfo);
	
	//NSString *file, *latestFile;
	//NSString *path = [[NSString alloc] initWithFormat:@"%@", contextInfo];
	//NSLog(@"path: %@", path);
	//NSDate *latestDate = [NSDate distantPast];
	//NSDirectoryEnumerator *dirEnum = [[NSFileManager defaultManager] enumeratorAtPath:[[path stringByDeletingLastPathComponent]stringByDeletingLastPathComponent]];
	//while (file = [dirEnum nextObject]) {
	//		if ([[file pathExtension] isEqualToString: @"jpg"]) {
	//			if ([(NSDate *)[[dirEnum fileAttributes] valueForKey:@"NSFileModificationDate"] compare:latestDate] == NSOrderedDescending){
	//				latestDate = [[dirEnum fileAttributes] valueForKey:@"NSFileModificationDate"];
	//				latestFile = [NSString stringWithString:file];
	//			}
	//		}
	//	}
	//	if(latestFile) {
	//		NSLog(@"Thumbnail file: %@", latestFile);
	//		latestFile = [NSTemporaryDirectory() stringByAppendingPathComponent:latestFile];
	//		
	//		NSData *videoData = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:videoPath]];
	//		[self useVideo:videoData withThumbnail:latestFile];
	//	}
	//	else {
	//		NSLog(@"lastestFile is nil.");
	//	}
	NSData *videoData = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:videoPath]];
	[self useVideo:videoData withThumbnail:@""];
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

- (UIImage *)scaleAndRotateImage:(UIImage *)image scaleFlag:(BOOL)aFlag {
    int kMaxResolution = 640; // Or whatever
	
    CGImageRef imgRef = image.CGImage;
	
    CGFloat width = CGImageGetWidth(imgRef);
    CGFloat height = CGImageGetHeight(imgRef);
	
    CGAffineTransform transform = CGAffineTransformIdentity;
    CGRect bounds = CGRectMake(0, 0, width, height);
	
    if (aFlag == YES) {
        BlogDataManager *dataManager = [BlogDataManager sharedDataManager];
        id currentPost = dataManager.currentPost;
        NSNumber *number = [currentPost valueForKey:kResizePhotoSetting];
		
        if (!number) {   // If post doesn't contain this key
            number = [dataManager.currentBlog valueForKey:kResizePhotoSetting];
			
            if (!number) {  // If blog doesn't contain this key
                number = [NSNumber numberWithInt:0];
            }
        }
		
        BOOL shouldResize = [number boolValue];
		
        if (shouldResize) {   // Resize the photo only when user opts this setting
            if (width > kMaxResolution || height > kMaxResolution) {
                CGFloat ratio = width / height;
				
                if (ratio > 1) {
                    bounds.size.width = kMaxResolution;
                    bounds.size.height = bounds.size.width / ratio;
                } else {
                    bounds.size.height = kMaxResolution;
                    bounds.size.width = bounds.size.height * ratio;
                }
            }
        }
    }
	
    CGFloat scaleRatio = bounds.size.width / width;
    CGSize imageSize = CGSizeMake(CGImageGetWidth(imgRef), CGImageGetHeight(imgRef));
    CGFloat boundHeight;
    UIImageOrientation orient = image.imageOrientation;
	
    switch (orient) {
        case UIImageOrientationUp: //EXIF = 1
            transform = CGAffineTransformIdentity;
            break;
			
        case UIImageOrientationUpMirrored: //EXIF = 2
            transform = CGAffineTransformMakeTranslation(imageSize.width, 0.0);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            break;
			
        case UIImageOrientationDown: //EXIF = 3
            transform = CGAffineTransformMakeTranslation(imageSize.width, imageSize.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
			
        case UIImageOrientationDownMirrored: //EXIF = 4
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.height);
            transform = CGAffineTransformScale(transform, 1.0, -1.0);
            break;
			
        case UIImageOrientationLeftMirrored: //EXIF = 5
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(imageSize.height, imageSize.width);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;
			
        case UIImageOrientationLeft: //EXIF = 6
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.width);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;
			
        case UIImageOrientationRightMirrored: //EXIF = 7
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeScale(-1.0, 1.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;
			
        case UIImageOrientationRight: //EXIF = 8
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(imageSize.height, 0.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;
			
        default:
            [NSException raise:NSInternalInconsistencyException format:@"Invalid image orientation"];
    }
	
    UIGraphicsBeginImageContext(bounds.size);
	
    CGContextRef context = UIGraphicsGetCurrentContext();
	
    if (orient == UIImageOrientationRight || orient == UIImageOrientationLeft) {
        CGContextScaleCTM(context, -scaleRatio, scaleRatio);
        CGContextTranslateCTM(context, -height, 0);
    } else {
        CGContextScaleCTM(context, scaleRatio, -scaleRatio);
        CGContextTranslateCTM(context, 0, -height);
    }
	
    CGContextConcatCTM(context, transform);
	
    CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, width, height), imgRef);
    UIImage *imageCopy = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
	
    return imageCopy;
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
	if (DeviceIsPad() == YES) {
		if (self.delegate && [self.delegate respondsToSelector:@selector(hidePhotoListImagePicker)]) {
			[self.delegate hidePhotoListImagePicker];
		}
	} else {
		[[picker parentViewController] dismissModalViewControllerAnimated:YES];
	}
    [self clearPickerContrller];
    [tableView reloadData];
}

// Implement this method in your code to do something with the image.
- (void)useImage:(UIImage *)theImage {
    //	if( !url )
    //		return;
	
    //	NSString *curText = textView.text;
    //	curText = ( curText == nil ? @"" : curText );
    //	textView.text = [curText stringByAppendingString:[NSString stringWithFormat:@"<img src=\"%@\"></img>",url]];
    //	[dataManager.currentPost setObject:textView.text forKey:@"description"];
	
    [delegate useImage:theImage];
	
    //postDetailViewController.hasChanges = YES;
	//
	//	id currentPost = dataManager.currentPost;
	//	if (![currentPost valueForKey:@"Photos"])
	//		[currentPost setValue:[NSMutableArray array] forKey:@"Photos"];
	//
	//	[[currentPost valueForKey:@"Photos"] addObject:[dataManager saveImage:theImage]];
	//	[postDetailViewController updatePhotosBadge];
}

- (void)useVideo:(NSData *)video withThumbnail:(NSString *)thumbnailURL {
	BlogDataManager *dm = [BlogDataManager sharedDataManager];
	NSDictionary *currentBlog = [dm currentBlog];
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"yyyyMMdd-hhmmss"];
	NSString *filename = [NSString stringWithFormat:@"%@.mov", [formatter stringFromDate:[NSDate date]]];
	NSString *filepath = [NSString stringWithFormat:@"%@/m_%@", [dm blogDir:currentBlog], filename];
	
	[video writeToFile:filepath atomically:YES];
	[delegate useVideo:video withThumbnail:thumbnailURL andFilename:filename];
	[formatter release];
	[self refreshData];
}

- (BOOL)supportsVideo {
	if(([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] == YES) && 
	   ([[UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera] containsObject:(NSString *)kUTTypeMovie]))
		return YES;
	else
		return NO;
}

- (void)refreshData {
	if(isAddingMedia == YES) {
		[self updateMessageLabel:@"Adding media..."];
		[spinner startAnimating];
	}
	else {
		switch ([[delegate photosDataSource] count]) {
			case 0:
				[self updateMessageLabel:[NSString stringWithFormat:@"No media.", [[delegate photosDataSource] count]]];
				break;
			case 1:
				[self updateMessageLabel:[NSString stringWithFormat:@"%d media item.", [[delegate photosDataSource] count]]];
				break;
			default:
				[self updateMessageLabel:[NSString stringWithFormat:@"%d media items.", [[delegate photosDataSource] count]]];
				break;
		}
		[spinner stopAnimating];
	}
	
    [tableView reloadData];
}

- (void)updateMessageLabel:(NSString *)message {
	self.messageLabel.text = message;
}

#pragma mark -
#pragma mark Autorotation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	if (DeviceIsPad() == YES) {
		return YES;
	}

    WordPressAppDelegate *wpAppDelegate = [[UIApplication sharedApplication] delegate];

    if ([wpAppDelegate isAlertRunning] == YES) {
        return NO; // Return YES for supported orientations
    }

    return YES;
}

- (void)deviceDidRotate:(NSNotification *)notification {
	if(self.videoOrientation != [self interpretOrientation:[[UIDevice currentDevice] orientation]]) {
		self.videoOrientation = [self interpretOrientation:[[UIDevice currentDevice] orientation]];
		didChangeOrientationDuringRecord = YES;
		NSLog(@"movie orientation changed to: %d", self.videoOrientation);
	}
}

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    WPLog(@"%@ %@", self, NSStringFromSelector(_cmd));
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
}

#pragma mark -
#pragma mark Dealloc

- (void)dealloc {
	[toolbar release];
	[messageLabel release];
	[addButton release];
	[spinner release];
	[currentVideo release];
    [pickerController release];
	[tableView release];
    [super dealloc];
}

@end
