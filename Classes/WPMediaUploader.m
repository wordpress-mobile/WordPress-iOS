//
//  WPMediaUploader.m
//  WordPress
//
//  Created by Chris Boyd on 8/3/10.
//  Code is poetry.

#import "WPMediaUploader.h"

@implementation WPMediaUploader
@synthesize messageLabel, mediaType, progressView, filename, bits, localEncodedURL, isAtomPub;
@synthesize filesize, orientation, xmlrpcURL, xmlrpcHost, localURL, stopButton;

#pragma mark -
#pragma mark View lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
		messageLabel = [[UILabel alloc] init];
		messageLabel.text = @"";
    }
	
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sendXMLRPC) name:@"FileEncodeSuccessful" object:nil];
}

#pragma mark -
#pragma mark Core transfer code

- (void)start {
	[self reset];
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
	
	// Get blog properties from BDM
	BlogDataManager *dm = [BlogDataManager sharedDataManager];
	dm.shouldStopSyncingBlogs = YES;
	self.xmlrpcURL = [dm.currentBlog valueForKey:@"xmlrpc"];
	
	[self checkAtomPub];
}

- (void)stop {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	[BlogDataManager sharedDataManager].shouldStopSyncingBlogs = NO;
}

- (void)stopWithStatus:(NSString *)status {
	[self stop];
	[self updateStatus:status];
}

- (void)stopWithNotificationName:(NSString *)notificationName {
	[self stop];
	[[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil];
}

- (void)finishWithNotificationName:(NSString *)notificationName object:(NSObject *)object userInfo:(NSDictionary *)userInfo {
	[[NSNotificationCenter defaultCenter] postNotificationName:notificationName 
														object:object 
													  userInfo:userInfo];
}

- (void)reset {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	[BlogDataManager sharedDataManager].shouldStopSyncingBlogs = NO;
	self.progressView.progress = 0.0;
	self.progressView.hidden = NO;
}

- (IBAction)cancelAction:(id)sender {
	[self stop];
	[self reset];
	[self updateStatus:@"Cancelled."];
}

- (void)updateStatus:(NSString *)status {
	self.messageLabel.text = status;
	[self.view setNeedsDisplay];
	[self.view setNeedsLayout];
}

- (void)updateProgress:(NSDictionary *)values {
	float currentFloat = [[values objectForKey:@"current"] floatValue];
	float totalFloat = [[values objectForKey:@"total"] floatValue];
	self.progressView.progress = currentFloat/totalFloat;
}

- (void)showAPIAlert {
	UIAlertView *atomPubAlert = [[UIAlertView alloc] initWithTitle:@"Remote Publishing" 
														   message:@"Video uploads work best with the AtomPub API. You can enable it by going to Settings > Writing > Remote Publishing, checking the box next to \"Atom Publishing Protocol\", then pressing Save Changes." 
														  delegate:self 
												 cancelButtonTitle:@"XML-RPC" 
												 otherButtonTitles:@"AtomPub", nil];
	[atomPubAlert show];
	[atomPubAlert release];
}

- (void)checkAtomPub {
	BOOL isWPcom = NO;
	NSRange range = [self.xmlrpcURL rangeOfString:@"wordpress.com"];
	if(range.location != NSNotFound)
		isWPcom = YES;
	
	if((self.mediaType == kVideo) && (!isWPcom)) {
		if([[NSUserDefaults standardUserDefaults] objectForKey:@"video_upload_preference"] != nil) {
			NSNumber *videoPreference = [[NSUserDefaults standardUserDefaults] objectForKey:@"video_upload_preference"];
			
			switch ([videoPreference intValue]) {
				case 0:
					[self showAPIAlert];
					break;
				case 1:
					[self sendAtomPub];
					break;
				case 2:
					[self buildXMLRPC];
					break;
				default:
					[self buildXMLRPC];
					break;
			}
		}
		else {
			[self showAPIAlert];
		}
	}
	else {
		[self buildXMLRPC];
	}
}

- (void)buildXMLRPC {
	self.progressView.hidden = YES;
	[self performSelectorInBackground:@selector(base64EncodeFile) withObject:nil];
}

- (void)sendXMLRPC {
	self.progressView.hidden = NO;
	
	if(self.mediaType == kImage)
		[self updateStatus:@"Uploading image..."];
	else if(self.mediaType == kVideo)
		[self updateStatus:@"Uploading video..."];
	
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:self.xmlrpcURL]];
	[request setDelegate:self];
	[request setShouldStreamPostDataFromDisk:YES];
	[request appendPostDataFromFile:self.localEncodedURL];
	[request setUploadProgressDelegate:self.progressView];
	[request setTimeOutSeconds:600];
	[request startAsynchronous];
}

