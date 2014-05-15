#import "WPMediaMetadataExtractor.h"
#import <ImageIO/ImageIO.h>

@implementation WPMediaMetadataExtractor

+ (NSDictionary *)metadataForAsset:(ALAsset *)asset enableGeolocation:(BOOL)enableGeolocation
{
    ALAssetRepresentation *rep = [asset defaultRepresentation];

    Byte *buf = malloc([rep size]);  // will be freed automatically when associated NSData is deallocated
    NSError *err = nil;
    NSUInteger bytes = [rep getBytes:buf fromOffset:0LL length:[rep size] error:&err];
    if (err || bytes == 0) {
        // Are err and bytes == 0 redundant? Doc says 0 return means
        // error occurred which presumably means NSError is returned.
        free(buf); // Free up memory so we don't leak.
        DDLogError(@"error from getBytes: %@", err);
       
        return nil;
    }
    NSData *imageJPEG = [NSData dataWithBytesNoCopy:buf
                                             length:[rep size]
                                       freeWhenDone:YES];  // YES means free malloc'ed buf that backs this when deallocated
   
    CGImageSourceRef source ;
    source = CGImageSourceCreateWithData((__bridge CFDataRef)imageJPEG, NULL);
   
    NSDictionary *metadata = (NSDictionary *)CFBridgingRelease(CGImageSourceCopyPropertiesAtIndex(source,0,NULL));
    CFRelease(source);

    // Make the metadata dictionary mutable so we can remove properties from it
    NSMutableDictionary *metadataAsMutable = [metadata mutableCopy];
   
    if (!enableGeolocation) {
       // We should remove the GPS info if the blog has the geolocation set to off
       [metadataAsMutable removeObjectForKey:@"{GPS}"];
    }
    [metadataAsMutable removeObjectForKey:@"Orientation"];
    [metadataAsMutable removeObjectForKey:@"{TIFF}"];
   
    return [NSDictionary dictionaryWithDictionary:metadataAsMutable];
}

@end
