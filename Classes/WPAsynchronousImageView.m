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

@implementation WPAsynchronousImageView

#pragma mark -
#pragma mark Memory Management

- (void)dealloc {
    [connection cancel];
    [connection release];
    [data release];
    [super dealloc];
}

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor lightGrayColor];
    }

    return self;
}

#pragma mark -
#pragma mark Image Loading
- (void)loadImageFromURL:(NSURL *)url {
    if (connection != nil) {
        [connection release];
    }

    if (data != nil) {
        [data release];
    }

    NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
    connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
}

- (void)connection:(NSURLConnection *)theConnection didReceiveData:(NSData *)incrementalData {
    if (data == nil) {
        data = [[NSMutableData alloc] initWithCapacity:2048];
    }

    [data appendData:incrementalData];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)theConnection {
    [connection release];
    connection = nil;

    if ([[self subviews] count] > 0) {
        [[[self subviews] objectAtIndex:0] removeFromSuperview];
    }

    UIImageView *imageView = [[[UIImageView alloc] initWithImage:[UIImage imageWithData:data]] autorelease];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.autoresizingMask = (UIViewAutoresizingFlexibleWidth || UIViewAutoresizingFlexibleHeight);
    [self addSubview:imageView];
    imageView.frame = self.bounds;
    [imageView setNeedsLayout];
    [self setNeedsLayout];

    [data release];
    data = nil;
}

@end
