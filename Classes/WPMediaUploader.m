//
//  WPMediaUploader.m
//  WordPress
//
//  Created by Chris Boyd on 8/3/10.

#import "WPMediaUploader.h"


@implementation WPMediaUploader
@synthesize messageLabel, mediaType, progressView, filename, bits, payload, connection, urlResponse, urlRequest;
@synthesize filesize, orientation, xmlrpcURL, xmlrpcHost;

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
}

#pragma mark -
#pragma mark Custom methods

- (void)start {
	[self reset];
	[BlogDataManager sharedDataManager].shouldStopSyncingBlogs = YES;
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	
	// Build our XML-RPC request
	NSMutableDictionary *mediaParams = [NSMutableDictionary dictionary];
	
	if(mediaType == kImage) {
		[mediaParams setValue:@"image/jpeg" forKey:@"type"];
		self.messageLabel.text = @"Uploading image...";
	}
	else if(mediaType == kVideo) {
		[mediaParams setValue:@"video/quicktime" forKey:@"type"];
		self.messageLabel.text = @"Uploading video...";
	}
	[self.messageLabel setNeedsLayout];
	
	[mediaParams setValue:filename forKey:@"name"];
	[mediaParams setValue:bits forKey:@"bits"];
	
	NSArray *args = [NSArray arrayWithObjects:[[[BlogDataManager sharedDataManager] currentBlog] valueForKey:kBlogId],
					 [[[BlogDataManager sharedDataManager] currentBlog] valueForKey:@"username"],
					 [[BlogDataManager sharedDataManager] getPasswordFromKeychainInContextOfCurrentBlog:[[BlogDataManager sharedDataManager] currentBlog]],
					 mediaParams, nil];
	
	NSMutableDictionary *xmlrpcParams = [[NSMutableDictionary alloc] init];
	[xmlrpcParams setObject:@"metaWeblog.newMediaObject" forKey:kMETHOD];
    self.xmlrpcURL = [[[BlogDataManager sharedDataManager] currentBlog] valueForKey:@"xmlrpc"];
	self.xmlrpcHost = [[[BlogDataManager sharedDataManager] currentBlog] valueForKey:@"url"];
	[xmlrpcParams setObject:args forKey:kMETHODARGS];
	
	// Execute the XML-RPC request
	XMLRPCRequest *xmlrpcRequest = [[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:self.xmlrpcHost]];
	[xmlrpcRequest setMethod:[xmlrpcParams valueForKey:kMETHOD] withObjects:[xmlrpcParams valueForKey:kMETHODARGS]];
	[xmlrpcParams release];
	
	[self createURLRequest:xmlrpcRequest];
	connection = [[NSURLConnection alloc] initWithRequest:urlRequest delegate:self];
	if (connection) {
		payload = [[NSMutableData data] retain];
	}
	else {
		UIAlertView *alert = [[UIAlertView alloc] init];
		[alert addButtonWithTitle:@"OK"];
		[alert setTitle:@"Unable to start upload."];
		[alert show];
		[alert release];
	}
	[xmlrpcRequest release];
}

- (void)stop {
	[connection cancel];
	[BlogDataManager sharedDataManager].shouldStopSyncingBlogs = NO;
}

- (void)reset {
	self.messageLabel.text = @"Uploading media...";
	self.progressView.progress = 0.0;
	self.progressView.hidden = NO;
	[BlogDataManager sharedDataManager].shouldStopSyncingBlogs = NO;
}

- (void)createURLRequest:(XMLRPCRequest *)xmlrpc {
	NSMutableURLRequest *_request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:self.xmlrpcURL]];
	NSNumber *length = [NSNumber numberWithInt:[bits length]];
	
	if (bits != nil) {
		[_request setHTTPMethod: @"POST"];
		
		if ([_request valueForHTTPHeaderField: @"Content-Length"] == nil)
		{
			[_request addValue: @"text/xml" forHTTPHeaderField: @"Content-Type"];
		}
		else
		{
			[_request setValue: @"text/xml" forHTTPHeaderField: @"Content-Type"];
		}
		
		if ([_request valueForHTTPHeaderField: @"Content-Length"] == nil)
		{
			[_request addValue: [length stringValue] forHTTPHeaderField: @"Content-Length"];
		}
		else
		{
			[_request setValue: [length stringValue] forHTTPHeaderField: @"Content-Length"];
		}
		
		[_request setHTTPBody:[xmlrpc.source dataUsingEncoding:NSUTF8StringEncoding]];
		
		urlRequest = (NSURLRequest *)_request;
	}
}

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

#pragma mark -
#pragma mark NSURLConnection delegate

