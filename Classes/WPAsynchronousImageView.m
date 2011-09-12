//
//  WPAsynchronousImageView.m
//  WordPress
//
//  Created by Gareth Townsend on 10/07/09.
//
//  Adapted from: http://www.markj.net/iphone-asynchronous-table-image/
//

#import "WPAsynchronousImageView.h"

#import "ImageCache.h"


@interface WPAsynchronousImageView (Private)

- (void)releaseConnectionAndData;

@end


@implementation WPAsynchronousImageView

@synthesize isWPCOM, isBlavatar;

#pragma mark -
#pragma mark Memory Management

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.contentMode = UIViewContentModeScaleAspectFit;
    }
    
    return self;
}

- (void)dealloc {
    [self releaseConnectionAndData];
    [super dealloc];
}

#pragma mark -
#pragma mark NSURLConnection Delegate Methods

- (void)connection:(NSURLConnection *)theConnection didReceiveData:(NSData *)incrementalData {
    if (data == nil) {
        data = [[NSMutableData alloc] initWithCapacity:2048];
    }

    [data appendData:incrementalData];
}

- (void)connection:(NSURLConnection *)theConnection didReceiveResponse:(NSURLResponse *)response {
    if ([response respondsToSelector:@selector(statusCode)])
    {
        int statusCode = [((NSHTTPURLResponse *)response) statusCode];
        if (statusCode == 404)
        {
            [theConnection cancel];  // stop connecting; no more delegate messages
        }
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)theConnection {
    ImageCache *cache =  [ImageCache sharedImageCache];
	
    if (data != nil) {
		[cache storeData:data forURL:url];
        self.image = [UIImage imageWithData:data];
	} else {
        self.image = nil;
    }

    [self releaseConnectionAndData];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [self releaseConnectionAndData];    
}

#pragma mark -
#pragma mark Public Methods

- (void)loadImageFromURL:(NSURL *)theUrl {
    ImageCache *cache =  [ImageCache sharedImageCache];
    
    if (isBlavatar) {
        if (isWPCOM)
            self.image = [UIImage imageNamed:@"blavatar-wpcom.png"];
        else
            self.image = [UIImage imageNamed:@"blavatar-wporg.png"];
    }
    
    [self releaseConnectionAndData];

    url = [theUrl retain];
    NSData *cachedData = [cache dataForURL:url];

    if (cachedData) {
        self.image = [UIImage imageWithData:cachedData];
    } else if (!isBlavatar) {
        self.image = nil;        
    }

    WordPressAppDelegate *appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:60.0];
    [request setValue:[appDelegate applicationUserAgent] forHTTPHeaderField:@"User-Agent"];
    
    //lazy load the image while scrolling, from stackoverflow.com/questions/1826913/delayed-uiimageview-rendering-in-uitableview
    connection = [[NSURLConnection alloc]
                                   initWithRequest:request
                                   delegate:self
                                   startImmediately:NO];
    [connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    [connection start];
}

#pragma mark -
#pragma mark Private Methods

- (void)releaseConnectionAndData {
    if (connection) {
        [connection cancel];
        [connection release];
        connection = nil;
    }

    if (data) {
        [data release];
        data = nil;
    }

    if (url) {
        [url release];
        url = nil;
    }
}

@end
