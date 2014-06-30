// SPDiffable.h

@class SPGhost;
@class SPBucket;

@protocol SPDiffable <NSObject>

@required
@property (nonatomic, strong) SPGhost *ghost;
@property (nonatomic, copy) NSString *ghostData;
@property (nonatomic, copy) NSString *simperiumKey;
@property (nonatomic, weak) SPBucket *bucket;

- (void)simperiumSetValue:(id)value forKey:(NSString *)key;
- (id)simperiumValueForKey:(NSString *)key;
- (void)loadMemberData:(NSDictionary *)data;
- (void)willBeRead;
- (NSDictionary *)dictionary;
- (NSString *)version;
- (id)object;

@optional
- (NSString *)getSimperiumKeyFromLegacyKey;
- (BOOL)shouldOverwriteLocalChangesFromIndex;

@end
