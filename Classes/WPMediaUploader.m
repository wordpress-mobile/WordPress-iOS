//
//  WPMediaUploader.m
//  WordPress
//
//  Created by Chris Boyd on 8/3/10.
//  Code is poetry.

#import "WPMediaUploader.h"

@implementation WPMediaUploader
@synthesize messageLabel, progressView, isAtomPub;
@synthesize stopButton, media;

#pragma mark -
#pragma mark View lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
		messageLabel = [[UILabel alloc] init];
		messageLabel.text = @"";
    }
	
    return self;
}

- (id)initWithMedia:(Media *)mediaItem {
    if (self = [super init]) {
        self.media = mediaItem;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sendXMLRPC) name:@"FileEncodeSuccessful" object:self.media];
}

#pragma mark -
#pragma mark Core transfer code

- (void)start {
    WPLog(@"%@ %@ (%@)", self, NSStringFromSelector(_cmd), self.media.filename);
	[self reset];
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
	
	[self checkAtomPub];
}

- (void)stop {
    WPLog(@"%@ %@ (%@)", self, NSStringFromSelector(_cmd), self.media.filename);
    [request cancel];
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)stopWithStatus:(NSString *)status {
	[self stop];
	[self updateStatus:status];
}

- (void)stopWithNotificationName:(NSString *)notificationName {
    WPLog(@"%@ %@ (%@)", self, NSStringFromSelector(_cmd), self.media.filename);
	[self stop];
	[[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:self.media];
}

- (void)finishWithNotificationName:(NSString *)notificationName object:(NSObject *)object userInfo:(NSDictionary *)userInfo {
    WPLog(@"%@ %@ (%@)", self, NSStringFromSelector(_cmd), self.media.filename);
	[[NSNotificationCenter defaultCenter] postNotificationName:notificationName 
														object:object 
													  userInfo:userInfo];
}

- (void)reset {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	self.media.progress = 0.0;
}

- (IBAction)cancelAction:(id)sender {
	[self stop];
	[self reset];
	[self updateStatus:@"Cancelled."];
}

- (void)updateStatus:(NSString *)status {
    WPLog(@"Upload Status: %@", status);
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
//	UIAlertView *atomPubAlert = [[UIAlertView alloc] initWithTitle:@"Remote Publishing" 
//														   message:@"Video uploads work best with the AtomPub API. You can enable it by going to Settings > Writing > Remote Publishing, checking the box next to \"Atom Publishing Protocol\", then pressing Save Changes." 
//														  delegate:self 
//												 cancelButtonTitle:@"XML-RPC" 
//												 otherButtonTitles:@"AtomPub", nil];
//	[atomPubAlert show];
//	[atomPubAlert release];
}

- (NSString *)localEncodedURL {
    return [NSString stringWithFormat:@"%@-base64.xml", self.media.filename];
}

- (void)checkAtomPub {
	BOOL isWPcom = NO;
	NSRange range = [self.media.blog.xmlrpc rangeOfString:@"wordpress.com"];
	if(range.location != NSNotFound)
		isWPcom = YES;
	
	if(([self.media.mediaType isEqualToString:@"video"]) && (!isWPcom)) {
		if([[NSUserDefaults standardUserDefaults] objectForKey:@"video_api_preference"] != nil) {
			NSString *videoPreference = [[NSUserDefaults standardUserDefaults] objectForKey:@"video_api_preference"];
			
			switch ([videoPreference intValue]) {
				case 0:
					[self buildXMLRPC];
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
			[self buildXMLRPC];
		}

	}
	else {
		[self buildXMLRPC];
	}
}

- (void)buildXMLRPC {
	[self performSelectorInBackground:@selector(base64EncodeFile) withObject:nil];
}

- (void)sendXMLRPC {
    WPLog(@"%@ %@ (%@)", self, NSStringFromSelector(_cmd), self.media.filename);
	self.progressView.hidden = NO;
	
	if([self.media.mediaType isEqualToString:@"image"])
		[self updateStatus:@"Uploading image..."];
	else if([self.media.mediaType isEqualToString:@"video"])
		[self updateStatus:@"Uploading video..."];
	
	request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:self.media.blog.xmlrpc]];
	[request setDelegate:self];
	[request setShouldStreamPostDataFromDisk:YES];
	[request appendPostDataFromFile:self.localEncodedURL];
	[request setUploadProgressDelegate:self.media];
	[request setTimeOutSeconds:600];
	[request startAsynchronous];
    [request retain];
}

