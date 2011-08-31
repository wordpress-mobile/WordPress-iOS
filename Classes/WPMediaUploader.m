//
//  WPMediaUploader.m
//  WordPress
//
//  Created by Chris Boyd on 8/3/10.
//  Code is poetry.

#import "WPMediaUploader.h"

@interface WPMediaUploader (Private)
- (void) displayResponseErrors;
- (void) displayErrors:(NSString *)status;
- (NSError *)errorWithResponse:(XMLRPCResponse *)res;
- (void) deleteEncodedTmpFile; 
@end


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
	 request.delegate = nil;
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
	[self updateStatus:NSLocalizedString(@"Cancelled.", @"")];
}

- (void)updateStatus:(NSString *)status {
    WPLog(@"Upload Status: %@", status);
	self.messageLabel.text = status;
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
	isAtomPub = NO;
	self.progressView.hidden = NO;
	
	if([self.media.mediaType isEqualToString:@"image"])
		[self updateStatus:NSLocalizedString(@"Uploading image...", @"")];
	else if([self.media.mediaType isEqualToString:@"video"])
		[self updateStatus:NSLocalizedString(@"Uploading video...", @"")];
    
    NSString *contentType = @"image/jpeg";
	if([self.media.mediaType isEqualToString:@"video"])
		contentType = @"video/mp4";
	
	request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:self.media.blog.xmlrpc]];
    NSString *version  = [[[NSBundle mainBundle] infoDictionary] valueForKey:[NSString stringWithFormat:@"CFBundleVersion"]];
	[request addRequestHeader:@"User-Agent" value:[NSString stringWithFormat:@"wp-iphone/%@",version]];
    [request addRequestHeader:@"Accept" value:@"*/*"];
    [request addRequestHeader:@"Content-Type" value:contentType];
	[request setDelegate:self];
	[request setValidatesSecureCertificate:NO]; 
	[request setShouldStreamPostDataFromDisk:YES];
	[request appendPostDataFromFile:self.localEncodedURL];
	[request setUploadProgressDelegate:self.media];
	[request setTimeOutSeconds:600];
    [request setNumberOfTimesToRetryOnTimeout:3];
	[request startAsynchronous];
    [request retain];
}

