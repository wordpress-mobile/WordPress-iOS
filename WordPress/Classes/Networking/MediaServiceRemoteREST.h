#import <Foundation/Foundation.h>
#import "MediaServiceRemote.h"

@class WordPressComApi;

@interface MediaServiceRemoteREST : NSObject <MediaServiceRemote>
- (id)initWithApi:(WordPressComApi *)api;
@end
