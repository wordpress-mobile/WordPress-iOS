//
//  WPMediaUploader.m
//  WordPress
//
//  Created by Chris Boyd on 8/3/10.
//  Code is poetry.

#import "WPMediaUploader.h"

@implementation WPMediaUploader
@synthesize messageLabel, mediaType, progressView, filename, bits, localEncodedURL;
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
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(send) name:@"FileEncodeSuccessful" object:nil];
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
	
	if(self.mediaType == kVideo)
		[self performSelectorInBackground:@selector(base64EncodeFile) withObject:nil];
	else if(self.mediaType == kImage)
		[self performSelectorInBackground:@selector(base64EncodeFile) withObject:nil];
//	else if(self.mediaType == kImage)
//		[self performSelectorInBackground:@selector(base64EncodeImage) withObject:nil];
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

- (void)send {
	[self performSelectorOnMainThread:@selector(updateStatus:) withObject:@"Uploading media..." waitUntilDone:NO];
	
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:self.xmlrpcURL]];
	[request setDelegate:self];
	[request setShouldStreamPostDataFromDisk:YES];
	[request appendPostDataFromFile:self.localEncodedURL];
	[request setUploadProgressDelegate:self.progressView];
	[request startAsynchronous];
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

- (void)updateProgress:(NSNumber *)current total:(NSNumber *)total {
	float currentFloat = [current floatValue];
	float totalFloat = [total floatValue];
	self.progressView.progress = currentFloat/totalFloat;
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
	NSUInteger chunkSize = 100 * 1024;
	NSUInteger offset = 0;
	while(offset < fileLength) {
		[originalFile seekToFileOffset:offset];
		NSData *chunk = [originalFile readDataOfLength:chunkSize];
		offset += chunkSize;
		
		NSData *serializedChunk = [NSPropertyListSerialization dataFromPropertyList:chunk format:NSPropertyListXMLFormat_v1_0 errorDescription:NULL];
		NSString *serializedString =  [[NSString alloc] initWithData:serializedChunk encoding:NSASCIIStringEncoding];
		NSRange r = [serializedString rangeOfString:@"<data>"];
		serializedString = [serializedString substringFromIndex:r.location+7];
		r = [serializedString rangeOfString:@"</data>"];
		serializedString = [serializedString substringToIndex:r.location-1];
		
		assert(encodedFile != nil);
		
		NSData *base64EncodedChunk = [serializedString dataUsingEncoding:NSASCIIStringEncoding];
		[encodedFile truncateFileAtOffset:[encodedFile seekToEndOfFile]];
		[encodedFile writeData:base64EncodedChunk];
		
//		NSString *contentString = [[NSString alloc] initWithData:base64EncodedChunk encoding:NSUTF8StringEncoding];
//		NSLog(@"contentString: %@", contentString);
//		[contentString release];
		
		base64EncodedChunk = nil;
		
		[self updateProgress:[NSNumber numberWithInt:offset] total:[NSNumber numberWithInt:fileLength]];
	}
	
	// Add the suffix to close out the xml payload
	NSString *suffix = [self xmlrpcSuffix];
	[encodedFile writeData:[suffix dataUsingEncoding:NSASCIIStringEncoding]];
	
	// Close the two files
	[originalFile closeFile];
	[encodedFile closeFile];
	
	// We're done
	[self performSelectorOnMainThread:@selector(updateStatus:) withObject:@"Media encoded." waitUntilDone:NO];
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
		[self performSelectorOnMainThread:@selector(updateStatus:) withObject:@"Media encoded." waitUntilDone:NO];
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
	[[NSFileManager defaultManager] removeItemAtURL:[NSURL fileURLWithPath:self.localEncodedURL] error:NULL];
	
	XMLRPCResponse *xmlrpcResponse = [[XMLRPCResponse alloc] initWithData:[request responseData]];
	NSDictionary *responseMeta = [xmlrpcResponse object];
	if ([xmlrpcResponse isKindOfClass:[NSError class]]) {
		[self finishWithNotificationName:VideoUploadFailed object:nil userInfo:nil];
	}
	else if(mediaType == kVideo) {
			NSMutableDictionary *videoMeta = [[NSMutableDictionary alloc] init];
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

- (void)requestFailed:(ASIHTTPRequest *)request {
	NSLog(@"request failed.");
	NSError *error = [request error];
	NSLog(@"requestFailed: %@", [error localizedDescription]);
	
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
