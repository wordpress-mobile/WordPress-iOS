#import <Foundation/Foundation.h>

@interface PrivateSiteURLProtocol : NSURLProtocol

/**
 (Un)RegisterPrivateSiteURLProtocol are convenience methods for registering and
 unregistering the protocol safely.
  
 For performance reasons we do not want to register the protocol for the 
 lifecycle of the app -- potentially `canInitWithRequest` would be called for every
 http request. Register the protocol for use when its needed and unregister it when 
 its not.  
 
 Use registerPrivateSiteURLProtocol and unregisterPrivateSiteURLProtocol to
 keep track of the number of users of the protocol.  The call to
 `NSURLProtcol unregisterClass:` is only made when there are no longer any uses
 remaining.  This will help avoid edgecases where the protcol could be potentially
 unregistered by one user immediately after another user had registered it.
 */
+ (void)registerPrivateSiteURLProtocol;
+ (void)unregisterPrivateSiteURLProtocol;

@end
