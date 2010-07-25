//
//  MediaViewController.m
//  WordPress
//
//  Created by Chris Boyd on 6/23/10.
//  Copyright 2010 WordPress. All rights reserved.
//

#import "MediaViewController.h"

@implementation MediaViewController
@synthesize mediaArray;
@synthesize managedObjectContext;
@synthesize addButton;
@synthesize postDetailViewController;
@synthesize wpAppDelegate;

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
	wpAppDelegate = [[UIApplication sharedApplication] delegate];
	
	if(managedObjectContext == nil)
        managedObjectContext = [wpAppDelegate managedObjectContext];
	
	[self fetchMedia];
	
    // Set the title.
    self.title = @"Media";
	
    // Set up the buttons.
    addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
															  target:self action:@selector(addMedia)];
    postDetailViewController.navigationItem.rightBarButtonItem = addButton;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
    postDetailViewController.navigationItem.rightBarButtonItem = addButton;
}

#pragma mark -
#pragma mark Media Methods

- (void)addMedia {
	UIActionSheet *actionSheet = [[UIActionSheet alloc] init];
	[actionSheet addButtonWithTitle:@"Import Media"];
	[actionSheet setDelegate:self];
	
	// Check for camera support
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
		[actionSheet addButtonWithTitle:@"Take Photo"];
	
	// Check for video support
	if([[UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera] containsObject:(NSString *)kUTTypeMovie])
		[actionSheet addButtonWithTitle:@"Record Video"];
	
	// Check for audio support
	if([[UIDevice currentDevice] hasMicrophone])
		[actionSheet addButtonWithTitle:@"Record Audio"];
	
	if(actionSheet.numberOfButtons == 1)
		[self pickMediaFromPhotoLibrary];
	else {
		[wpAppDelegate setAlertRunning:YES];
		[actionSheet addButtonWithTitle:@"Cancel"];
		[actionSheet setCancelButtonIndex:actionSheet.numberOfButtons-1];
		actionSheet.actionSheetStyle = UIActionSheetStyleDefault;
		[actionSheet showInView:postDetailViewController.view];
	}
	[actionSheet release];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
		case 0:
			[self pickMediaFromPhotoLibrary];
			break;
		case 1:
			[self pickPhotoFromCamera];
			break;
		case 2:
			[self pickVideoFromCamera];
			break;
		case 3:
			[self pickAudioFromMicrophone];
			break;
	}
	[wpAppDelegate setAlertRunning:YES];
}

- (void)pickMediaFromPhotoLibrary {
	NSLog(@"Pick media from Library.");
	if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
		picker.delegate = self;
		
		if(DeviceIsPad())
			[postDetailViewController displayPhotoListImagePicker:picker];
		else
			[postDetailViewController.navigationController presentModalViewController:picker animated:YES];
	}
}

- (void)pickPhotoFromCamera {
	NSLog(@"Take photo with Camera.");
	if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
		picker.delegate = self;
		picker.allowsEditing = NO;
		[postDetailViewController.navigationController presentModalViewController:picker animated:YES];
    }
}

- (void)pickVideoFromCamera {
	NSLog(@"Record video with Camera.");
	if([[UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera] containsObject:(NSString *)kUTTypeMovie]) {
		UIImagePickerController *picker = [[UIImagePickerController alloc] init];
		picker.sourceType =  UIImagePickerControllerSourceTypeCamera;
	    picker.mediaTypes = [NSArray arrayWithObject:(NSString *)kUTTypeMovie];
		picker.delegate = self;
		picker.allowsEditing = NO;
		[postDetailViewController.navigationController presentModalViewController:picker animated:YES];
	}
}

- (void)pickAudioFromMicrophone {
	NSLog(@"Record audio with Microphone.");
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {	
	if([[info valueForKey:@"UIImagePickerControllerMediaType"] isEqualToString:@"public.movie"]) {
		NSString *video = [(NSURL *)[info valueForKey:UIImagePickerControllerMediaURL] absoluteString];
		video = [[video substringFromIndex:16] retain];
		if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(video))
			UISaveVideoAtPathToSavedPhotosAlbum(video, self, @selector(video:didFinishSavingWithError:contextInfo:), video);
	}
	else if([[info valueForKey:@"UIImagePickerControllerMediaType"] isEqualToString:@"public.image"]) {
		UIImage *image = [info valueForKey:@"UIImagePickerControllerOriginalImage"];
		if (picker.sourceType == UIImagePickerControllerSourceTypeCamera)
			UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
		
		NSData *thumbnail = UIImageJPEGRepresentation([self generateThumbnail:image], 0.75f);
		
		[self saveMedia:[[info valueForKey:UIImagePickerControllerMediaURL] absoluteString] thumbnail:thumbnail mediaType:@"image"];
	}
	
	[[picker parentViewController] dismissModalViewControllerAnimated:YES];
}

- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(NSString *)contextInfo {
	NSString *file, *latestFile;
	NSDate *latestDate = [NSDate distantPast];
	NSDirectoryEnumerator *dirEnum = [[NSFileManager defaultManager] enumeratorAtPath:[[contextInfo stringByDeletingLastPathComponent]stringByDeletingLastPathComponent]];
	while (file = [dirEnum nextObject]) {
		if ([[file pathExtension] isEqualToString: @"jpg"]) {
			if ([(NSDate *)[[dirEnum fileAttributes] valueForKey:@"NSFileModificationDate"] compare:latestDate] == NSOrderedDescending){
				latestDate = [[dirEnum fileAttributes] valueForKey:@"NSFileModificationDate"];
				latestFile = file;
			}
		}
	}
	
	latestFile = [NSTemporaryDirectory() stringByAppendingPathComponent:latestFile];
	NSLog(@"Video thumbnail complete.");
	[self saveMedia:contextInfo thumbnail:[NSData dataWithContentsOfURL:[NSURL URLWithString:latestFile]] mediaType:@"video"];
}

- (void)saveMedia:(NSString *)localURL thumbnail:(NSData *)thumbnail mediaType:(NSString *)mediaType {
	NSLog(@"Saving %@...", mediaType);
	Media *media = (Media *)[NSEntityDescription insertNewObjectForEntityForName:@"Media" inManagedObjectContext:self.managedObjectContext];
	[media setLocalURL:localURL];
	[media setThumbnail:thumbnail];
	[media setCreationDate:[NSDate date]];
	[media setMediaType:mediaType];
	[mediaArray insertObject:media atIndex:0];
	NSError *mediaError;
	if (![managedObjectContext save:&mediaError]) {
		NSLog(@"error saving media: %@", mediaError);
	}
	
	NSLog(@"Save complete. Updating table...", mediaType);
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
	[self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
						  withRowAnimation:UITableViewRowAnimationFade];
	[self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
	[[picker parentViewController] dismissModalViewControllerAnimated:YES];
}

- (void)fetchMedia {
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Media" inManagedObjectContext:managedObjectContext];
	[request setEntity:entity];
	
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"creationDate" ascending:NO];
	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
	[request setSortDescriptors:sortDescriptors];
	[sortDescriptors release];
	[sortDescriptor release];
	
	NSError *mediaError;
	NSMutableArray *mutableFetchResults = [[managedObjectContext executeFetchRequest:request error:&mediaError] mutableCopy];
	if (mutableFetchResults == nil) {
		NSLog(@"error fetching media: %@", mediaError);
	}
	
	self.mediaArray = mutableFetchResults;
	[mutableFetchResults release];
	[request release];
}

- (UIImage *)generateThumbnail:(UIImage *)fromImage {
	CGImageRef imageRef = [fromImage CGImage];
	CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(imageRef);
	
	//if (alphaInfo == kCGImageAlphaNone)
	alphaInfo = kCGImageAlphaNoneSkipLast;
	
	CGContextRef bitmap = CGBitmapContextCreate(NULL, 50, 50, CGImageGetBitsPerComponent(imageRef), 4 * 50, CGImageGetColorSpace(imageRef), alphaInfo);
	CGContextDrawImage(bitmap, CGRectMake(0, 0, 50, 50), imageRef);
	CGImageRef ref = CGBitmapContextCreateImage(bitmap);
	UIImage *result = [UIImage imageWithCGImage:ref];
	
	CGContextRelease(bitmap);
	CGImageRelease(ref);
	
	return result;	
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [mediaArray count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	// A date formatter for the time stamp
	static NSDateFormatter *dateFormatter = nil;
	if (dateFormatter == nil) {
		dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
		[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
	}
	
	static NSString *CellIdentifier = @"Cell";
	
	// Dequeue or create a new cell
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
	}
	
	Media *media = (Media *)[mediaArray objectAtIndex:indexPath.row];
	
	// Thumbnail
	if(media.thumbnail == nil)
		cell.imageView.image = [UIImage imageNamed:@"photos.png"];
	else
		cell.imageView.image = [UIImage imageWithData:media.thumbnail];
	
	// Text
	if((media.title == nil) || ([media.title isEqualToString:@""]))
		cell.textLabel.text = [NSString stringWithFormat:@"%@ %d", [media.mediaType capitalizedString], indexPath.row + 1];
	else
		cell.textLabel.text = media.title;
	cell.detailTextLabel.text = [dateFormatter stringFromDate:[media creationDate]];
	
	return cell;
}


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
	/*
	 <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
	 [self.navigationController pushViewController:detailViewController animated:YES];
	 [detailViewController release];
	 */
}

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}


- (void)dealloc {
	[postDetailViewController release];
	[addButton release];
	[managedObjectContext release];
	[mediaArray release];
    [super dealloc];
}


@end