- (void)sendAtomPub {
	self.progressView.hidden = NO;
	isAtomPub = YES;
	
	if([self.media.mediaType isEqualToString:@"image"])
		[self updateStatus:@"Uploading image..."];
	else if([self.media.mediaType isEqualToString:@"video"])
		[self updateStatus:@"Uploading video..."];
	
	NSString *blogURL = self.media.blog.url;
	
	NSURL *atomURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/wp-app.php/attachments", blogURL]];
	
	NSDictionary *attributes = [[NSFileManager defaultManager] fileAttributesAtPath:self.media.localURL traverseLink: NO];
	NSString *contentType = @"image/jpeg";
	if([self.media.mediaType isEqualToString:@"video"])
		contentType = @"video/mp4";
    NSError *error = nil;
	NSString *username = self.media.blog.username;
	NSString *password = [SFHFKeychainUtils getPasswordForUsername:username andServiceName:self.media.blog.hostURL error:&error];
	
	request = [ASIFormDataRequest requestWithURL:atomURL];
	[request setUsername:username];
	[request setPassword:password];
	[request setRequestMethod:@"POST"];
	[request addRequestHeader:@"Content-Type" value:contentType];
	[request addRequestHeader:@"Content-Length" value:[NSString stringWithFormat:@"@d",[[attributes objectForKey:NSFileSize] intValue]]];
	[request setShouldStreamPostDataFromDisk:YES];
	[request setPostBodyFilePath:self.media.localURL];
	[request setDelegate:self];
	[request setUploadProgressDelegate:self.media];
	[request startAsynchronous];
    [request retain];
}
		   
#pragma mark -
#pragma mark UIAlertView delegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
	switch (buttonIndex) {
		case 0:
			break;
		case 1:
		{
			NSString *buttonTitle = [alertView buttonTitleAtIndex:buttonIndex];
			if ([buttonTitle isEqualToString:@"Yes"]){
				[[UIApplication sharedApplication] openURL:[NSURL URLWithString: @"http://videopress.com"]];
			}
			else{
				[[NSUserDefaults standardUserDefaults] setObject:@"1" forKey:@"video_api_preference"];
				[[NSUserDefaults standardUserDefaults] synchronize];
				[self sendAtomPub];
			}
			[buttonTitle release];
			break;
		}
		case 2:
			[[NSUserDefaults standardUserDefaults] setObject:@"2" forKey:@"video_api_preference"];
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
	NSNumber *blogID = self.media.blog.blogID;
    NSError *error = nil;
	NSString *username = self.media.blog.username;
	NSString *password = [SFHFKeychainUtils getPasswordForUsername:username andServiceName:self.media.blog.hostURL error:&error];
	username = [NSString encodeXMLCharactersIn:username];
	password = [NSString encodeXMLCharactersIn:password];
	
	NSString *type = @"image/jpeg";
	if([self.media.mediaType isEqualToString:@"video"])
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
					  self.media.filename];
	return body;
}

- (NSString *)xmlrpcSuffix {
	return  @"</base64></value></member></struct></value></param></params></methodCall>";
}

