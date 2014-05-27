#import <Foundation/Foundation.h>
#import "AccountServiceRemote.h"

@class WordPressComApi;

@interface AccountServiceRemoteREST : NSObject <AccountServiceRemote>
- (id)initWithApi:(WordPressComApi *)api;
@end