- (void)sendAtomPub {
	self.progressView.hidden = NO;
	isAtomPub = YES;
	
	if(self.mediaType == kImage)
		[self updateStatus:@"Uploading image..."];
	else if(self.mediaType == kVideo)
		[self updateStatus:@"Uploading video..."];
	
	BlogDataManager *dm = [BlogDataManager sharedDataManager];
	NSString *blogURL = [dm.currentBlog objectForKey:@"url"];
	
	NSURL *atomURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/wp-app.php/attachments", blogURL]];
	
	NSDictionary *attributes = [[NSFileManager defaultManager] fileAttributesAtPath:self.localURL traverseLink: NO];
	NSString *contentType = @"image/jpeg";
	if(self.mediaType == kVideo)
		contentType = @"video/mp4";
	NSString *username = [dm.currentBlog objectForKey:@"username"];
	NSString *password = [dm getPasswordFromKeychainInContextOfCurrentBlog:dm.currentBlog];
	
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:atomURL];
	[request setUsername:username];
	[request setPassword:password];
	[request setRequestMethod:@"POST"];
	[request addRequestHeader:@"Content-Type" value:contentType];
	[request addRequestHeader:@"Content-Length" value:[NSString stringWithFormat:@"@d",[[attributes objectForKey:NSFileSize] intValue]]];
	[request setShouldStreamPostDataFromDisk:YES];
	[request setPostBodyFilePath:self.localURL];
	[request setDelegate:self];
	[request setUploadProgressDelegate:self.progressView];
	[request startAsynchronous];
}
		   
#pragma mark -
#pragma mark UIAlertView delegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
	switch (buttonIndex) {
		case 1:
			[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:1] forKey:@"video_upload_preference"];
			[[NSUserDefaults standardUserDefaults] synchronize];
			[self sendAtomPub];
			break;
		case 2:
			[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:2] forKey:@"video_upload_preference"];
			[[NSUserDefaults standardUserDefaults] synchronize];
			[self base64EncodeFile];
			break;
		default:
			[self base64EncodeFile];
			break;
	}
}

#pragma mark -
#pragma mark XML-RPC data

- (NSString *)xmlrpcPrefix {
	BlogDataManager *dm = [BlogDataManager sharedDataManager];
	NSString *blogID =  [dm.currentBlog valueForKey:kBlogId];
	NSString *username = [dm.currentBlog valueForKey:@"username"];
	NSString *password = [dm getPasswordFromKeychainInContextOfCurrentBlog:dm.currentBlog];
	
	NSString *type = @"image/jpeg";
	if(self.mediaType == kVideo)
		type = @"video/mp4";
	
	NSString *body = [NSString stringWithFormat:@"<?xml version=\"1.0\"?>"
	"<methodCall><methodName>metaWeblog.newMediaObject</methodName>"
	"<params><param><value><string>%@</string></value></param>"
	"<param><value><string>%@</string></value></param>"
	"<param><value><string>%@</string></value></param>"
	"<param><value><struct>"
	"<member><name>type</name><value><string>%@</string></value></member>"
	"<member><name>name</name><value><string>%@</string></value></member>"
	"<member><name>bits</name><value><base64>",
					  blogID,
					  username,
					  password,
					  type,
					  self.filename];
	return body;
}

- (NSString *)xmlrpcSuffix {
	return  @"</base64></value></member></struct></value></param></params></methodCall>";
}

