//
//  ImageCache.m
//  WordPress
//
//  Created by Josh Bassett on 15/07/09.
//

#import "ImageCache.h"


@implementation ImageCache

static ImageCache *sharedImageCache;

- (id)init {
    if ((self = [super init])) {
        _data = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

- (void)dealloc {
    [_data release];
    [super dealloc];
}

+ (ImageCache *)sharedImageCache {
    if (!sharedImageCache) {
        sharedImageCache = [[ImageCache alloc] init];
    }

    return sharedImageCache;
}

- (NSString *)cacheDir {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    if ([paths count] > 0) {
        return [paths objectAtIndex:0];
    }
    return nil;
}

- (NSString *)pathForURL:(NSURL *)url {
    NSString *filePath = [url absoluteString];
    // FIXME: use regexp when deprecating iOS 3.x
    // See NSRegularExpressionSearch
    filePath = [filePath stringByReplacingOccurrencesOfString:@"/" withString:@""];
    return [NSString stringWithFormat:@"%@/%@",
             [self cacheDir],
             filePath];
}

- (void)storeData:(NSData *)data forURL:(NSURL *)url {
    NSString *urlString = [url description];
	if (data != nil) {
		[_data setObject:data forKey:urlString];
        NSString *path = [self pathForURL:url];
        [data writeToFile:path atomically:YES];
	}
}

- (NSData *)dataForURL:(NSURL *)url {
    NSString *urlString = [url description];
    NSData *cached = nil;
    cached = [_data valueForKey:urlString];
    if (cached) {
        return cached;
    } else {
        return [NSData dataWithContentsOfFile:[self pathForURL:url]];
    }
}

@end
