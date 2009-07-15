//
//  WPAsynchronousImageView.m
//  WordPress
//
//  Created by Gareth Townsend on 10/07/09.
//  Copyright 2009 Clear Interactive. All rights reserved.
//
//  Adapted from: http://www.markj.net/iphone-asynchronous-table-image/
//

#import "WPAsynchronousImageView.h"


@interface WPAsynchronousImageView (Private)

- (void)releaseConnectionAndData;

@end


@implementation WPAsynchronousImageView

#pragma mark -
#pragma mark Memory Management

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor lightGrayColor];
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
    self.image = [UIImage imageWithData:data];
    [self releaseConnectionAndData];
}

#pragma mark -
#pragma mark Public Methods

- (void)loadImageFromURL:(NSURL *)url {
    self.image = nil;
    [self releaseConnectionAndData];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
    connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
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
}

@end