- (void)base64EncodeFile {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	[self performSelectorOnMainThread:@selector(updateStatus:) withObject:@"Encoding media..." waitUntilDone:NO];
	
	NSFileHandle *originalFile, *encodedFile;
	self.localEncodedURL = [NSString stringWithFormat:@"%@-base64.xml", self.localURL];
	
	// Open the original video file for reading
	originalFile = [NSFileHandle fileHandleForReadingAtPath:self.localURL];
	if (originalFile == nil) {
		[self performSelectorOnMainThread:@selector(updateStatus:) withObject:@"Encoding failed." waitUntilDone:NO];
		return;
	}
	
	// Create our XML-RPC payload file
	[[NSFileManager defaultManager] createFileAtPath:self.localEncodedURL
											contents:nil
										  attributes:nil];
	
	// Open XML-RPC file for writing
	encodedFile = [NSFileHandle fileHandleForWritingAtPath:self.localEncodedURL];
	if (encodedFile == nil) {
		[self performSelectorOnMainThread:@selector(updateStatus:) withObject:@"Encoding failed." waitUntilDone:NO];
		return;
	}
	
	// Add our XML-RPC payload prefix
	NSString *prefix = [self xmlrpcPrefix];
	[encodedFile writeData:[prefix dataUsingEncoding:NSASCIIStringEncoding]];
	
	// Read data in chunks from the original file
	[originalFile seekToEndOfFile];
	NSUInteger fileLength = [originalFile offsetInFile];
	[originalFile seekToFileOffset:0];
	
	// Many thanks to GregInYEG and eskimo1@apple.com:
	// For base64, each chunk *MUST* be a multiple of 3
	NSUInteger chunkSize = 24000;
	NSUInteger offset = 0;
	NSAutoreleasePool *chunkPool = [[NSAutoreleasePool alloc] init];
	while(offset < fileLength) {
		// Read the next chunk from the input file
		[originalFile seekToFileOffset:offset];
		NSData *chunk = [originalFile readDataOfLength:chunkSize];
		
		// Update our offset
		offset += chunkSize;
		
		// Base64 encode the input chunk
		NSData *serializedChunk = [NSPropertyListSerialization dataFromPropertyList:chunk format:NSPropertyListXMLFormat_v1_0 errorDescription:NULL];
		NSString *serializedString =  [[NSString alloc] initWithData:serializedChunk encoding:NSASCIIStringEncoding];
		NSRange r = [serializedString rangeOfString:@"<data>"];
		serializedString = [serializedString substringFromIndex:r.location+7];
		r = [serializedString rangeOfString:@"</data>"];
		serializedString = [serializedString substringToIndex:r.location-1];
		
		// Write the base64 encoded chunk to our output file
		NSData *base64EncodedChunk = [serializedString dataUsingEncoding:NSASCIIStringEncoding];
		[encodedFile truncateFileAtOffset:[encodedFile seekToEndOfFile]];
		[encodedFile writeData:base64EncodedChunk];
		
		// Cleanup
		base64EncodedChunk = nil;
		serializedChunk = nil;
		serializedString = nil;
		chunk = nil;
		
		// Drain and recreate the pool
		[chunkPool release];
		chunkPool = [[NSAutoreleasePool alloc] init];
	}
	[chunkPool release];
	
	// Add the suffix to close out the xml payload
	NSString *suffix = [self xmlrpcSuffix];
	[encodedFile writeData:[suffix dataUsingEncoding:NSASCIIStringEncoding]];
	
	// Close the two files
	[originalFile closeFile];
	[encodedFile closeFile];
	
	// We're done
	if(self.mediaType == kImage)
		[self performSelectorOnMainThread:@selector(updateStatus:) withObject:@"Uploading image..." waitUntilDone:NO];
	else if(self.mediaType == kVideo)
		[self performSelectorOnMainThread:@selector(updateStatus:) withObject:@"Uploading video..." waitUntilDone:NO];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"FileEncodeSuccessful" object:nil];
	
	[pool release];
}

- (void)base64EncodeImage {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	[self performSelectorOnMainThread:@selector(updateStatus:) withObject:@"Encoding media..." waitUntilDone:NO];
	
	NSFileHandle *encodedFile;
	self.localEncodedURL = [NSString stringWithFormat:@"%@-base64.xml", self.filename];
	
	// Create our XML-RPC payload file
	[[NSFileManager defaultManager] createFileAtPath:self.localEncodedURL
											contents:nil
										  attributes:nil];
	
	// Open XML-RPC file for writing
	encodedFile = [NSFileHandle fileHandleForWritingAtPath:self.localEncodedURL];
	if (encodedFile == nil) {
		[self performSelectorOnMainThread:@selector(updateStatus:) withObject:@"Encoding failed." waitUntilDone:NO];
		return;
	}
	else {
		// Add our XML-RPC payload prefix
		NSString *prefix = [self xmlrpcPrefix];
		[encodedFile writeData:[prefix dataUsingEncoding:NSASCIIStringEncoding]];
		
		// Convert the image bytes to a base64 string, then back to bytes
		NSString *base64EncodedImageString = [self.bits base64EncodedString];
		NSData *base64EncodedImage = [base64EncodedImageString dataUsingEncoding:NSASCIIStringEncoding];
		[encodedFile writeData:base64EncodedImage];
		
		// Add the suffix to close out the xml payload
		NSString *suffix = [self xmlrpcSuffix];
		[encodedFile writeData:[suffix dataUsingEncoding:NSASCIIStringEncoding]];
		
		// Close the two files
		[encodedFile closeFile];
		
		// We're done
		if(self.mediaType == kImage)
			[self performSelectorOnMainThread:@selector(updateStatus:) withObject:@"Uploading image..." waitUntilDone:NO];
		else if(self.mediaType == kVideo)
			[self performSelectorOnMainThread:@selector(updateStatus:) withObject:@"Uploading video..." waitUntilDone:NO];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"FileEncodeSuccessful" object:nil];
	}
	
	[pool release];
}

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

