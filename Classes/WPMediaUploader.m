//
//  WPMediaUploader.m
//  WordPress
//
//  Created by Chris Boyd on 8/3/10.

#import "WPMediaUploader.h"


@implementation WPMediaUploader
@synthesize messageLabel, progressView, filename, video, payload, connection, urlResponse, urlRequest, filesize, orientation;

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
}

#pragma mark -
#pragma mark Custom methods

- (void)start {
	[self reset];
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	
	// Build our XML-RPC request
	NSMutableDictionary *videoParams = [NSMutableDictionary dictionary];
	[videoParams setValue:@"video/quicktime" forKey:@"type"];
	[videoParams setValue:video forKey:@"bits"];
	[videoParams setValue:filename forKey:@"name"];
	[videoParams setValue:nil forKey:@"categories"];
	[videoParams setValue:@"" forKey:@"description"];
	
	NSArray *args = [NSArray arrayWithObjects:[[[BlogDataManager sharedDataManager] currentBlog] valueForKey:kBlogId],
					 [[[BlogDataManager sharedDataManager] currentBlog] valueForKey:@"username"],
					 [[BlogDataManager sharedDataManager] getPasswordFromKeychainInContextOfCurrentBlog:[[BlogDataManager sharedDataManager] currentBlog]],
					 videoParams, nil];
	
	NSMutableDictionary *xmlrpcParams = [[NSMutableDictionary alloc] init];
	[xmlrpcParams setObject:[[[BlogDataManager sharedDataManager] currentBlog] valueForKey:@"xmlrpc"] forKey:kURL];
	[xmlrpcParams setObject:@"metaWeblog.newMediaObject" forKey:kMETHOD];
	[xmlrpcParams setObject:args forKey:kMETHODARGS];
	
	// Execute the XML-RPC request
	XMLRPCRequest *xmlrpcRequest = [[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:[xmlrpcParams valueForKey:kURL]]];
	[xmlrpcRequest setMethod:[xmlrpcParams valueForKey:kMETHOD] withObjects:[xmlrpcParams valueForKey:kMETHODARGS]];
	
	urlRequest = [xmlrpcRequest request];
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
	[xmlrpcParams release];
	[xmlrpcRequest release];
}

- (void)stop {
	[connection cancel];
}

- (void)reset {
	self.messageLabel.text = @"Uploading video...";
	self.progressView.progress = 0.0;
	self.progressView.hidden = NO;
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
				self.messageLabel.text = errorString;
			}
			else {
				XMLRPCResponse *xmlrpcResponse = [[XMLRPCResponse alloc] initWithData:payload];
				NSDictionary *responseMeta = [xmlrpcResponse object];
				
				if ([xmlrpcResponse isKindOfClass:[NSError class]]) {
					[[NSNotificationCenter defaultCenter] postNotificationName:VideoUploadFailed object:nil];
				}
				else {
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
				
				[xmlrpcResponse release];
			}

		}
		
		[str release];
	}
}

- (void)connection:(NSURLConnection *)conn didFailWithError:(NSError *)error {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	[payload setLength:0];
	self.messageLabel.text = @"Upload failed. Please try again.";
	self.progressView.hidden = YES;
	[self.view setNeedsDisplay];
}

#pragma mark -
#pragma mark Dealloc

- (void)dealloc {
	[connection release];
	[urlResponse release];
	[urlRequest release];
	[payload release];
	[filename release];
	[video release];
	[messageLabel release];
	[progressView release];
    [super dealloc];
}


@end
