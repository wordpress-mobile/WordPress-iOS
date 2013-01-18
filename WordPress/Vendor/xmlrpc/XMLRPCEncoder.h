#import <Foundation/Foundation.h>

@interface XMLRPCEncoder : NSObject {
    NSString *myMethod;
    NSArray *myParameters;
    NSFileHandle *streamingCacheFile;
    NSString *streamingCacheFilePath;
}

- (NSString *)encode;

- (void)encodeForStreaming;

- (NSInputStream *)encodedStream;

- (NSNumber *)encodedLength;

#pragma mark -

- (void)setMethod: (NSString *)method withParameters: (NSArray *)parameters;

#pragma mark -

- (NSString *)method;

- (NSArray *)parameters;

@end