#pragma mark ASIHTTPRequest delegate

- (void)requestFinished:(ASIHTTPRequest *)request {
	NSLog(@"request.responseString: %@", [request responseString]);
	if(![[request responseString] isEmpty]) {
		NSMutableDictionary *videoMeta = [[NSMutableDictionary alloc] init];
		if(isAtomPub) {
			NSString *regEx = @"src=\"([^\"]*)\"";
			NSString *link = [[request responseString] stringByMatching:regEx capture:0];
			[videoMeta setObject:link forKey:@"url"];
			[self finishWithNotificationName:VideoUploadSuccessful object:nil userInfo:videoMeta];
			NSLog(@"atomPub remote media link: %@", link);
		}
		else {
			[[NSFileManager defaultManager] removeItemAtURL:[NSURL fileURLWithPath:self.localEncodedURL] error:NULL];
			XMLRPCResponse *xmlrpcResponse = [[XMLRPCResponse alloc] initWithData:[request responseData]];
			NSDictionary *responseMeta = [xmlrpcResponse object];
			if ([xmlrpcResponse isKindOfClass:[NSError class]]) {
				[self finishWithNotificationName:VideoUploadFailed object:nil userInfo:nil];
			}
			else if(mediaType == kVideo) {
				if([responseMeta objectForKey:@"videopress_shortcode"] != nil)
					[videoMeta setObject:[responseMeta objectForKey:@"videopress_shortcode"] forKey:@"shortcode"];
				
				if([responseMeta objectForKey:@"url"] != nil)
					[videoMeta setObject:[responseMeta objectForKey:@"url"] forKey:@"url"];
				
				if(videoMeta.count > 0) {
					[videoMeta setValue:[NSNumber numberWithInt:orientation] forKey:@"orientation"];
					[self finishWithNotificationName:VideoUploadSuccessful object:nil userInfo:videoMeta];
				}
				[videoMeta release];
			}
			else if(mediaType == kImage) {
				NSMutableDictionary *imageMeta = [[NSMutableDictionary alloc] init];
				if([responseMeta objectForKey:@"url"] != nil)
					[imageMeta setObject:[responseMeta objectForKey:@"url"] forKey:@"url"];
				[self finishWithNotificationName:ImageUploadSuccessful object:nil userInfo:imageMeta];
				[imageMeta release];
			}
			
			[xmlrpcResponse release];
		}
	}
	else {
		[self updateStatus:@"Upload failed. Please try again."];
		
		[NSThread sleepForTimeInterval:2.0];
		
		if(self.mediaType == kImage)
			[self stopWithNotificationName:@"ImageUploadFailed"];
		else if(self.mediaType == kVideo)
			[self stopWithNotificationName:@"VideoUploadFailed"];
	}

}

- (void)requestFailed:(ASIHTTPRequest *)request {
	[self updateStatus:@"Upload failed. Please try again."];
	
	[NSThread sleepForTimeInterval:2.0];
	
	if(self.mediaType == kImage)
		[self stopWithNotificationName:@"ImageUploadFailed"];
	else if(self.mediaType == kVideo)
		[self stopWithNotificationName:@"VideoUploadFailed"];
	
	if(!isAtomPub)
		[[NSFileManager defaultManager] removeItemAtURL:[NSURL fileURLWithPath:self.localEncodedURL] error:NULL];
}

- (void)connection:(NSURLConnection *)conn didFailWithError:(NSError *)error {
	[self updateStatus:@"Upload failed. Please try again."];
	NSLog(@"connection failed: %@", [error localizedDescription]);
	
	if(self.mediaType == kImage)
		[self stopWithNotificationName:@"ImageUploadFailed"];
	else if(self.mediaType == kVideo)
		[self stopWithNotificationName:@"VideoUploadFailed"];
}

#pragma mark -
#pragma mark Dealloc

- (void)dealloc {
    [self stopWithStatus:@"Stopped"];
	
	[stopButton release];
	[localURL release];
	[xmlrpcURL release];
	[xmlrpcHost release];
	[filename release];
	[bits release];
	[messageLabel release];
	[progressView release];
	
    [super dealloc];
}


@end