- (void)base64EncodeFile {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	[self performSelectorOnMainThread:@selector(updateStatus:) withObject:@"Encoding media..." waitUntilDone:NO];
	
	NSFileHandle *originalFile, *encodedFile;
	
	// Open the original video file for reading
	originalFile = [NSFileHandle fileHandleForReadingAtPath:self.media.localURL];
	if (originalFile == nil) {
		[self performSelectorOnMainThread:@selector(updateStatus:) withObject:@"Encoding failed." waitUntilDone:NO];
		return;
	}
	
    // If encoded file already exists, don't try encoding again
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.localEncodedURL]) {
        if([self.media.mediaType isEqualToString:@"image"])
            [self performSelectorOnMainThread:@selector(updateStatus:) withObject:@"Uploading image..." waitUntilDone:NO];
        else if([self.media.mediaType isEqualToString:@"video"])
            [self performSelectorOnMainThread:@selector(updateStatus:) withObject:@"Uploading video..." waitUntilDone:NO];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"FileEncodeSuccessful" object:self.media];
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
	[encodedFile writeData:[prefix dataUsingEncoding:NSUTF8StringEncoding]];
	
	// Read data in chunks from the original file
	[originalFile seekToEndOfFile];
	NSUInteger fileLength = [originalFile offsetInFile];
	[originalFile seekToFileOffset:0];
	
	// Many thanks to GregInYEG from StackOverflow and eskimo1 from Apple:
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
		NSString *serializedString =  [[NSString alloc] initWithData:serializedChunk encoding:NSUTF8StringEncoding];
		NSRange r = [serializedString rangeOfString:@"<data>"];
		serializedString = [serializedString substringFromIndex:r.location+7];
		r = [serializedString rangeOfString:@"</data>"];
		serializedString = [serializedString substringToIndex:r.location-1];
		
		// Write the base64 encoded chunk to our output file
		NSData *base64EncodedChunk = [serializedString dataUsingEncoding:NSUTF8StringEncoding];
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
	[encodedFile writeData:[suffix dataUsingEncoding:NSUTF8StringEncoding]];
	
	// Close the two files
	[originalFile closeFile];
	[encodedFile closeFile];
	
	// We're done
	if([self.media.mediaType isEqualToString:@"image"])
		[self performSelectorOnMainThread:@selector(updateStatus:) withObject:@"Uploading image..." waitUntilDone:NO];
	else if([self.media.mediaType isEqualToString:@"video"])
		[self performSelectorOnMainThread:@selector(updateStatus:) withObject:@"Uploading video..." waitUntilDone:NO];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"FileEncodeSuccessful" object:self.media];
	
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

