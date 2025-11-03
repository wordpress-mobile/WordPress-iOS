#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RemotePostTerm : NSObject

@property (nonatomic, strong) NSNumber *termID;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *slug;
@property (nonatomic, strong) NSString *taxonomySlug;
@property (nonatomic, strong) NSString *termDescription;
@property (nonatomic, strong) NSNumber *count;

- (instancetype)initWithXMLRPCResponse:(NSDictionary *)response;
- (instancetype)initWithRESTAPIResponse:(NSDictionary *)response taxonomySlug:(NSString *)taxonomySlug;

- (NSDictionary *)RESTAPIRepresentation;

+ (NSDictionary<NSString *, NSArray<NSString *> *> *)simpleMappingRepresentation:(NSArray<RemotePostTerm *> *)terms;

@end

NS_ASSUME_NONNULL_END
