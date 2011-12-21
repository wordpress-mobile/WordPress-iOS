#import "XMLRPCRequest.h"
#import "XMLRPCEncoder.h"

@implementation XMLRPCRequest

- (id)initWithURL: (NSURL *)URL {
    self = [super init];
    if (self) {
        if (URL) {
            myRequest = [[NSMutableURLRequest alloc] initWithURL: URL];
        } else {
            myRequest = [[NSMutableURLRequest alloc] init];
        }
        
        myXMLEncoder = [[XMLRPCEncoder alloc] init];
    }
    
    return self;
}

#pragma mark -

- (void)setURL: (NSURL *)URL {
    [myRequest setURL: URL];
}

- (NSURL *)URL {
    return [myRequest URL];
}

#pragma mark -

- (void)setUserAgent: (NSString *)userAgent {
    if (![self userAgent]) {
        [myRequest addValue: userAgent forHTTPHeaderField: @"User-Agent"];
    } else {
        [myRequest setValue: userAgent forHTTPHeaderField: @"User-Agent"];
    }
}

- (NSString *)userAgent {
    return [myRequest valueForHTTPHeaderField: @"User-Agent"];
}

#pragma mark -

- (void)setMethod: (NSString *)method {
    [myXMLEncoder setMethod: method withParameters: nil];
}

- (void)setMethod: (NSString *)method withParameter: (id)parameter {
    NSArray *parameters = nil;
    
    if (parameter) {
        parameters = [NSArray arrayWithObject: parameter];
    }
    
    [myXMLEncoder setMethod: method withParameters: parameters];
}

- (void)setMethod: (NSString *)method withParameters: (NSArray *)parameters {
    [myXMLEncoder setMethod: method withParameters: parameters];
}

#pragma mark -

- (NSString *)method {
    return [myXMLEncoder method];
}

- (NSArray *)parameters {
    return [myXMLEncoder parameters];
}

#pragma mark -

- (NSString *)body {
    return [myXMLEncoder encode];
}

- (NSInputStream *)bodyStream {
    return [myXMLEncoder encodedStream];
}

- (NSNumber *)bodyLength {
    return [myXMLEncoder encodedLength];
}

#pragma mark -

- (NSURLRequest *)request {
    NSNumber *contentLength = [self bodyLength];
    
    if (!myRequest) {
        return nil;
    }
    
    [myRequest setHTTPMethod: @"POST"];
    
    if (![myRequest valueForHTTPHeaderField: @"Content-Type"]) {
        [myRequest addValue: @"text/xml" forHTTPHeaderField: @"Content-Type"];
    } else {
        [myRequest setValue: @"text/xml" forHTTPHeaderField: @"Content-Type"];
    }
    
    if (contentLength) {
        if (![myRequest valueForHTTPHeaderField: @"Content-Length"]) {
            [myRequest addValue: [contentLength stringValue] forHTTPHeaderField: @"Content-Length"];
        } else {
            [myRequest setValue: [contentLength stringValue] forHTTPHeaderField: @"Content-Length"];
        }
    }
    
    if (![myRequest valueForHTTPHeaderField: @"Accept"]) {
        [myRequest addValue: @"text/xml" forHTTPHeaderField: @"Accept"];
    } else {
        [myRequest setValue: @"text/xml" forHTTPHeaderField: @"Accept"];
    }
    
    if (![self userAgent]) {
      NSString *userAgent = [[NSUserDefaults standardUserDefaults] objectForKey:@"UserAgent"];
      if (userAgent) {
        [self setUserAgent:userAgent];
      }
    }
    
    if (streamRequestFromDisk) {
        [myRequest setHTTPBodyStream: [self bodyStream]];
    } else {
        [myRequest setHTTPBody: [[self body] dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    return (NSURLRequest *)myRequest;
}

#pragma mark -

- (void)setValue: (NSString *)value forHTTPHeaderField: (NSString *)header {
    [myRequest setValue: value forHTTPHeaderField: header];
}

#pragma mark -

- (BOOL)streamRequestFromDisk {
    return streamRequestFromDisk;
}

- (void)setStreamRequestFromDisk:(BOOL)shouldStream {
    streamRequestFromDisk = shouldStream;
}

#pragma mark -

- (void)dealloc {
    [myRequest release];
    [myXMLEncoder release];
    
    [super dealloc];
}

@end
