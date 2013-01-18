#import <Foundation/Foundation.h>
#import "XMLRPCConnectionDelegate.h"

@class XMLRPCConnectionManager, XMLRPCRequest, XMLRPCResponse;

@interface XMLRPCConnection : NSObject {
    XMLRPCConnectionManager *myManager;
    XMLRPCRequest *myRequest;
    NSString *myIdentifier;
    NSMutableData *myData;
    NSURLConnection *myConnection;
    id<XMLRPCConnectionDelegate> myDelegate;
}

- (id)initWithXMLRPCRequest: (XMLRPCRequest *)request delegate: (id<XMLRPCConnectionDelegate>)delegate manager: (XMLRPCConnectionManager *)manager;

#pragma mark -

+ (XMLRPCResponse *)sendSynchronousXMLRPCRequest: (XMLRPCRequest *)request error: (NSError **)error;

#pragma mark -

- (NSString *)identifier;

#pragma mark -

- (id<XMLRPCConnectionDelegate>)delegate;

#pragma mark -

- (void)cancel;

@end
