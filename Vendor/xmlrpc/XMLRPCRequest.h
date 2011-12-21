#import <Foundation/Foundation.h>

@class XMLRPCEncoder;

@interface XMLRPCRequest : NSObject {
    NSMutableURLRequest *myRequest;
    XMLRPCEncoder *myXMLEncoder;
    BOOL streamRequestFromDisk;
}

- (id)initWithURL: (NSURL *)URL;

#pragma mark -

- (void)setURL: (NSURL *)URL;

- (NSURL *)URL;

#pragma mark -

- (void)setUserAgent: (NSString *)userAgent;

- (NSString *)userAgent;

#pragma mark -

- (void)setMethod: (NSString *)method;

- (void)setMethod: (NSString *)method withParameter: (id)parameter;

- (void)setMethod: (NSString *)method withParameters: (NSArray *)parameters;

#pragma mark -

- (NSString *)method;

- (NSArray *)parameters;

#pragma mark -

- (NSString *)body;

- (NSInputStream *)bodyStream;

- (NSNumber *)bodyLength;

#pragma mark -

- (NSURLRequest *)request;

#pragma mark -

- (void)setValue: (NSString *)value forHTTPHeaderField: (NSString *)header;

#pragma mark -

- (BOOL)streamRequestFromDisk;

- (void)setStreamRequestFromDisk:(BOOL)shouldStream;

@end
