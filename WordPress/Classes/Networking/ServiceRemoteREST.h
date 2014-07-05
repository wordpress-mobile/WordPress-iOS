#import <Foundation/Foundation.h>

@class WordPressComApi;

@protocol ServiceRemoteREST <NSObject>
- (id)initWithApi:(WordPressComApi *)api;
@end
