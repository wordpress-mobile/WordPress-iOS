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

#pragma mark -
#pragma mark Memory Management

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
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

- (void)connectionDidFinishLoading:(NSURLConnection *)theConnection {
    ImageCache *cache =  [ImageCache sharedImageCache];
    [cache storeData:data forURL:url];

    self.image = [UIImage imageWithData:data];
    [self releaseConnectionAndData];
}

#pragma mark -
#pragma mark Public Methods

- (void)loadImageFromURL:(NSURL *)theUrl {
    ImageCache *cache =  [ImageCache sharedImageCache];

    [self releaseConnectionAndData];

    url = [theUrl retain];
    NSData *cachedData = [cache dataForURL:url];

    if (cachedData) {
        self.image = [UIImage imageWithData:cachedData];
    } else {
        self.image = nil;
        NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:60.0];
        connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    }
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
