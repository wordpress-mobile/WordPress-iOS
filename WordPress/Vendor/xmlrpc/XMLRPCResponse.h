#import <Foundation/Foundation.h>

@class XMLRPCDecoder;

@interface XMLRPCResponse : NSObject {
    NSString *myBody;
    id myObject;
    BOOL isFault;
}

- (id)initWithData: (NSData *)data;

#pragma mark -

- (BOOL)isFault;

- (NSNumber *)faultCode;

- (NSString *)faultString;

#pragma mark -

- (id)object;

#pragma mark -

- (NSString *)body;

@end
