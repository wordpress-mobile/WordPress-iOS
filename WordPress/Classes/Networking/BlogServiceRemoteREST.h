#import <Foundation/Foundation.h>
#import "BlogServiceRemote.h"

@class WordPressComApi;

@interface BlogServiceRemoteREST : NSObject<BlogServiceRemote>

- (id)initWithApi:(WordPressComApi *)api;

@end
