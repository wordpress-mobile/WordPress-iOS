@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@protocol WordPressOrgXMLRPCApiInterfacing <NSObject>

- (NSProgress *)callMethod:(NSString *)method
                parameters:(NSArray * _Nullable)parameters
                   success:(void (^)(id responseObject, NSHTTPURLResponse * _Nullable httpResponse))success
                   failure:(void (^)(NSError *error, NSHTTPURLResponse * _Nullable httpResponse))failure;

- (NSProgress *)streamCallMethod:(NSString *)method
                      parameters:(NSArray * _Nullable)parameters
                         success:(void (^)(id responseObject, NSHTTPURLResponse * _Nullable httpResponse))success
                         failure:(void (^)(NSError *error, NSHTTPURLResponse * _Nullable httpResponse))failure;

@end

NS_ASSUME_NONNULL_END
