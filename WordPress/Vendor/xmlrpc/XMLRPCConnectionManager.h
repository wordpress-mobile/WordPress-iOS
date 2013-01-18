#import <Foundation/Foundation.h>
#import "XMLRPCConnectionDelegate.h"

@class XMLRPCConnection, XMLRPCRequest;

@interface XMLRPCConnectionManager : NSObject {
    NSMutableDictionary *myConnections;
}

+ (XMLRPCConnectionManager *)sharedManager;

#pragma mark -

- (NSString *)spawnConnectionWithXMLRPCRequest: (XMLRPCRequest *)request delegate: (id<XMLRPCConnectionDelegate>)delegate;

#pragma mark -

- (NSArray *)activeConnectionIdentifiers;

- (int)numberOfActiveConnections;

#pragma mark -

- (XMLRPCConnection *)connectionForIdentifier: (NSString *)identifier;

#pragma mark -

- (void)closeConnectionForIdentifier: (NSString *)identifier;

- (void)closeConnections;

@end
