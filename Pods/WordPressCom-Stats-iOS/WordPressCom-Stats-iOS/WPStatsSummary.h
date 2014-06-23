@interface WPStatsSummary : NSObject

@property (nonatomic, strong) NSNumber *totalCategories;
@property (nonatomic, strong) NSNumber *totalComments;
@property (nonatomic, strong) NSNumber *totalFollowersBlog;
@property (nonatomic, strong) NSNumber *totalFollowersComments;
@property (nonatomic, strong) NSNumber *totalPosts;
@property (nonatomic, strong) NSNumber *totalShares;
@property (nonatomic, strong) NSNumber *totalTags;
@property (nonatomic, strong) NSNumber *totalViews;
@property (nonatomic, strong) NSNumber *viewCountBest;
@property (nonatomic, strong) NSNumber *viewCountToday;
@property (nonatomic, strong) NSNumber *visitorCountToday;

- (id)initWithData:(NSDictionary *)summary;

@end