- (void)connection:(NSURLConnection *)conn didReceiveResponse:(NSURLResponse *)response {	
	[self.payload setLength:0];
	[self setUrlResponse:response];
}

- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite {
    float progress = [[NSNumber numberWithInteger:totalBytesWritten] floatValue];
	float total = [[NSNumber numberWithInteger: totalBytesExpectedToWrite] floatValue];
	self.progressView.progress = progress/total;
	
	if(progress == total) {
		self.messageLabel.text = @"Processing...";
	}
}

- (void)connection:(NSURLConnection *)conn didReceiveData:(NSData *)data {
	[self.payload appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)conn {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	[BlogDataManager sharedDataManager].shouldStopSyncingBlogs = NO;
	self.progressView.progress = 1.0;
	conn = nil;
	
	if(payload != nil)
	{
		NSString  *str = [[NSString alloc] initWithData:payload encoding:NSUTF8StringEncoding];
		if ( ! str ) {
			str = [[NSString alloc] initWithData:payload encoding:[NSString defaultCStringEncoding]];
			payload = (NSMutableData *)[[str dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES] retain];
		}
		
		if ([urlResponse isKindOfClass:[NSHTTPURLResponse class]]) {
			if ([(NSHTTPURLResponse *)urlResponse statusCode] >= 400) {
				NSString *errorIntString = [NSString stringWithFormat:@"%d", [(NSHTTPURLResponse *)urlResponse statusCode]];
				NSString *stringForStatusCode = [NSHTTPURLResponse localizedStringForStatusCode:[(NSHTTPURLResponse *)urlResponse statusCode]];
				NSString *errorString = [[errorIntString stringByAppendingString:@" "] stringByAppendingString:stringForStatusCode];
				//NSInteger code = -1; //This is not significant, just a number with no meaning
				//NSDictionary *usrInfo = [NSDictionary dictionaryWithObject:errorString forKey:NSLocalizedDescriptionKey];
				//NSError *err = [NSError errorWithDomain:@"org.wordpress.iphone" code:code userInfo:usrInfo];
				NSLog(@"urlResponse: %@", urlResponse);
				self.messageLabel.text = errorString;
				[[NSNotificationCenter defaultCenter] postNotificationName:VideoUploadFailed object:nil];
			}
			else {
				XMLRPCResponse *xmlrpcResponse = [[XMLRPCResponse alloc] initWithData:payload];
				NSDictionary *responseMeta = [xmlrpcResponse object];
				
				if ([xmlrpcResponse isKindOfClass:[NSError class]]) {
					[[NSNotificationCenter defaultCenter] postNotificationName:VideoUploadFailed object:nil];
				}
				else if(mediaType == kVideo) {
					NSLog(@"responseMeta: %@", responseMeta);
					NSMutableDictionary *videoMeta = [[NSMutableDictionary alloc] init];
					if([responseMeta objectForKey:@"videopress_shortcode"] != nil)
						[videoMeta setObject:[responseMeta objectForKey:@"videopress_shortcode"] forKey:@"shortcode"];
					
					if([responseMeta objectForKey:@"url"] != nil)
						[videoMeta setObject:[responseMeta objectForKey:@"url"] forKey:@"url"];
					
					if(videoMeta.count > 0) {
						[videoMeta setValue:[NSNumber numberWithInt:orientation] forKey:@"orientation"];
						[[NSNotificationCenter defaultCenter] postNotificationName:VideoUploadSuccessful 
																			object:self 
																		  userInfo:videoMeta];
					}
					[videoMeta release];
				}
				else if(mediaType == kImage) {
					NSLog(@"responseMeta: %@", responseMeta);
					NSMutableDictionary *imageMeta = [[NSMutableDictionary alloc] init];
					[[NSNotificationCenter defaultCenter] postNotificationName:ImageUploadSuccessful 
																		object:self 
																	  userInfo:imageMeta];
				}

				
				[xmlrpcResponse release];
			}

		}
		
		[str release];
	}
}

- (void)connection:(NSURLConnection *)conn didFailWithError:(NSError *)error {
	NSLog(@"error: %@", error);
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	[payload setLength:0];
	self.messageLabel.text = @"Upload failed. Please try again.";
	self.progressView.hidden = YES;
	[self.view setNeedsDisplay];
}

#pragma mark -
#pragma mark Dealloc

- (void)dealloc {
	[xmlrpcURL release];
	[xmlrpcHost release];
	[connection release];
	[urlResponse release];
	[urlRequest release];
	[payload release];
	[filename release];
	[bits release];
	[messageLabel release];
	[progressView release];
    [super dealloc];
}


@end
