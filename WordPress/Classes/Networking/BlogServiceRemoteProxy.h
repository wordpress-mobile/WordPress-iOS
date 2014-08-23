#import <Foundation/Foundation.h>
#import "BlogServiceRemote.h"

@class BlogServiceRemoteXMLRPC, BlogServiceRemoteREST;

/**
 BlogServiceRemoteProxy acts as a proxy for remote requests
 
 Since it would be hard to implement REST support for every BlogServiceRemote
 method, this proxy will use REST when available and fall back to XML-RPC.
 */
@interface BlogServiceRemoteProxy : NSObject<BlogServiceRemote>

@property (nonatomic) BlogServiceRemoteXMLRPC *xmlrpcRemote;
@property (nonatomic) BlogServiceRemoteREST *restRemote;

- (id)initWithXMLRPCRemote:(BlogServiceRemoteXMLRPC *)xmlrpcRemote RESTRemote:(BlogServiceRemoteREST *)restRemote;

@end
