#import <Foundation/Foundation.h>
#import "WordPress-Swift.h"

@class WordPressOrgXMLRPCApi;

NS_ASSUME_NONNULL_BEGIN

@interface ServiceRemoteWordPressXMLRPC : NSObject

- (id)initWithApi:(id<WordPressOrgXMLRPC>)api username:(NSString *)username password:(NSString *)password;

@property (nonatomic, readonly) id<WordPressOrgXMLRPC> api;

- (NSArray *)defaultXMLRPCArguments;
- (NSArray *)XMLRPCArgumentsWithExtra:(_Nullable id)extra;

@end

NS_ASSUME_NONNULL_END