- (void)requestFinished:(ASIHTTPRequest *)req {
	if(![[request responseString] isEmpty]) {
		NSLog(@"response: %@", [request responseString]);
		NSMutableDictionary *videoMeta = [[NSMutableDictionary alloc] init];
		if ([[request responseString] rangeOfString:@"AtomPub services are disabled"].location != NSNotFound){
			UIAlertView *uploadAlert = [[UIAlertView alloc] initWithTitle:@"Upload Failed" 
													 message:[request responseString] 
													delegate:self
										   cancelButtonTitle:@"OK" otherButtonTitles:nil];
			[uploadAlert show];
			[uploadAlert release];
            self.media.remoteStatus = MediaRemoteStatusFailed;
			if([self.media.mediaType isEqualToString:@"video"])
				[self finishWithNotificationName:VideoUploadFailed object:self.media userInfo:nil];
			else if([self.media.mediaType isEqualToString:@"image"])
				[self finishWithNotificationName:ImageUploadFailed object:self.media userInfo:nil];
		}
		else if(isAtomPub) {
			NSString *regEx = @"src=\"([^\"]*)\"";
			NSString *link = [[request responseString] stringByMatching:regEx capture:1];
			link = [link stringByReplacingOccurrencesOfString:@"\"" withString:@""];
			[videoMeta setObject:link forKey:@"url"];
            self.media.remoteURL = link;
            self.media.remoteStatus = MediaRemoteStatusSync;
            [self finishWithNotificationName:VideoUploadSuccessful object:self.media userInfo:videoMeta];
		}
		else {
			XMLRPCResponse *xmlrpcResponse = [[XMLRPCResponse alloc] initWithData:[request responseData]];
			NSDictionary *responseMeta = [xmlrpcResponse object];
			if ([xmlrpcResponse isKindOfClass:[NSError class]]) {
                self.media.remoteStatus = MediaRemoteStatusFailed;
				[self finishWithNotificationName:VideoUploadFailed object:self.media userInfo:nil];
			}
			else if([responseMeta valueForKey:@"faultString"] != nil) {
				NSString *faultString = [responseMeta valueForKey:@"faultString"];
				UIAlertView *uploadAlert;
				if ([faultString rangeOfString:@"Invalid file type"].location == NSNotFound){
					uploadAlert = [[UIAlertView alloc] initWithTitle:@"Upload Failed" 
															 message:faultString 
															delegate:self
												   cancelButtonTitle:@"OK" otherButtonTitles:nil];
				}
				else {
					faultString = @"You can upload videos to your blog with VideoPress. Would you like to learn more about VideoPress now?";
					uploadAlert = [[UIAlertView alloc] initWithTitle:@"Upload Failed" 
															 message:faultString 
															delegate:self
												   cancelButtonTitle:@"No" otherButtonTitles:nil];
					[uploadAlert addButtonWithTitle:@"Yes"];
				}
				[uploadAlert show];
				[uploadAlert release];
                
                self.media.remoteStatus = MediaRemoteStatusFailed;
                if([self.media.mediaType isEqualToString:@"video"])
                    [self finishWithNotificationName:VideoUploadFailed object:self.media userInfo:nil];
                else if([self.media.mediaType isEqualToString:@"image"])
                    [self finishWithNotificationName:ImageUploadFailed object:self.media userInfo:nil];
			}
			else if([self.media.mediaType isEqualToString:@"video"]) {
				if([responseMeta objectForKey:@"videopress_shortcode"] != nil)
                    self.media.shortcode = [responseMeta objectForKey:@"videopress_shortcode"];
				
				if([responseMeta objectForKey:@"url"] != nil)
                    self.media.remoteURL = [responseMeta objectForKey:@"url"];
				
                self.media.remoteStatus = MediaRemoteStatusSync;
                if(videoMeta.count > 0) {
					[self finishWithNotificationName:VideoUploadSuccessful object:self.media userInfo:responseMeta];
				}
			}
			else if([self.media.mediaType isEqualToString:@"image"]) {
				NSMutableDictionary *imageMeta = [[NSMutableDictionary alloc] init];
				
				if([responseMeta objectForKey:@"url"] != nil)
                    self.media.remoteURL = [responseMeta objectForKey:@"url"];
                self.media.remoteStatus = MediaRemoteStatusSync;
                [self finishWithNotificationName:ImageUploadSuccessful object:self.media userInfo:responseMeta];
				[imageMeta release];
			}
			
			[xmlrpcResponse release];
		}
        [videoMeta release];
    }
	else {
		[self updateStatus:@"Upload failed. Please try again."];
		NSLog(@"connection failed: %@", [request responseData]);
		
		[NSThread sleepForTimeInterval:2.0];
        
        self.media.remoteStatus = MediaRemoteStatusFailed;
		if([self.media.mediaType isEqualToString:@"image"])
			[self finishWithNotificationName:ImageUploadFailed object:self.media userInfo:nil];
		else if([self.media.mediaType isEqualToString:@"video"])
			[self finishWithNotificationName:VideoUploadFailed object:self.media userInfo:nil];
	}

    [request release]; request = nil;
}

- (void)requestFailed:(ASIHTTPRequest *)req {
	[self updateStatus:@"Upload failed. Please try again."];
	NSLog(@"connection failed: %@", [request responseData]);
	
	[NSThread sleepForTimeInterval:2.0];
	
    self.media.remoteStatus = MediaRemoteStatusFailed;
	if([self.media.mediaType isEqualToString:@"image"])
		[self stopWithNotificationName:@"ImageUploadFailed"];
	else if([self.media.mediaType isEqualToString:@"video"])
		[self stopWithNotificationName:@"VideoUploadFailed"];
	
    [request release]; request = nil;
}

- (void)connection:(NSURLConnection *)conn didFailWithError:(NSError *)error {
	[self updateStatus:@"Upload failed. Please try again."];
	NSLog(@"connection failed: %@", [error localizedDescription]);
	
    self.media.remoteStatus = MediaRemoteStatusFailed;
	if([self.media.mediaType isEqualToString:@"image"])
		[self stopWithNotificationName:@"ImageUploadFailed"];
	else if([self.media.mediaType isEqualToString:@"video"])
		[self stopWithNotificationName:@"VideoUploadFailed"];

    [request release]; request = nil;
}

#pragma mark -
#pragma mark Dealloc

- (void)dealloc {
    [self stopWithStatus:@"Stopped"];

    request.delegate = nil;
    [request release];
	[stopButton release];
	[messageLabel release];
	[progressView release];
	
    [super dealloc];
}


@end
