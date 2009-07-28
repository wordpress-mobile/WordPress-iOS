//
//  ImageCache.h
//  WordPress
//
//  Created by Josh Bassett on 15/07/09.
//

#import <Foundation/Foundation.h>


@interface ImageCache : NSObject {
@private
    NSMutableDictionary *_data;
}

+ (ImageCache *)sharedImageCache;

- (void)storeData:(NSData *)data forURL:(NSURL *)url;
- (NSData *)dataForURL:(NSURL *)url;

@end
