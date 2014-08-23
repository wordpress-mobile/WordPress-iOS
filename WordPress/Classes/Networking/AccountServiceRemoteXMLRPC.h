#import <Foundation/Foundation.h>
#import "AccountServiceRemote.h"

@class WordPressXMLRPCApi;

@interface AccountServiceRemoteXMLRPC : NSObject<AccountServiceRemote>
- (id)initWithApi:(WordPressXMLRPCApi *)api;
@end
