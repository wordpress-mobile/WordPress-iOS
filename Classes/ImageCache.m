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
    if (self = [super init]) {
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

- (void)storeData:(NSData *)data forURL:(NSURL *)url {
    NSString *urlString = [url description];
    [_data setObject:data forKey:urlString];
}

- (NSData *)dataForURL:(NSURL *)url {
    NSString *urlString = [url description];
    return [_data valueForKey:urlString];
}

@end
