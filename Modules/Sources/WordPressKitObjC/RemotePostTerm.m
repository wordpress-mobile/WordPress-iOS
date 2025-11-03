#import "RemotePostTerm.h"

@import NSObject_SafeExpectations;

@implementation RemotePostTerm

- (instancetype)initWithXMLRPCResponse:(NSDictionary *)response
{
    self = [super init];
    if (self) {
        self.termID = [response numberForKey:@"term_id"];
        self.name = [response stringForKey:@"name"];
        self.slug = [response stringForKey:@"slug"];
        self.taxonomySlug = [response stringForKey:@"taxonomy"];
        self.termDescription = [response stringForKey:@"description"];
        self.count = [response numberForKey:@"count"];
    }
    return self;
}

- (instancetype)initWithRESTAPIResponse:(NSDictionary *)response taxonomySlug:(NSString *)taxonomySlug
{
    self = [super init];
    if (self) {
        self.termID = [response numberForKey:@"ID"];
        self.name = [response stringForKey:@"name"];
        self.slug = [response stringForKey:@"slug"];
        self.taxonomySlug = taxonomySlug;
        self.termDescription = [response stringForKey:@"description"];
        self.count = [response numberForKey:@"post_count"];
    }
    return self;
}

- (NSDictionary *)RESTAPIRepresentation
{
    return @{
        @"ID": self.termID,
        @"name": self.name,
        @"slug": self.slug,
        @"description": self.termDescription ?: @"",
        @"post_count": self.count
    };
}

+ (NSDictionary<NSString *, NSArray<NSString *> *> *)simpleMappingRepresentation:(NSArray<RemotePostTerm *> *)terms
{
    NSMutableDictionary<NSString *, NSMutableArray<NSString *> *> *dict = [NSMutableDictionary dictionary];
    for (RemotePostTerm *term in terms) {
        NSMutableArray *termNames = dict[term.taxonomySlug];
        if (termNames == nil) {
            termNames = [NSMutableArray array];
            dict[term.taxonomySlug] = termNames;
        }
        [termNames addObject:term.name];
    }
    return [dict copy];
}

- (NSString *)debugDescription
{
    NSDictionary *properties = @{
                                 @"ID": self.termID,
                                 @"name": self.name
                                 };
    return [NSString stringWithFormat:@"<%@: %p> (%@)", NSStringFromClass([self class]), self, properties];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p> %@[%@]", NSStringFromClass([self class]), self, self.name, self.termID];
}

@end