- (void)sendAtomPub {
    WPLog(@"%@ %@ (%@)", self, NSStringFromSelector(_cmd), self.media.filename);
	self.progressView.hidden = NO;
	isAtomPub = YES;
	
	if([self.media.mediaType isEqualToString:@"image"])
		[self updateStatus:NSLocalizedString(@"Uploading image...", @"")];
	else if([self.media.mediaType isEqualToString:@"video"])
		[self updateStatus:NSLocalizedString(@"Uploading video...", @"")];
	
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
    NSString *version  = [[[NSBundle mainBundle] infoDictionary] valueForKey:[NSString stringWithFormat:@"CFBundleVersion"]];
	[request addRequestHeader:@"User-Agent" value:[NSString stringWithFormat:@"wp-iphone/%@",version]];
	[request setValidatesSecureCertificate:NO]; 	
	[request setUsername:username];
	[request setPassword:password];
	[request setRequestMethod:@"POST"];
	[request addRequestHeader:@"Content-Type" value:contentType];
    [request addRequestHeader:@"Accept" value:@"*/*"];
	[request addRequestHeader:@"Content-Length" value:[NSString stringWithFormat:@"@d",[[attributes objectForKey:NSFileSize] intValue]]];
	[request setShouldStreamPostDataFromDisk:YES];
	[request setPostBodyFilePath:self.media.localURL];
	[request setDelegate:self];
	[request setTimeOutSeconds:600];
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
			if ([buttonTitle isEqualToString:NSLocalizedString(@"Yes", @"")]){
				[[UIApplication sharedApplication] openURL:[NSURL URLWithString: @"http://videopress.com"]];
			}
			else{
				[[NSUserDefaults standardUserDefaults] setObject:@"1" forKey:@"video_api_preference"];
				[[NSUserDefaults standardUserDefaults] synchronize];
				[self sendAtomPub];
			}
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
	
	// If encoded file already exists, don't try encoding again
    if (![[NSFileManager defaultManager] fileExistsAtPath:self.localEncodedURL]) {
		[self performSelectorOnMainThread:@selector(updateStatus:) withObject:NSLocalizedString(@"Encoding media...", @"") waitUntilDone:NO];
		
		NSFileHandle *originalFile, *encodedFile;
		
		// Open the original video file for reading
		originalFile = [NSFileHandle fileHandleForReadingAtPath:self.media.localURL];
		if (originalFile == nil) {
			[self displayErrors:NSLocalizedString(@"Encoding failed.", @"")];
			return;
		}
		
		// Create our XML-RPC payload file
		[[NSFileManager defaultManager] createFileAtPath:self.localEncodedURL
												contents:nil
											  attributes:nil];
		
		// Open XML-RPC file for writing
		encodedFile = [NSFileHandle fileHandleForWritingAtPath:self.localEncodedURL];
		if (encodedFile == nil) {
			[self displayErrors:NSLocalizedString(@"Encoding failed.", @"")];
			//[self performSelectorOnMainThread:@selector(updateStatus:) withObject:@"Encoding failed." waitUntilDone:NO];
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
			NSString *serializedString =  [[[NSString alloc] initWithData:serializedChunk encoding:NSUTF8StringEncoding] autorelease];
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
			[self performSelectorOnMainThread:@selector(updateStatus:) withObject:NSLocalizedString(@"Encoding finished.", @"") waitUntilDone:NO];
		else if([self.media.mediaType isEqualToString:@"video"])
			[self performSelectorOnMainThread:@selector(updateStatus:) withObject:NSLocalizedString(@"Encoding finished.", @"") waitUntilDone:NO];		
	}
	[self sendXMLRPC];

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


-(void) deleteEncodedTmpFile {
	if ([[NSFileManager defaultManager] fileExistsAtPath:self.localEncodedURL]) {
		NSError *error;
		BOOL success =  [[NSFileManager defaultManager] removeItemAtPath:self.localEncodedURL error:&error];
		if (!success) 
			NSLog(@"Error deleting data path: %@", [error localizedDescription]);
	}
}


#pragma mark ASIHTTPRequest delegate
- (void)requestFinished:(ASIHTTPRequest *)req {
	WPLog(@"requestFinished: %@", self);
	
	[self deleteEncodedTmpFile];
		  
	NSMutableDictionary *videoMeta = [[NSMutableDictionary alloc] init];
	NSMutableDictionary *imageMeta = [[NSMutableDictionary alloc] init];
	
	if([request responseString] != nil && ![[request responseString] isEmpty]) {
		@try{
			WPLog(@"response: %@", [request responseString]);
			if(isAtomPub) {
				if ([[request responseString] rangeOfString:@"AtomPub services are disabled"].location != NSNotFound){
					UIAlertView *uploadAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Sorry, upload failed", @"") 
																		  message:[request responseString] 
																		 delegate:self
																cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
					[uploadAlert show];
					[uploadAlert release];
					[self displayResponseErrors];
				} else {
					//TODO: we should use regxep to capture other type of errors!!
					//atom pub services could be enable but errors can occur.
					NSString *regEx = @"src=\"([^\"]*)\"";
					NSString *link = [[request responseString] stringByMatching:regEx capture:1];
					link = [link stringByReplacingOccurrencesOfString:@"\"" withString:@""];
					[videoMeta setObject:link forKey:@"url"];
					self.media.remoteURL = link;
					self.media.remoteStatus = MediaRemoteStatusSync;
					[self finishWithNotificationName:VideoUploadSuccessful object:self.media userInfo:videoMeta];
				}
			}
			else { //XML-RPC Response
				XMLRPCResponse *xmlrpcResponse = [[XMLRPCResponse alloc] initWithData:[request responseData]];
				NSError *err = nil;
				err = [self errorWithResponse:xmlrpcResponse];
				if (err) {

					NSString *faultString = [err localizedDescription];
					UIAlertView *uploadAlert;
					
					if([faultString rangeOfString:@"NSXMLParserErrorDomain"].location != NSNotFound) {
						//Error Domain=NSXMLParserErrorDomain Code=5 "The operation couldn\u2019t be completed. (NSXMLParserErrorDomain error 5.)	
						//this happens when there are server issues, such as memory issues or permissions issues.
						uploadAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Sorry, upload failed", @"") 
																 message:NSLocalizedString(@"There was an error processing your file. Please check the configuration of your blog.", @"")  
																delegate:self
													   cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
					}
					else if ( ([faultString rangeOfString:NSLocalizedString(@"Invalid file type", @"")].location != NSNotFound) &&
							 ([self.media.mediaType isEqualToString:@"video"]) ){
						//invalid file type && video: VideoPress suggest
						faultString = NSLocalizedString(@"To upload videos you need to have VideoPress installed. Would you like to learn more about VideoPress now?", @"");
						uploadAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Sorry, upload failed", @"") 
																 message:faultString 
																delegate:self
													   cancelButtonTitle:NSLocalizedString(@"No", @"") otherButtonTitles:nil];
						[uploadAlert addButtonWithTitle:NSLocalizedString(@"Yes", @"")];
					}
					else {
						//show a generic error
						uploadAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Sorry, upload failed", @"") 
																 message:faultString 
																delegate:self
													   cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
					}						
					[uploadAlert show];
					[uploadAlert release];
					[self displayResponseErrors];
				} else {
					//XML-RPC response OK
					NSDictionary *responseMeta = [xmlrpcResponse object];
					if ([xmlrpcResponse isKindOfClass:[NSError class]]) {
						[self displayResponseErrors];
					} else 
						if([xmlrpcResponse object] == nil ) {
							[self displayResponseErrors];
						}
						else if (![[xmlrpcResponse object] isKindOfClass:[NSDictionary class]]) {
							[self displayResponseErrors];
						} 
					
						else if([self.media.mediaType isEqualToString:@"video"]) {
							if([responseMeta objectForKey:@"videopress_shortcode"] != nil)
								self.media.shortcode = [responseMeta objectForKey:@"videopress_shortcode"];
							
							if([responseMeta objectForKey:@"url"] != nil)
								self.media.remoteURL = [responseMeta objectForKey:@"url"];
							
							self.media.remoteStatus = MediaRemoteStatusSync;
							[self finishWithNotificationName:VideoUploadSuccessful object:self.media userInfo:responseMeta];
						}
						else if([self.media.mediaType isEqualToString:@"image"]) {
							if([responseMeta objectForKey:@"url"] != nil)
								self.media.remoteURL = [responseMeta objectForKey:@"url"];
							self.media.remoteStatus = MediaRemoteStatusSync;
							[self finishWithNotificationName:ImageUploadSuccessful object:self.media userInfo:responseMeta];
						}
				}
				[xmlrpcResponse release];
			}
		}@catch (NSException *ex) {
			[self displayResponseErrors];
		}
		@finally {
			[videoMeta release];
			[imageMeta release];
		}
    }
	else {
		WPLog(@"connection failed: %@", [request responseData]);
		[self displayResponseErrors];
	}
	
    [request release]; request = nil;
}

- (void) displayErrors:(NSString *)status {
	[self updateStatus:status];		
	[NSThread sleepForTimeInterval:2.0];
	
	self.media.remoteStatus = MediaRemoteStatusFailed;
	if([self.media.mediaType isEqualToString:@"image"])
		[self finishWithNotificationName:ImageUploadFailed object:self.media userInfo:nil];
	else if([self.media.mediaType isEqualToString:@"video"])
		[self finishWithNotificationName:VideoUploadFailed object:self.media userInfo:nil];
}

- (void) displayResponseErrors {
	[self displayErrors:NSLocalizedString(@"Upload failed. Please try again.", @"")];		
}

- (NSError *)errorWithResponse:(XMLRPCResponse *)res {
    NSError *err = nil;
	
    if ([res isKindOfClass:[NSError class]]) {
        err = (NSError *)res;
    } else {
        if ([res isFault]) {
            NSDictionary *usrInfo = [NSDictionary dictionaryWithObjectsAndKeys:[res fault], NSLocalizedDescriptionKey, nil];
            err = [NSError errorWithDomain:@"org.wordpress.iphone" code:[[res code] intValue] userInfo:usrInfo];
        }
		
        if ([res isParseError]) {
            err = [res object];
        }
    }
    
	return err;
}


- (void)requestFailed:(ASIHTTPRequest *)req {

	[self deleteEncodedTmpFile];
	
	NSError *error = [req error];
	NSString *errorMessage = [error localizedDescription];
	WPLog(@"connection failed: %@", errorMessage);
	[self displayResponseErrors];
    [request release]; request = nil;
}

- (void)connection:(NSURLConnection *)conn didFailWithError:(NSError *)error {

	[self deleteEncodedTmpFile];
	
	WPLog(@"connection failed: %@", [error localizedDescription]);
	[self updateStatus:NSLocalizedString(@"Upload failed. Please try again.", @"")];

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
    [self stopWithStatus:NSLocalizedString(@"Stopped", @"")];

    request.delegate = nil;
    [request release];
	[stopButton release];
	[messageLabel release];
	[progressView release];
	
    [super dealloc];
}


@end
