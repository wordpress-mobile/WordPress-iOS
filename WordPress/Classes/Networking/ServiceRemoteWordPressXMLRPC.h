#import <Foundation/Foundation.h>

@class WordPressOrgXMLRPCApi;

NS_ASSUME_NONNULL_BEGIN

@interface ServiceRemoteWordPressXMLRPC : NSObject

- (id)initWithApi:(WordPressOrgXMLRPCApi *)api username:(NSString *)username password:(NSString *)password;

@property (nonatomic, readonly) WordPressOrgXMLRPCApi *api;

- (NSArray *)defaultXMLRPCArguments;
- (NSArray *)XMLRPCArgumentsWithExtra:(_Nullable id)extra;

@end

NS_ASSUME_NONNULL_END
